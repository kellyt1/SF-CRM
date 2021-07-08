@isTest(SeeAllData=false)
public with sharing class CaseTriggerHandlerTest {
    @isTest(SeeAllData=false)
    static void testOutboundRecordTypeId() {
        Id outboundRecordTypeId = CaseTriggerHandler.outboundRecordTypeId;

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName()
            .get('Outbound Call')
            .getRecordTypeId();

        System.assertEquals(recordTypeId, outboundRecordTypeId);
    }

    @isTest(SeeAllData=false)
    static void testGetSkills() {
        Map<String, String> skillTest = CaseTriggerHandler.getSkills();
        Map<Id, Skill> skills = new Map<Id, Skill>(
            [SELECT Id, DeveloperName FROM Skill]
        );

        System.assertEquals(
            skills.values().size(),
            skillTest.values().size(),
            'The size of both collections should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testGetSkillLanguage() {
        Map<String, String> languages = CaseTriggerHandler.getSkillLanguage();

        List<Language_Skill__mdt> languagesMdt = [
            SELECT MasterLabel, API_Name__c
            FROM Language_Skill__mdt
        ];

        System.assertEquals(
            languagesMdt.size(),
            languages.values().size(),
            'The size of both collections should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testCreatePendingServiceRoutingRecords() {
        List<Case> cases = createCases();

        List<PendingServiceRouting> pSR = CaseTriggerHandler.createPendingServiceRoutingRecords(
            cases
        );

        System.assertEquals(
            cases.size(),
            pSR.size(),
            'The size of both collections should match'
        );
    }

    @isTest(SeeAllData=false)
    static void testRouteUsingSkill() {
        List<Case> cases = createCases();

        Integer i = 0;
        for (Case c : cases) {
            c.Id = null;
            c.County__c = (i < 3) ? 'Mower' : c.County__c;
            c.Preferred_Language_Unrestricted__c = (i > 8)
                ? 'Spanish'
                : c.Preferred_Language_Unrestricted__c;
            i++;
        }
        insert cases;
        Map<Id, Case> tstCases = new Map<Id, Case>();
        tstCases.putAll(cases);

        List<PendingServiceRouting> pSRs = [
            SELECT
                CapacityWeight,
                IsReadyForRouting,
                RoutingModel,
                RoutingPriority,
                RoutingType,
                ServiceChannelId,
                WorkItemId
            FROM PendingServiceRouting
        ];

        for (PendingServiceRouting pSR : pSRs) {
            System.assert(
                pSR.IsReadyForRouting,
                'Is Ready for Routing should be true'
            );

            System.assert(
                tstCases.containsKey(pSR.WorkItemId),
                'The PendingServiceRouting should map to a Case'
            );
        }
    }

    @isTest(seeAllData=false)
    static void testRoutingLogic() {
        String interviewjurisdiction = 'GEN';
        String county = 'MN-87';
        String region = 'SR-NW';
        //MN-63
        List<Case> cases = new List<Case>();

        Case caseTemplate = new Case(
            MEDSS_Event_ID__c = 'SAMPLE ID',
            MEDSS_Case_Key__c = 'SAMPLE CASEID',
            Aged_Out__c = MEDSS_DateUtil.determineAgeThreshold(DateTime.now()),
            //Intake_Completion_Date__c = DateTime.now(),
            Intake_Completion_Date__c = DateTime.now().addHours(-30),
            SubregionBasedJurisdictionCode__c = region,
            InterviewJurisdictionCode__c = interviewjurisdiction,
            CountyCode__c = county,
            Preferred_Language_Unrestricted__c = 'English',
            MN_ID__c = 'MNID ' + 1,
            SubjectId__c = '1010101010',
            Subject = 'Outbound Call',
            Description = 'NOT A REAL CASE',
            Origin = 'Phone',
            RecordTypeId = MEDSS_Batch_Helper.outboundRecordTypeId
        );

        Case blankLanguage = caseTemplate.clone();
        blankLanguage.Preferred_Language_Unrestricted__c = '';
        cases.add(blankLanguage);

        Case clayDoNotCall = caseTemplate.clone();
        clayDoNotCall.CountyCode__c = 'MN-27';
        clayDoNotCall.SubregionBasedJurisdictionCode__c = 'SR-WC';
        cases.add(clayDoNotCall);

        Case bloomington = caseTemplate.clone();
        bloomington.CountyCode__c = '';
        bloomington.SubregionBasedJurisdictionCode__c = 'SR-METRO';
        cases.add(bloomington);

        Case mdh = caseTemplate.clone();
        mdh.InterviewJurisdictionCode__c = 'MDH';
        mdh.SubregionBasedJurisdictionCode__c = 'SR-NW';
        cases.add(mdh);

        Case washingtonNoCI = caseTemplate.clone();
        washingtonNoCI.CountyCode__c = 'MN-163';
        washingtonNoCI.SubregionBasedJurisdictionCode__c = 'SR-METRO';
        cases.add(washingtonNoCI);

        Case noRegion = caseTemplate.clone();
        noRegion.SubregionBasedJurisdictionCode__c = 'SR-NOREGION';
        cases.add(noRegion);

        Case agedOut = caseTemplate.clone();
        agedOut.CountyCode__c = 'MN-61';
        agedOut.SubregionBasedJurisdictionCode__c = 'SR-NE';
        agedOut.Aged_Out__c = DateTime.now().addDays(-1);
        cases.add(agedOut);

        insert cases;
    }

    @isTest(SeeAllData=false)
    static void testGetDoNotCallCounty() {
        List<Do_Not_Call_County__c> countiesCustSet = new List<Do_Not_Call_County__c>();
        Set<String> testCounties = new Set<String>();

        for (Integer i = 0; i < 5; i++) {
            Do_Not_Call_County__c c = new Do_Not_Call_County__c(
                Name = 'County - ' + i,
                County_Name__c = 'County - ' + i
            );
            testCounties.add(c.County_Name__c);
            countiesCustSet.add(c);
        }
        insert countiesCustSet;

        Set<String> counties = CaseTriggerHandler.getDoNotCallCounty();

        for (String county : counties) {
            System.assert(testCounties.contains(county));
        }
    }

    @isTest(SeeAllData=false)
    static void testGetCountyWithoutCI() {
        List<Counties_Without_CI__c> countiesCustSet = new List<Counties_Without_CI__c>();
        Set<String> testCounties = new Set<String>();

        for (Integer i = 0; i < 5; i++) {
            Counties_Without_CI__c c = new Counties_Without_CI__c(
                Name = 'County - ' + i,
                County_Name__c = 'County - ' + i
            );
            testCounties.add(c.County_Name__c);
            countiesCustSet.add(c);
        }
        insert countiesCustSet;

        Set<String> counties = CaseTriggerHandler.getCountyWithoutCI();

        for (String county : counties) {
            System.assert(testCounties.contains(county));
        }
    }

    @isTest(seeAllData=false)
    static void testDebugLanguage() {
        Id debugLanguage = CaseTriggerHandler.debugLanguage;
        Skill queriedLanguage = [
            SELECT Id
            FROM Skill
            WHERE DeveloperName = 'Language_Korean'
        ];
        Id queriedId = queriedLanguage.id;

        System.assertEquals(queriedId, debugLanguage);
    }

    // Create cases for testing
    static List<Case> createCases() {
        Id caseRecTypeId = CaseTriggerHandler.outboundRecordTypeId;
        List<Case> cases = new List<Case>();

        for (Integer i = 0; i < 10; i++) {
            Case c = new Case(
                Id = '500r0000000000' + i,
                RecordTypeId = caseRecTypeId,
                County__c = 'Cass',
                Preferred_Language_Unrestricted__c = 'English',
                Aged_Out__c = MEDSS_DateUtil.determineAgeThreshold(
                    DateTime.now()
                ),
                Status = 'New',
                Origin = 'Phone'
            );
            cases.add(c);
        }
        return cases;
    }
}
