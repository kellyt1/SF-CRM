global class MEDSS_ReleaseOwnedCases implements Database.Batchable<sObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String statusNew = 'New';
        String statusRequeued = 'Re-queued';
        
        return Database.getQueryLocator(
            'SELECT Id FROM Case WHERE Status =: statusNew OR Status =: statusRequeued'
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        releaseCases(scope);
    }
    
    @testVisible
    private static void releaseCases(List<Case> scope) {
        List<Case> listCasesToRelease = new List<Case>();
        Set<Id> setIdsWithPSR = MEDSS_Batch_Helper.getSetOfCasesWithPSR(scope);
        
        for(Case c : scope){
            if(!setIdsWithPSR.contains(c.Id)){
                c.Status = 'Closed';
                listCasesToRelease.add(c);
            }
        }
        
        if(!listCasesToRelease.isEmpty()) update listCasesToRelease;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finish ReleaseOwnedCases');
    }
}