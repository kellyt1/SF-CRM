@isTest(SeeAllData=false)
public class DisplayUserSkillsAndQueuesTest {
    private static void createTestQueue() {
        List<Group> queues = new List<Group>();

        for (Integer i = 0; i < 3; i++) {
            Group queue = new Group(Name = 'Test Queue: ' + i, Type = 'Queue');
            queues.add(queue);
        }
        insert queues;
    }

    @isTest(SeeAllData=false)
    static void testGetQueueMembers() {
        createTestQueue();
        Id queueId = [SELECT Id, Type FROM Group WHERE Type = 'Queue' LIMIT 1]
        .Id;
        List<User> userQueues = DisplayUserSkillsAndQueuesSetup.getUsersGroups(
            queueId
        );
        System.assertNotEquals(null, userQueues);
    }

    @isTest(SeeAllData=false)
    static void testGetSkillMembers() {
        Id skillId = [SELECT Id FROM Skill LIMIT 1].Id;
        List<User> userSkills = DisplayUserSkillsAndQueuesSetup.getUsersSkills(
            skillId
        );
        System.assertNotEquals(null, userSkills);
    }
}
