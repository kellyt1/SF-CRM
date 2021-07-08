//***This is the scheduler class for the MEDSS_Batch_FiveHourFollowup Apex***
global class MEDSS_BatchFiveHourFollowup_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        MEDSS_Batch_FiveHourFollowup batchObject = new MEDSS_Batch_FiveHourFollowup();
        Id batchId = Database.executeBatch(batchObject, 200);
    }
}
