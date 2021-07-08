@isTest(SeeAllData=false)
public class TaskTriggerTest {
    @isTest(SeeAllData=false)
    static void testDeleteTasks() {
        Task tsk1 = new Task();
        tsk1.Subject = 'Task 1';
        tsk1.ownerId = UserInfo.getUserId();
        insert tsk1;

        Task tsk2 = new Task();
        tsk2.Subject = 'Task 2';
        tsk2.ownerId = UserInfo.getUserId();
        insert tsk2;

        List<Task> testResults = [SELECT Id, Subject FROM Task];
        System.assertEquals(1, testResults.size());
        System.assertEquals('Task 2', testResults[0].Subject);
    }
}
