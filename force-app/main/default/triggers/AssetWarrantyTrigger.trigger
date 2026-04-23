trigger AssetWarrantyTrigger on Asset_Warranty__c (before insert, after insert,before update, after update) {

    if (Trigger.isBefore && (Trigger.isInsert || trigger.isUpdate)) {
        AssetWarrantyTriggerHandler.updateWarrantyEndDate(Trigger.new);
    }

    // added by keshav
    if (Trigger.isBefore && Trigger.isInsert) {
       AssetWarrantyTriggerHandler.setWarrantyOwner(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        AssetWarrantyTriggerHandler.createAssetVisit(Trigger.new);
        AssetWarrantyTriggerHandler.updateAsset(Trigger.newMap);
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        AssetWarrantyTriggerHandler.updateWarrantyStatusAndAssetType(trigger.new);
    }

}