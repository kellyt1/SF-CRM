@isTest(SeeAllData=false)
public class SelectedUserDetailsTest {
    
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
		Id userId = UserInfo.getUserId();
        List<ServiceResourceSkill> usersServResourceSkillTest = SelectedUserDetails.getUsersResourceSkills(userId);
    }
    
    @isTest(SeeAllData=true)
    static void testGetUsersGroups() {

		Id userId = UserInfo.getUserId();
        List<GroupMember> usersGroupsTest = SelectedUserDetails.getUsersGroups(userId);
    }

}