/***
 * Created By: Amrutha Thaliyil, Slalom
 * Created Date: Dec 3, 2020
 * Description: Apex class to make callout to amazon connect to update MedssId in Contact Trace Record
 * Updated: Also stamps the Call Attempted Date on the case when an investigator presses the 'Call Attempted' button on the case
 * Updated: April 7, 2021 to make new callout to pass MEDSS ID to Amazon Connect endpoint & added references to custom labels for endpoint URLs.
 */
public with sharing class MEDSS_EventController {
    @TestVisible
    private static Integer testResponse = null;
    // URL for Passing MEDSS ID is stored in 'Send MEDSS ID to AC Endpoint URL' custom label
    private static String callOutUrlForUpdateMedssId = System.Label.Send_MEDSS_ID_to_AC_Endpoint_URL;
    // Parameters needed for updateAttributes method
    // initialContactId: string
    // attributes: { [name: MEDSS_ID]: string }
    // URL for Stopping Recording in AC is stored in 'Stop Recording Endpoint URL' custom label
    private static String callOutUrlForStopRecording = System.Label.Stop_Recording_Endpoint_URL;

    public static void connectMedssIdToContactTraceRecord(
        String contactId,
        String phoneNumber,
        String token
    ) {
        // Insert Task on every call connected
        insertTaskRecord(contactId, token, phoneNumber);
    }

    public static void insertTaskRecord(
        String contactId,
        String token,
        String phoneNumber
    ) {
        if (
            !String.isBlank(contactId) &&
            !String.isBlank(token) &&
            !String.isBlank(phoneNumber)
        ) {
            Task tsk = new Task();
            tsk.ContactIdCTI__c = contactId;
            tsk.TokenCTI__c = token;
            tsk.Subject = 'Call Recording Activity';
            tsk.Status = 'Open';
            tsk.Priority = 'Normal';
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Amazon_Connect_Phone_Number__c = phoneNumber;
            insert tsk;
        }
    }

    @AuraEnabled
    public static Boolean stopRecInAmazonConnect(String userInfoId) {
        System.debug('--- UserId: ' + userInfoId);
        List<Task> tsk = [
            SELECT ContactIdCTI__c, TokenCTI__c, Status, OwnerId, Subject
            FROM Task
            WHERE Status = 'Open' AND OwnerId = :userInfoId
        ];
        if (tsk.size() > 0) {
            String contactTraceId = tsk[0].ContactIdCTI__c;
            String tokenCtiVal = tsk[0].TokenCTI__c;
            String body = '{' + '"contactId": "' + contactTraceId + '"' + '}';
            String header = 'Bearer ' + tokenCtiVal;
            System.debug('***Stop Recording Contact Id: ' + contactTraceId);
            System.debug('***Stop Recording Token: ' + tokenCtiVal);
            Integer statusCode = restService(
                callOutUrlForStopRecording,
                body,
                header
            );
            // prettier-ignore
            if (statusCode != 200) {
                System.debug('The status code returned was not expected: ' + statusCode);
                return false;
            } else {
                return true;
            }
        } else {
            System.debug('--- no task');
            return false;
        }
    }

    private static Integer restService(
        String calloutUrl,
        String body,
        String header
    ) {
        if (testResponse >= 0) {
            return testResponse;
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(calloutUrl);
        request.setMethod('POST');
        request.setHeader('Authorization', header);
        request.setBody(body);
        HttpResponse response = http.send(request);
        return response.getStatusCode();
    }

    public static void clearOutAmazonCTIFields() {
        delete [SELECT Id FROM Task WHERE OwnerId = :UserInfo.getUserId()];
    }

    private static case getCasefromRecordId(String caseRecordId) {
        Case nCase = [
            SELECT
                Id,
                MEDSS_Event_ID__c,
                ContactIdCTI__c,
                TokenCTI__c,
                CountyCode__c,
                RecordType.Name,
                Status,
                SubregionBasedJurisdictionCode__c,
                Subject,
                Preferred_Language_Unrestricted__c,
                InterviewJurisdictionCode__c,
                Standard_QueueId__c,
                OwnerId
            FROM Case
            WHERE Id = :caseRecordId
        ];
        return nCase;
    }

    @AuraEnabled
    public static void updateOwnerForCase(String caseRecordId) {
        User integrationUser = [SELECT id FROM User WHERE alias = 'iuser'];
        Case nCase = getCasefromRecordId(caseRecordId);

        // For Intake End shift
        if (
            nCase.Standard_QueueId__c != null &&
            nCase.RecordType.Name.equalsIgnoreCase('Intake')
        ) {
            nCase.OwnerId = nCase.Standard_QueueId__c;
            update nCase;

            // For Outbound End shift
        } else if (
            nCase.RecordType.Name.equalsIgnoreCase('Outbound Call') &&
            nCase.Status != 'Closed'
        ) {
            // Close the Case to delete AgentWork
            nCase.Status = 'Closed';
            nCase.AllowStatusUpdate__c = true;
            nCase.OwnerId = integrationUser.Id;
            update nCase;
            Map<Id, Case> caseMapToPass = new Map<Id, Case>();
            caseMapToPass.put(nCase.Id, nCase);
            CaseTriggerHandler.routeUsingSkill(caseMapToPass);
        }
    }

    public static void connectMedssIdToAmazon(
        String contactId,
        String primaryObjectId,
        String token,
        String phoneNumber
    ) {
        // Insert task on every call connected
        insertTaskRecord(contactId, token, phoneNumber);
        calloutToAmazonConnectWithMedssId(contactId, primaryObjectId, token, phoneNumber);
    }
    
    //build the body and header for web service callout to update Medss Id
    public static void calloutToAmazonConnectWithMedssId(
        String contactId,
        String primaryObjectId,
        String token,
        String phoneNumber
    ){
        String medssId = getMedssId(primaryObjectId);
        System.debug('***MEDSS ID to pass to AC: ' + medssId);
        System.debug('***Contact ID: ' + contactId);
        System.debug('***Token: ' + token);

        // prettier-ignore
        String body =
            '{' + '"initialContactId": "' + contactId + '", ' + '"attributes": {"MEDSS_ID": "' + medssId + '"' + '}}';
        String header = 'Bearer ' + token;
        System.debug('***Body String: ' + body);
        System.debug('***Header String: ' + header);

        //web service callout to update the MEDSS ID attribute
        if(test.isRunningTest() == false){
            updateAttributesRestService(
                callOutUrlForUpdateMedssId,
                body,
                header
            );
        }
    }
    
    @future(callout=true)
    private static void updateAttributesRestService(
        String calloutUrl,
        String body,
        String header
    ) {
        if (testResponse >= 0) {
            system.debug('***Test Response: ' + testResponse);
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(calloutUrl);
        request.setMethod('POST');
        request.setHeader('Authorization', header);
        request.setBody(body);
        request.setHeader('content-type', 'text/plain');
        System.debug('****HTTP POST REQUEST' + request);
        HttpResponse response = http.send(request);
        system.debug('***updateAttributes web service response: ' + response.getStatusCode());
    }

    // Used when CI makes call. Not meant to be bulkified.
    public static String getMedssId(String recordId) {
        String medssId = '';
        if (!String.isBlank(recordId)) {
            Case nCase = getCasefromRecordId(recordId);
            medssId = nCase.MEDSS_Event_ID__c;
        }
        return medssId;
    }
}