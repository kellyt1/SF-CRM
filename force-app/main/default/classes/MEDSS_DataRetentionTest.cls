@IsTest(SeeAllData=false)
private class MEDSS_DataRetentionTest {
    @IsTest(SeeAllData=false)
    static void testCreatedDateStart() {
        Date todaysDate = Date.today();

        Data_Retention__mdt dataRetention = [
            SELECT
                MasterLabel,
                Number_of_Days_for_Deletion_Medss_Event__c,
                Number_of_Days_for_Deletion_Account__c
            FROM Data_Retention__mdt
            WHERE MasterLabel = 'Standard Retention Policy'
        ];

        Date createdDateStartCase = todaysDate.addDays(
            -Integer.valueOf(
                dataRetention.Number_of_Days_for_Deletion_Medss_Event__c
            )
        );

        Date createdDateStartAcct = todaysDate.addDays(
            -Integer.valueOf(
                dataRetention.Number_of_Days_for_Deletion_Account__c
            )
        );

        MEDSS_DataRetention dr = new MEDSS_DataRetention();
        System.assertEquals(createdDateStartCase, dr.getCreatedDateStart());

        MEDSS_DataRetentionAcct drAcct = new MEDSS_DataRetentionAcct();
        System.assertEquals(createdDateStartAcct, drAcct.getCreatedDateStart());
    }

    @IsTest(SeeAllData=false)
    static void testStart() {
        Test.startTest();
        MEDSS_DataRetention dr = new MEDSS_DataRetention();
        Database.executeBatch(dr);

        MEDSS_DataRetentionAcct drAcct = new MEDSS_DataRetentionAcct();
        Database.executeBatch(drAcct);
        Test.stopTest();
    }

    @IsTest(SeeAllData=false)
    static void testDeleteRecords() {
        makeData();
        MEDSS_DataRetention dr = new MEDSS_DataRetention();
        dr.deleteRecords([SELECT Id FROM Account]);

        MEDSS_DataRetentionAcct drAcct = new MEDSS_DataRetentionAcct();
        drAcct.deleteRecords([SELECT Id FROM Case]);
    }

    private static void makeData() {
        Account account = new Account(
            MnId__c = '12365',
            FirstName = 'Test',
            LastName = 'TestLast'
        );
        insert account;

        Case nwCase = new Case(
            MEDSS_Event_ID__c = '12349',
            MEDSS_Case_Key__c = '6789',
            MN_ID__c = '12365'
        );
        insert nwCase;
    }
}
