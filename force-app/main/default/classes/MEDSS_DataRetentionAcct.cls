global with sharing class MEDSS_DataRetentionAcct implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date createdDateStart = getCreatedDateStart();

        return Database.getQueryLocator(
            'SELECT Id, CreatedDate FROM Account WHERE DAY_ONLY(CreatedDate) <= :createdDateStart'
        );
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        deleteRecords(scope);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Finish DataRetentionAcct');
    }

    @testVisible
    private void deleteRecords(List<SObject> records) {
        if (!records.isEmpty()) {
            try {
                Database.delete(records, false);
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
                Number_of_Days_for_Deletion_Account__c
            FROM Data_Retention__mdt
            WHERE MasterLabel = 'Standard Retention Policy'
        ];

        Date createdDateStart = todaysDate.addDays(
            -Integer.valueOf(
                dataRetention.Number_of_Days_for_Deletion_Account__c
            )
        );

        return createdDateStart;
    }
}
