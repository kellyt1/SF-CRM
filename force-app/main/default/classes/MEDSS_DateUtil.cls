public with sharing class MEDSS_DateUtil {
    @TestVisible
    private static Integer hoursThreshold {
        get {
            if (hoursThreshold == null) {
                Set<String> wkEndDays = new Set<String>{ 'Sat', 'Sun' };
                String dayOfWk = Datetime.now().format('E');
                if (wkEndDays.contains(dayOfWk)) {
                    hoursThreshold = Integer.valueOf(
                        MEDSS_Batch_Helper.getMedssMetadata('wkend')
                    );
                } else {
                    hoursThreshold = Integer.valueOf(
                        MEDSS_Batch_Helper.getMedssMetadata('wkday')
                    );
                }
            }
            return hoursThreshold;
        }
        private set;
    }

    // TODO: set Company Business Hours in Setup
    // Get the default business hours
    @TestVisible
    private static BusinessHours businessHours {
        get {
            if (businessHours == null) {
                businessHours = [
                    SELECT Id
                    FROM BusinessHours
                    WHERE IsDefault = TRUE
                ];
            }
            return businessHours;
        }
        private set;
    }

    // Determine Age threshold of Case Intake time based on an hoursThreshold defined.
    public static DateTime determineAgeThreshold(DateTime dtTm) {
        return determineAgeThreshold(dtTm, hoursThreshold);
    }

    // Determine Age threshold of Case using date passed.
    public static DateTime determineAgeThreshold(DateTime dtTm, Integer hours) {
        return addHours(dtTm, hours);
    }

    @TestVisible
    private static DateTime addHours(DateTime dtTm, Integer hrs) {
        // prettier-ignore
        if (dtTm == null) { return null; }
        // Find new time
        return System.BusinessHours.addGMT(
            businessHours.Id,
            dtTm,
            (3600000 * hrs)
        );
    }
}
