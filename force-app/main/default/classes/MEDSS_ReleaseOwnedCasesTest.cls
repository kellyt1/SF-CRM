@isTest(SeeAllData=false)
public with sharing class MEDSS_ReleaseOwnedCasesTest {
    @isTest(SeeAllData=false)
    static void testReleaseCases() {
        
        Case testCase = new Case(MEDSS_Event_ID__c = '1');
        
        insert testCase;
        
        Case validateCase1 = [SELECT Id, Status FROM Case LIMIT 1];
        List<PendingServiceRouting> testPSR1 = [SELECT Id FROM PendingServiceRouting LIMIT 1];
        
        System.assert(testPSR1.isEmpty());
        System.assertEquals('New', validateCase1.Status);
        
        updateCase(testCase);
        MEDSS_ReleaseOwnedCases.releaseCases([SELECT Id FROM Case WHERE Status = 'New' OR Status = 'Re-queued']);
        
        Case validateCase2 = [SELECT Id, Status FROM Case LIMIT 1];
        
        System.assertEquals('Closed', validateCase2.Status);
    }
    
    static void updateCase(Case testCase){
        testCase.MEDSS_Case_Key__c = 'SAMPLE CASEID';
        testCase.Aged_Out__c = MEDSS_DateUtil.determineAgeThreshold(DateTime.now());
        testCase.Intake_Completion_Date__c = DateTime.now();
        testCase.SubregionBasedJurisdictionCode__c = 'SR-NW';
        testCase.InterviewJurisdictionCode__c = 'GEN';
        testCase.CountyCode__c = 'MN-87';
        testCase.Preferred_Language_Unrestricted__c = 'English';
        testCase.MN_ID__c = 'TEST MNID';
        testCase.SubjectId__c = '1010101010';
        testCase.Subject = 'Outbound Call';
        testCase.Description = 'NOT A REAL CASE';
        testCase.Origin = 'Phone';
        testCase.RecordTypeId = MEDSS_Batch_Helper.outboundRecordTypeId;
    }
}