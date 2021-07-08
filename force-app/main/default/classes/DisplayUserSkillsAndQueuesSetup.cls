public without sharing class DisplayUserSkillsAndQueuesSetup {
    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Queues
    public static List<User> getUsersGroups(Id queueId) {
        // Query for all Users in the Queue based on the Queue ID that is selected to search on
        System.debug('***Queue ID passed in to the Apex: ' + queueId);
        List<User> groupUsers = [
            SELECT
                User.Id,
                User.Email,
                User.Name,
                User.LastLoginDate,
                User.IsActive,
                User.LastModifiedDate,
                User.UserRole.Name
            FROM User
            WHERE
                Id IN (
                    SELECT UserOrGroupId
                    FROM GroupMember
                    WHERE GroupId = :queueId
                )
        ];

        System.debug('***List of Queue Members to return: ' + groupUsers);
        //Return results back to the LWC
        return groupUsers;
    }

    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Queues
    public static List<User> getUsersSkills(Id skillId) {
        // Query for all Users with the Skill based on the Skill ID that is selected to search on
        System.debug('***Skill ID passed in to the Apex: ' + skillId);
        List<ServiceResource> servResources = [
            SELECT ServiceResource.RelatedRecordId, ServiceResource.Id
            FROM ServiceResource
            WHERE
                Id IN (
                    SELECT ServiceResourceId
                    FROM ServiceResourceSkill
                    WHERE SkillId = :skillId
                )
        ];
        List<Id> userIds = new List<Id>();
        for (ServiceResource sr : servResources) {
            userIds.add(sr.RelatedRecordId);
        }
        System.debug('**List of user IDs to query: ' + userIds);
        List<User> skillUsers = [
            SELECT
                Id,
                Name,
                Email,
                LastLoginDate,
                IsActive,
                LastModifiedDate,
                UserRole.Name
            FROM User
            WHERE Id IN :userIds
        ];
        System.debug('***List of Skill Members to return: ' + skillUsers);
        //Return results back to the LWC
        return skillUsers;
    }
}
