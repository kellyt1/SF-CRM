trigger TaskTrigger on Task(before insert) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            //Delete other existing Tasks for the owner of the inserted task
            Set<Id> setOwnerIds = new Set<Id>();

            for (Task t : Trigger.new) {
                setOwnerIds.add(t.OwnerId);
            }

            List<Task> listTasksToDelete = [
                SELECT Id
                FROM Task
                WHERE OwnerId IN :setOwnerIds
            ];
            if (!listTasksToDelete.isEmpty()) {
                delete listTasksToDelete;
            }
        }
    }
}
