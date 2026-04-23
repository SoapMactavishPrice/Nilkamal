trigger QuoteLineItemTrigger on QuoteLineItem (before insert, before update, before delete) {
    if(Trigger.isBefore && Trigger.isUpdate) {
        QuoteTriggerHandler.lockQuoteLineItems(Trigger.new, Trigger.oldMap);
        QuoteLineItemTriggerHandler.UpdatePrice(Trigger.new, Trigger.oldMap);
        QuoteLineItemTriggerHandler.UpdateDiscountValue(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.IsInsert) {
        QuoteLineItemTriggerHandler.UpdateHSNCodeGST(Trigger.new, Trigger.oldMap);
    }

    // if (Trigger.isAfter) {
    //     List<Id> quoteIds = new List<Id>();
    //     for (QuoteLineItem qli : Trigger.new){
    //         if(qli.QuoteId != null) {
    //             quoteIds.add(qli.QuoteId);
    //         }
    //     }
    //     QuoteLineItemTriggerHandler.overrideGrandPriceTotal(quoteIds);
    // }

    if(Trigger.isBefore && Trigger.isDelete) {
        QuoteLineItemTriggerHandler.unlinkSpareRequests(Trigger.old);
    }
}