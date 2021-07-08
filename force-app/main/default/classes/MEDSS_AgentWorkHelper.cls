public with sharing class MEDSS_AgentWorkHelper {
    @testVisible
    private static Map<Id, Case> cases = new Map<Id, Case>();

    @testVisible
    private static Boolean isActiveAgtWrkHist {
        get {
            if (isActiveAgtWrkHist == null) {
                String isActiveStr = MEDSS_Batch_Helper.getMedssMetadata(
                    'Run_Agent_Work_History'
                );
                if (isActiveStr.equalsIgnoreCase('true')) {
                    isActiveAgtWrkHist = true;
                } else {
                    isActiveAgtWrkHist = false;
                }
            }
            return isActiveAgtWrkHist;
        }
        private set;
    }

    // Entry for trigger insert
    public static void createHistoryOnInsert(List<AgentWork> agentsWork) {
        // If not active return without action
        if (!isActiveAgtWrkHist) {
            return;
        }

        Set<Id> caseIds = getCaseIds(agentsWork);
        getCases(caseIds);

        List<AgentWorkHistory__c> agentWorkHistory = populateAgentWorkInsert(
            agentsWork
        );
        insert agentWorkHistory;
    }

    @testVisible
    private static Set<Id> getCaseIds(List<AgentWork> agentsWork) {
        Set<Id> caseIds = new Set<Id>();
        for (AgentWork aw : agentsWork) {
            caseIds.add(aw.WorkItemId);
        }
        return caseIds;
    }

    @testVisible
    private static void getCases(Set<Id> caseIds) {
        // return a list of cases SOQL
        cases = new Map<Id, Case>(
            [
                SELECT
                    Id,
                    CaseNumber,
                    County__c,
                    MEDSS_Event_ID__c,
                    MN_Id__c,
                    Owner.Name,
                    RecordType.Name,
                    Region__c,
                    Status
                FROM Case
                WHERE Id IN :caseIds
            ]
        );
    }

    @testVisible
    private static List<AgentWorkHistory__c> populateAgentWorkInsert(
        List<AgentWork> agentsWork
    ) {
        List<AgentWorkHistory__c> recordsToInsert = new List<AgentWorkHistory__c>();
        Map<Id, SObject> ownerNames = getUserOrGroupName(agentsWork);

        for (AgentWork aw : agentsWork) {
            Case cs = cases.get(aw.WorkItemId);

            AgentWorkHistory__c awh = new AgentWorkHistory__c(
                AgentWorkId__c = aw.Id,
                Case_Status__c = (cs != null) ? cs.Status : null,
                Company__c = (ownerNames.containsKey(aw.OwnerId))
                    ? (String) ownerNames.get(aw.OwnerId).get('CompanyName')
                    : null,
                County__c = (cs != null) ? cs.County__c : null,
                MEDSS_Event_ID__c = (cs != null) ? cs.MEDSS_Event_Id__c : null,
                MEDSS_Event_Name__c = (cs != null) ? cs.CaseNumber : null,
                MEDSS_Event_Record_Type__c = (cs != null)
                    ? cs.RecordType.Name
                    : null,
                MNId__c = (cs != null) ? cs.MN_Id__c : null,
                Name = aw.Name,
                OriginalGroupName__c = (ownerNames.containsKey(
                        aw.OriginalGroupId
                    ))
                    ? (String) ownerNames.get(aw.OriginalGroupId).get('Name')
                    : null,
                OriginalQueueName__c = (ownerNames.containsKey(
                        aw.OriginalQueueId
                    ))
                    ? (String) ownerNames.get(aw.OriginalQueueId).get('Name')
                    : null,
                OwnerName__c = (ownerNames.containsKey(aw.OwnerId))
                    ? (String) ownerNames.get(aw.OwnerId).get('Name')
                    : null,
                Region__c = (cs != null) ? cs.Region__c : null,
                RequestDateTime__c = aw.RequestDateTime,
                Status__c = aw.Status,
                UserId__c = aw.UserId,
                UserRole__c = (ownerNames.containsKey(aw.OwnerId))
                    ? ((User) ownerNames.get(aw.OwnerId)).UserRole.Name
                    : null,
                WorkItemId__c = aw.WorkItemId
            );
            recordsToInsert.add(awh);
        }
        return recordsToInsert;
    }

    // Entry for trigger update
    public static void updateHistoryRecords(List<AgentWork> agentsWork) {
        // If not active return without action
        if (!isActiveAgtWrkHist) {
            return;
        }
        List<AgentWorkHistory__c> updAgentsWork = updateAgentsWork(agentsWork);
        upsert updAgentsWork AgentWorkId__c;
    }

    @testVisible
    private static List<AgentWorkHistory__c> updateAgentsWork(
        List<AgentWork> agentsWork
    ) {
        List<AgentWorkHistory__c> updAgentsWork = new List<AgentWorkHistory__c>();
        Map<Id, SObject> ownerNames = getUserOrGroupName(agentsWork);

        for (AgentWork aw : agentsWork) {
            Case cs = cases.get(aw.WorkItemId);

            AgentWorkHistory__c awh = new AgentWorkHistory__c(
                AgentWorkId__c = aw.Id,
                AcceptDateTime__c = aw.AcceptDateTime,
                AssignedDateTime__c = aw.AssignedDateTime,
                CancelDateTime__c = aw.CancelDateTime,
                Case_Status__c = (cs != null) ? cs.Status : null,
                CloseDateTime__c = aw.CloseDateTime,
                Company__c = (ownerNames.containsKey(aw.OwnerId))
                    ? (String) ownerNames.get(aw.OwnerId).get('CompanyName')
                    : null,
                DeclineDateTime__c = aw.DeclineDateTime,
                HandleTime__c = aw.HandleTime,
                OwnerName__c = (ownerNames.containsKey(aw.OwnerId))
                    ? (String) ownerNames.get(aw.OwnerId).get('Name')
                    : null,
                PushTimeout__c = aw.PushTimeout,
                PushTimeoutDateTime__c = aw.PushTimeoutDateTime,
                Status__c = aw.Status,
                UserId__c = aw.UserId,
                UserRole__c = (ownerNames.containsKey(aw.OwnerId))
                    ? ((User) ownerNames.get(aw.OwnerId)).UserRole.Name
                    : null
            );
            updAgentsWork.add(awh);
        }
        return updAgentsWork;
    }

    @testVisible
    private static Map<Id, SObject> getUserOrGroupName(
        List<AgentWork> histories
    ) {
        Map<Id, SObject> names = new Map<Id, SObject>();
        Set<Id> ids = new Set<Id>();

        for (AgentWork aw : histories) {
            ids.add(aw.OwnerId);
            ids.add(aw.OriginalGroupId);
            ids.add(aw.OriginalQueueId);
        }

        for (User usr : [
            SELECT Name, CompanyName, UserRole.Name
            FROM User
            WHERE Id IN :ids
        ]) {
            names.put(usr.Id, usr);
        }

        // Groups and Queues
        for (Group grp : [SELECT Name FROM Group WHERE Id IN :ids]) {
            names.put(grp.Id, grp);
        }
        return names;
    }
}
