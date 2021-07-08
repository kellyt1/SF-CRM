global with sharing class MEDSS_DataRetentionAcctScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchDataRetentionAcct = Database.executeBatch(
            new MEDSS_DataRetentionAcct(),
            200
        );
    }
}
