/*** 
 * Created By: Travis Bain, Slalom
 * Description: Trigger Handler that contains most of the Case routing logic upon a Case insert or a direct call to routing methods
 */
public without sharing class CaseTriggerHandler {
    private static final Id serviceChannelId = '0N9t0000000fxSQCAY';

    /**
     * Note that all cases passed into this method should have a non-Open Status for routing to properly function, unless
     * specifically being handled by the Outbound Batch (which will process Status separately beforehand).
     */
    public static void routeUsingSkill(Map<Id, Case> newMap) {
        Map<Id, Case> mapCases = getCaseMap(newMap);
        DateTime currentTime = DateTime.now();
        Map<String, String> mapCountyMdt = getSkillCounty();
        Map<String, String> mapInterviewJurisdictionMdt = getSkillInterviewJurisdiction();
        Map<String, String> mapLanguageMdt = getSkillLanguage();
        Map<String, String> mapCountyNames = getMapCountyNames();
        User integrationUser = [SELECT id FROM User WHERE alias = 'iuser'];

        //Remove existing AgentWork records to allow for fresh re-queueing of cases upon status update
        deleteAgentWorkForExistingCases(newMap);

        for (Case c : mapCases.values()) {
            c.AllowStatusUpdate__c = false;
            
            //Update Status if Closed
            if (c.Status == 'Closed' || c.Status == 'Follow-up') {
                c.Status = 'New';
            }
            //Update Status to 'Re-queued' specifically if case was closed and then re-read in by the Intake/Outbound batch
            if (c.Status == 'Ready for Re-queue') {
                c.Status = 'Re-queued';
            }
            //Update County value using the County custom metadata values
            if (c.CountyCode__c != null) {
                if (mapCountyMdt.containsKey(c.CountyCode__c)) {
                    String tmp = (mapCountyMdt.get(c.CountyCode__c))
                        .substringAfter('_');
                    if (
                        tmp.substringBefore('_').contains('Central') ||
                        tmp.substringBefore('_').contains('Quin')
                    )
                        tmp = tmp.substringAfter('_');
                    c.County__c = tmp.replace('_', ' ');
                } else {
                    c.County__c = 'No Value';
                }

                if (mapCountyNames.containsKey(c.CountyCode__c)) {
                    c.County_Name__c = (mapCountyNames.get(c.CountyCode__c))
                        .replace('_', ' ');
                }
            }
            //Update Owner to initial default owner (Integration User)
            if (c.RecordTypeId == outboundRecordTypeId)
                c.OwnerId = integrationUser.Id;
        }
        update mapCases.values();

        //Create and insert PSR records to prepare for routing
        List<PendingServiceRouting> listPSRToInsert = createPendingServiceRoutingRecords(
            mapCases.values()
        );
        if (!listPSRToInsert.isEmpty()) {
            Schema.SObjectField fld = PendingServiceRouting.Fields.Id;
            Database.upsert(listPSRToInsert, fld, false);
        }

        //Assign Cases to Regional Queues
        List<Case> listCasesToUpdate = new List<Case>();
        Map<String, QueueSObject> mapQueues = getMapCaseQueues();
        Map<String, Map<String, String>> mapRegions = MEDSS_Batch_Helper.regionMap;

        //Iterate through each case
        for (Case c : mapCases.values()) {
            Boolean updateCase = false;
            if (mapRegions.containsKey(c.SubregionBasedJurisdictionCode__c)) {
                if (c.RecordTypeId == outboundRecordTypeId) {
                    //This conditional determines whether the case will be released to the regional queues or not. Checks for case being Aged Out,
                    //as well as whether it's part of the Do Not Call List or assigned directly to MDH
                    if (
                        ((c.Aged_Out__c < DateTime.now() && !setDoNotCallCounty.contains(c.County__c)) ||
                        setCountyWithoutCI.contains(c.County__c)) &&
                        c.InterviewJurisdictionCode__c != 'MDH'
                    ) {
                        //If a call attempt is logged on the case, assign it to the standard or 'called' queue for that region
                        if (c.Call_Attempt_Date__c != null) {
                            c.OwnerId = mapQueues.get(
                                    mapRegions.get(
                                            c.SubregionBasedJurisdictionCode__c
                                        )
                                        .get('Queue')
                                )
                                .QueueId;
                        } else {
                            //Else, assign that case to the Uncalled queue for that region
                            c.OwnerId = mapQueues.get(
                                    mapRegions.get(
                                            c.SubregionBasedJurisdictionCode__c
                                        )
                                        .get('Uncalled Queue')
                                )
                                .QueueId;
                        }

                        c.Aged_To_Regional_Queue__c = true; //Set the flag to avoid the case being re-queued by Age Out process in Outbound Batch
                    }
                }
                //Update Region value
                c.Region__c = mapRegions.get(
                        c.SubregionBasedJurisdictionCode__c
                    )
                    .get('Region');

                updateCase = true;
            }

            if (updateCase)
                listCasesToUpdate.add(c);
            updateCase = false;
        }
        if (!listCasesToUpdate.isEmpty()) {
            update listCasesToUpdate;
        }

        if (!listPSRToInsert.isEmpty()) {
            List<SkillRequirement> listSRToInsert = new List<SkillRequirement>();

            Map<String, String> mapSkills = getSkills();

            // For each PendingServiceRouting
            for (PendingServiceRouting psr : listPSRToInsert) {
                Case tempCase = mapCases.get(psr.WorkItemId);

                /**
                 * This next large code block is a logic tree that determines which skills will be assigned to a case based
                 * on various criteria. Each case will only meet one of these criteria and be assigned a Consultant Staff or
                 * County skill based on that criteria.
                 **/
                if (true) {
                    //IF InterviewJurisdictionCode__c != null: process normally
                    if (tempCase.InterviewJurisdictionCode__c != null) {
                        if (tempCase.InterviewJurisdictionCode__c == 'MDH') {
                            //IF InterviewJurisdictionCode__c == MDH: Send to Rose based on region
                            System.debug(
                                'TBAIN (MDH LOGIC) Assigning Consultant Staff Skill for Case: ' +
                                tempCase
                            );
                            listSRToInsert.add(
                                getSkillRequirement(
                                    psr.Id,
                                    mapSkills.get(
                                        mapRegions.get(
                                                tempCase.SubregionBasedJurisdictionCode__c
                                            )
                                            .get('Consultant Staff Skill')
                                    )
                                )
                            );
                        } else if (
                            tempCase.InterviewJurisdictionCode__c == 'GEN' ||
                            tempCase.InterviewJurisdictionCode__c.contains(
                                'LPH-'
                            )
                        ) {
                            if (
                                tempCase.SubregionBasedJurisdictionCode__c ==
                                'SR-NOREGION'
                            ) {
                                //IF SubregionBasedJurisdictionCode__c == SR-NOREGION: Send to general Rose
                                System.debug(
                                    'TBAIN (GEN+NOREGION LOGIC) Assigning County Skill for Case: ' +
                                    tempCase
                                );
                                listSRToInsert.add(
                                    getSkillRequirement(
                                        psr.Id,
                                        mapSkills.get(
                                            mapRegions.get(
                                                    tempCase.SubregionBasedJurisdictionCode__c
                                                )
                                                .get('Consultant Staff Skill')
                                        )
                                    )
                                );
                            } else if (
                                tempCase.CountyCode__c == null &&
                                tempCase.SubregionBasedJurisdictionCode__c ==
                                'SR-METRO'
                            ) {
                                //IF CountyCode__c == NULL && SubregionBasedJurisdictionCode__c == SR-METRO: Send to Bloomington Skill
                                System.debug(
                                    'TBAIN (GEN+NULLCOUNTY+METRO LOGIC) Assigning County Skill for Case: ' +
                                    tempCase
                                );
                                listSRToInsert.add(
                                    getSkillRequirement(
                                        psr.Id,
                                        mapSkills.get(mapCountyMdt.get('MN-53'))
                                    )
                                );
                            } else if (
                                tempCase.CountyCode__c == null &&
                                tempCase.SubregionBasedJurisdictionCode__c !=
                                'SR-METRO'
                            ) {
                                //IF CountyCode__c == NULL && SubregionBasedJurisdictionCode__c != SR-METRO: Send to general rose
                                System.debug(
                                    'TBAIN (GEN+NULLCOUNTY+NOTMETRO LOGIC) Assigning County Skill for Case: ' +
                                    tempCase
                                );
                                listSRToInsert.add(
                                    getSkillRequirement(
                                        psr.Id,
                                        mapSkills.get(
                                            mapRegions.get(
                                                    tempCase.SubregionBasedJurisdictionCode__c
                                                )
                                                .get('Consultant Staff Skill')
                                        )
                                    )
                                );
                            } else if (tempCase.CountyCode__c == 'MN-53') {
                                //IF CountyCode__c == MN-53: Send to Bloomington Skill. TO-DO: If there are other city-based exceptions, maybe handle here?
                                System.debug(
                                    'TBAIN (GEN+MN-53 LOGIC) Assigning County Skill for Case: ' +
                                    tempCase
                                );
                                listSRToInsert.add(
                                    getSkillRequirement(
                                        psr.Id,
                                        mapSkills.get(
                                            mapCountyMdt.get(
                                                tempCase.CountyCode__c
                                            )
                                        )
                                    )
                                );
                            } else {
                                //ELSE: Assign to County skill based on CountyCode__c mapping
                                System.debug(
                                    'TBAIN (GEN+COUNTY LOGIC) Assigning County Skill for Case: ' +
                                    tempCase
                                );
                                listSRToInsert.add(
                                    getSkillRequirement(
                                        psr.Id,
                                        mapSkills.get(
                                            mapCountyMdt.get(
                                                tempCase.CountyCode__c
                                            )
                                        )
                                    )
                                );
                            }
                        } else {
                            //PRINT CASES WITH MISSING LOGIC HERE!!!
                            System.debug(
                                'TBAIN ERROR! Case had no valid routing logic: ' +
                                tempCase
                            );
                        }
                    } else {
                        //ELSE: Send to general Rose staff.
                        System.debug(
                            'TBAIN (NO INTERVIEWJURISDICTION LOGIC) Assigning County Skill for Case: ' +
                            tempCase
                        );
                        listSRToInsert.add(
                            getSkillRequirement(
                                psr.Id,
                                mapSkills.get(
                                    mapRegions.get('SR-NOREGION')
                                        .get('Consultant Staff Skill')
                                )
                            )
                        );
                    }
                } //County and Consultant Staff Logic End
                
                //Only assign Language skill is case is not aged out
                if (currentTime < tempCase.Aged_Out__c) {
                    if (
                        tempCase.Preferred_Language_Unrestricted__c != null &&
                        tempCase.Preferred_Language_Unrestricted__c != '' &&
                        mapLanguageMdt.get(
                            tempCase.Preferred_Language_Unrestricted__c
                        ) != null
                    ) {
                        System.debug(
                            'TBAIN Language Found! Language: ' +
                            tempCase.Preferred_Language_Unrestricted__c
                        );
                        if (
                            mapSkills.get(
                                mapLanguageMdt.get(
                                    tempCase.Preferred_Language_Unrestricted__c
                                )
                            ) != null
                        )
                            listSRToInsert.add(
                                getLanguageSkillRequirement(
                                    psr.Id,
                                    mapSkills.get(
                                        mapLanguageMdt.get(
                                            tempCase.Preferred_Language_Unrestricted__c
                                        )
                                    )
                                )
                            );
                    } else {
                        //Blank Language, assign English by default
                        System.debug('TBAIN Blank Language!');
                        listSRToInsert.add(
                            getLanguageSkillRequirement(
                                psr.Id,
                                mapSkills.get(mapLanguageMdt.get('English'))
                            )
                        );
                    }
                }

                // Set PendingServiceRouting IsReadyForRouting to true
                psr.IsReadyForRouting = true;
            }

            // Insert SkillRequirement list
            if (!listSRToInsert.isEmpty()) {
                System.debug('TBAIN SKILL LIST NOT EMPTY');
                insert listSRToInsert;
                // Update PendingServiceRouting list
            }
            update listPSRToInsert;
        }
    }

    //TO-DO: Delete duplicate method from Outbound Batch
    @TestVisible
    private static Map<String, QueueSObject> getMapCaseQueues() {
        Map<String, QueueSObject> mapQueues = new Map<String, QueueSObject>();
        for (QueueSObject qSObj : [
            SELECT Id, Queue.Name, QueueId
            FROM QueueSObject
            WHERE SObjectType = 'Case'
        ]) {
            mapQueues.put(qSObj.Queue.Name, qSObj);
        }
        return mapQueues;
    }

    @TestVisible
    private static SkillRequirement getSkillRequirement(
        Id psrId,
        String skillName
    ) {
        //If no matching skill is found, assign the debug skill
        if (skillName == null) {
            System.debug('TBAIN Null SkillId. PSR ID: ' + psrId);
            return (new SkillRequirement(
                RelatedRecordId = psrId,
                SkillId = debugLanguage
            ));
        } else {
            return (new SkillRequirement(
                RelatedRecordId = psrId,
                SkillId = (Id) skillName
            ));
        }
    }

    @TestVisible
    private static SkillRequirement getLanguageSkillRequirement(
        Id psrId,
        String skillName
    ) {
        //If no matching skill is found, assign the debug skill
        if (skillName == null) {
            System.debug('TBAIN Null SkillId. PSR ID: ' + psrId);
            return (new SkillRequirement(
                RelatedRecordId = psrId,
                SkillId = debugLanguage
            ));
        } else {
            return (new SkillRequirement(
                RelatedRecordId = psrId,
                isAdditionalSkill = true,
                SkillPriority = 1,
                SkillId = (Id) skillName
            ));
        }
    }

    @TestVisible
    private static Id outboundRecordTypeId {
        get {
            if (outboundRecordTypeId == null) {
                Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Case.getRecordTypeInfosByName();
                outboundRecordTypeId = recordTypes.get('Outbound Call')
                    .getRecordTypeId();
            }
            return outboundRecordTypeId;
        }
        private set;
    }

    @TestVisible
    private static List<PendingServiceRouting> createPendingServiceRoutingRecords(
        List<Case> cases
    ) {
        List<PendingServiceRouting> listExistingPSR = [
            SELECT Id, WorkItemId
            FROM PendingServiceRouting
            WHERE WorkItemId IN :cases
        ];
        Map<Id, PendingServiceRouting> mapExistingPSR = new Map<Id, PendingServiceRouting>();
        for (PendingServiceRouting psr : listExistingPSR) {
            mapExistingPSR.put(psr.WorkItemId, psr);
        }

        List<PendingServiceRouting> listPSRToInsert = new List<PendingServiceRouting>();
        DateTime currentTime = DateTime.now();

        /**
         * Case Priority and Custom Routing Configurations are assigned here. This is done primarily to assign routing priority dynamically,
         * as the routing priority can vary based on Interview Jurisdiction as well as if there is a previous Call Attempt
         **/
        for (Case c : cases) {
            //Default case to Priority 1
            Integer psrPriority = 1;
            
            //If MDH, assigned Priority 2 to be the same priority as queue-based routing
            if (c.InterviewJurisdictionCode__c == 'MDH') 
                psrPriority = 2;
            //If there is a call attempt on the case, lower the priority by 2 (Priority 1 becomes 3, 2 becomes 4)
            if (c.Call_Attempt_Date__c != null)
                psrPriority = psrPriority + 2;

            // Check if case record type is outbound AND is not Aged Out, as well as WithoutCI and Do Not Call lists
            if (
                c.RecordTypeID == outboundRecordTypeId &&
                ((c.Aged_Out__c > currentTime &&
                !setCountyWithoutCI.contains(c.County__c) &&
                !setDoNotCallCounty.contains(c.County__c)) ||
                setDoNotCallCounty.contains(c.County__c) ||
                c.InterviewJurisdictionCode__c == 'MDH')
            ) {
                // Create a psr and add to insert list using custom Routing Configuration
                if (!mapExistingPSR.containsKey(c.Id)) {
                    PendingServiceRouting psr = new PendingServiceRouting(
                        CapacityWeight = 1,
                        IsReadyForRouting = false,
                        RoutingModel = 'MostAvailable', //LeastAvailbale
                        RoutingPriority = psrPriority,
                        RoutingType = 'SkillsBased',
                        ServiceChannelId = serviceChannelId,
                        DropAdditionalSkillsTimeout = 1800,
                        PushTimeout = 30,
                        WorkItemId = c.Id
                    );
                    listPSRToInsert.add(psr);
                } else {
                    PendingServiceRouting psr = mapExistingPSR.get(c.Id);
                    psr.CapacityWeight = 1;
                    psr.IsReadyForRouting = false;
                    psr.RoutingModel = 'MostAvailable'; //LeastAvailbale
                    psr.RoutingPriority = psrPriority;
                    psr.RoutingType = 'SkillsBased';
                    psr.ServiceChannelId = serviceChannelId;
                    psr.DropAdditionalSkillsTimeout = 1800;
                    psr.PushTimeout = 30;
                    listPSRToInsert.add(psr);
                }
            }
        }
        return listPSRToInsert;
    }

    @TestVisible
    private static Map<String, String> getSkills() {
        Map<String, String> mapSkills = new Map<String, String>();
        for (Skill skill : [SELECT Id, DeveloperName FROM Skill]) {
            mapSkills.put(skill.DeveloperName, skill.Id);
        }
        return mapSkills;
    }

    @TestVisible
    private static Map<Id, Case> getCaseMap(Map<Id, Case> mapCases) {
        Map<Id, Case> caseMap = new Map<Id, Case>();

        for (Case c : [
            SELECT
                Id,
                Aged_Out__c,
                Status,
                OwnerId,
                Call_Attempt_Date__c,
                County__c,
                CountyCode__c,
                SubregionBasedJurisdictionCode__c,
                InterviewJurisdictionCode__c,
                Preferred_Language_Unrestricted__c,
                Preferred_Language__c,
                RecordTypeId
            FROM Case
            WHERE Id IN :mapCases.keySet()
        ]) {
            caseMap.put(c.Id, c);
        }

        return caseMap;
    }

    @TestVisible
    private static Map<String, String> getSkillCounty() {
        return mapCounties(
            [SELECT County_Code__c, API_Name__c FROM County_Skill__mdt]
        );
    }

    @TestVisible
    private static Set<String> getDoNotCallCounty() {
        Set<String> listCounties = new Set<String>();
        for (SObject s : [SELECT County_Name__c FROM Do_Not_Call_County__c]) {
            listCounties.add((String) s.get('County_Name__c'));
        }
        return listCounties;
    }

    @TestVisible
    private static Set<String> getCountyWithoutCI() {
        Set<String> listCounties = new Set<String>();
        for (SObject s : [SELECT County_Name__c FROM Counties_Without_CI__c]) {
            listCounties.add((String) s.get('County_Name__c'));
        }
        return listCounties;
    }

    @TestVisible
    private static Map<String, String> getSkillInterviewJurisdiction() {
        return mapInterviewJurisdictions(
            [
                SELECT Interview_Jurisdiction_Code__c, API_Name__c
                FROM County_Skill__mdt
            ]
        );
    }

    @TestVisible
    private static Map<String, String> getSkillLanguage() {
        return mapLanguages(
            [SELECT MasterLabel, API_Name__c FROM Language_Skill__mdt]
        );
    }

    @TestVisible
    private static Map<String, String> mapInterviewJurisdictions(
        List<SObject> skills
    ) {
        Map<String, String> skillsMap = new Map<String, String>();
        for (SObject skill : skills) {
            skillsMap.put(
                (String) skill.get('Interview_Jurisdiction_Code__c'), //TBAIN 1/4/2021 Switch from MasterLabel to County_Code__c
                (String) skill.get('API_Name__c')
            );
        }
        return skillsMap;
    }

    @TestVisible
    private static Map<String, String> mapCounties(List<SObject> skills) {
        Map<String, String> skillsMap = new Map<String, String>();
        for (SObject skill : skills) {
            skillsMap.put(
                (String) skill.get('County_Code__c'),
                (String) skill.get('API_Name__c')
            );
        }
        return skillsMap;
    }

    @TestVisible
    private static Map<String, String> getMapCountyNames() {
        Map<String, String> countyNameMap = new Map<String, String>();
        List<County_Skill__mdt> listCounty = [
            SELECT County_Code__c, MasterLabel
            FROM County_Skill__mdt
        ];
        for (County_Skill__mdt c : listCounty) {
            countyNameMap.put(
                (String) c.get('County_Code__c'),
                (String) c.get('MasterLabel')
            );
        }
        return countyNameMap;
    }

    @TestVisible
    private static Map<String, String> mapLanguages(List<SObject> skills) {
        Map<String, String> skillsMap = new Map<String, String>();
        for (SObject skill : skills) {
            skillsMap.put(
                (String) skill.get('MasterLabel'),
                (String) skill.get('API_Name__c')
            );
        }
        return skillsMap;
    }

    public static Set<String> setDoNotCallCounty {
        get {
            if (setDoNotCallCounty == null) {
                setDoNotCallCounty = getDoNotCallCounty();
            }
            return setDoNotCallCounty;
        }
        private set;
    }

    public static Set<String> setCountyWithoutCI {
        get {
            if (setCountyWithoutCI == null) {
                setCountyWithoutCI = getCountyWithoutCI();
            }
            return setCountyWithoutCI;
        }
        private set;
    }

    /**
     * The debug skill was set to 'Language - Korean' to be able to easily check if there are cases without valid skills,
     * which would likely indicate that we are missing a mapping or skill. A real language was chosen due to the fact that skills
     * can't be hidden or deleted, meaning that any skill labeled 'Debug Skill' or such would display on the front end as a
     * valid choice. 
     **/
    public static Id debugLanguage {
        get {
            if (debugLanguage == null) {
                List<Skill> tempSkill = [
                    SELECT Id
                    FROM Skill
                    WHERE DeveloperName = 'Language_Korean'
                ];
                debugLanguage = tempSkill[0].Id;
            }
            return debugLanguage;
        }
        private set;
    }

    /**
     * AgentWork for existing cases is deleted due to the the behavior in which re-opening cases from a Closed to New status 
     * would default back to routing the cases under it's previous routing. We prevent this by deleting the AgentWork records upon
     * entering the routing logic in order to ensure the case receives the latest and most relevant routing assignment.
     * Agent Work records are maintained for reporting purposes in the AgentWorkHistory custom object 
     * which is created in the AgentWork insert trigger.
     **/
    private static void deleteAgentWorkForExistingCases(
        Map<Id, Case> mapCases
    ) {
        List<AgentWork> listAgentWork = [
            SELECT Id
            FROM AgentWork
            WHERE WorkItemId IN :mapCases.keySet()
        ];
        for (AgentWork aw : listAgentWork) {
            System.debug('AGENT WORK: ' + aw);
        }
        if (!listAgentWork.isEmpty())
            delete listAgentWork;
    }

    //This method stamps a field to remember the previous queue the case was associated with, in order to default
    //back under certain circumstances
    public static void updateQueueId(List<Case> newCases) {
        system.debug('--- update queueId--');
        Set<Id> queueIds = new Set<Id>();
        for (Case cse : newCases) {
            if (cse.OwnerId != null) {
                queueIds.add(cse.OwnerId);
                // cse.Standard_QueueId__c = cse.OwnerId;
                system.debug('--- queue id--' + cse.OwnerId);
            }
        }
        List<QueueSObject> allQueues = [
            SELECT Id, queue.Name, QueueId
            FROM QueueSObject
            WHERE SObjectType = 'Case' AND QueueId IN :queueIds
        ];
        system.debug('--- all queueus--' + allQueues);
        Map<Id, QueueSObject> queueMap = new Map<Id, QueueSObject>();
        for (QueueSObject q : allQueues) {
            queueMap.put(q.QueueId, q);
        }
        system.debug('--- queue Map--' + queueMap);
        for (Case cse : newCases) {
            if (
                cse.OwnerId != null &&
                queueMap.containsKey(cse.OwnerId) &&
                cse.status != 'Closed'
            ) {
                system.debug('--- owner id--' + cse.OwnerId);
                cse.Standard_QueueId__c = cse.OwnerId;
            }
        }
    }
}