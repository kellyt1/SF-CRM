@isTest(SeeAllData=false)
public with sharing class MEDSS_AgentWorkHelperTest {
    @isTest(SeeAllData=false)
    static void testIsActiveAgtWrkHist() {
        Boolean isActive = MEDSS_AgentWorkHelper.isActiveAgtWrkHist;
        System.assert(isActive != null);

        MEDSS_AgentWorkHelper.isActiveAgtWrkHist = false;
        MEDSS_AgentWorkHelper.createHistoryOnInsert(new List<AgentWork>());
        MEDSS_AgentWorkHelper.updateHistoryRecords(new List<AgentWork>());
    }

    @isTest(SeeAllData=false)
    static void testGetCaseIds() {
        List<AgentWork> agentsWork = new List<AgentWork>();
        agentsWork.add(new AgentWork(WorkItemId = '001000000000000'));
        agentsWork.add(new AgentWork(WorkItemId = '001000000000001'));

        Set<Id> aWrkIds = MEDSS_AgentWorkHelper.getCaseIds(agentsWork);
        System.assert(aWrkIds.contains('001000000000000'));
    }

    @isTest(SeeAllData=false)
    static void testGetCases() {
        List<Case> cases = new List<Case>();
        Set<Id> caseIds = new Set<Id>();

        for (Integer i = 0; i < 10; i++) {
            Case cs = new Case(Subject = 'Test - ' + i);
            cases.add(cs);
        }
        insert cases;
        for (Case c : cases) {
            caseIds.add(c.Id);
        }

        MEDSS_AgentWorkHelper.getCases(caseIds);

        Map<Id, Case> casesTest = MEDSS_AgentWorkHelper.cases;
        System.assertEquals(cases.size(), casesTest.values().size());
    }

    @isTest(SeeAllData=false)
    static void testPopulateAgentWorkInsert() {
        List<AgentWork> agentsWork = createAgentWork();
        List<AgentWorkHistory__c> agemtsWrkHist = MEDSS_AgentWorkHelper.populateAgentWorkInsert(
            agentsWork
        );

        System.assertEquals(agemtsWrkHist[0].AgentWorkId__c, agentsWork[0].Id);
        System.assertEquals(
            agemtsWrkHist[0].IsOwnerChangeInitiated__c,
            agentsWork[0].IsOwnerChangeInitiated
        );
        System.assertEquals(
            agemtsWrkHist[0].IsStatusChangeInitiated__c,
            agentsWork[0].IsStatusChangeInitiated
        );
        System.assertEquals(agemtsWrkHist[0].Name, agentsWork[0].Name);
        System.assertEquals(
            agemtsWrkHist[0].PushTimeoutDateTime__c,
            agentsWork[0].PushTimeoutDateTime
        );
        System.assertEquals(
            agemtsWrkHist[0].OriginalQueueId__c,
            agentsWork[0].OriginalQueueId
        );
        System.assertEquals(
            agemtsWrkHist[0].RequestDateTime__c,
            agentsWork[0].RequestDateTime
        );
        System.assertEquals(agemtsWrkHist[0].Status__c, agentsWork[0].Status);
        System.assertEquals(agemtsWrkHist[0].UserId__c, agentsWork[0].UserId);
        System.assertEquals(
            agemtsWrkHist[0].WorkItemId__c,
            agentsWork[0].WorkItemId
        );
    }

    @isTest(SeeAllData=false)
    static void testUpdateAgentsWork() {
        List<AgentWork> agentsWork = createAgentWork();
        List<AgentWorkHistory__c> agemtsWrkHist = MEDSS_AgentWorkHelper.updateAgentsWork(
            agentsWork
        );

        System.assertEquals(agemtsWrkHist[0].AgentWorkId__c, agentsWork[0].Id);
        System.assertEquals(
            agemtsWrkHist[0].IsOwnerChangeInitiated__c,
            agentsWork[0].IsOwnerChangeInitiated
        );
        System.assertEquals(
            agemtsWrkHist[0].IsStatusChangeInitiated__c,
            agentsWork[0].IsStatusChangeInitiated
        );
        System.assertEquals(
            agemtsWrkHist[0].PushTimeout__c,
            agentsWork[0].PushTimeout
        );
        System.assertEquals(
            agemtsWrkHist[0].PushTimeoutDateTime__c,
            agentsWork[0].PushTimeoutDateTime
        );
        System.assertEquals(
            agemtsWrkHist[0].OriginalQueueId__c,
            agentsWork[0].OriginalQueueId
        );
        System.assertEquals(agemtsWrkHist[0].Status__c, agentsWork[0].Status);
        System.assertEquals(agemtsWrkHist[0].UserId__c, agentsWork[0].UserId);
    }

    static List<AgentWork> createAgentWork() {
        String jsonAgentWork = '[{"AcceptDateTime":"2021-04-01T15:29:26.000Z","AssignedDateTime":"2021-04-01T15:29:25.000Z","CapacityModel":"StatusBased","CapacityWeight":1.00,"CloseDateTime":"2021-04-05T17:58:03.000Z","CreatedById":"005t0000004s04lAAA","CreatedDate":"2021-04-01T15:29:25.000Z","HandleTime":354517,"Id":"0Bzr0000000L2sWCAS","IsDeleted":false,"IsOwnerChangeInitiated":false,"IsPreferredUserRequired":false,"IsStatusChangeInitiated":false,"LastModifiedById":"005t0000004s04lAAA","LastModifiedDate":"2021-04-05T17:58:03.000Z","Name":"00002900","OwnerId":"005t0000004s04lAAA","PushTimeout":30,"RequestDateTime":"2021-03-12T19:55:04.000Z","RoutingModel":"MostAvailable","RoutingPriority":1,"RoutingType":"SkillsBased","ServiceChannelId":"0N9t0000000fxSQCAY","ShouldSkipCapacityCheck":false,"SpeedToAnswer":1712062,"Status":"Closed","SystemModstamp":"2021-04-05T17:58:03.000Z","UserId":"005t0000004s04lAAA","WorkItemId":"500r0000008PGeAAAW"}]';
        List<AgentWork> agentsWork = (List<AgentWork>) JSON.deserialize(
            jsonAgentWork,
            List<AgentWork>.class
        );
        return agentsWork;
    }
}
