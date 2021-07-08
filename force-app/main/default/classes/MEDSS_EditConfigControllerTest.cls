@isTest(SeeAllData=false)
public inherited sharing class MEDSS_EditConfigControllerTest {
    private static void createDNCCounties() {
        List<Do_Not_Call_County__c> counties = new List<Do_Not_Call_County__c>();

        for (Integer i = 0; i < 3; i++) {
            Do_Not_Call_County__c county = new Do_Not_Call_County__c(
                Name = 'County: ' + i,
                County_Name__c = 'County: ' + i
            );
            counties.add(county);
        }
        insert counties;
    }

    private static void createCountiesWOutCI() {
        List<Counties_Without_CI__c> counties = new List<Counties_Without_CI__c>();

        for (Integer i = 0; i < 3; i++) {
            Counties_Without_CI__c county = new Counties_Without_CI__c(
                Name = 'County: ' + i,
                County_Name__c = 'County: ' + i
            );
            counties.add(county);
        }
        insert counties;
    }

    @isTest(SeeAllData=false)
    static void testGetDoNotCallCounties() {
        createDNCCounties();
        List<Do_Not_Call_County__c> doNotCallCounties = MEDSS_EditConfigController.getDoNotCallCounties();
        System.assertEquals(3, doNotCallCounties.size());
        System.assertEquals('County: 0', doNotCallCounties[0].County_Name__c);
    }

    @isTest(SeeAllData=false)
    static void testDeleteDoNotCallCounties() {
        createDNCCounties();
        List<Do_Not_Call_County__c> doNotCallCounties0 = MEDSS_EditConfigController.getDoNotCallCounties();
        System.assertEquals(3, doNotCallCounties0.size());

        List<Id> countyIds = new List<Id>{ doNotCallCounties0[0].Id };
        MEDSS_EditConfigController.deleteDoNotCallCounties(countyIds);
        List<Do_Not_Call_County__c> doNotCallCounties1 = MEDSS_EditConfigController.getDoNotCallCounties();
        System.assertEquals(2, doNotCallCounties1.size());
    }

    @isTest(SeeAllData=false)
    static void testAddDoNotCallCounties() {
        List<Do_Not_Call_County__c> doNotCallCounties0 = MEDSS_EditConfigController.getDoNotCallCounties();
        System.assertEquals(0, doNotCallCounties0.size());
        String county = 'County: A';
        MEDSS_EditConfigController.addDoNotCallCounties(county);

        List<Do_Not_Call_County__c> doNotCallCounties1 = MEDSS_EditConfigController.getDoNotCallCounties();
        System.assertEquals(1, doNotCallCounties1.size());
        System.assertEquals('County: A', doNotCallCounties1[0].County_Name__c);
    }

    @isTest(SeeAllData=false)
    static void testGetCountiesWOutCI() {
        createCountiesWOutCI();
        List<Counties_Without_CI__c> countiesWOutCI = MEDSS_EditConfigController.getCountiesWOutCI();
        System.assertEquals(3, countiesWOutCI.size());
        System.assertEquals('County: 0', countiesWOutCI[0].County_Name__c);
    }

    @isTest(SeeAllData=false)
    static void testDeleteCountiesWOutCI() {
        createCountiesWOutCI();
        List<Counties_Without_CI__c> countiesWOutCI0 = MEDSS_EditConfigController.getCountiesWOutCI();
        System.assertEquals(3, countiesWOutCI0.size());

        List<Id> countyIds = new List<Id>{ countiesWOutCI0[0].Id };
        MEDSS_EditConfigController.deleteCountiesWOutCI(countyIds);
        List<Counties_Without_CI__c> countiesWOutCI1 = MEDSS_EditConfigController.getCountiesWOutCI();
        System.assertEquals(2, countiesWOutCI1.size());
    }

    @isTest(SeeAllData=false)
    static void testAddCountiesWOutCI() {
        List<Counties_Without_CI__c> countiesWOutCI0 = MEDSS_EditConfigController.getCountiesWOutCI();
        System.assertEquals(0, countiesWOutCI0.size());
        String county = 'County: A';
        MEDSS_EditConfigController.addCountiesWOutCI(county);

        List<Counties_Without_CI__c> countiesWOutCI1 = MEDSS_EditConfigController.getCountiesWOutCI();
        System.assertEquals(1, countiesWOutCI1.size());
        System.assertEquals('County: A', countiesWOutCI1[0].County_Name__c);
    }

    @isTest(SeeAllData=false)
    static void testGetSlackTags() {
        List<Slack_Tag__c> testTags = new List<Slack_Tag__c>();
        for (Integer i = 0; i < 3; i++) {
            Slack_Tag__c tag = new Slack_Tag__c(
                Name = '@tagTestName' + i,
                SlackId__c = 'tagTestId' + i
            );
            testTags.add(tag);
        }
        insert testTags;

        List<Slack_Tag__c> tags = MEDSS_EditConfigController.getSlackTags();

        List<Slack_Tag__c> slackTags = [
            SELECT Id, Name, SlackId__c
            FROM Slack_Tag__c
        ];
        System.assertEquals(tags.size(), slackTags.size());
    }

    @isTest(SeeAllData=false)
    static void testDeleteSlackTags() {
        Slack_Tag__c tag = new Slack_Tag__c(
            Name = '@tagTestName',
            SlackId__c = 'tagTestId'
        );
        insert new List<Slack_Tag__c>{ tag };

        MEDSS_EditConfigController.deleteSlackTags(new List<Id>{ tag.Id });

        List<Slack_Tag__c> slackTags = [
            SELECT Id, Name, SlackId__c
            FROM Slack_Tag__c
        ];
        System.assertEquals(0, slackTags.size());
    }

    @isTest(SeeAllData=false)
    static void testAddSlackTag() {
        MEDSS_EditConfigController.addSlackTag('@tagTestName', 'tagTestId');

        List<Slack_Tag__c> slackTags = [
            SELECT Id, Name, SlackId__c
            FROM Slack_Tag__c
        ];
        System.assertEquals(1, slackTags.size());
    }
}
