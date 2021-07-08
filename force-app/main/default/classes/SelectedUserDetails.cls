public with sharing class SelectedUserDetails {

    // Allows the Apex method to be called in our Lightning Web Component
    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Skills or Jurisdictions
    public static List<ServiceResourceSkill> getUsersResourceSkills(String userId) {
        // Then, query our data from the Skill object based on Current Logged in UserId
        List<ServiceResourceSkill> lUsersSRS = [
            SELECT
                Id,
                Skill.MasterLabel,
                ServiceResourceId,
                ServiceResource.IsActive,
                ServiceResource.RelatedRecordId
            FROM ServiceResourceSkill
            WHERE
                ServiceResource.RelatedRecordId = :userId
                AND ServiceResource.IsActive = TRUE
            ORDER BY Skill.MasterLabel
        ];
        return lUsersSRS; // returning the results of our query
    }

    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Queues
    public static List<GroupMember> getUsersGroups(String userId) {
        System.debug('***User ID to search for: ' + userId);
        // Querying our data from the Group object based on Current Logged in UserId
        List<GroupMember> lUsersGroups = [
            SELECT Id, Group.Name
            FROM GroupMember
            WHERE UserOrGroupId = :userId AND Group.Type = 'Queue'
            ORDER BY Group.Name
        ];
        return lUsersGroups;
    }

}