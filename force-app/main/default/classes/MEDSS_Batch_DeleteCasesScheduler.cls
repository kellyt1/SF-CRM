global with sharing class MEDSS_Batch_DeleteCasesScheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobIdCaseDelete = Database.executeBatch(
            new MEDSS_Batch_DeleteCases(),
            200
        ); // For MEDSS_Batch_DeleteCases
    }
}
