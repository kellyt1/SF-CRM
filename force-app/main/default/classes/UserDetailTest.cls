@isTest(SeeAllData=false)
public with sharing class UserDetailTest {
    /*
        Some tests are dependent on data in Org. Skills can not be directly inserted in to 
        the Org. There are workarounds using REST or SOAP. 
    */

    @isTest(SeeAllData=false)
    static void testUserId() {
        Id userId = UserDetail.userId;
        System.assertEquals(
            UserInfo.getUserId(),
            userId,
            'User Ids should match'
        );
        userId = UserDetail.userId;
        System.assertEquals(
            UserInfo.getUserId(),
            userId,
            'User Ids should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testGetCallBackNbrs() {
        List<Call_Back_Number__mdt> callBackNumbers = [
            SELECT Id, Queue_Name__c, Label, Call_Back_Number__c
            FROM Call_Back_Number__mdt
        ];

        System.assert(
            callBackNumbers.size() > 0,
            'Custom Metadata does not exist'
        );
        List<String> lQueueNames = new List<String>{
            callBackNumbers[0].Queue_Name__c
        };

        List<Call_Back_Number__mdt> callBackNumbersTest = UserDetail.getCallBackNbrs(
            lQueueNames
        );
        System.assert(callBackNumbersTest.size() > 0);
    }

    @isTest(SeeAllData=true)
    static void testGetUsersResourceSkills() {
        List<ServiceResourceSkill> usersServResourceSkill = [
            SELECT
                Id,
                Skill.MasterLabel,
                ServiceResourceId,
                ServiceResource.IsActive,
                ServiceResource.RelatedRecordId
            FROM ServiceResourceSkill
            WHERE ServiceResource.IsActive = TRUE
        ];

        System.assert(
            usersServResourceSkill.size() > 0,
            'Test is dependent on data existing in Org'
        );

        UserDetail.userId = usersServResourceSkill[0]
            .ServiceResource.RelatedRecordId;

        List<ServiceResourceSkill> usersServResourceSkillTest = UserDetail.getUsersResourceSkills();

        Integer srsCount = 0;
        for (ServiceResourceSkill srs : usersServResourceSkill) {
            if (srs.ServiceResource.RelatedRecordId == UserDetail.userId)
                srsCount++;
        }

        System.assertEquals(
            srsCount,
            usersServResourceSkillTest.size(),
            'Counts should match'
        );
    }

    // Not currently needed as we are pulling in the Queue name to display under "Current Queue"
    // @isTest(SeeAllData=true)
    // static void testGetUserRegion() {
    //     Map<Id, User> users = new Map<Id, User>(
    //         [
    //             SELECT Id
    //             FROM User
    //             WHERE IsActive = TRUE AND Profile.Name = 'CICT Portal User'
    //             LIMIT 100
    //         ]
    //     );

    //     List<ServiceResourceSkill> userRegions = [
    //         SELECT Id, Skill.MasterLabel, ServiceResource.RelatedRecordId
    //         FROM ServiceResourceSkill
    //         WHERE
    //             ServiceResource.RelatedRecordId = :users.keySet()
    //             AND Skill.MasterLabel LIKE '%Region%'
    //     ];

    //     System.assert(
    //         userRegions.size() > 0,
    //         'Test is dependent on data existing in Org - Size: ' +
    //         userRegions.size()
    //     );

    //     User user = users.get(userRegions[0].ServiceResource.RelatedRecordId);

    //     List<ServiceResourceSkill> userSRSs = new List<ServiceResourceSkill>();
    //     for (ServiceResourceSkill sRS : userRegions) {
    //         if (sRS.ServiceResource.RelatedRecordId == user.Id) {
    //             userSRSs.add(sRS);
    //         }
    //     }

    //     List<ServiceResourceSkill> userRegionTest;
    //     System.runAs(user) {
    //         userRegionTest = UserDetail.getUserRegion();
    //     }
    //     System.assertEquals(
    //         userSRSs.size(),
    //         userRegionTest.size(),
    //         'Values should match'
    //     );
    // }

    @isTest(SeeAllData=false)
    static void testGetCallbackNumbers() {
        List<Call_Back_Number__mdt> callBackNbrs = UserDetail.getCallbackNumbers();
    }
}
