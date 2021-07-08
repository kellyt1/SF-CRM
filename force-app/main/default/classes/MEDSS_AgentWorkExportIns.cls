global with sharing class MEDSS_AgentWorkExportIns implements Database.Batchable<sObject>, Database.Stateful {
    // Addtional documentation on Writable External Objs
    // https://help.salesforce.com/articleView?id=sf.platform_connect_considerations_writable_external_objects.htm&type=5
    // Database.deleteImmediate([SELECT Id FROM AgentWorks__x LIMIT 1000]);

    private final Date runForDate;
    @testVisible
    private final DateTime insertDateTime = Datetime.now();
    private final Timezone tz = Timezone.getTimeZone('America/Chicago');

    // Assumption is that this will run for previous day
    global MEDSS_AgentWorkExportIns() {
        this.runForDate = Date.today() - 1;
    }

    global MEDSS_AgentWorkExportIns(Date runForDate) {
        this.runForDate = runForDate;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return getAgentWorkHistory();
    }

    global void execute(
        Database.BatchableContext bc,
        List<AgentWorkHistory__c> scope
    ) {
        runExport(scope);
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob aApexJob = [
            SELECT
                Id,
                Status,
                NumberOfErrors,
                JobItemsProcessed,
                TotalJobItems,
                CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];

        System.debug('Finish Export - Status: ' + aApexJob.Status);
        System.debug(
            'Finish Export - NumberOfErrors: ' + aApexJob.NumberOfErrors
        );
        System.debug(
            'Finish Export - JobItemsProcessed: ' + aApexJob.JobItemsProcessed
        );
        System.debug(
            'Finish Export - TotalJobItems: ' + aApexJob.TotalJobItems
        );
    }

    public void runExport(List<AgentWorkHistory__c> histories) {
        List<AgentWorks__x> agentsWork = createAgentsWork(histories);

        if (Test.isRunningTest()) {
            return;
        }

        List<Database.SaveResult> saveResults = Database.insertImmediate(
            agentsWork
        );

        for (Database.SaveResult saveResult : saveResults) {
            for (Database.Error err : saveResult.getErrors()) {
                System.debug(
                    'Error: ' +
                    err.getStatusCode() +
                    ': ' +
                    err.getMessage()
                );
                System.debug(
                    'Fields that affected this error: ' + err.getFields()
                );
            }
        }
    }

    @testVisible
    private DateTime convertToLocal(DateTime dtm) {
        if (dtm == null) {
            //return null;
            
            return DateTime.newInstance(1111, 1, 1); //To revert workaround, comment out this line and uncomment 'return null;' above
        }
        return dtm.addSeconds((tz.getOffset(dtm) / 1000));
    }

    @testVisible
    private List<AgentWorks__x> createAgentsWork(
        List<AgentWorkHistory__c> agentsWrkHist
    ) {
        List<AgentWorks__x> agentsWork = new List<AgentWorks__x>();

        for (AgentWorkHistory__c agtWrk : agentsWrkHist) {
            AgentWorks__x agentWork = new AgentWorks__x(
                Id__c = agtWrk.Id,
                AcceptDateTime__c = convertToLocal(agtWrk.AcceptDateTime__c),
                AgentWorkName__c = agtWrk.Name,
                AssignedDateTime__c = convertToLocal(
                    agtWrk.AssignedDateTime__c
                ),
                CancelDateTime__c = convertToLocal(agtWrk.CancelDatetime__c),
                CloseDateTime__c = convertToLocal(agtWrk.CloseDateTime__c),
                Company__c = agtWrk.Company__c,
                County__c = agtWrk.County__c,
                DeclineDateTime__c = convertToLocal(agtWrk.DeclineDateTime__c),
                InsertDatetime__c = convertToLocal(this.insertDateTime),
                HandleTime__c = agtWrk.HandleTime__c,
                MedssEventId__c = agtWrk.MEDSS_Event_Id__c,
                MedssEventName__c = agtWrk.Medss_Event_Name__c,
                MedssEventRecordType__c = agtWrk.MEDSS_Event_Record_Type__c,
                MedssEventStatus__c = agtWrk.Case_Status__c,
                MNId__c = agtWrk.MNId__c,
                OriginalGroupName__c = agtWrk.OriginalGroupName__c,
                OriginalQueueName__c = agtWrk.OriginalQueueName__c,
                OwnerName__c = agtWrk.OwnerName__c,
                PushTimeout__c = agtWrk.PushTimeout__c,
                PushTimeoutDatetime__c = convertToLocal(
                    agtWrk.PushTimeoutDateTime__c
                ),
                Region__c = agtWrk.Region__c,
                RequestDateTime__c = convertToLocal(agtWrk.RequestDatetime__c),
                Status__c = agtWrk.Status__c,
                UserName__c = agtWrk.UserId__r.Name,
                UserRole__c = agtWrk.UserRole__c
            );
            agentsWork.add(agentWork);
        }
        return agentsWork;
    }

    @testVisible
    private Database.QueryLocator getAgentWorkHistory() {
        return Database.getQueryLocator(
            'SELECT ' +
            'Id, ' +
            'AcceptDateTime__c, ' +
            'AgentWorkId__c, ' +
            'AssignedDateTime__c, ' +
            'CancelDatetime__c, ' +
            'Case_Status__c, ' +
            'CloseDateTime__c, ' +
            'Company__c, ' +
            'County__c, ' +
            'DeclineDateTime__c, ' +
            'HandleTime__c, ' +
            'MEDSS_Event_ID__c, ' +
            'Medss_Event_Name__c, ' +
            'MEDSS_Event_Record_Type__c, ' +
            'MNId__c, ' +
            'Name, ' +
            'OriginalGroupName__c, ' +
            'OriginalQueueName__c, ' +
            'OwnerName__c, ' +
            'PushTimeout__c, ' +
            'PushTimeoutDateTime__c, ' +
            'Region__c, ' +
            'RequestDateTime__c, ' +
            'Status__c, ' +
            'UserId__r.Name, ' +
            'UserRole__c ' +
            'FROM AgentWorkHistory__c ' +
            'WHERE DAY_ONLY(CreatedDate) = :runForDate'
        );
    }
}
