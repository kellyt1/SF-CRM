@isTest(SeeAllData=false)
public class MEDSS_Batch_FiveHourFollowupTest {
    static testMethod void testCaseLessThanFiveHoursCallAttempt() {
        Test.startTest();
        List<SObject> objLs = createCaseWithCallAttemptDate(3);
        MEDSS_Batch_FiveHourFollowup obj = new MEDSS_Batch_FiveHourFollowup();
        Database.executeBatch(obj);
        Test.stopTest();
    }

    static testMethod void testCaseGreaterThanFiveHoursCallAttempt() {
        Test.startTest();
        List<SObject> objLs = createCaseWithCallAttemptDate(6);
        MEDSS_Batch_FiveHourFollowup obj = new MEDSS_Batch_FiveHourFollowup();
        //obj.execute(bc, scope);
        Test.stopTest();
    }

    @isTest(SeeAllData=false)
    static void testCasesToRoute() {
        MEDSS_Batch_FiveHourFollowup followUp = new MEDSS_Batch_FiveHourFollowup();
        List<Case> cases = new List<Case>();
        cases.addAll(createCaseWithCallAttemptDate(2));
        cases.addAll(createCaseWithCallAttemptDate(7));

        Map<Id, Case> mapCases = followUp.casesToRoute(cases);
        System.assert(mapCases.keySet().size() == 1);
    }

    private static List<Case> createCaseWithCallAttemptDate(Integer hours) {
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Outbound Call')
            .getRecordTypeId();

        String idEnd = String.valueOf(hours).leftPad(3, '0');
        Case newCase = new Case(
            Id = '500r0000006x000' + idEnd,
            Preferred_Language_Unrestricted__c = 'English',
            Call_Attempt_Date__c = system.now().addHours(-hours),
            Region__c = 'Central',
            County__c = 'Pine',
            Requeue_Reason__c = 'Call Attempted',
            RecordTypeId = recTypeId,
            Status = 'Follow-up'
        );
        return new List<Case>{ newCase };
    }
}
