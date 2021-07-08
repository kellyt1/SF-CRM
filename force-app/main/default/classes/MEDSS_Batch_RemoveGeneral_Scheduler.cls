global class MEDSS_Batch_RemoveGeneral_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobIdRemove = Database.executeBatch(
            new MEDSS_RemoveGeneralBatch(),
            200
        );
    }
}