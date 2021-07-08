global with sharing class MEDSS_BatchUtil implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Delete Batch History
        Datetime delBefore = getBatchHistoryRetentionDate();
        deleteHistory(delBefore);
    }

    @Testvisible
    private static Datetime getBatchHistoryRetentionDate() {
        String nbrDays = MEDSS_Batch_Helper.getMedssMetadata(
            'BatchHistRetenDays'
        );

        nbrDays = (nbrDays == null) ? '5' : nbrDays;

        Date day = Date.today().addDays(-Integer.valueOf(nbrDays));

        Datetime delBefore = Datetime.newInstance(
            day.year(),
            day.month(),
            day.day()
        );
        return delBefore;
    }

    // Delete older records. Custom Settings have a Governor Limit that we can not exceed.
    @Testvisible
    private static void deleteHistory(Datetime delBefore) {
        delete ([
            SELECT Id, CreatedDate
            FROM Batch_History__c
            WHERE CreatedDate <= :delBefore
        ]);
    }
}
