trigger InvoiceTrigger on Invoice__c(before insert, before update, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        InvoiceTriggerHandler.updateExternalId(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        InvoiceTriggerHandler.createAssets(Trigger.new);
        InvoiceTriggerHandler.updateInvoiceCountToQuote(Trigger.new);
        InvoiceTriggerHandler.createSpareInstallationCases(Trigger.new);
    }
    if ((Trigger.isBefore && Trigger.isInsert) || (Trigger.isAfter && Trigger.isUndelete)) {
        // InvoiceTriggerHandler.insertUndeleteFlowToUpdateSalesAchieved(Trigger.new, Trigger.isInsert);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        // InvoiceTriggerHandler.updateFlowToUpdateSalesAchieved(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        // InvoiceTriggerHandler.deleteFlowToUpdateSalesAchieved(Trigger.oldMap);
    }

}