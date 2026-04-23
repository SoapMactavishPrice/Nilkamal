trigger UpdateQuoteTrigger on Quote (before insert, before update) {

    if (Trigger.isBefore && Trigger.isInsert) {
        // UpdateQuoteTriggerHandler.UpdateDefaultValues(Trigger.new);
    }

    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        // UpdateQuoteTriggerHandler.updateQuoteAddress(Trigger.new, Trigger.oldMap);
        // UpdateQuoteTriggerHandler.handleFOCPaymentTerms(Trigger.new, Trigger.oldMap);
    }

}