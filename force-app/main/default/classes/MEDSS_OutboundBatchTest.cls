@isTest(SeeAllData=false)
public with sharing class MEDSS_OutboundBatchTest {
    @isTest(SeeAllData=false)
    static void testGetMapCaseQueues() {
        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();
        Map<String, QueueSObject> mapQueues = medssOut.getMapCaseQueues();
        System.assert(mapQueues.keySet().size() > 0);
        System.assert(mapQueues.values().size() > 0);
    }

    @isTest(SeeAllData=false)
    static void testCreateCase() {
        CovidCases__x covidCase = new CovidCases__x(
            CaseId__c = '67890123',
            CaseKey__c = 12345612,
            SubjectId__c = '67890123',
            IntakeCompleteDateTime__c = '12/30/2020 10:00 PM',
            SpecimenDate__c = '12/23/2020',
            SubregionBasedJurisdiction__c = '',
            InterviewJurisdiction__c = '',
            ReservationName__c = '',
            TribeName__c = '',
            LanguageInterview__c = '',
            PreferredLanguage__c = '',
            MnId__c = ''
        );

        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();
        Case tstCase = medssOut.createCase(covidCase);
        System.assertEquals('Outbound Call', tstCase.Subject);
    }

    @isTest(SeeAllData=false)
    static void testGetMapOfExistingAccounts() {
        List<Account> accounts = new List<Account>();
        Set<String> setSubIds = new Set<String>();

        for (Integer i = 0; i < 3; i++) {
            Account a = new Account(
                FirstName = 'pAcct' + i,
                LastName = 'pAcct' + i,
                MnId__c = '9988' + i,
                SubjectId__c = '9988' + i,
                RecordTypeId = MEDSS_Batch_Helper.personAccountRecordTypeId
            );
            setSubIds.add(a.SubjectId__c);
            accounts.add(a);
        }
        insert accounts;

        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();
        Map<String, Account> pAccounts0 = medssOut.getMapOfExistingAccounts(
            setSubIds
        );
        Map<String, Account> pAccounts1 = medssOut.getMapOfExistingAccounts(
            new Set<String>{ '99880' }
        );
        System.assert(pAccounts0.keySet().size() == 3, pAccounts0.keySet());
        System.assert(pAccounts1.keySet().size() == 1, pAccounts1.keySet());
    }

    @isTest(SeeAllData=false)
    static void testCreateAccount() {
        String strDate = '12/23/2001 00:00 AM';
        DateTime nwDate = MEDSS_Batch_Helper.convertDateTime(strDate);

        List<CovidCases__x> covidCases = createCases();

        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();
        Account pAccount = medssOut.createAccount(covidCases[0]);

        System.assertEquals(covidCases[0].MnId__c, pAccount.MnId__c);
        System.assertEquals(
            covidCases[0].Zip__c,
            pAccount.PersonMailingPostalCode
        );
        // System.assertEquals(covidCase.BirthDate__c, pAccount.BirthDate);
        System.assertEquals('English', pAccount.Language__pc);
        System.assertEquals(covidCases[0].Email__c, pAccount.PersonEmail);
        // System.assertEquals(covidCase. ,pAccount.MEDSS_Case_Number__pc);
        // System.assertEquals(covidCase.TelephoneCell__c, pAccount.PersonHomePhone);
        // System.assertEquals(covidCase.TelephoneHome__c, pAccount.PersonOtherPhone);
        System.assertEquals(
            MEDSS_Batch_Helper.personAccountRecordTypeId,
            pAccount.RecordTypeId
        );
    }

    @isTest(SeeAllData=false)
    static void testHandleOutboundCases() {
        List<CovidCases__x> covidCases = createCases();

        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();
        medssOut.handleOutboundCases(covidCases);

        List<Case> nwCases = [SELECT Id, Subject FROM Case];
        List<Account> nwAccounts = [
            SELECT Id, FirstName, LastName
            FROM Account
        ];

        System.assertEquals(3, nwCases.size(), nwCases);
        System.assertEquals(3, nwAccounts.size(), nwAccounts);
    }

    @isTest(SeeAllData=false)
    static void testSetMaxIntakeDate() {
        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();

        String dt0 = String.valueOf(DateTime.now().addHours(-1));
        String dt1 = String.valueOf(DateTime.now());

        medssOut.setMaxIntakeDate(dt0);
        medssOut.setMaxIntakeDate(dt1);
        System.assertEquals(dt1, medssOut.maxIntakeDate);

        medssOut.setMaxIntakeDate(dt1);
        medssOut.setMaxIntakeDate(dt0);
        System.assertEquals(dt1, medssOut.maxIntakeDate);
    }

    @isTest(SeeAllData=false)
    static void testGetMaxIntakeFromBatchHistory() {
        MEDSS_OutboundBatch medssOut = new MEDSS_OutboundBatch();

        Batch_History__c bHistory = MEDSS_Batch_Helper.getLatestBatchHistory();

        String startDt = medssOut.getMaxIntakeFromBatchHistory();

        // Default value if no records found
        System.assertEquals('01/01/2010 00:00 AM', startDt);
    }

    static List<CovidCases__x> createCases() {
        List<CovidCases__x> xCases = new List<CovidCases__x>();

        String strDate = '12/23/2001 00:00 AM';
        DateTime nwDate = MEDSS_Batch_Helper.convertDateTime(strDate);

        for (Integer i = 0; i < 3; i++) {
            CovidCases__x covidCase = new CovidCases__x(
                MnId__c = '9998877' + i,
                SubjectId__c = '9998877' + i,
                CaseKey__c = Integer.valueOf('9998877' + i),
                CaseId__c = '9998877' + i,
                FirstName__c = 'John',
                MiddleName__c = 'D',
                LastName__c = 'Doe' + i,
                StreetAddress__c = '',
                City__c = '',
                State__c = '',
                Zip__c = '',
                BirthDate__c = nwDate,
                PreferredLanguage__c = (i == 2) ? 'Spanish' : 'English',
                Email__c = i + 'jd@test.com',
                TelephoneCell__c = '888.888.888' + i,
                TelephoneHome__c = '777.777.777' + i,
                TelephoneWork__c = '',
                SubregionBasedJurisdiction__c = 'NOTSR-NOREGION',
                InterviewJurisdiction__c = 'NOTLPH'
            );
            xCases.add(covidCase);
        }
        return xCases;
    }
}
