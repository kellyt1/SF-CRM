global with sharing class MEDSS_Batch_DeleteCases implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> statuses = new Set<String>{ 'Re-queued', 'New' };
        return Database.getQueryLocator(
            // Query for Cases
            'SELECT Id FROM Case WHERE Call_Attempt_Date__c != null AND Status in :statuses'
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        //List<Case> listCasesToDelete = new List<Case>();
        Set<Id> setCasesWithPSR = new Set<Id>();
        List<PendingServiceRouting> listPSR = [
            SELECT WorkItemId
            FROM PendingServiceRouting
            WHERE WorkItemId IN :scope
        ];

        for (PendingServiceRouting psr : listPSR) {
            //listCasesToDelete.add(new Case(Id = psr.WorkItemId));
            setCasesWithPSR.add(psr.WorkItemId);
        }

        for (Case c : scope) {
            if (setCasesWithPSR.contains(c.Id))
                c.Status = 'Closed';
        }

        try {
            if (!scope.isEmpty()) {
                update scope;
            }
        } catch (Exception ex) {
            System.debug(ex);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finish MEDSS_Batch_DeleteCases');
    }
}
