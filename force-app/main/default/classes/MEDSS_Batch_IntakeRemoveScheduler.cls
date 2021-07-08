global class MEDSS_Batch_IntakeRemoveScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobIdRemove = Database.executeBatch(
            new MEDSS_RemoveIntakeBatch(),
            200
        );
    }
}
