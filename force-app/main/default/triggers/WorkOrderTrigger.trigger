trigger WorkOrderTrigger on Work_Order__c (after insert, after update, before insert) {

    if(Trigger.isBefore && Trigger.isInsert) {
        WorkOrderHandler.createWorkOrderFromCase(Trigger.New);
    }

    if(Trigger.isBefore && Trigger.isUpdate) {

    }

    if(Trigger.isBefore && Trigger.isDelete) {

    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

    }



    if(Trigger.isAfter && Trigger.isInsert) {
        WorkOrderHandler.manageSharingOnInsert(Trigger.New);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {

    }

    if(Trigger.isAfter && Trigger.isDelete) {

    }

    if(Trigger.isAfter && Trigger.isUndelete) {

    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        WorkOrderHandler.rollUpOwnerToCaseTeam(Trigger.New, Trigger.oldMap);
    }

}