global class MEDSS_Batch_IntakeRefresh implements Database.Batchable<sObject>, Database.Stateful {
    global Id intakeRecordTypeId = MEDSS_Batch_Helper.intakeRecordTypeId;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            //Query for Cases in the org that have
            'SELECT Id FROM Case WHERE RecordTypeId =: intakeRecordTypeId'
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        try {
            if (!scope.isEmpty()) {
                delete scope;
            }
        } catch (Exception e) {
            System.debug(e);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finish IntakeRefresh');
    }
}
