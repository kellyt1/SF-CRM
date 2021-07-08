global class MEDSS_Batch_RemoveLTF_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchJobIdRemove = Database.executeBatch(
            new MEDSS_RemoveLTFBatch(),
            200
        );
    }
}