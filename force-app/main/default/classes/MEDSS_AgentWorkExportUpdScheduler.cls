global with sharing class MEDSS_AgentWorkExportUpdScheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobIdAgentWorkExportUpd = Database.executeBatch(
            new MEDSS_AgentWorkExportUpd(),
            200
        );
    }
}
