/***
 * Created By: Lauren Knudsen, Slalom
 * Created Date: December 22, 2020
 * Description: Apex class queries for any Cases where Call_Attempt_Date__c is not null AND is greater than Five Hours ago
 * If Case had first call attempt greater than Five Hours ago, then re-insert the Case record into Omni-Channel Skills-based routing
 */
global class MEDSS_Batch_FiveHourFollowup implements Database.Batchable<sObject>, Database.Stateful {
    private Set<String> followupStatus = new Set<String>{ 'Follow-up' };
    private Integer timeDiffInHours = 5;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            // Query for Cases in the org in status of 'Follow-up' and that have a Call_Attempt_Date__c that is populated
            'SELECT Id, Status, County__c, OwnerId, Aged_Out__c, Requeue_Reason__c, InterviewJurisdictionCode__c, CountyCode__c, RecordTypeId, Region__c, Preferred_Language_Unrestricted__c, Call_Attempt_Date__c, SubregionBasedJurisdictionCode__c FROM Case WHERE Call_Attempt_Date__c != null AND Status IN: followupStatus'
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        // TO-DO: Add custom metadata type for five hour follow-up
        Map<Id, Case> caseMap = this.casesToRoute(scope);

        system.debug(' case scope five hour batch' + scope);

        if (!caseMap.isEmpty())
            update caseMap.values();

        // Invoke the method to pass the Case back into the Skill-based routing method
        if (!caseMap.isEmpty()) {
            CaseTriggerHandler.routeUsingSkill(caseMap);
        }
    }

    @TestVisible
    private Map<Id, Case> casesToRoute(List<Case> cases) {
        Datetime currentTime = DateTime.now();
        Datetime timeDiff = currentTime.addHours(-this.timeDiffInHours);

        //TO-DO: Add custom metadata type for five hour follow-up
        Map<Id, Case> caseMap = new Map<Id, Case>();

        for (Case caseRecord : cases) {
            // If the Case is in 'Follow-up' status and has a Call Attempt Date populated,
            // check to make sure the call date & time was greater than five hours ago
            Datetime callAttmptGmt = caseRecord.Call_Attempt_Date__c;

            if (
                caseRecord.Status == 'Follow-up' &&
                callAttmptGmt.addHours(5) < currentTime &&
                caseRecord.Requeue_Reason__c == 'Call Attempted'
            ) {
                system.debug(' inside loop caseRecord' + caseRecord);

                //PCG-608, TBAIN 2-19-2020: Logic to reset the 5 hour period when a case is re-queued after a call attempt is made
                //If the case wasn't Aged Out when the call attempt was made, reset the 5 business hours and re-queue
                if (caseRecord.Aged_Out__c > callAttmptGmt)
                    caseRecord.Aged_Out__c = MEDSS_DateUtil.determineAgeThreshold(
                        currentTime
                    );
                //If the case was already Aged Out when the call attempt was made, re-queue at the Regional Backlog level (no changes)
                caseMap.put(caseRecord.Id, caseRecord);
            }
        }
        return caseMap;
    }

    global void finish(Database.BatchableContext bc) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [
            SELECT
                Id,
                Status,
                NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems,
                CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
    }
}
