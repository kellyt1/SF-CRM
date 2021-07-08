/*** 
 * Created By: Travis Bain, Slalom
 * Description: Batch job to query cases via CovidCases__x external object and create/update Cases and Person Accounts accordingly.
 * Also includes a portion of the routing logic in regards to updating existing cases, which performs checks for Call Attempts, Aging Out, etc.
 */

global class MEDSS_OutboundBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    @TestVisible
    private List<SObject> testDataset = null; // For testing ONLY
    global Integer queryLimit = 2000; //Recommended 2000 record limit as querying more can cause timeouts from S3
    global Integer recordCnt = 0; // Used to store total record count for sequential reading
    global String maxIntakeDate; // Used to store max intake DateTime for sequential reading

    global Iterable<SObject> start(Database.BatchableContext BC) {
        List<sObject> scope = new List<sObject>();
        String intakeDt = getMaxIntakeFromBatchHistory();

        if (testDataset != null) {
            return testDataset;
        }
		//The WHERE clause in the query below can be modified to change which cases are filtered out of the portal.
		//When the external object returns more than 2000 cases, the IntakeCompleteDateTime of the most recent record of the 2000
		//records that are pulled in is recorded in the BatchHistory and then used as a filter for the next batch to continue reading
		//sequentially from that point where the previous batch left off. Once we reach the end (less than <2000 records), the next batch
		//starts again from the oldest record.
        return [
            SELECT
                MnId__c,
                SubjectId__c,
                FirstName__c,
                MiddleName__c,
                LastName__c,
                StreetAddress__c,
                City__c,
                State__c,
                Zip__c,
                BirthDate__c,
                PreferredLanguage__c,
                Email__c,
                TelephoneCell__c,
                TelephoneHome__c,
                TelephoneWork__c,
                CaseId__c,
                CaseKey__c,
                IntakeCompleteDateTime__c,
                LatestCallAttemptDateTime__c,
                SpecimenDate__c,
                SubregionBasedJurisdiction__c,
                InterviewJurisdiction__c,
                County__c,
                ReservationName__c,
                TribeName__c,
                LanguageInterview__c,
                CaseInterviewStatus__c
            FROM CovidCases__x
            WHERE
                IntakeCompleteDateTime__c > :intakeDt
                AND (InterviewJurisdiction__c = 'MDH'
                OR InterviewJurisdiction__c = 'GEN'
                OR InterviewJurisdiction__c LIKE 'LPH-%')
            ORDER BY IntakeCompleteDateTime__c ASC
            LIMIT :queryLimit
        ];
    }

    global void execute(
        Database.BatchableContext BC,
        List<CovidCases__x> covidCaseList
    ) {
        // Find Max Intake Complete DateTime to store for later queries
        // Depends on Order By in SOQL
        recordCnt += covidCaseList.size();
        setMaxIntakeDate(
            covidCaseList[covidCaseList.size() - 1].IntakeCompleteDateTime__c
        );

        //Main method that handles mappings and Case/Account creation and updating
        handleOutboundCases(covidCaseList);
    }

    // If batches run out of order then preserve Max
    global void setMaxIntakeDate(String dtTm) {
        if (maxIntakeDate < dtTm) {
            maxIntakeDate = dtTm;
        }
    }

    @TestVisible
    private String getMaxIntakeFromBatchHistory() {
        String startDt = '01/01/2010 00:00 AM';
        Batch_History__c bHistory = MEDSS_Batch_Helper.getLatestBatchHistory();

        if (bHistory.Record_Count__c < 2000) {
            // Do nothing
        } else {
            startDt = bHistory.Max_DateTime__c;
        }
        return startDt;
    }

    @TestVisible
    private void handleOutboundCases(List<CovidCases__x> covidCaseList) {
        Map<String, Case> mapCases = new Map<String, Case>();
        Map<Id, Case> mapExistingCases = new Map<Id, Case>();
        Map<String, QueueSObject> mapQueues = new Map<String, QueueSObject>();
        Map<String, Account> mapPersonAccountsToUpsert = new Map<String, Account>();
        List<Case> medssEventsToInsert = new List<Case>();
        List<Case> listNonEnglish = new List<Case>();
        List<Case> listEnglish = new List<Case>();
        List<Account> personAccountsToUpsert = new List<Account>();
        Set<String> setSubjectIds = new Set<String>();
        Set<String> setMEDSSEventIds = new Set<String>();

        // Set up region map, get queues
        Map<String, Map<String, String>> mapRegions = MEDSS_Batch_Helper.regionMap;
        mapQueues = this.getMapCaseQueues();

        // Process each batch of records, default size is 200
        for (CovidCases__x covidCase : covidCaseList) {
            //Keep a unique set of Accounts based on SubjectId to avoid errors with upsert in the case that the same SubjectId happens
            //to come in twice in the same batch
            if (
                !mapPersonAccountsToUpsert.keySet()
                    .contains(covidCase.SubjectId__c)
            ) {
                Account personAccount = this.createAccount(covidCase);

                mapPersonAccountsToUpsert.put(
                    personAccount.SubjectId__c,
                    personAccount
                );
            }

            //Create MEDSS Event
            Case insertCase = createCase(covidCase);

            // TBAIN 12-7-2020: keep a map of only inserted records
            Boolean isAddedToQueue = false;

            insertCase.Origin = 'Phone';
            //Don't insert case if InterviewJurisdion = LPH-xx AND Subregion = NOREGION
            if (
                !setMEDSSEventIds.contains(insertCase.MEDSS_Event_ID__c) &&
                !(insertCase.InterviewJurisdictionCode__c.contains('LPH') &&
                insertCase.SubregionbasedJurisdictionCode__c == 'SR-NOREGION')
            ) {
                //Add non-English cases to a separate list to be inserted before the English caes. This should help prioritize 
                //non-English cases to CI's with non-English skills by utilizing language skill requirements + FIFO
                if (
                    insertCase.Preferred_Language_Unrestricted__c.containsIgnoreCase(
                        'English'
                    )
                ) {
                    listNonEnglish.add(insertCase);
                } else {
                    listEnglish.add(insertCase);
                }
                setMEDSSEventIds.add(insertCase.MEDSS_Event_Id__c);
                mapCases.put(insertCase.MEDSS_Event_Id__c, insertCase);
                setSubjectIds.add(insertCase.SubjectId__c);
            }
        }

        //PCG-482: Check if MEDSS Events already exist, and if so, perform existing case logic
        mapExistingCases = getMapOfExistingCasesAndUpdateStatus(mapCases);

        personAccountsToUpsert.addAll(mapPersonAccountsToUpsert.values());
        medssEventsToInsert.addAll(mapCases.values());

        try {
            // Insert Person Accounts
            Schema.SObjectField fld = Account.Fields.SubjectId__c;
            this.doDml(personAccountsToUpsert, fld);

            Map<String, Account> mapExistingAccounts = getMapOfExistingAccounts(
                setSubjectIds
            );

            // Related MEDSS Events to inserted PersonAccounts
            for (Case tempCase : medssEventsToInsert) {
                if (tempCase.SubjectId__c != null) {
                    tempCase.AccountId = mapExistingAccounts.get(
                            tempCase.SubjectId__c
                        )
                        .Id;
                    tempCase.contactId = mapExistingAccounts.get(
                            tempCase.SubjectId__c
                        )
                        .PersonContactId;

                    // prettier-ignore
                    System.debug(
                        'Existing Account. MN_ID__c: ' + tempCase.SubjectId__c +
                        ', AccountId: ' + mapPersonAccountsToUpsert.get(tempCase.SubjectId__c).Id +
                        ', ContactId: ' + mapPersonAccountsToUpsert.get(tempCase.SubjectId__c)
                            .PersonContactId
                    );
                }
            }

            //Perform DML
            fld = Case.Fields.MEDSS_Event_ID__c;
            this.doDml(listNonEnglish, fld);
            this.doDml(listEnglish, fld);

            //PCG-482: Pass existing cases directly to queueing logic to be re-queued
            if (!mapExistingCases.isEmpty()) {
                CaseTriggerHandler.routeUsingSkill(mapExistingCases);
            }
        } catch (Exception e) {
            System.debug(e);
        }
    }

    private void doDml(list<SObject> sObjs, Schema.SObjectField fld) {
        if (sObjs.isEmpty()) {
            return;
        }

        List<Database.UpsertResult> srList = new List<Database.UpsertResult>();

        srList.addAll(Database.upsert(sObjs, fld, false));

        // Iterate through each returned result
        for (Database.UpsertResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully insert. Object ID: ' + sr.getId());
            } else {
                // Operation failed, so get all errors
                for (Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred: ');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(
                        'Object fields that caused this error: ' +
                        err.getFields()
                    );
                }
            }
        }
    }

    //Method to map all the Person Account fields
    @TestVisible
    private Account createAccount(CovidCases__x covidCase) {
        return new Account(
            MnId__c = covidCase.MnId__c,
            SubjectId__c = covidCase.SubjectId__c,
            FirstName = covidCase.FirstName__c,
            MiddleName = covidCase.MiddleName__c,
            LastName = covidCase.LastName__c,
            PersonMailingStreet = covidCase.StreetAddress__c,
            PersonMailingCity = covidCase.City__c,
            PersonMailingState = covidCase.State__c,
            PersonMailingPostalCode = covidCase.Zip__c,
            PersonBirthdate = (covidCase.BirthDate__c == null)
                ? null
                : covidCase.BirthDate__c.dateGMT(),
            Language__pc = covidCase.PreferredLanguage__c,
            PersonEmail = covidCase.Email__c,
            PersonMobilePhone = covidCase.TelephoneCell__c,
            PersonHomePhone = covidCase.TelephoneHome__c,
            PersonOtherPhone = covidCase.TelephoneWork__c,
            RecordTypeId = MEDSS_Batch_Helper.personAccountRecordTypeId
        );
    }

    //Method to map all the Case fields including timezone conversions (all DateTimes are stored in the backend in GMT and then converted
    //in the UI by Salesforce to Central time)
    @TestVisible
    private Case createCase(CovidCases__x covidCase) {
        DateTime intakeCmpDtTm;
        if (covidCase.IntakeCompleteDateTime__c != null) {
            intakeCmpDtTm = MEDSS_Batch_Helper.convertDateTime(
                covidCase.IntakeCompleteDateTime__c
            );
        }

        return new Case(
            MEDSS_Event_ID__c = covidCase.CaseId__c,
            MEDSS_Case_Key__c = String.ValueOf(covidCase.CaseKey__c),
            Aged_Out__c = MEDSS_DateUtil.determineAgeThreshold(intakeCmpDtTm),
            Intake_Completion_Date__c = intakeCmpDtTm,
            Call_Attempt_Date__c = (CovidCase.LatestCallAttemptDateTime__c ==
                null)
                ? null
                : MEDSS_Batch_Helper.convertDateTime(
                      covidCase.LatestCallAttemptDateTime__c
                  ),
            Test_Date__c = (covidCase.SpecimenDate__c == null)
                ? null
                : date.parse(covidCase.SpecimenDate__c),
            SubregionBasedJurisdictionCode__c = covidCase.SubregionBasedJurisdiction__c,
            InterviewJurisdictionCode__c = covidCase.InterviewJurisdiction__c,
            CountyCode__c = covidCase.County__c,
            Reservation_Name__c = covidCase.ReservationName__c,
            Tribe_Name__c = covidCase.TribeName__c,
            Preferred_Language_Unrestricted__c = (covidCase.PreferredLanguage__c ==
                null) //TBAIN 2-16-2021 Removed defaulting to English
                ? ''
                : covidCase.PreferredLanguage__c,
            MN_ID__c = covidCase.MnId__c,
            SubjectId__c = covidCase.SubjectId__c,
            Mobile_Phone__c = covidCase.TelephoneCell__c,
            Home_Phone__c = covidCase.TelephoneHome__c,
            Other_Phone__c = covidCase.TelephoneWork__c,
            Subject = 'Outbound Call',
            RecordTypeId = MEDSS_Batch_Helper.outboundRecordTypeId
        );
    }

    // Get existing accounts with matching SubjectIds
    @TestVisible
    private Map<String, Account> getMapOfExistingAccounts(
        Set<String> setSubjectIds
    ) {
        Map<String, Account> mapExistingAccounts = new Map<String, Account>();
        for (Account acc : [
            SELECT Id, MnId__c, PersonContactId, SubjectId__c
            FROM Account
            WHERE SubjectId__c IN :setSubjectIds AND SubjectId__c != NULL
        ]) {
            mapExistingAccounts.put(acc.SubjectId__c, acc);
        }
        return mapExistingAccounts;
    }

    @TestVisible
    private Map<String, QueueSObject> getMapCaseQueues() {
        Map<String, QueueSObject> mapQueues = new Map<String, QueueSObject>();
        for (QueueSObject qSObj : [
            SELECT Id, Queue.Name, QueueId
            FROM QueueSObject
            WHERE SObjectType = 'Case'
        ]) {
            mapQueues.put(qSObj.Queue.Name, qSObj);
        }
        return mapQueues;
    }

    //This function processes existing cases within the portal in order to update statuses and routing as needed
    @TestVisible
    private Map<Id, Case> getMapOfExistingCasesAndUpdateStatus(
        Map<String, Case> mapCases
    ) {
        Map<Id, Case> mapExistingCases = new Map<Id, Case>();
        //Query for current values of existing cases
        List<Case> listCasesToCompare = [
            SELECT
                Id,
                OwnerId,
                Status,
                Subject,
                Standard_QueueId__c,
                Aged_Out__c,
                Aged_To_Regional_Queue__c,
                Preferred_Language_Unrestricted__c,
                Call_Attempt_Date__c,
                County__c,
                Region__c,
                CountyCode__c,
                SubregionBasedJurisdictionCode__c,
                InterviewJurisdictionCode__c,
                MEDSS_Event_Id__c,
                SubjectId__c,
                RecordTypeId
            FROM Case
            WHERE MEDSS_Event_Id__c IN :mapCases.keySet()
        ];
        List<Case> listExistingCasesToDelete = new List<Case>();
        DateTime currentTime = dateTime.now();
        Set<Id> setOfCasesWithPSR = MEDSS_Batch_Helper.getSetOfCasesWithPSR(listCasesToCompare);
        
        Set<String> setDoNotCallCounty = CaseTriggerHandler.setDoNotCallCounty;

        for (Case c : listCasesToCompare) {
            /***
             * 'WHERE' CLAUSE SCENARIOS
             * ------------------------
             * Closed - Requeue the case because it is still open in MEDSS
             * Subject!=Outbound - Case found in Intake workflow but belongs in Outbound
             *
             * AGED OUT SCENARIO
             * OwnerId - Case is not currently assigned to a user
             * Aged_Out - Case has passed its 5 business hour life
             * Aged_To_Regional_Queue - Case is not already aged out to the regional queue
             * County not in Do Not Call - Counties in Do Not Call List never age out
             ***/

            if (c.Subject == 'Outbound Call') {
                System.debug('TBAIN Inside FOR Loop');
                //Compare with existing call attempt timestamp and take the more recent one
                if (
                    c.Call_Attempt_Date__c >
                    mapCases.get(c.MEDSS_Event_Id__c).Call_Attempt_Date__c ||
                    mapCases.get(c.MEDSS_Event_Id__c).Call_Attempt_Date__c == null
                ) {
                    mapCases.get(c.MEDSS_Event_Id__c)
                        .Call_Attempt_Date__c = c.Call_Attempt_Date__c;
                }
                //Take the later Age Out threshold between the current/values to maintain instances where the Age Out was updated
                if (
                    c.Aged_Out__c >
                    mapCases.get(c.MEDSS_Event_Id__c).Aged_Out__c
                ) {
                    mapCases.get(c.MEDSS_Event_Id__c)
                        .Aged_Out__c = c.Aged_Out__c;
                }
                
                //Perform a check if the latest call attempt was within the last 5 hours
                Boolean isLessThanFiveHours = false;	
                if (	
                    mapCases.get(c.MEDSS_Event_Id__c).Call_Attempt_Date__c !=	
                    null	
                ) {	
                    isLessThanFiveHours = (mapCases.get(c.MEDSS_Event_Id__c)	
                        .Call_Attempt_Date__c.addHours(5) > currentTime);
                }	
                if (	//If the latest call attempt was within the last 5 hours and the case is not currently assigned, set to Follow-Up
                    (setOfCasesWithPSR.contains(c.Id) ||	
                    c.status == 'Closed') && isLessThanFiveHours	
                ) {	
                    System.debug('TEST Setting status to Follow-up');	
                    mapCases.get(c.MEDSS_Event_Id__c).Status = 'Follow-up';	
                    mapCases.get(c.MEDSS_Event_Id__c).Requeue_Reason__c = 'Call Attempted';
                } else if ( //Else if the case is ready to be Aged Out, has not been previously Aged Out by this code block, and is not
                    		//being prevented from Aging Out by another process such as the Do Not Call list, then requeue this case
                    		//to reflect its current status as Aged Out
                    setOfCasesWithPSR.contains(c.Id) &&
                    c.Aged_Out__c < currentTime &&
                    c.Aged_To_Regional_Queue__c == false &&
                    !setDoNotCallCounty.contains(c.County__c) &&
                    (c.Status == 'New' ||
                    c.Status == 'Re-queued')
                ) {
                    mapCases.get(c.MEDSS_Event_Id__c)
                        .Aged_To_Regional_Queue__c = true; //This flag is set so that this case will only be re-queued by this condition once
                    mapCases.get(c.MEDSS_Event_Id__c)
                        .Status = 'Closed';
                    mapExistingCases.put(c.Id, c);
                } else if (c.Status == 'Closed') { //Else if the case does not have a recent call attempt but is closed in the portal and is
                    							   //still coming in through the query, prepare the case to be Re-queued
                    mapCases.get(c.MEDSS_Event_Id__c)
                        .Status = MEDSS_Batch_Helper.getUpdatedStatus(
                        mapCases.get(c.MEDSS_Event_Id__c),
                        c
                    );
                    mapExistingCases.put(c.Id, c);
                }
            } else {
                //Case is coming from Intake workflow
                //Delete existing case to remove Queue-based PendingServiceRouting
                listExistingCasesToDelete.add(c);
            }
        }

        try {
            Database.delete(listExistingCasesToDelete, false);
        } catch (Exception e) {
            System.debug('TBAIN Delete existing Intake cases failed!');
        }

        return mapExistingCases;
    }

    global void finish(Database.BatchableContext BC) {
        // Execute any post-processing operations like sending emails
        System.debug('Batch Vals: ' + recordCnt + ' / ' + maxIntakeDate);
        MEDSS_Batch_Helper.updateBatchHistory(maxIntakeDate, recordCnt);
    }
}