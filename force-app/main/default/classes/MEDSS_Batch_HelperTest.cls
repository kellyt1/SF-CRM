@isTest(SeeAllData=false)
public class MEDSS_Batch_HelperTest {
    @isTest(SeeAllData=false)
    static void testPersonAccountRecordTypeId() {
        Id accountRecordIdTest = MEDSS_Batch_Helper.personAccountRecordTypeId;
        Id accountRecordId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Person Account')
            .getRecordTypeId();

        System.assertEquals(
            accountRecordId,
            accountRecordIdTest,
            'Ids should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testConvertDateTime() {
        String strDate = '12/23/2020 10:00 PM';
        DateTime nwDate = MEDSS_Batch_Helper.convertDateTime(strDate);

        //        System.assertEquals('2020-12-23 22:00:00', String.valueOf(nwDate));

        strDate = '12/23/2020 10:00 AM';
        nwDate = MEDSS_Batch_Helper.convertDateTime(strDate);
        System.assertEquals('2020-12-23 10:00:00', String.valueOf(nwDate));
    }

    @isTest(SeeAllData=false)
    static void testGetUpdatedStatus() {
        Case cOld = new Case(Subject = 'cOld');
        Case cNew = new Case(Subject = 'cOld');

        String status0 = MEDSS_Batch_Helper.getUpdatedStatus(cOld, cNew);
        System.assertEquals('New', status0);

        cNew = new Case(Subject = 'cNew');
        String status1 = MEDSS_Batch_Helper.getUpdatedStatus(cOld, cNew);
        System.assertEquals('New', status1);
    }

    @isTest(SeeAllData=false)
    static void testIntakeRecordTypeId() {
        Id intakeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Intake')
            .getRecordTypeId();

        System.assertEquals(
            intakeRecordTypeId,
            MEDSS_Batch_Helper.intakeRecordTypeId
        );
    }

    @isTest(SeeAllData=false)
    static void testOutboundRecordTypeId() {
        Id outboundRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Outbound Call')
            .getRecordTypeId();

        System.assertEquals(
            outboundRecordTypeId,
            MEDSS_Batch_Helper.outboundRecordTypeId
        );
    }

    @isTest(SeeAllData=false)
    static void testCovidIntakeDedupQueueId() {
        Id covidIntakeDedupQueueId = MEDSS_Batch_Helper.getQueueSObject(
            'CovidIntakeDedup'
        );

        System.assertEquals(
            covidIntakeDedupQueueId,
            MEDSS_Batch_Helper.covidIntakeDedupQueueId
        );

        System.assertEquals(
            null,
            MEDSS_Batch_Helper.getQueueSObject('test test')
        );
    }

    @isTest(SeeAllData=false)
    static void testRegionMap() {
        Map<String, Map<String, String>> regionMap = MEDSS_Batch_Helper.regionMap;
        Map<String, Map<String, String>> regionMapMaster = MEDSS_Batch_Helper.getRegionMap();

        System.assertEquals(
            regionMap.keySet().size(),
            regionMapMaster.keySet().size()
        );
    }

    @isTest(SeeAllData=false)
    static void testSetOwnerIdToIntakeQueue() {
        Case cOld = new Case(Subject = 'Positive Intake Test');
        Case cNew = new Case(Subject = 'Positive Dedup Test');

        MEDSS_Batch_Helper.setOwnerIdToIntakeQueue(cOld);
        System.assertEquals(
            MEDSS_Batch_Helper.covidIntakePositiveQueueId,
            cOld.OwnerId
        );

        MEDSS_Batch_Helper.setOwnerIdToIntakeQueue(cNew);
        System.assertEquals(
            MEDSS_Batch_Helper.covidIntakeDedupQueueId,
            cNew.OwnerId
        );
    }

    @isTest(SeeAllData=false)
    static void testGetMedssMetadata() {
        List<Medss__mdt> mdt = [
            SELECT Id, DeveloperName, MasterLabel, Record_Value__c
            FROM Medss__mdt
        ];

        if (mdt == null || mdt.size() < 1) {
            return;
        }

        String mdtRec = MEDSS_Batch_Helper.getMedssMetadata(
            mdt[0].DeveloperName
        );
        System.assertEquals(mdt[0].Record_Value__c, mdtRec);
    }

    @isTest(SeeAllData=false)
    static void testUpdateBatchHistory() {
        Batch_History__c bHist0 = MEDSS_Batch_Helper.getLatestBatchHistory();
        // Check for default value if object is empty
        System.assertEquals('01/01/2010 00:00 AM', bHist0.Max_DateTime__c);
        System.assertEquals(1, bHist0.Record_Count__c);

        String maxDate = String.valueOf(DateTime.now());
        MEDSS_Batch_Helper.updateBatchHistory(maxDate, 200);

        Batch_History__c bHist1 = MEDSS_Batch_Helper.getLatestBatchHistory();
        System.assertEquals(maxDate, bHist1.Max_DateTime__c);
        System.assertEquals(200, bHist1.Record_Count__c);
    }
}
