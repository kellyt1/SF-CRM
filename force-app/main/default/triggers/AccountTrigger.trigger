trigger AccountTrigger on Account(before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountTriggerHandler.populateAccountPhone(
                (List<Account>) Trigger.new
            );
        }
    }
}
