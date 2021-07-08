trigger CaseTrigger on Case(after insert, before insert, before update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.routeUsingSkill(Trigger.newMap);
        }
    }

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            CaseTriggerHandler.updateQueueId(Trigger.new);
        }
    }
}
