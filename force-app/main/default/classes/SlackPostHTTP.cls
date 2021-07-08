public class SlackPostHTTP {
    public class FlowVariables {
        @InvocableVariable
        public String slackUrl;
        @InvocableVariable
        public String messageText;
        @InvocableVariable
        public String tokenId;
    }

    @InvocableMethod
    public static void postToSlack(List<FlowVariables> request) {
        // System.debug('*** request: ' + request);

        FlowVariables fVars = request[0];
        fVars.messageText = convertTags(fVars.messageText);

        Map<String, Object> msg = new Map<String, Object>();
        msg.put('text', fVars.messageText);
        msg.put('mrkdwn', 'true');
        msg.put('as_user', 'true');
        String body = JSON.serialize(msg);
        String url = fVars.slackUrl;

        System.enqueueJob(
            new QueueableSlackCall(url, 'POST', body, fVars.tokenId)
        );
    }

    @TestVisible
    private static String convertTags(String msg) {
        List<String> newMsg = new List<String>();

        // Do not continue if there are no tags in msg
        if (!msg.contains('@')) {
            return msg;
        }
        // Split on space
        for (String word0 : msg.split(' ')) {
            if (word0.contains('@')) {
                System.debug('Word: "' + word0 + '"');
                // Split on new line
                if (word0.contains('\n')) {
                    List<String> newMsg1 = new List<String>();
                    for (String word1 : word0.split('\n')) {
                        if (word1.contains('@')) {
                            word1 = convertTag(word1);
                        }
                        newMsg1.add(word1);
                    }
                    word0 = String.join(newMsg1, '\n');
                } else {
                    word0 = convertTag(word0);
                }
            }
            newMsg.add(word0);
        }
        System.debug('List: ' + newMsg);
        return String.join(newMsg, ' ');
    }

    @TestVisible
    private static String convertTag(String word) {
        // Format for tag expected in Slack
        String tagTemplate = '<!subteam^{0}|{1}>';

        // Remove punctuation
        String tagOrig = checkForPunctuation(word);
        // Convert to lower case for matching
        String tag = tagOrig.toLowerCase();

        if (slackTags.containsKey(tag)) {
            String fmtTag = String.format(
                tagTemplate,
                new List<String>{ slackTags.get(tag), tagOrig }
            );
            word = word.replace(tagOrig, fmtTag);
            // System.debug('Tag Found Id: ' + slackTags.get(tag));
            // System.debug('Tag Found fmtTag: ' + fmtTag);
            // System.debug('Tag Found Word: ' + word);
        }
        return word;
    }

    @TestVisible
    private static String checkForPunctuation(String tag) {
        // prettier-ignore
        Set<String> punctuation = new Set<String>{
            '.', '!', ',', '(', ')', '{', '}', '|', '/', '#', '?', '<', '>', '*'
        };
        for (String p : punctuation) {
            if (tag.contains(p)) {
                tag = tag.remove(p);
            }
        }
        return tag;
    }

    @TestVisible
    private static Map<String, String> slackTags {
        get {
            if (slackTags == null) {
                slackTags = new Map<String, String>();
                for (Slack_Tag__c tag : [
                    SELECT Name, SlackId__c
                    FROM Slack_Tag__c
                ]) {
                    slackTags.put(tag.Name, tag.SlackId__c);
                }
            }
            return slackTags;
        }
        private set;
    }

    public class QueueableSlackCall implements System.Queueable, Database.AllowsCallouts {
        private final String url;
        private final String method;
        private final String body;
        // private final String token; // Not used

        public QueueableSlackCall(
            String url,
            String method,
            String body,
            String token
        ) {
            this.url = url;
            this.method = method;
            this.body = body;
        }

        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod(method);
            req.setBody(body);
            Http http = new Http();
            HttpResponse res = http.send(req);

            // String respBody = res.getBody();
            // System.debug('*** response body: ' + respBody);
            // System.debug('*** esponse status: ' + res.getStatus());
            // System.debug('*** response status code: ' + res.getStatusCode());
            // System.debug('*** response headers: ' + res.getHeaderKeys());
        }
    }
}
