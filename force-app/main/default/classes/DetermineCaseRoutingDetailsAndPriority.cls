// This class is intentionally not bulkified - users are entering one case at a time to search by
public with sharing class DetermineCaseRoutingDetailsAndPriority {
    @AuraEnabled(cacheable=true)
    //searchCaseRoutingDetails LWC invokes this Apex method
    public static String getCaseDetails(String searchTerm) {
        System.debug('**In Apex method to query case details***');
        System.debug('**Search Term: ' + searchTerm);
        List<Case> caseList = [
            SELECT
                Id,
                CaseNumber,
                MN_ID__c,
                Call_Attempted__c,
                Exceeds_Aged_Out__c,
                MEDSS_Event_ID__c,
                Owner.Name,
                OwnerId,
                Status,
                County_Name__c,
                SubregionBasedJurisdictionCode__c,
                InterviewJurisdictionCode__c,
                Call_Attempt_Date__c
            FROM Case
            WHERE
                MN_ID__c = :searchTerm
                OR CaseNumber = :searchTerm
                OR MEDSS_Event_Id__c = :searchTerm
        ];
        //Set a variable for the County that the case is from
        String county = caseList[0].County_Name__c;
        System.debug('***Count: ' + county);
        System.debug('***Case List: ' + caseList);
        Boolean caseOnDNCList = false;
        Boolean caseOnCountyWoCIList = false;
        //Query for the list of counties which are on the Do Not Call List
        List<Do_Not_Call_County__c> dncList = [SELECT Id, County_Name__c FROM Do_Not_Call_County__c
                                                WHERE County_Name__c = :county];
        System.debug('***Do Not Call List Match to county: ' + dncList);
        //Check if this case is on the Do Not Call List or not, set a boolean attribute
        if(dncList.size() > 0){
            caseOnDNCList = true;
        }

        //Query for the list of counties which are on the Counties without CI List
        List<Counties_Without_CI__c> cntyNoCIList = [SELECT Id, County_Name__c FROM Counties_Without_CI__c
                                                    WHERE County_Name__c = :county];
        System.debug('***Counties without CI List match: ' + cntyNoCIList);
        //Check if this case is on the Counties without CI List or not, set a boolean attribute
        if(cntyNoCIList.size() > 0){
            caseOnCountyWoCIList = true;
        }
        System.debug('**Is Case on Do Not Call List? ' + caseOnDNCList);
        System.debug('**Is Case on Counties Without CI List? ' + caseOnCountyWoCIList);
        //Return all PendingServiceRouting records related to the case that the user searched by
        List<PendingServiceRouting> psrList = [
            SELECT Id, GroupId, IsPushed, RoutingType, WorkItemId, IsReadyForRouting
            FROM PendingServiceRouting
            WHERE WorkItemId IN :caseList
        ];
        System.debug('***PSR List: ' + psrList);
        List<CaseRouting> caseRoutingDetailList = new List<CaseRouting>();
        for (Case caseRecord : caseList) {
            CaseRouting newCaseResult = new CaseRouting();
                    newCaseResult.salesforceCaseNumber = caseRecord.CaseNumber;
                    newCaseResult.MNId = caseRecord.MN_ID__c;
                    newCaseResult.MEDSSEventId = caseRecord.MEDSS_Event_ID__c;
                    newCaseResult.CountyName = caseRecord.County_Name__c;
                    newCaseResult.DoNotCallList = caseOnDNCList;
                    newCaseResult.CountyWithoutCIList = caseOnCountyWoCIList;
                    if(caseRecord.Call_Attempt_Date__c != null){
                        newCaseResult.CallAttDate = caseRecord.Call_Attempt_Date__c.format();
                    }
                    newCaseResult.InterviewJurisdictionCode = caseRecord.InterviewJurisdictionCode__c;
                    newCaseResult.SubRegionJurisdictionCode = caseRecord.SubregionBasedJurisdictionCode__c;
                    newCaseResult.Owner = caseRecord.Owner.Name;
                    newCaseResult.CaseStatus = caseRecord.Status;
                    newCaseResult.CallAttempted = caseRecord.Call_Attempted__c;
                    if(caseRecord.Exceeds_Aged_Out__c == true){
                        newCaseResult.AgedToRegionalQueue = 'Case Aged Out';
                    }else if(caseRecord.Exceeds_Aged_Out__c == false){
                        newCaseResult.AgedToRegionalQueue = ' Case NOT Aged Out';
                    }
            for(PendingServiceRouting psrRec : psrList)
            {
                System.debug('***PSR record linked to the Case: ' + psrRec);
                if(psrRec.WorkItemId == caseRecord.Id)
                {
                    
                    if(psrRec.IsPushed == true){
                        newCaseResult.RoutingStatus = 'Case Pushed to CI';
                    }else if(psrRec.IsPushed == false){
                        if(psrRec.IsReadyForRouting == true){
                            newCaseResult.RoutingStatus = 'Case NOT Pushed to CI - Ready for Routing';
                        }else if(psrRec.IsReadyForRouting == false){
                            newCaseResult.RoutingStatus = 'Case NOT Pushed to CI - NOT Ready for Routing';
                        }
                    }
                    newCaseResult.RoutingType = psrRec.RoutingType;
                    // If the case has 'SkillsBased' routing on it, then also query for all related SkillRequirement records linked to this case and PSR record
                    if(psrRec.RoutingType == 'SkillsBased'){
                        // This class is intentionally not bulkified - users are entering one case at a time to search by
                        List<SkillRequirement> skillReqList = [SELECT Id,
                                                                SkillId,
                                                                Skill.MasterLabel,
                                                                RelatedRecordId
                                                            FROM SkillRequirement
                                                            WHERE RelatedRecordId = :psrRec.Id];
                        List<SkillDetails> skillsList = new List<SkillDetails>();
                        for(SkillRequirement skill : skillReqList){
                            SkillDetails skillDet = new SkillDetails();
                            skillDet.Id = skill.Id;
                            skillDet.SkillName = skill.Skill.MasterLabel;
                            skillsList.add(skillDet);
                            newCaseResult.SkillNames = newCaseResult.SkillNames + ' | ' + skill.Skill.MasterLabel;
                        } 
                        System.debug('***Skill linked to Case: ' + skillsList);
                        newCaseResult.SkillDetails = skillsList;
                        newCaseResult.SkillNames = newCaseResult.SkillNames.substring(4);
                    }
                }
            }
            caseRoutingDetailList.add(newCaseResult);
        }
        System.debug('***Case Routing Detail List: ' + caseRoutingDetailList);
        return JSON.serialize(caseRoutingDetailList);
    }

    //Combine Case attributes and PendingServiceRouting attributes together in custom class
    public class CaseRouting {
        public String salesforceCaseNumber { get; set; }
        public String MNId { get; set; }
        public String MEDSSEventId { get; set; }
        public String CountyName { get; set; }
        public String CallAttDate { get; set; }
        public String InterviewJurisdictionCode { get; set; }
        public String SubRegionJurisdictionCode { get; set; }
        public Boolean DoNotCallList { get; set; }
        public Boolean CountyWithoutCIList { get; set; }
        public String Owner { get; set; }
        public String CaseStatus { get; set; }
        public String CallAttempted { get; set; }
        public String AgedToRegionalQueue { get; set; }
        public String RoutingStatus { get; set; }
        public String RoutingType { get; set; }
        public String SkillNames { get; set; }
        public List<SkillDetails> SkillDetails { get; set; }
    }

    //Many Skills to one Case
    public class SkillDetails {
        public String Id { get; set; }
        public String SkillName { get; set; }
    }
}