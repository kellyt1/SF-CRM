@isTest(SeeAllData=false)
public with sharing class MEDSS_RemoveBatchTest {
    @isTest(SeeAllData=false)
    static void testRemoveCovidCases() {
        List<RemoveCovidCases__x> xCases = buildTestCovidCases();

        MEDSS_RemoveBatch rmBatch = new MEDSS_RemoveBatch();
        /*rmBatch.removeCovidCases(xCases);

        List<Case> cases = [SELECT Id, Status FROM Case];
        System.assertEquals(200, cases.size());
        for (Case cs : cases) {
            System.assertEquals('New', cs.Status);
        }*/
    }

    static List<RemoveCovidCases__x> buildTestCovidCases() {
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Outbound Call')
            .getRecordTypeId();
        List<RemoveCovidCases__x> xCases = new List<RemoveCovidCases__x>();
        List<Case> cases = new List<Case>();

        for (Integer i = 0; i < 200; i++) {
            String mId = String.valueOf(i).leftPad(5, '0');
            RemoveCovidCases__x x = new RemoveCovidCases__x(CaseId__c = mId);
            xCases.add(x);

            Case c = new Case(
                Status = 'New',
                RecordTypeId = recordTypeId,
                MEDSS_Event_Id__c = mId
            );
            cases.add(c);
        }
        insert cases;
        return xCases;
    }
}
