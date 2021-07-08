global class MEDSS_AgentWorkHistoryRetention implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date createdDateStart = getCreatedDateStart();
   
        return Database.getQueryLocator(
            'SELECT Id, CreatedDate FROM AgentWorkHistory__c WHERE DAY_ONLY(CreatedDate) <= :createdDateStart'
        );
    }

    global void execute(Database.BatchableContext bc, List<AgentWorkHistory__c> scope) {
        deleteRecords(scope);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finish DataRetention');
    }

    @testVisible
    private void deleteRecords(List<SObject> records) {    
        if (!records.isEmpty()) {
            try {
                delete records;
                Database.emptyRecycleBin(records);
            } catch (Exception ex) {
                System.debug(
                    'An Exception occured record deletion ' + ex.getMessage()
                );
            }
        }
    } 

    @testVisible
    private Date getCreatedDateStart() {
        Date todaysDate = Date.today();

        Data_Retention__mdt dataRetention = [
            SELECT
                MasterLabel,
                Number_of_Days_for_Deletion_Medss_Event__c,
                Number_of_Days_for_Deletion_Account__c,
                Days_for_Deletion_AgentWorkHistory__c
            FROM Data_Retention__mdt
            WHERE MasterLabel = 'Standard Retention Policy'
        ];

        Date createdDateStart = todaysDate.addDays(
            -Integer.valueOf(
                dataRetention.Days_for_Deletion_AgentWorkHistory__c
            )
        );

        return createdDateStart;
    }
}
