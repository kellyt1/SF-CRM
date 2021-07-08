public class AccountTriggerHandler {
    public static void populateAccountPhone(List<Account> lstNew) {
        for (Account acc : lstNew) {
            if (acc.Phone == null) {
                if (acc.PersonMobilePhone != null) {
                    acc.Phone = acc.PersonMobilePhone;
                } else if (acc.PersonHomePhone != null) {
                    acc.Phone = acc.PersonHomePhone;
                } else if (acc.PersonOtherPhone != null) {
                    acc.Phone = acc.PersonOtherPhone;
                }
            }
        }
    }
}
