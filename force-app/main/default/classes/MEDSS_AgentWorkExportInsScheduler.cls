global with sharing class MEDSS_AgentWorkExportInsScheduler implements Schedulable {
    // Execute at regular intervals
    global void execute(SchedulableContext ctx) {
        Id batchJobIdAgentWorkExportIns = Database.executeBatch(
            new MEDSS_AgentWorkExportIns(),
            200
        );
    }
}
