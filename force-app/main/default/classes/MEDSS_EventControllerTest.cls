@isTest(SeeAllData=false)
public with sharing class MEDSS_EventControllerTest {
    @isTest(SeeAllData=false)
    static void testConnectMedssIdToContactTraceRcd() {
        Case testCase = new Case(
            Subject = 'Test class',
            Status = 'New',
            Priority = 'Medium',
            Origin = 'Email',
            MEDSS_Event_ID__c = '12345'
        );
        testCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByName()
            .get('Outbound Call')
            .getRecordTypeId();
        insert testCase;
        User user = createPortalUser();
        Id caseRecordId = testCase.Id;
        Id userId = user.Id;
        Task tsk = createTask();
        String contactId = 'o123TestContact';
        String phoneNumber = '123456789';
        // String taskId = tsk.Id;
        String token = 'token';

        //Establish connection
        MEDSS_EventController.connectMedssIdToContactTraceRecord(
            contactId,
            phoneNumber,
            token
        );

        //Success response code for Stop Recording
        MEDSS_EventController.testResponse = 200;
        Boolean success0 = MEDSS_EventController.stopRecInAmazonConnect(userId);
        System.assertEquals(true, success0, 'Should be success path');

        //Error server code for Stop Recording
        MEDSS_EventController.testResponse = 500;
        Boolean success1 = MEDSS_EventController.stopRecInAmazonConnect(
            userId
        );
        System.assertEquals(false, success1, 'Should be fail path');
        
        //Sending MEDSS ID to AC
        MEDSS_EventController.connectMedssIdToAmazon(contactId, caseRecordId, phoneNumber, token);

        //End the connection
        MEDSS_EventController.clearOutAmazonCTIFields();

        //Update OwnerId
        MEDSS_EventController.updateOwnerForCase(caseRecordId);
    }
    private static User createPortalUser() {
        Profile profile = [SELECT id FROM profile WHERE Name = 'CICT Portal User'];
        User user = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testfind@mnitintake.com'
        );
        insert user;
        return user;
    }

    //create Task
    private static Task createTask(){
        User ul = [select id from User WHERE alias = :'standt'];
        Task tsk = new Task();
        tsk.ContactIdCTI__c = 'contact trace id 1234';
        tsk.TokenCTI__c = 'token 1234';
        tsk.Subject = 'Call Recording Activity';
        tsk.Status = 'Open';
        tsk.Priority = 'Normal';
        tsk.OwnerId = ul.Id;
        tsk.Amazon_Connect_Phone_Number__c = '12345';
        insert tsk;
        return tsk;
    }
}