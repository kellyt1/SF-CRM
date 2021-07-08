global class MEDSS_IntakeBatch_Scheduler implements Schedulable {
    /*code snippet for cron id - RUNS EVERY 30 MINS

        MEDSS_IntakeBatch_Scheduler m = new MEDSS_IntakeBatch_Scheduler();
        String sch ='0 30 * * * ? *';
        String sample = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ? ' + year;
        String jobID = system.schedule('Merge Job', sch, m);


    */

    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobIdIntake = Database.executeBatch(
            new MEDSS_IntakeBatch(),
            200
        ); // For Intake
    }
}
