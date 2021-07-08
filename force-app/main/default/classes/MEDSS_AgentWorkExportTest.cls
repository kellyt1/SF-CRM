@isTest(SeeAllData=false)
public with sharing class MEDSS_AgentWorkExportTest {
    private static MEDSS_AgentWorkExportIns agtWrkExpIns = new MEDSS_AgentWorkExportIns();
    private static MEDSS_AgentWorkExportUpd agtWrkExpUpd = new MEDSS_AgentWorkExportUpd();

    @isTest(SeeAllData=false)
    private static void testCreateAgentsWork() {
        List<AgentWorkHistory__c> agentsWrkHist = createAgentsWorkHistories();
        List<AgentWorks__x> aWorkIns = agtWrkExpIns.createAgentsWork(
            agentsWrkHist
        );
        System.assertEquals(
            agtWrkExpIns.convertToLocal(agtWrkExpIns.insertDateTime),
            aWorkIns[0].InsertDatetime__c
        );
        System.assertEquals(1, aWorkIns.size());

        List<AgentWorks__x> aWorkUpd = agtWrkExpUpd.createAgentsWork(
            agentsWrkHist
        );
        System.assertEquals(
            agtWrkExpUpd.convertToLocal(agtWrkExpUpd.updateDateTime),
            aWorkUpd[0].ModifiedDatetime__c
        );
        System.assertEquals(1, aWorkUpd.size());
    }

    @isTest(SeeAllData=false)
    private static void testGetAgentWorkHistory() {
        Database.QueryLocator qLocatorIns = agtWrkExpIns.getAgentWorkHistory();
        System.assert(qLocatorIns.getQuery().contains('SELECT '));

        Database.QueryLocator qLocatorUpd = agtWrkExpUpd.getAgentWorkHistory();
        System.assert(qLocatorUpd.getQuery().contains('SELECT '));
    }

    @isTest(SeeAllData=false)
    private static void testExecute() {
        List<AgentWorkHistory__c> agentsWrkHist = createAgentsWorkHistories();
        agentsWrkHist[0].Id = null;
        DateTime dt = agentsWrkHist[0].CreatedDate;

        insert agentsWrkHist;

        Test.startTest();
        MEDSS_AgentWorkExportIns agtWrkExpIns0 = new MEDSS_AgentWorkExportIns(
            Date.today()
        );
        Database.executeBatch(agtWrkExpIns0);

        MEDSS_AgentWorkExportUpd agtWrkExpUpd0 = new MEDSS_AgentWorkExportUpd(
            Date.today()
        );
        Database.executeBatch(agtWrkExpUpd0);
        Test.stopTest();
    }

    static List<AgentWorkHistory__c> createAgentsWorkHistories() {
        List<User> users = [SELECT Id, Name FROM User WHERE isActive = TRUE];
        String jsonAgentWorkHist = '[{"Id":"a0br0000001tfr9AAA","AcceptDateTime__c":"2021-04-27T11:59:25.000Z","AssignedDateTime__c":"2021-04-27T11:59:25.000Z","CloseDateTime__c":"2021-04-27T12:59:25.000Z","HandleTime__c":60000,"MEDSS_Event_ID__c":"E0001341","MEDSS_Event_Record_Type__c":"RecType","Name":"a0br0000001tfr9","PushTimeout__c":30,"PushTimeoutDateTime__c":"2021-04-27T18:59:25.000Z","Region__c":"Central","RequestDateTime__c":"2021-04-27T18:59:25.000Z","Status__c":"Complete","UserId__c":"_005r","UserId__r":{"Id":"_005r","Name":"_uname"}}]';
        jsonAgentWorkHist = jsonAgentWorkHist.replace('_005r', users[0].Id);
        jsonAgentWorkHist = jsonAgentWorkHist.replace('_uname', users[0].Name);

        List<AgentWorkHistory__c> agentsWorkHist = (List<AgentWorkHistory__c>) JSON.deserialize(
            jsonAgentWorkHist,
            List<AgentWorkHistory__c>.class
        );
        return agentsWorkHist;
    }
}
