@isTest(SeeAllData=false)
public with sharing class AccountTriggerHandler_Test {
    @isTest(SeeAllData=false)
    static void testPopulateAccountPhone() {
        Test.startTest();
        RecordType personAccountRecordType = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'Person Account' AND SObjectType = 'Account'
        ];

        List<Account> listAccountsToInsert = new List<Account>();

        listAccountsToInsert.add(
            new Account(
                LastName = 'Test1',
                PersonOtherPhone = '1234567890',
                RecordType = personAccountRecordType
            )
        );
        listAccountsToInsert.add(
            new Account(
                LastName = 'Test2',
                PersonHomePhone = '1234567890',
                PersonOtherPhone = '0101010101',
                RecordType = personAccountRecordType
            )
        );
        listAccountsToInsert.add(
            new Account(
                LastName = 'Test3',
                PersonMobilePhone = '1234567890',
                PersonHomePhone = '1010101010',
                PersonOtherPhone = '0101010101',
                RecordType = personAccountRecordType
            )
        );
        insert listAccountsToInsert;
        Test.stopTest();

        List<Account> listAccountsToTest = [
            SELECT Id, LastName, Phone
            FROM Account
        ];
        Map<String, Account> mapAccountsToTest = new Map<String, Account>();
        for (Account acc : listAccountsToTest) {
            mapAccountsToTest.put(acc.LastName, acc);
        }

        System.assertEquals('1234567890', mapAccountsToTest.get('Test1').Phone);
        System.assertEquals('1234567890', mapAccountsToTest.get('Test2').Phone);
        System.assertEquals('1234567890', mapAccountsToTest.get('Test3').Phone);
    }
}
