@isTest
global class SlackPostHTTPMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // Fake response for test callout
        HTTPResponse response = new HTTPResponse();
        response.setBody('ok');

        if (req.getEndpoint() == 'http://TestFail') {
            response.setStatusCode(401);
        } else {
            response.setBody('ok');
            response.setStatus('OK');
            response.setStatusCode(201);
        }
        return response;
    }

    // Example Slack
    // response body: ok
    // response status: OK
    // response status code: 200
    // Request: (FlowVariables:[messageText=Posted by: TEST SLACK MESSAGE FROM SALESFORCE - IGNORE - LK from UAT, please ignore., slackUrl=https://hooks.slack.com/services/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, tokenId=Gsx2MTeB5FJFWgIMaO5L+09yMIQ72ntW0FtzSaZ/somCWAyhI2FkwnKxZNtbZAt06M6EO3+jQMuzni1QKnRnvPDthkEMBhiPXTr0ioJsXLKgLqlj7KRiwQ8BucovgnFB])
}
