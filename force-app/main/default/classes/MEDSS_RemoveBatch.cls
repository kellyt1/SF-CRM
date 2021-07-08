global class MEDSS_RemoveBatch implements Database.Batchable<sObject> {
    global Integer queryLimit = 2000;

    // Start Method for querying 4 external objects- get all records ------
    global Iterable<SObject> start(Database.BatchableContext BC) {
        return [
            SELECT CaseId__c
            FROM RemoveCovidCases__x
            ORDER BY ModificationDate__c DESC
            LIMIT :this.queryLimit
        ];
    }

    // Execute Method ------
    global void execute(
        Database.BatchableContext BC,
        List<RemoveCovidCases__x> removeCovidCaseList
    ) {
        MEDSS_Batch_Helper.removeCovidCases(removeCovidCaseList, '%Outbound%');
    }

    // Finish Method ------
    global void finish(Database.BatchableContext BC) {
        system.debug('- Finish Method -');
    }
}
