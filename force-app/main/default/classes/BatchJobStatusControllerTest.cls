@isTest(SeeAllData=false)
public class BatchJobStatusControllerTest {
    
    @isTest(SeeAllData=false)
    static void testIntakeJobStatus() {
        String intakeRunDate = BatchJobStatusController.getIntakeJobs();
    }

    @isTest(SeeAllData=false)
    static void testOutboundJobStatus() {
        String outboundRunDate = BatchJobStatusController.getOutboundJobs();
    }

}