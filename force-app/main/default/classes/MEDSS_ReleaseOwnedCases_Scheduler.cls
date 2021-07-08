global class MEDSS_ReleaseOwnedCases_Scheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobId = Database.executeBatch(new MEDSS_ReleaseOwnedCases(), 200);
    }
}