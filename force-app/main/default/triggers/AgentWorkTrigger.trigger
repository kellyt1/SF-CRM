trigger AgentWorkTrigger on AgentWork(before insert, before update, after insert, after update) {
    if (Trigger.isUpdate && Trigger.isBefore) {
        for (AgentWork aw : Trigger.new) {
            if (aw.Status == 'Transferred') {
                aw.addError('Error');
            }
        }
    } 
    
    if (Trigger.isInsert && Trigger.isAfter) {
        MEDSS_AgentWorkHelper.createHistoryOnInsert(Trigger.new);
    }
    
    if (Trigger.isUpdate && Trigger.isAfter) {
        MEDSS_AgentWorkHelper.updateHistoryRecords(Trigger.new);
    }
}