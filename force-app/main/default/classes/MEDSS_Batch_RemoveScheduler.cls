global class MEDSS_Batch_RemoveScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobIdRemove = Database.executeBatch(
            new MEDSS_RemoveBatch(),
            200
        );
    }
}
