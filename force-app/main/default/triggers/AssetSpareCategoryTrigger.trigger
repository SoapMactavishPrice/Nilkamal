trigger AssetSpareCategoryTrigger on Asset_Spare_Category__c(before insert, before update) {

    for(Asset_Spare_Category__c ascRecord : Trigger.new) {
        ascRecord.External_Id__c = ascRecord.Asset_Serial_No__c + ' - ' + ascRecord.Spare_Material_Code__c + ' - ' + ascRecord.Category__c;
    }

}