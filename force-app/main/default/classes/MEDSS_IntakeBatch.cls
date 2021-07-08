/*** 
* Created By: Amrutha Thaliyil, Travis Bain, Slalom
* Created Date: Dec 18, 2020
* Description: Batch apex class to create intake case records from External Objects(4 objects - 
    CovidIntakePositiveUncodeds__x,
    CovidIntakePositives__x,
    CovidIntakeDedupUncodeds__x,
    CovidIntakeDedups__x
*/
global class MEDSS_IntakeBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    @TestVisible
    private List<SObject> testDataset = null; // For testing ONLY
    private String covidIntakePositive = 'Positive Intake';
    private String covidIntakeDedup = 'Positive Dedup';
    private String covidIntakePositiveUncoded = 'Positive Intake Uncoded';
    private String covidIntakeDedupUncoded = 'Positive Dedup Uncoded';

    global Integer queryLimit = 2000;

   // Todo- Add SUbject for uncoded

    // Start Method for querying 4 external objects- get all records ------
    global Iterable<SObject> start(Database.BatchableContext BC) {
        List<sObject> scope = new List<sObject>();
            if (testDataset == null) {      
            scope = getAllIntakeExternalData();
        } else {
            scope = testDataset;
        }
        return scope;
    }

    // Execute Method ------
    global void execute(
        Database.BatchableContext BC,
        List<SObject> intakeCovidCaseList
    ) {
        Set<String> setSubIds = new Set<String>();
        Map<String, Case> mapIntakeAllCases = new Map<String, Case>();
        Map<String, Account> mapAccountsToUpsert = new Map<String, Account>();
        List<Account> accountsToBeUpserted = new List<Account>();
        List<Case> casesToBeUpserted = new List<Case>();
        Map<String, Case> mapExistingClosedCases = new Map<String, Case>();
        Map<String, Case> mapExistingUserCases = new Map<String, Case>();



        for (SObject covidCase : intakeCovidCaseList) {
            String subjectId = (String) covidCase.get('SubjectId__c');

            if (!mapAccountsToUpsert.keySet().contains(subjectId)) {
                Account personAccount = createAccount(covidCase);
                mapAccountsToUpsert.put(personAccount.SubjectId__c, personAccount);
            }

            Case intakeCase = createCase(covidCase);

            // Get All Cases on Intake Medss Map
            mapIntakeAllCases.put(intakeCase.MEDSS_Event_ID__c, intakeCase);

            // Get All Mn_Ids for Verifying existing Account
            if (intakeCase.SubjectId__c != null) {
                setSubIds.add(intakeCase.SubjectId__c);
            }
        }
        
        //Accounts to be upserted are collected here
        accountsToBeUpserted.addAll(mapAccountsToUpsert.values());

        //Check if case exist already in salesforce and are closed, in that case requeue to Original Queue
        mapExistingClosedCases = reQueueIfClosed(mapIntakeAllCases);
        mapExistingUserCases = updateOwnerIdForTakenCases(mapIntakeAllCases);
        system.debug('mapExistingUserCases'+mapExistingUserCases);

        if(!mapExistingClosedCases.isEmpty()){
            for(Case intake: mapIntakeAllCases.values()){
                if(mapExistingClosedCases.containsKey(intake.MEDSS_Event_ID__c)){
                    mapIntakeAllCases.put(intake.MEDSS_Event_ID__c,mapExistingClosedCases.get(intake.MEDSS_Event_ID__c));
                }
                
            }
        }

        if(!mapExistingUserCases.isEmpty()){
            for(Case intake: mapIntakeAllCases.values()){
                if(mapExistingUserCases.containsKey(intake.MEDSS_Event_ID__c)){
                    mapIntakeAllCases.put(intake.MEDSS_Event_ID__c,mapExistingUserCases.get(intake.MEDSS_Event_ID__c));
                }
                
            }
        }


        casesToBeUpserted.addAll(mapIntakeAllCases.values());
        List<Database.UpsertResult> srList = new List<Database.UpsertResult>();

        try {

            // Upsert Accounts
            if (!accountsToBeUpserted.isEmpty()) {
                Schema.SObjectField f = Account.Fields.SubjectId__c;
                srList.addAll(Database.upsert(accountsToBeUpserted, f, false));
            }

            // Link case with newly inserted accounts
            // Get all existing accounts with collected MnIds
            Map<String, Account> mapExistingAccounts = this.getExistingAccountsMap(
                setSubIds
            );

            // Link case with existing accounts
            for (Case c : mapIntakeAllCases.values()) {
                if (mapExistingAccounts.keySet().contains(c.SubjectId__c)) {
                    mapIntakeAllCases.get(c.MEDSS_Event_ID__c)
                        .AccountId = mapExistingAccounts.get(c.SubjectId__c).Id;
                    c.contactId = mapExistingAccounts.get(
                                    c.SubjectId__c
                            )
                            .PersonContactId; 
                }
            }

            // Upsert Cases
            Schema.SObjectField f = Case.Fields.MEDSS_Event_ID__c;
            if (!casesToBeUpserted.isEmpty()) {
                srList.addAll(Database.upsert(casesToBeUpserted, f, false));
            }
        } catch (Exception e) {
            system.debug(' error found : ' + e.getMessage());
        }
             // Iterate through each returned result
             for (Database.UpsertResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug(
                        ' Successfully inserted object. Object ID: ' +
                        sr.getId()
                    );
                } else {
                    // Operation failed, so get all errors
                    for (Database.Error err : sr.getErrors()) {
                        // MISSING ARGUMENT - MnID__c is not specified, because MnId is null from MEDSS
                        System.debug(
                            ' ' +
                            err.getStatusCode() +
                            ': ' +
                            err.getMessage()
                        );
                        System.debug(
                            ' Object fields that affected this error: ' +
                            err.getFields()
                        );
                    }
                }
            }
    }

    // Finish Method ------
    global void finish(Database.BatchableContext BC) {
        system.debug('- Finish Method -');
    }

    private Account createAccount(sObject covidCase) {
        Date formattedDobinDate ;
        DateTime birthDate = (DateTime)covidCase.get('BirthDate__c');
        system.debug('birthDate  '+birthDate);
        if(birthDate != null){
            formattedDobinDate = date.newinstance(birthDate.year(), birthDate.month(), birthDate.day());

        }
        Boolean isSandbox = this.runningInASandbox ;
        Account acc = new Account(
            MnId__c = (String) covidCase.get('MnId__c'),
            SubjectId__c = (String) covidCase.get('SubjectId__c'),
            FirstName = (String) covidCase.get('FirstName__c'),
            MiddleName = (String) covidCase.get('MiddleName__c'),
            LastName = (String) covidCase.get('LastName__c'),
            PersonMailingStreet = (String) covidCase.get('StreetAddress__c'),
            PersonMailingCity = (String) covidCase.get('City__c'),
            PersonMailingState = (String) covidCase.get('State__c'),
            PersonMailingPostalCode = (String) covidCase.get('Zip__c'),
            PersonBirthdate = (covidCase.get('BirthDate__c') == null)
                ? null
                : formattedDobinDate,
            Language__pc = (String) covidCase.get('PreferredLanguage__c'),
            PersonEmail = (String) covidCase.get('Email__c'),
            RecordTypeId = this.personAccountRecordTypeId
        );
        if (!isSandbox) {
            acc.PersonMobilePhone = (String) covidCase.get('TelephoneCell__c');
            acc.PersonHomePhone = (String) covidCase.get('TelephoneCell__c');
            acc.PersonOtherPhone = (String) covidCase.get('TelephoneCell__c');
        }
        else{            
            acc.PersonMobilePhone = '123-456-7890';
            acc.PersonHomePhone = '123-456-7890';
            acc.PersonOtherPhone = '123-456-7890';
        }
        return acc;

    }

    @TestVisible
    private Id intakeRecordTypeId {
        get {
            if (intakeRecordTypeId == null) {
                intakeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                    .get('Intake')
                    .getRecordTypeId();
            }
            return intakeRecordTypeId;
        }
        private set;
    }

    @TestVisible
    private Case createCase(sObject covidCase) {
        Case nwCase = new Case(
            MEDSS_Event_ID__c = (String) covidCase.get('CaseId__c'),
            MEDSS_Case_Key__c = String.valueOf(covidCase.get('CaseKey__c')),
            Region__c = (String) covidCase.get('SubregionBasedJurisdiction__c'),
            County__c = (String) covidCase.get('InterviewJurisdiction__c'),
            Reservation_Name__c = (String) covidCase.get('ReservationName__c'),
            Tribe_Name__c = (String) covidCase.get('TribeName__c'),
            Preferred_Language__c = (String) covidCase.get(
                'PreferredLanguage__c'
            ),
            MN_ID__c = (String) covidCase.get('MnId__c'),
            SubjectId__c = (String) covidCase.get('SubjectId__c'),
            origin = 'Phone',
            RecordtypeId = this.intakeRecordTypeId
        );

        switch on covidCase {
            when CovidIntakePositiveUncodeds__x positiveUncodes {
                nwCase.ownerId = this.covidIntakePositiveQueueId;
                nwCase.Subject = this.covidIntakePositiveUncoded;
            }
            when CovidIntakePositives__x positives {
                nwCase.ownerId = this.covidIntakePositiveQueueId;
                nwCase.Subject = this.covidIntakePositive;
            }
            when CovidIntakeDedupUncodeds__x deDupUncodeds {
                nwCase.ownerId = this.covidIntakeDedupQueueId;
                nwCase.Subject = this.covidIntakeDedupUncoded;
            }
            when CovidIntakeDedups__x deDups {
                nwCase.ownerId = this.covidIntakeDedupQueueId;
                nwCase.Subject = this.covidIntakeDedup;
            }
        }
        return nwCase;
    }

    @TestVisible
    private Boolean runningInASandbox {
        get {
            if (runningInASandbox == null) {
                runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        }
        private set;
    }

    @TestVisible
    private Map<String, Case> updateOwnerIdForTakenCases(Map<String, Case> mapCases){
        Map<String, Case> mapExistingUserCases = new Map<String, Case>();
        List<Case> caseList = [SELECT Id, OwnerId, Standard_QueueId__c, County__c, Region__c, 
        MEDSS_Event_Id__c, SubjectId__c, RecordTypeId ,subject,Status
        FROM Case
        WHERE Status != 'Closed'
        AND MEDSS_Event_Id__c IN: mapCases.keySet() AND owner.type = 'user' ];
        
        for(Case c : caseList){
        
        mapExistingUserCases.put(c.MEDSS_Event_Id__c , c); 
        system.debug('inside loop'+mapExistingUserCases);
                    }     
                     system.debug('inside method'+mapExistingUserCases.values());
        return mapExistingUserCases;

    }

    @TestVisible
    private Map<String, Case> reQueueIfClosed(Map<String, Case> mapCases){
        Map<String, Case> mapExistingClosedCases = new Map<String, Case>();

        //Verify if passed cases are closed in salesforce(i.e- Not closed in Medss- In that case, Re-Queue it)
        for(Case c : [SELECT Id, Standard_QueueId__c, County__c, Region__c, 
                    MEDSS_Event_Id__c, SubjectId__c, RecordTypeId ,OwnerId,subject,Status
                    FROM Case
                    WHERE Status = 'Closed'
                    AND MEDSS_Event_Id__c IN: mapCases.keySet()]){
            //mapCases.get(c.MEDSS_Event_Id__c).Status = 'Re-queued';
            if(mapCases.get(c.MEDSS_Event_Id__c).subject.contains('Positive Intake')){
                mapCases.get(c.MEDSS_Event_Id__c).OwnerId = this.covidIntakePositiveQueueId; // based on subject
            }
            else if( mapCases.get(c.MEDSS_Event_Id__c).subject.contains('Positive Dedup')){
                mapCases.get(c.MEDSS_Event_Id__c).OwnerId = this.covidIntakeDedupQueueId; // based on subject
            }
            //TBAIN 1/20/20201: Update Status based on subject to determine if requeue or new case (from different workflow)
            mapCases.get(c.MEDSS_Event_Id__c).Status = MEDSS_Batch_Helper.getUpdatedStatus(mapCases.get(c.MEDSS_Event_Id__c), c);
            
            mapExistingClosedCases.put(c.MEDSS_Event_Id__c, mapCases.get(c.MEDSS_Event_Id__c));
        } 
        return mapExistingClosedCases;
    } 

    private List<SObject> getAllIntakeExternalData() {
        List<sObject> scope = new List<sObject>();
        scope.addAll(
            [
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
                    SpecimenDate__c,
                    SubregionBasedJurisdiction__c,
                    InterviewJurisdiction__c,
                    ReservationName__c,
                    TribeName__c,
                    LanguageInterview__c,
                    CaseInterviewStatus__c
                FROM CovidIntakePositiveUncodeds__x
                LIMIT: queryLimit
            ]
        );
        scope.addAll(
            [
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
                    SpecimenDate__c,
                    SubregionBasedJurisdiction__c,
                    InterviewJurisdiction__c,
                    ReservationName__c,
                    TribeName__c,
                    LanguageInterview__c,
                    CaseInterviewStatus__c
                FROM CovidIntakePositives__x
                LIMIT: queryLimit
            ]
        );
        scope.addAll(
            [
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
                    SpecimenDate__c,
                    SubregionBasedJurisdiction__c,
                    InterviewJurisdiction__c,
                    ReservationName__c,
                    TribeName__c,
                    LanguageInterview__c,
                    CaseInterviewStatus__c
                FROM CovidIntakeDedupUncodeds__x
                LIMIT: queryLimit
            ]
        );
        scope.addAll(
            [
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
                    SpecimenDate__c,
                    SubregionBasedJurisdiction__c,
                    InterviewJurisdiction__c,
                    ReservationName__c,
                    TribeName__c,
                    LanguageInterview__c,
                    CaseInterviewStatus__c
                FROM CovidIntakeDedups__x
                LIMIT: queryLimit
            ]
        );
        return scope;
    }

    @TestVisible
    private Id covidIntakePositiveQueueId {
        get {
            if (covidIntakePositiveQueueId == null) {
                covidIntakePositiveQueueId = this.getQueueSObject(
                    'CovidIntakePositive'
                );
            }
            return covidIntakePositiveQueueId;
        }
        private set;
    }

    @TestVisible
    private Id covidIntakeDedupQueueId {
        get {
            if (covidIntakeDedupQueueId == null) {
                covidIntakeDedupQueueId = this.getQueueSObject(
                    'CovidIntakeDedup'
                );
            }
            return covidIntakeDedupQueueId;
        }
        private set;
    }

    @TestVisible
    private Id getQueueSObject(String qName) {
        QueueSObject qSObj = [
            SELECT Id, Queue.Name, QueueId
            FROM QueueSObject
            WHERE SObjectType = 'Case' AND queue.Name = :qName
            LIMIT 1
        ];

        if (qSObj != null) {
            return qSObj.QueueId;
        } else {
            return null;
        }
    }

    @TestVisible
    private Map<String, Account> getExistingAccountsMap(Set<String> setSubIds) {
        // Get all existing Accounts with collected MnIds
        Map<String, Account> mapExistingAccounts = new Map<String, Account>();
        for (Account account : [
            SELECT Id, MnId__c, PersonContactId,SubjectId__c
            FROM Account
            WHERE SubjectId__c IN :setSubIds
        ]) {
            mapExistingAccounts.put(account.SubjectId__c, account);
        }
        return mapExistingAccounts;
    }

    @TestVisible
    private Id personAccountRecordTypeId {
        get {
            if (personAccountRecordTypeId == null) {
                personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                    .get('Person Account')
                    .getRecordTypeId();
            }
            return personAccountRecordTypeId;
        }
        private set;
    }
   
}