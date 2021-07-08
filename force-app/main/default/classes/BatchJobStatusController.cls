//Apex class that returns Apex batch jobs that run for Intake and Outbound case ingestion from S3
public class BatchJobStatusController {
    
    @AuraEnabled(cacheable=true)
    public static String getIntakeJobs(){
        //Get the time of the most recently completed Intake run, along with State
        List<CronJobDetail> intakeJobSchedule = [SELECT Id,JobType,Name FROM CronJobDetail
                                                WHERE Name LIKE 'Batch Intake%'];
        List<CronTrigger> completedIntakeJobList = [SELECT CreatedById,CreatedDate,CronExpression,CronJobDetailId,EndTime,Id,LastModifiedById,NextFireTime,OwnerId,
                                     PreviousFireTime,StartTime,State,TimesTriggered,TimeZoneSidKey 
                                     FROM CronTrigger 
                                     WHERE CronJobDetailID IN :intakeJobSchedule AND PreviousFireTime != null ORDER BY PreviousFireTime ASC];
        System.debug('***Intake Job Runs: ' + completedIntakeJobList);
        DateTime lastIntakeRunGMT;
        String lastIntakeRun;
        for(CronTrigger intakeJob : completedIntakeJobList){
                System.debug('***Last Intake Run Local Time: ' + intakeJob.PreviousFireTime);
                lastIntakeRunGMT = intakeJob.PreviousFireTime;
                lastIntakeRun = lastIntakeRunGMT.format('yyyy-MM-dd HH:mm:ss', 'CST');
        }
        //Get the time of the next Intake run 
        DateTime nextIntakeRunGMT;
        String nextIntakeRun;
        List<CronTrigger> upcomingIntakeJobList = [SELECT CreatedById,CreatedDate,CronExpression,CronJobDetailId,EndTime,Id,LastModifiedById,NextFireTime,OwnerId,
                                     PreviousFireTime,StartTime,State,TimesTriggered,TimeZoneSidKey 
                                     FROM CronTrigger 
                                     WHERE CronJobDetailID IN :intakeJobSchedule AND NextFireTime != null ORDER BY NextFireTime DESC];
        for(CronTrigger intakeJob1 : upcomingIntakeJobList){
            nextIntakeRunGMT = intakeJob1.NextFireTime;
            nextIntakeRun = nextIntakeRunGMT.format('yyyy-MM-dd HH:mm:ss', 'CST');
            System.debug('***Next Intake Run Local Time: ' + nextIntakeRun);
        }
        String combinedIntakeRuns = 'Last Intake Run - ' + lastIntakeRun;
        combinedIntakeRuns = combinedIntakeRuns + '   |   Next Intake Run - ' + nextIntakeRun;
        System.debug('***Intake Runs: ' + combinedIntakeRuns);
        return combinedIntakeRuns;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getOutboundJobs(){
        
        //Get the time of the most recently completed Outbound run, along with State
        List<CronJobDetail> outboundJobSchedule = [SELECT Id,JobType,Name FROM CronJobDetail
                                                WHERE Name LIKE 'Batch Outbound%'];
        List<CronTrigger> completedOutboundJobList = [SELECT CreatedById,CreatedDate,CronExpression,CronJobDetailId,EndTime,Id,LastModifiedById,NextFireTime,OwnerId,
                                     PreviousFireTime,StartTime,State,TimesTriggered,TimeZoneSidKey 
                                     FROM CronTrigger 
                                     WHERE CronJobDetailID IN :outboundJobSchedule AND PreviousFireTime != null ORDER BY PreviousFireTime ASC];
        System.debug('***Outbound Job Runs: ' + completedOutboundJobList);
        DateTime lastOutboundRunGMT;
        String lastOutboundRun;
        for(CronTrigger outboundJob : completedOutboundJobList){
            lastOutboundRunGMT = outboundJob.PreviousFireTime;
            lastOutboundRun = lastOutboundRunGMT.format('yyyy-MM-dd HH:mm:ss', 'CST');
            System.debug('***Last Outbound Run Local Time: ' + lastOutboundRun);
        }
        //Get the time of the next Outbound run 
        DateTime nextOutboundRunGMT;
        String nextOutboundRun;
        List<CronTrigger> upcomingOutboundJobList = [SELECT CreatedById,CreatedDate,CronExpression,CronJobDetailId,EndTime,Id,LastModifiedById,NextFireTime,OwnerId,
                                     PreviousFireTime,StartTime,State,TimesTriggered,TimeZoneSidKey 
                                     FROM CronTrigger 
                                     WHERE CronJobDetailID IN :outboundJobSchedule AND NextFireTime != null ORDER BY NextFireTime DESC];
        for(CronTrigger outboundJob1 : upcomingOutboundJobList){
            nextOutboundRunGMT = outboundJob1.NextFireTime;
            nextOutboundRun = nextOutboundRunGMT.format('yyyy-MM-dd HH:mm:ss', 'CST');
            System.debug('***Next Outbound Run Local Time: ' + nextOutboundRun);
        }
        String combinedOutboundRuns = 'Last Outbound Run - ' + lastOutboundRun;
        combinedOutboundRuns = combinedOutboundRuns + '   |   Next Outbound Run - ' + nextOutboundRun;
        System.debug('***Outbound Runs: ' + combinedOutboundRuns);
        return combinedOutboundRuns;
    }

}