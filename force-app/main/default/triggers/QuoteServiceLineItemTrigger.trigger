trigger QuoteServiceLineItemTrigger on Quote_Service_Line_Item__c (before insert,before update, after insert, after update, after delete, after undelete,before delete) {

    if(Trigger.isBefore && Trigger.isDelete){
        QuoteServiceLineItemTriggerHandler.unlinkServiceRequests(Trigger.old);
    }
    if(Trigger.isBefore){
        if((Trigger.isInsert || Trigger.isUpdate)){
              QuoteServiceLineItemTriggerHandler.UpdateGST(Trigger.new);
        }
      
        if(Trigger.isUpdate) {
            QuoteTriggerHandler.lockQuoteServiceLineItems(Trigger.new, Trigger.oldMap);
            QuoteServiceLineItemTriggerHandler.UpdateDiscountValue(Trigger.new,Trigger.oldMap);

        } 
    }
    
    else {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
             System.debug('Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete');
            QuoteServiceLineItemTriggerHandler.updateQuoteSummary(Trigger.new, Trigger.old);
        }
        else if (Trigger.isDelete) {
            QuoteServiceLineItemTriggerHandler.updateQuoteSummary(null, Trigger.old);
        }
    }
    
     
}