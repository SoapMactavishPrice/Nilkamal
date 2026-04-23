trigger AccountTrigger on Account (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.updatePriceList(Trigger.new);
    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.handleTerritoryUpdate(Trigger.new, Trigger.isInsert, Trigger.isUpdate);
        AccountTriggerHandler.updatePinCode(Trigger.new, Trigger.oldMap);
    }

}