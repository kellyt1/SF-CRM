@isTest(SeeAllData=false)
public class MEDSS_IntakeBatchTest {
    static testMethod void testIntakeBatch() {
        Test.startTest();
        List<SObject> objLs = makeData();
        createCase();
        MEDSS_IntakeBatch obj = new MEDSS_IntakeBatch();
        obj.testDataset = objLs;
        DataBase.executeBatch(obj);
        Test.stopTest();
    }

    @isTest(SeeAllData=false)
    static void testIntakeRecordTypeId() {
        MEDSS_IntakeBatch intakeBatch = new MEDSS_IntakeBatch();
        Id intakeRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Intake')
            .getRecordTypeId();
        Id intakeRecordTypeIdTest = intakeBatch.intakeRecordTypeId;

        System.assertEquals(
            intakeRecordTypeId,
            intakeRecordTypeIdTest,
            'Ids should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testQueueSObject() {
        MEDSS_IntakeBatch intakeBatch = new MEDSS_IntakeBatch();
        Id covidIntakePositiveQueueId = intakeBatch.getQueueSObject(
            'CovidIntakePositive'
        );
        Id covidIntakePositiveQueueIdTest = intakeBatch.covidIntakePositiveQueueId;
        System.assertEquals(
            covidIntakePositiveQueueId,
            covidIntakePositiveQueueIdTest,
            'Ids should match'
        );

        Id covidIntakeDedupQueueId = intakeBatch.getQueueSObject(
            'CovidIntakeDedup'
        );
        Id covidIntakeDedupQueueIdTest = intakeBatch.covidIntakeDedupQueueId;
        System.assertEquals(
            covidIntakeDedupQueueId,
            covidIntakeDedupQueueIdTest,
            'Ids should match'
        );
    }
    @isTest(SeeAllData=false)
    static void testReQueueLogic() {
        createCase();

        List<Case> cases = [
            SELECT
                Id,
                Standard_QueueId__c,
                County__c,
                Region__c,
                MEDSS_Event_Id__c,
                SubjectId__c,
                RecordTypeId,
                OwnerId,
                Owner.Name,
                Subject,
                Status
            FROM Case
        ];

        Map<String, Case> mapCases = new Map<String, Case>();

        for (Case cs : cases) {
            mapCases.put(cs.MEDSS_Event_Id__c, cs);
            cs.Status = (cs.MEDSS_Event_Id__c != '23945')
                ? 'Closed'
                : cs.Status;
        }
        update cases;

        MEDSS_IntakeBatch cs = new MEDSS_IntakeBatch();
        Map<String, Case> mapCasesAfter = cs.reQueueIfClosed(mapCases);

        Group intakePosQueue = [
            SELECT Id, Type
            FROM Group
            WHERE Type = 'Queue' AND DeveloperNAME = 'CovidIntakePositive'
        ];
        Group intakeDedupQueue = [
            SELECT Id, Type
            FROM Group
            WHERE Type = 'Queue' AND DeveloperNAME = 'CovidIntakeDedup'
        ];
        system.assertEquals(
            intakePosQueue.Id,
            mapCases.get('2345').OwnerId,
            'assert'
        );
        system.assertEquals(
            intakeDedupQueue.Id,
            mapCases.get('12345').OwnerId,
            'assert'
        );
    }

    private static void createCase() {
        User user = createPortalUser();

        List<Case> cases = new List<Case>();
        Case caseInSalesForce0 = new Case(
            MEDSS_Event_ID__c = '2345',
            MEDSS_Case_Key__c = '1009894',
            Subject = 'Positive Intake',
            Standard_QueueId__c = user.Id,
            Status = 'Closed',
            Origin = 'Phone',
            OwnerId = user.Id
        );
        Case caseInSalesForce1 = new Case(
            MEDSS_Event_ID__c = '23945',
            Subject = 'Positive Intake',
            Standard_QueueId__c = user.Id,
            MEDSS_Case_Key__c = '1009893',
            Origin = 'Phone',
            OwnerId = user.Id
        );
        Case caseInSalesForce2 = new Case(
            MEDSS_Event_ID__c = '12345',
            Status = 'Closed',
            Subject = 'Positive Dedup',
            MEDSS_Case_Key__c = '1009893',
            Origin = 'Phone',
            OwnerId = user.Id
        );
        cases.add(caseInSalesForce0);
        cases.add(caseInSalesForce1);
        cases.add(caseInSalesForce2);
        insert cases;
    }

    private static List<SObject> makeData() {
        CovidIntakePositiveUncodeds__x cCase1 = new CovidIntakePositiveUncodeds__x(
            MnId__c = '1000098',
            FirstName__c = 'Donald',
            MiddleName__c = 'Scooby',
            LastName__c = 'Duck',
            StreetAddress__c = 'Test',
            City__c = 'Mountain View',
            State__c = 'CA',
            Zip__c = '94055',
            PreferredLanguage__c = 'English',
            Email__c = 'amr@test.com',
            TelephoneHome__c = '1234567890',
            CaseId__c = '12345',
            CaseKey__c = 12345
            // BirthDate__c = datetime.newInstance(2014, 9, 15, 13, 30, 0)
        );
        CovidIntakePositives__x cCase2 = new CovidIntakePositives__x(
            MnId__c = '1000099',
            FirstName__c = 'Donald',
            MiddleName__c = 'Mickey',
            LastName__c = 'Duck',
            StreetAddress__c = 'Test',
            City__c = 'Milpitas',
            State__c = 'CA',
            Zip__c = '94033',
            PreferredLanguage__c = 'English',
            Email__c = 'amr@test.com',
            TelephoneHome__c = '1234567890',
            CaseId__c = '23945',
            CaseKey__c = 1009894
            //BirthDate__c = datetime.newInstance(2014, 9, 15, 13, 30, 0)
        );
        CovidIntakeDedupUncodeds__x cCase3 = new CovidIntakeDedupUncodeds__x(
            MnId__c = '1000092',
            FirstName__c = 'Donald',
            MiddleName__c = 'dedup',
            LastName__c = 'uncoded',
            StreetAddress__c = 'Test',
            City__c = 'St Helena',
            State__c = 'CA',
            Zip__c = '94024',
            PreferredLanguage__c = 'English',
            Email__c = 'amr@test.com',
            TelephoneHome__c = '1234567890',
            CaseId__c = '24345',
            CaseKey__c = 23945
            //BirthDate__c = datetime.newInstance(2014, 9, 15, 13, 30, 0)
        );
        CovidIntakeDedups__x cCase4 = new CovidIntakeDedups__x(
            MnId__c = '1000091',
            FirstName__c = 'Donald',
            MiddleName__c = 'Minnie',
            LastName__c = 'Uncoded',
            StreetAddress__c = 'Test',
            City__c = 'San Jose',
            State__c = 'CA',
            Zip__c = '94034',
            PreferredLanguage__c = 'English',
            Email__c = 'amr@test.com',
            TelephoneHome__c = '1234567890',
            CaseId__c = '23945',
            CaseKey__c = 1009893
        );
        List<SObject> listSobjs = new List<SObject>();
        listSobjs.add(cCase1);
        listSobjs.add(cCase2);
        listSobjs.add(cCase3);
        listSobjs.add(cCase4);
        return listSobjs;
    }

    private static User createPortalUser() {
        Profile profile = [
            SELECT id
            FROM profile
            WHERE Name = 'CICT Portal User'
        ];
        User user = new User(
            Alias = 'standt',
            Email = 'standarduser@testorg.com',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testfind@mnitintake.com'
        );
        insert user;
        return user;
    }
}
