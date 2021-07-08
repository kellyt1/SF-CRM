List<Do_Not_Call_Counties__mdt> lists =  [SELECT County_Name__c, Region__c FROM Do_Not_Call_Counties__mdt];

List<Do_Not_Call_County__c> doNotCallList = new List<Do_Not_Call_County__c>();
for (Do_Not_Call_Counties__mdt s : lists) {
    Do_Not_Call_County__c cc = new Do_Not_Call_County__c();
    cc.Name =  s.County_Name__c;
    cc.County_Name__c = s.County_Name__c;
    cc.Region__c = s.Region__c;
    doNotCallList.add(cc);
}
 
System.debug('doNotCallList ' + doNotCallList);
insert doNotCallList;

List<Counties_Without_CI__c> countiesWOutCi = new List<Counties_Without_CI__c>();
for (Regional_Counties_Without_CI__mdt s : [SELECT County_Name__c FROM Regional_Counties_Without_CI__mdt]) {
    Counties_Without_CI__c cc = new Counties_Without_CI__c();
    cc.Name = (String)s.get('County_Name__c');
    cc.County_Name__c = (String)s.get('County_Name__c');
    countiesWOutCi.add(cc);
}
 
System.debug('countiesWOutCi ' + countiesWOutCi);
insert countiesWOutCi;