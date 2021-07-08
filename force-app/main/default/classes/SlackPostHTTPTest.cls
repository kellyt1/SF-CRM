@isTest
private class SlackPostHTTPTest {
    @isTest(SeeAllData=false)
    static void testSlackPost() {
        Test.setMock(HttpCalloutMock.class, new SlackPostHTTPMock());

        Test.startTest();
        SlackPostHTTP.FlowVariables fVars = new SlackPostHTTP.FlowVariables();
        fVars.slackUrl = 'https://hooks.slack.tst/services/xxxxxxxxxxxxxxx';
        fVars.messageText = 'Test Message for Slack';
        fVars.tokenId = 'xxxxxxxxxxxx/00112233445566778899';

        SlackPostHTTP.postToSlack(
            new List<SlackPostHTTP.FlowVariables>{ fVars }
        );
        Test.stopTest();
    }

    @isTest(SeeAllData=false)
    static void testCheckForPunctuation() {
        String a0 = '@testtag';
        String b0 = '@testtag,';
        String c0 = '<@testtag>';

        String a1 = SlackPostHTTP.checkForPunctuation(a0);
        System.assertEquals(a0, a1);

        String b1 = SlackPostHTTP.checkForPunctuation(b0);
        System.assertEquals(a0, b1);

        String c1 = SlackPostHTTP.checkForPunctuation(c0);
        System.assertEquals(a0, c1);
    }

    @isTest(SeeAllData=false)
    static void testSlackTags() {
        createSlackTags(3);

        Map<String, String> tags = SlackPostHTTP.slackTags;
        System.assertEquals(3, tags.keySet().size());
    }

    @isTest(SeeAllData=false)
    static void testConvertTags() {
        createSlackTags(3);

        String a0 = 'this is a @tag-test-name';
        String b0 = 'this is a @tag-test-name1,';
        String c0 = 'this is a @tag-test-name2<>';
        String d0 = 'this is a tag-test-name2';
        String e0 = 'this is a\n@tag-Test-Name1';

        String a1 = SlackPostHTTP.convertTags(a0);
        System.debug('a1: ' + a1);
        // Should not have a proper tag
        System.assertEquals('this is a @tag-test-name', a1);

        String b1 = SlackPostHTTP.convertTags(b0);
        System.assertEquals(
            'this is a <!subteam^tagtestid1|@tag-test-name1>,',
            b1
        );

        String c1 = SlackPostHTTP.convertTags(c0);
        System.assertEquals(
            'this is a <!subteam^tagtestid2|@tag-test-name2><>',
            c1
        );

        String d1 = SlackPostHTTP.convertTags(d0);
        System.assertEquals(d0, d1);

        String e1 = SlackPostHTTP.convertTags(e0);
        System.assertEquals(
            'this is a\n<!subteam^tagtestid1|@tag-Test-Name1>',
            e1
        );
    }

    static void createSlackTags(Integer cnt) {
        List<Slack_Tag__c> testTags = new List<Slack_Tag__c>();

        for (Integer i = 0; i < cnt; i++) {
            Slack_Tag__c tag = new Slack_Tag__c(
                Name = '@tag-test-name' + i,
                SlackId__c = 'tagtestid' + i
            );
            testTags.add(tag);
        }
        insert testTags;
    }
}
