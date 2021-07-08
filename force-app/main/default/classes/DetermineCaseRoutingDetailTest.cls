@isTest(SeeAllData=false)
public class DetermineCaseRoutingDetailTest {
    
    @isTest(SeeAllData=false)
    static void testGetCaseDetails() {
        Case newCase = new Case(
        	MEDSS_Event_ID__c = '1234556677888'
        );
        insert newCase;
        
        String searchTerm = '1234556677888';
        String caseDetails = DetermineCaseRoutingDetailsAndPriority.getCaseDetails(searchTerm);
        System.assertNotEquals(null, caseDetails);
    }
}