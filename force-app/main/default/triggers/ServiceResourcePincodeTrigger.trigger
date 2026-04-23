trigger ServiceResourcePincodeTrigger on Service_Resource_Pincode__c (before insert, before update) {

    for(Service_Resource_Pincode__c srp : Trigger.New) {
    srp.External_Id__c = srp.Service_Resource_Formula__c + ' - ' + srp.Pin_Code_Formula__c;
    }

}