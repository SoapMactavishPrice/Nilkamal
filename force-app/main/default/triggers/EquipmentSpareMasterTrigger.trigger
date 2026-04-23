trigger EquipmentSpareMasterTrigger on Equipment_Spare_Master__c(before insert, before update) {

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        for(Equipment_Spare_Master__c esm : Trigger.new) {
            esm.External_Id__c = esm.SAP_Nilkamal_Model_Code_Equipment__c + ' - ' + esm.SAP_Material_Code_Spare__c;
        }
    }

}