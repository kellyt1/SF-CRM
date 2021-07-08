global with sharing class MEDSS_DataRetentionScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchDataRetention = Database.executeBatch(
            new MEDSS_DataRetention(),
            200
        );
    }
}
