trigger FeedItemTrigger on FeedItem (after insert, before delete) {

    if (Trigger.isAfter && Trigger.isInsert) {
        FeedItemTriggerHandler.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        FeedItemTriggerHandler.handleBeforeDelete(Trigger.old);
    }

}