trigger ServiceResourceLeaveTrigger on Service_Resource_Leave__c (after insert, after update, after delete) {

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        ServiceResourceLeaveHandler.processActiveLeaves(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        ServiceResourceLeaveHandler.processActiveLeaves(Trigger.old);
    }

}