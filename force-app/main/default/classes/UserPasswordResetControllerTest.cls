@isTest(SeeAllData=false)
public inherited sharing class UserPasswordResetControllerTest {
    @isTest(SeeAllData=false)
    static void testFindUsers() {
        User tUser = createUserForTesting();

        List<User> users = (List<User>) UserPasswordResetController.findUsers(
            '|Test User'
        );
        System.assertEquals('|Test User', users[0].Name);
    }

    @isTest(SeeAllData=false)
    static void testResetPassword() {
        User tUser = createUserForTesting();

        Boolean success = UserPasswordResetController.resetPassword(tUser.Id);
        System.assert(success);
    }

    private static User createUserForTesting() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];

        User user = new User(
            FirstName = '|Test',
            LastName = 'User',
            Email = 'test.user@test.tst',
            Username = 'test.user@test.tst',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert user;
        return user;
    }
}
