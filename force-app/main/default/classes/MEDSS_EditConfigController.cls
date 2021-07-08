public inherited sharing class MEDSS_EditConfigController {
    private static AccessConfig accessConfig = new AccessConfig();

    @AuraEnabled
    public static List<Do_Not_Call_County__c> getDoNotCallCounties() {
        return accessConfig.getDoNotCallCounties();
    }

    @AuraEnabled
    public static void deleteDoNotCallCounties(List<Id> countyIds) {
        accessConfig.deleteDoNotCallCounties(countyIds);
    }

    @AuraEnabled
    public static void addDoNotCallCounties(String county) {
        accessConfig.addDoNotCallCounties(county);
    }

    @AuraEnabled
    public static List<Counties_Without_CI__c> getCountiesWOutCI() {
        return accessConfig.getCountiesWOutCI();
    }

    @AuraEnabled
    public static void deleteCountiesWOutCI(List<Id> countyIds) {
        accessConfig.deleteCountiesWOutCI(countyIds);
    }

    @AuraEnabled
    public static void addCountiesWOutCI(String county) {
        accessConfig.addCountiesWOutCI(county);
    }

    @AuraEnabled
    public static List<Slack_Tag__c> getSlackTags() {
        return accessConfig.getSlackTags();
    }

    @AuraEnabled
    public static void deleteSlackTags(List<Id> slackIds) {
        accessConfig.deleteSlackTags(slackIds);
    }

    @AuraEnabled
    public static void addSlackTag(String name, String slackId) {
        accessConfig.addSlackTag(name, slackId);
    }

    @TestVisible
    private without sharing class AccessConfig {
        public List<Do_Not_Call_County__c> getDoNotCallCounties() {
            return [
                SELECT Id, Name, County_Name__c
                FROM Do_Not_Call_County__c
                ORDER BY County_Name__c
            ];
        }

        public void deleteDoNotCallCounties(List<Id> countyIds) {
            List<Do_Not_Call_County__c> listDoNotCallCounties  = [SELECT Id, County_Name__c FROM Do_Not_Call_County__c WHERE Id = :countyIds];
            
            Set<String> listCounties = new Set<String>();
            for(Do_Not_Call_County__c c : listDoNotCallCounties) listCounties.add(c.County_Name__c);
            
            if(!listDoNotCallCounties.isEmpty()) delete listDoNotCallCounties;
            
            requeueCases(listCounties);
        }

        public void addDoNotCallCounties(String county) {
            Do_Not_Call_County__c counties = new Do_Not_Call_County__c(
                Name = county,
                County_Name__c = county
            );
            insert new List<Do_Not_Call_County__c>{ counties };
                
            requeueCases(new Set<String> { county });
        }

        public List<Counties_Without_CI__c> getCountiesWOutCI() {
            return [
                SELECT Id, Name, County_Name__c
                FROM Counties_Without_CI__c
                ORDER BY County_Name__c
            ];
        }

        public void deleteCountiesWOutCI(List<Id> countyIds) {
            List<Counties_Without_CI__c> listCountiesWithoutCI = [
                SELECT Id, County_Name__c
                FROM Counties_Without_CI__c
                WHERE Id = :countyIds
            ];
            Set<String> listCounties = new Set<String>();
            for(Counties_Without_CI__c c : listCountiesWithoutCI) listCounties.add(c.County_Name__c);
            
            if(!listCountiesWithoutCI.isEmpty()) delete listCountiesWithoutCI;
            
            requeueCases(listCounties);
        }

        public void addCountiesWOutCI(String county) {
            Counties_Without_CI__c counties = new Counties_Without_CI__c(
                Name = county,
                County_Name__c = county
            );
            insert new List<Counties_Without_CI__c>{ counties };
                
            requeueCases(new Set<String> { county });
		}

        public List<Slack_Tag__c> getSlackTags() {
            return [
                SELECT Id, Name, SlackId__c
                FROM Slack_Tag__c
                ORDER BY Name
            ];
        }

        public void deleteSlackTags(List<Id> tagIds) {
            delete [SELECT Id FROM Slack_Tag__c WHERE Id = :tagIds];
        }

        public void addSlackTag(String name, String tagId) {
            Slack_Tag__c tag = new Slack_Tag__c(
                Name = name,
                SlackId__c = tagId
            );
            insert new List<Slack_Tag__c>{ tag };
        }
        
        public void requeueCases(Set<String> countySet) {
            List<Case> caseList = [SELECT Id FROM Case WHERE Subject = 'Outbound Call' AND (Status = 'New' OR Status = 'Re-queued') AND County__c IN: countySet];
            Set<Id> casesWithPSR = MEDSS_Batch_Helper.getSetOfCasesWithPSR(caseList);
            Map<Id, Case> caseMap = new Map<Id, Case>();
            for(Case c : caseList){
                if(casesWithPSR.contains(c.Id)){
                    c.Status = 'Closed';
                    c.AllowStatusUpdate__c = true;
                    c.Aged_To_Regional_Queue__c = false; //Will allow case to route to its new proper location. Will be automatically re-set to true by CaseTrigger if needed
                    caseMap.put(c.Id, c);
                }
            }
            update caseMap.values();
            CaseTriggerHandler.routeUsingSkill(caseMap);
        }
    }
}