trigger PricebookTrigger on Pricebook2(after insert, after update) {

    if(Trigger.isAfter && Trigger.isInsert) {
        PricebookTriggerHandler.copyStandardPricebookEntries(Trigger.new);
    }

}