public inherited sharing class UserPasswordResetController {
    private static PasswordDml pwDml = new PasswordDml();

    // Used to find the User in order to reset password
    @AuraEnabled(cacheable=true)
    public static List<SObject> findUsers(String searchKey) {
        String key = '%' + searchKey + '%';

        List<SObject> sObjectList = [
            SELECT Id, Name, Email, LastLoginDate
            FROM User
            WHERE Name LIKE :key
        ];
        return sObjectList;
    }

    // Calls System class to send password reset to user
    @AuraEnabled
    public static Boolean resetPassword(Id selectedUser) {
        return pwDml.resetPassword(selectedUser);
    }

    @TestVisible
    private without sharing class PasswordDml {
        public Boolean resetPassword(Id selectedUser) {
            Boolean resetSuccess = true;
            try {
                System.resetPassword(selectedUser, true);
            } catch (exception e) {
                resetSuccess = false;
            }
            return resetSuccess;
        }
    }
}
