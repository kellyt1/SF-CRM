@IsTest(SeeAllData=false)
public class MEDSS_BatchUtilTest {
    /*  Script to Schedule job
        MEDSS_BatchUtil m6 = new MEDSS_BatchUtil();
        String batchUtilJob00 = system.schedule('Batch Util', '0 0 0 * * ? *', m6);
    */

    @IsTest(SeeAllData=false)
    static void testGetBatchHistoryRetentionDate() {
        // Duplicate code from method
        String nbrDays = MEDSS_Batch_Helper.getMedssMetadata(
            'BatchHistRetenDays'
        );
        Date day = Date.today().addDays(-Integer.valueOf(nbrDays));

        Datetime delBefore = Datetime.newInstance(
            day.year(),
            day.month(),
            day.day()
        );

        Datetime delBeforeTest = MEDSS_BatchUtil.getBatchHistoryRetentionDate();
        System.assertEquals(delBefore, delBeforeTest);
    }

    @IsTest(SeeAllData=false)
    static void testDeleteHistory() {
        insert (new Batch_History__c(
            Name = String.valueOf(DateTime.now()),
            Max_DateTime__c = String.valueOf(DateTime.now()),
            Record_Count__c = 200
        ));

        MEDSS_BatchUtil.deleteHistory(Datetime.now().addDays(1));
        List<Batch_History__c> batchHistory = [SELECT Id FROM Batch_History__c];
        System.assertEquals(0, batchHistory.size());
    }
}
