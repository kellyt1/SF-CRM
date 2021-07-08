/**
 * To schedule batch jobs, copy/paste and execute the below code using Anonymous Apex in the Developer Console.
 * You can adjust the scheduled time using the 2nd value of the 2nd argument. For example, the 35 in
 * '35 * * * ?' will have the job execute at x:35 every hour.
 *
 * Because S3 updates in 15 minute intervals (:00, :15, :30, :45) it is recommend that you schedule jobs a
 * minimum of 5 minutes after the S3 refresh to allow for the views to update (ex. :05, :20, etc)
 */

// MEDSS_Batch_Scheduler m = new MEDSS_Batch_Scheduler();
// String outboundeJobID05 = system.schedule('Batch Outbound :05', '0 5 * * * ?', m);
// String outboundJobID35 = system.schedule('Batch Outbound :35', '0 35 * * * ?', m);

global class MEDSS_OutboundBatch_Scheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        //String soql = 'SELECT Id, Name FROM Account';
        Id batchJobId = Database.executeBatch(new MEDSS_OutboundBatch(), 200);

        //Database.executebatch(batch, 200);
    }
}
