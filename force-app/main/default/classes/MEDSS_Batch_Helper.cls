/*** 
 * Created By: Travis Bain, Slalom
 * Description: Various helper methods to assist with DateTime conversion, case routing, and other batch processes.
 */

public with sharing class MEDSS_Batch_Helper {
    //Converts DateTimes from the MEDSS format to GMT
    public static DateTime convertDateTime(String dt) {
        List<String> listValue = dt.split(' ');
        List<String> listDate = listValue[0].split('/');
        List<String> listTime = listValue[1].split(':');

        if (listValue[2] == 'PM') {
            if (listTime[0] != '12') {
                listTime[0] = String.valueOf(Integer.valueOf(listTime[0]) + 12);
            }
        }
        // prettier-ignore
        String strDateTime = 
            listDate[2] + '-' +
            listDate[0] + '-' +
            listDate[1] + ' ' +
            listTime[0] + ':' +
            listTime[1] + ':00';
        DateTime output = DateTime.valueOf(strDateTime);
        return output;
    }

    //Checks if a case should be set to New or Re-queued and updates the status accordingly
    public static String getUpdatedStatus(Case oldCase, Case newCase) {
        // If Subjects match (ex. 'Outbound Call' and 'Outbound Call'), update status to reflect Re-queueing
        if (oldCase.Subject == newCase.Subject) {
            if (oldCase.recordTypeId == outboundRecordTypeId)
                return 'Ready for Re-queue';
            else if (oldCase.recordTypeId == intakeRecordTypeId)
                return 'Re-queued';
        }
        return 'New';
    }
    
    public static List<Case> getListCasesFromCaseId(List<String> caseIds){
        return [SELECT Id FROM Case WHERE MEDSS_Event_Id__c IN: caseIds];
    }
    
    /**
     * Checks if cases having an active PendingServiceRouting, meaning that the case is currently being routed and is not
     * closed or currently assigned to a user through Omni-Channel.
     * 
     * This method is useful for any process that should only operate on cases that are not actively being worked by an agent.
     * For example, closing a case that an agent is currently working can cause confusion as they are suddenly pushed a new case,
     * so this method can be used to ensure only cases that aren't being worked are closed.
     **/
    public static Set<Id> getSetOfCasesWithPSR(List<Case> caseList){
		Set<Id> setCasesWithPSR = new Set<Id>();
        List<PendingServiceRouting> listPSR = [SELECT WorkItemId FROM PendingServiceRouting WHERE WorkItemId IN: caseList];
        
        for(PendingServiceRouting psr : listPSR){
            setCasesWithPSR.add(psr.WorkItemId);
        }
        
        return setCasesWithPSR;
    }

    public static void setOwnerIdToIntakeQueue(Case c) {
        if (c.subject.contains('Positive Intake')) {
            c.OwnerId = MEDSS_Batch_Helper.covidIntakePositiveQueueId; // based on subject
        } else if (c.subject.contains('Positive Dedup')) {
            c.OwnerId = MEDSS_Batch_Helper.covidIntakeDedupQueueId; // based on subject
        }
    }
    
    /**
     * Generic method used by the Remove Query/Batches in order to close cases based on IDs passed in by MEDSS.
     **/
    public static void removeCovidCases(List<sObject> removeCovidCaseList, String subjectString){
        User integrationUser = [SELECT id FROM User WHERE alias = 'iuser'];
        List<String> removeCaseIds = new List<String>();
        List<Case> removeCaseList = new List<Case>();
        
        for (sObject r : removeCovidCaseList) {
            removeCaseIds.add((String) r.get('CaseId__c'));
        }

        List<Case> caseList = [
            SELECT Id, Status
            FROM Case
            WHERE MEDSS_Event_Id__c IN :removeCaseIds
            AND Subject LIKE :subjectString
        ];
        
        Set<Id> setOfCasesWithPSR = getSetOfCasesWithPSR(caseList);

        for (Case c : caseList) {
            System.debug('TBAIN Case: ' + c);
            
            //Only close the case if it is in Follow-up status or actively being routed (not being worked by an agent)
            if(setOfCasesWithPSR.contains(c.Id) || c.Status == 'Follow-up'){
                c.OwnerId = integrationUser.Id;
                c.Status = 'Closed';
             	removeCaseList.add(c);   
            }
        }

        if (!removeCaseList.isEmpty()) {
            update removeCaseList;
        }
    }

    public static Id getQueueSObject(String qName) {
        List<QueueSObject> qSObjs = [
            SELECT Id, Queue.Name, QueueId
            FROM QueueSObject
            WHERE SObjectType = 'Case' AND queue.Name = :qName
            LIMIT 1
        ];

        if (qSObjs.size() > 0) {
            return qSObjs[0].QueueId;
        } else {
            return null;
        }
    }

    @TestVisible
    public static Id covidIntakePositiveQueueId {
        get {
            if (covidIntakePositiveQueueId == null) {
                covidIntakePositiveQueueId = getQueueSObject(
                    'CovidIntakePositive'
                );
            }
            return covidIntakePositiveQueueId;
        }
        private set;
    }

    @TestVisible
    public static Id covidIntakeDedupQueueId {
        get {
            if (covidIntakeDedupQueueId == null) {
                covidIntakeDedupQueueId = getQueueSObject('CovidIntakeDedup');
            }
            return covidIntakeDedupQueueId;
        }
        private set;
    }

    public static Id personAccountRecordTypeId {
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

    // Get the Record Type  for the Case Intake records
    public static Id intakeRecordTypeId {
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

    // Get the Record Type for the Case Outbound Call records
    public static Id outboundRecordTypeId {
        get {
            if (outboundRecordTypeId == null) {
                Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
                outboundRecordTypeId = recordTypes.get('Outbound Call')
                    .getRecordTypeId();
            }
            return outboundRecordTypeId;
        }
        private set;
    }

    // Return the Region Map defined in this class
    public static Map<String, Map<String, String>> regionMap {
        get {
            if (regionMap == null) {
                regionMap = getRegionMap();
            }
            return regionMap;
        }
        private set;
    }

    //Mappings for each region and the related Queue and Skill values
    @TestVisible
    private static Map<String, Map<String, String>> getRegionMap() {
        Map<String, Map<String, String>> mapRegions = new Map<String, Map<String, String>>();
        Map<String, String> tmp = new Map<String, String>();

        tmp.put('Region', 'Northwest Quin');
        tmp.put('Queue', 'Northwest Quin Region Queue');
        tmp.put('Uncalled Queue', 'Northwest Quin Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Northwest_Quin_Consultant_Staff');
        tmp.put('Region Skill', 'Northwest_Quin_Region');
        mapRegions.put('SR-NWQ', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'No Region');
        tmp.put('Queue', 'No Region Queue');
        tmp.put('Uncalled Queue', 'No Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'No_Region_Consultant_Staff');
        tmp.put('Region Skill', 'No_Region');
        mapRegions.put('SR-NOREGION', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Central');
        tmp.put('Queue', 'Central Region Queue');
        tmp.put('Uncalled Queue', 'Central Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Central_Consultant_Staff');
        tmp.put('Region Skill', 'Central_Region');
        mapRegions.put('SR-CR', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Metro');
        tmp.put('Queue', 'Metro Region Queue');
        tmp.put('Uncalled Queue', 'Metro Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Metro_Consultant_Staff');
        tmp.put('Region Skill', 'Metro_Region');
        mapRegions.put('SR-METRO', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Northeast');
        tmp.put('Queue', 'Northeast Region Queue');
        tmp.put('Uncalled Queue', 'Northeast Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Northeast_Consultant_Staff');
        tmp.put('Region Skill', 'Northeast_Region');
        mapRegions.put('SR-NE', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Northwest');
        tmp.put('Queue', 'Northwest Region Queue');
        tmp.put('Uncalled Queue', 'Northwest Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Northwest_Consultant_Staff');
        tmp.put('Region Skill', 'Northwest_Region');
        mapRegions.put('SR-NW', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'South Central');
        tmp.put('Queue', 'South Central Region Queue');
        tmp.put('Uncalled Queue', 'South Central Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'South_Central_Consultant_Staff');
        tmp.put('Region Skill', 'South_Central_Region');
        mapRegions.put('SR-SC', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Southeast');
        tmp.put('Queue', 'Southeast Region Queue');
        tmp.put('Uncalled Queue', 'Southeast Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Southeast_Consultant_Staff');
        tmp.put('Region Skill', 'Southeast_Region');
        mapRegions.put('SR-SE', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'Southwest');
        tmp.put('Queue', 'Southwest Region Queue');
        tmp.put('Uncalled Queue', 'Southwest Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'Southwest_Consultant_Staff');
        tmp.put('Region Skill', 'Southwest_Region');
        mapRegions.put('SR-SW', tmp);

        tmp = new Map<String, String>();
        tmp.put('Region', 'West Central');
        tmp.put('Queue', 'West Central Region Queue');
        tmp.put('Uncalled Queue', 'West Central Region Uncalled Queue');
        tmp.put('Consultant Staff Skill', 'West_Central_Consultant_Staff');
        tmp.put('Region Skill', 'West_Central_Region');
        mapRegions.put('SR-WC', tmp);

        //TO-DO Do we need NoRegion?

        return mapRegions;
    }

    @TestVisible
    private static Medss__mdt getMedssMdt(String devName) {
        return [
            SELECT Id, DeveloperName, MasterLabel, Record_Value__c
            FROM Medss__mdt
            WHERE DeveloperName = :devName
            LIMIT 1
        ];
    }

    // MEDSS Metadata is meant to be a Key Value list of variables used by the application
    public static String getMedssMetadata(String devName) {
        Medss__mdt objMetadata = getMedssMdt(devName);
        return objMetadata.Record_Value__c;
    }

    public static void updateBatchHistory(String maxDate, Integer recCount) {
        System.debug('MaxDate: ' + maxDate);
        insert (new Batch_History__c(
            Name = String.valueOf(DateTime.now()),
            Max_DateTime__c = maxDate,
            Record_Count__c = recCount
        ));
    }

    //Batch History is used exclusively for reading cases sequentially in the Outbound Batch in use cases where
    //there are more than 2000 records that need to be pulled.
    public static Batch_History__c getLatestBatchHistory() {
        List<Batch_History__c> batchHistory = [
            SELECT Max_DateTime__c, Record_Count__c
            FROM Batch_History__c
            ORDER BY CreatedDate DESC
        ];

        // Handle if Batch History is empty or too large
        if (batchHistory == null || batchHistory.size() == 0) {
            return new Batch_History__c(
                Name = 'First Record',
                Max_DateTime__c = '01/01/2010 00:00 AM',
                Record_Count__c = 1
            );
        } 
        return batchHistory[0];
    }
}