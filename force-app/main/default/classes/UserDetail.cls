/*
    Author             : jon.ferneau@slalom.com
    Last Modified By   : Jon Ferneau
    Last Modified On   : 1/27/2021
*/

public without sharing class UserDetail {
    // getting our Current Logged in UserId
    @TestVisible
    private static Id userId {
        get {
            if (userId == null) {
                userId = UserInfo.getUserId();
            }
            return userId;
        }
        private set;
    }

    // Allows the Apex method to be called in our Lightning Web Component
    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Skills or Jurisdictions
    public static List<ServiceResourceSkill> getUsersResourceSkills() {
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
    public static List<GroupMember> getUsersGroups() {
        // Querying our data from the Group object based on Current Logged in UserId
        List<GroupMember> lUsersGroups = [
            SELECT Id, Group.Name
            FROM GroupMember
            WHERE UserOrGroupId = :userId AND Group.Type = 'Queue'
            ORDER BY Group.Name
        ];
        return lUsersGroups;
    }

    // @AuraEnabled(cacheable=true)
    // // Setting our Apex method list for Skills, filtered by only those that contain the word "Region"
    // public static List<ServiceResourceSkill> getUserRegion() {
    //     // Querying our data from the Skill object based on Current Logged in UserId
    //     List<ServiceResourceSkill> lUserRegion = [
    //         SELECT Id, Skill.MasterLabel, ServiceResource.RelatedRecordId
    //         FROM ServiceResourceSkill
    //         WHERE ServiceResource.RelatedRecordId = :userId
    //         AND Skill.MasterLabel LIKE '%Region%'
    //     ];
    //     return lUserRegion;
    // }

    @AuraEnabled(cacheable=true)
    // Setting our Apex method list for Callback Numbers
    public static List<Call_Back_Number__mdt> getCallbackNumbers() {
        // We need to first create a new list to house the Queues that a User belongs to for query filtering
        List<GroupMember> groupMembers = getUsersGroups();
        List<String> lQueueNames = new List<String>();
        // Iterate over the list so that we can add all Queues to our new list for a User
        for (GroupMember gm : groupMembers) {
            lQueueNames.add(gm.Group.Name);
        }

        // Querying our data from the Callback Number Custom Metadata and returning the counties and their respective callback numbers based on Queue and Skills assigned to the logged in User
        List<Call_Back_Number__mdt> lCallbackNumbers = getCallBackNbrs(
            lQueueNames
        );
        return lCallbackNumbers;
    }

    @TestVisible
    private static List<Call_Back_Number__mdt> getCallBackNbrs(
        List<String> lQueueNames
    ) {
        return [
            SELECT Id, Queue_Name__c, Label, Call_Back_Number__c
            FROM Call_Back_Number__mdt
            WHERE Queue_Name__c IN :lQueueNames
            ORDER BY Label
        ];
    }
}
