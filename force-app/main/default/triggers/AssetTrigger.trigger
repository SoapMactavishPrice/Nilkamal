trigger AssetTrigger on Asset (before insert, after insert, before update, after update) {

    if (Trigger.isInsert) {
        if (Trigger.isBefore) {
            AssetTriggerHandler.updateAssetBusinessVertical(Trigger.new);
        }
        if (Trigger.isAfter) {
            AssetTriggerHandler.createCase(Trigger.new);
            AssetTriggerHandler.notifyServiceHead(Trigger.new);
        }
    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        if (Trigger.isUpdate) {
            //AssetTriggerHandler.updateAssetType(Trigger.newMap);
        }
        AssetTriggerHandler.updateAssetSerialNumber(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        // AssetTriggerHandler.pullAddressDetails(Trigger.new, Trigger.oldMap);
        AssetTriggerHandlerWithoutSharing.validateBeforeAssetTransfer(Trigger.new, Trigger.oldMap);
        AssetTriggerHandler.updateShipToPinCode(Trigger.new, Trigger.oldMap);
        AssetTriggerHandler.updatePincodeFieldsBasedOnOwner(Trigger.new, Trigger.oldMap);
        AssetTriggerHandler.updateAssetType(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        AssetTriggerHandler.handleAssetSharing(Trigger.new, Trigger.oldMap);
        AssetTriggerHandlerWithoutSharing.pushOwnerToWarrantyAndAMC(Trigger.new, Trigger.oldMap);
        AssetTriggerHandler.notifyServiceHeadOnFieldChange(Trigger.new, Trigger.oldMap);
    }

}