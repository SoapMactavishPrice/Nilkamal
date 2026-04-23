trigger AssetAMCTrigger on Asset_AMC__c (before insert, after insert, before update, after update, before delete) {

    if (Trigger.isBefore && (Trigger.isInsert|| Trigger.isUpdate)) {
        AssetAMCTriggerHandler.updateAMCEndDates(Trigger.new);
        AssetAMCTriggerHandler.updateExternalId(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        AssetAMCTriggerHandler.createAssetVisit(Trigger.new);
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        AssetAMCTriggerHandler.updateAMCDetailsOnAsset(Trigger.new, Trigger.oldMap);
        AssetAMCTriggerHandler.updateAMCStatusAndAssetType(Trigger.new);
        AssetAMCTriggerHandler.markLatestAMC(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete) {
        AssetAMCTriggerHandler.updateAMCDetailsOnAsset(Trigger.new, Trigger.oldMap);
    }

}