global class MEDSS_Batch_IntakeRefreshScheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobIdIntake = Database.executeBatch(
            new MEDSS_Batch_IntakeRefresh(),
            200
        ); // For Intake Refresh
    }
}
