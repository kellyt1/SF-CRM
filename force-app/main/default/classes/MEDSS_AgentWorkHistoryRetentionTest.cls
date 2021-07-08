@IsTest(SeeAllData=false)  
private class MEDSS_AgentWorkHistoryRetentionTest {
    @IsTest(SeeAllData=false)
    static void testCreatedDateStart() {
        Date todaysDate = Date.today();

        Data_Retention__mdt dataRetention = [
            SELECT
                MasterLabel,
                Number_of_Days_for_Deletion_Medss_Event__c,
                Number_of_Days_for_Deletion_Account__c,
                Days_for_Deletion_AgentWorkHistory__c
            FROM Data_Retention__mdt
            WHERE MasterLabel = 'Standard Retention Policy'
        ];

        Date createdDateStart = todaysDate.addDays(
            -Integer.valueOf(
                dataRetention.Days_for_Deletion_AgentWorkHistory__c
            )
        );
        
        MEDSS_AgentWorkHistoryRetention dr = new MEDSS_AgentWorkHistoryRetention();
        System.assertEquals(createdDateStart, dr.getCreatedDateStart());
    }

    @IsTest(SeeAllData=false)
    static void testStart() {
        Test.startTest();
            MEDSS_AgentWorkHistoryRetention awhretention = new MEDSS_AgentWorkHistoryRetention();
            Database.executeBatch(awhretention);
        Test.stopTest();
    }

    @IsTest(SeeAllData=false)
    static void testDeleteRecords() {
        makeData();
        Test.startTest();
            MEDSS_AgentWorkHistoryRetention dr = new MEDSS_AgentWorkHistoryRetention();
            dr.deleteRecords([SELECT Id FROM AgentWorkHistory__c]);
            
        Test.stopTest();
    }     

    private static void makeData() {
        AgentWorkHistory__c testrecord = new AgentWorkHistory__c();
        insert testrecord;
    }
}
