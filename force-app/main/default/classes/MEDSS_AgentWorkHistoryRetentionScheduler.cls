global with sharing class MEDSS_AgentWorkHistoryRetentionScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Id batchDataRetention = Database.executeBatch(
            new MEDSS_AgentWorkHistoryRetention(),
            200
        );  
    }
}
