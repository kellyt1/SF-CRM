// Info about scheduling and cron
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_scheduler.htm

MEDSS_Batch_IntakeRefreshScheduler m0 = new MEDSS_Batch_IntakeRefreshScheduler();
String intakeRefreshJobID05 = system.schedule('Intake Refresh :40', '0 40 23 * * ? *', m0);

MEDSS_DataRetention m1 = new MEDSS_DataRetention();
String dataRetentionJob00 = system.schedule('Data Retention', '0 0 0 * * ? *', m1);

MEDSS_IntakeBatch_Scheduler m2 = new MEDSS_IntakeBatch_Scheduler();
String intakeJobID05 = system.schedule('Batch Intake :05', '0 5 * * * ?', m2);
String intakeJobID35 = system.schedule('Batch Intake :35', '0 35 * * * ?', m2);

MEDSS_OutboundBatch_Scheduler m3 = new MEDSS_OutboundBatch_Scheduler();
String outboundJobID05 = system.schedule('Batch Outbound :05', '0 5 * * * ?', m3);
String outboundJobID35 = system.schedule('Batch Outbound :35', '0 35 * * * ?', m3);

MEDSS_BatchFiveHourFollowup_Scheduler m4 = new MEDSS_BatchFiveHourFollowup_Scheduler();
String followupJobID35 = system.schedule('Batch Five Hour Followup :30', '0 30 * * * ?', m4);

MEDSS_Batch_RemoveScheduler m5 = new MEDSS_Batch_RemoveScheduler();
String removeJobID10 = system.schedule('Batch Remove :10', '0 10 * * * ?', m5);
String removeJobID20 = system.schedule('Batch Remove :20', '0 20 * * * ?', m5);
String removeJobID40 = system.schedule('Batch Remove :40', '0 40 * * * ?', m5);
String removeJobID50 = system.schedule('Batch Remove :50', '0 50 * * * ?', m5);

MEDSS_BatchUtil m6 = new MEDSS_BatchUtil();
String batchUtilJob00 = system.schedule('Batch Util', '0 0 0 * * ? *', m6);

MEDSS_Batch_IntakeRemoveScheduler m8 = new MEDSS_Batch_IntakeRemoveScheduler();
String removeIntakeJobID10 = system.schedule('Batch Remove Intake :10', '0 10 * * * ?', m8);
String removeIntakeJobID20 = system.schedule('Batch Remove Intake :20', '0 20 * * * ?', m8);
String removeIntakeJobID40 = system.schedule('Batch Remove Intake :40', '0 40 * * * ?', m8);
String removeIntakeJobID50 = system.schedule('Batch Remove Intake :50', '0 50 * * * ?', m8);

MEDSS_AgentWorkExportInsScheduler m9 = new MEDSS_AgentWorkExportInsScheduler();
String agentWorkExportInsJobID05 = system.schedule('Agentwork Export Ins :05', '0 05 1 * * ?', m9);

MEDSS_AgentWorkExportUpdScheduler m10 = new MEDSS_AgentWorkExportUpdScheduler();
String agentWorkExportUpdJobID05 = system.schedule('Agentwork Export Upd :05', '0 05 2 * * ?', m10);
