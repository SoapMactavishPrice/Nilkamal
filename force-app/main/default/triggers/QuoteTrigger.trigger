trigger QuoteTrigger on Quote (before insert, after insert, before update, after update) {
    
    if(Trigger.isBefore && Trigger.isInsert) {
        QuoteTriggerHandler.updateOrderType(Trigger.new);
        UpdateQuoteTriggerHandler.UpdateDefaultValues(Trigger.new);
        
        List<Quote> newQuote=new List<Quote>();
        for(Quote eachQuote : Trigger.new) {
            if(eachQuote.Parent_Quote_Version__c == null) {
                newQuote.add(eachQuote);
            }
        }
        if(newQuote.size() > 0) {
            QuoteTriggerHandler.assignDocumentNumber(newQuote);
        }
        
        QuoteTriggerHandler.setCoordinatorFromServiceResource(Trigger.new);
    }
    
    if(Trigger.isBefore && Trigger.isUpdate) {
        QuoteTriggerHandler.setExternalId(Trigger.new);
        QuoteTriggerHandler.updateOwnerToEnquiry(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.updateContactDetailsByContactId(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.lockQuoteFields(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.validateReturnableReceived(Trigger.new, Trigger.oldMap);
        //QuoteTriggerHandler.updateOrderType(Trigger.new); //commented by shashank
        QuoteTriggerHandler.validateSalesGroup(Trigger.new);
    }
    
    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        UpdateQuoteTriggerHandler.updateQuoteAddress(Trigger.new, Trigger.oldMap);
        UpdateQuoteTriggerHandler.handleFOCPaymentTerms(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.checkApprovalRequired(Trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate) {
        QuoteTriggerHandler.updateAssetAMC(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.UpdateEnquiry(Trigger.new);
        QuoteTriggerHandler.UpdateDiscount(Trigger.new,Trigger.oldMap);
        QuoteTriggerHandler.notifyCoordinatorForFailedOrders(Trigger.new, Trigger.oldMap);
        
        QuoteTriggerHandler.updateCaseStatus(Trigger.new, Trigger.oldMap);
        QuoteTriggerHandler.sendReturnableReceivedNotification(Trigger.new, Trigger.oldMap);
        
    }
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        QuoteTriggerHandler.updateActivityDateToAsset(Trigger.new);
    }
    
}