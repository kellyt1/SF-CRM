@isTest(SeeAllData=false)
public with sharing class MEDSS_DateUtilTest {
    @isTest(SeeAllData=false)
    static void testBusinessHours() {
        BusinessHours busHours = [
            SELECT Id
            FROM BusinessHours
            WHERE IsDefault = TRUE
        ];
        System.assertEquals(busHours.Id, MEDSS_DateUtil.businessHours.Id);
    }

    @isTest(SeeAllData=false)
    static void testAddHours() {
        Id busHoursId = MEDSS_DateUtil.businessHours.Id;
        Integer hrs = MEDSS_DateUtil.hoursThreshold;
        DateTime testDtTm = DateTime.now();

        DateTime testTime0a = MEDSS_DateUtil.determineAgeThreshold(testDtTm);
        DateTime testTime0b = System.BusinessHours.addGMT(
            busHoursId,
            testDtTm,
            (3600000 * hrs)
        );
        System.assertEquals(testTime0a, testTime0b);

        testDtTm = DateTime.now().addHours(-12);
        DateTime testTime0c = MEDSS_DateUtil.determineAgeThreshold(testDtTm);
        DateTime testTime0d = System.BusinessHours.addGMT(
            busHoursId,
            testDtTm,
            (3600000 * hrs)
        );
        System.assertEquals(testTime0c, testTime0d);
    }
}
