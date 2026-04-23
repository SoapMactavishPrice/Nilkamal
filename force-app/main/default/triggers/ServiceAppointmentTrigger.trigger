trigger ServiceAppointmentTrigger on Service_Appointment__c (before insert, after insert, before update, after update) {

    if(Trigger.isBefore && Trigger.isInsert) {

    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        ServiceAppointmentHandler.updateStatus(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isBefore && Trigger.isDelete) {

    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ServiceAppointmentHandlerWithoutSharing.validateServiceAppointmentForDuplicate(Trigger.new);
        ServiceAppointmentHandler.generateUniqueKey(Trigger.new);
    }



    if(Trigger.isAfter && Trigger.isInsert) {
        ServiceAppointmentHandler.manageSharingOnInsert(Trigger.New);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        ServiceAppointmentHandler.updateGeoLocation(Trigger.New, Trigger.oldMap);
        ServiceAppointmentHandler.updateAccountInAsset(Trigger.New, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete) {

    }

    if(Trigger.isAfter && Trigger.isUndelete) {

    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        ServiceAppointmentHandler.rollUpOwnerToCaseTeam(Trigger.New, Trigger.oldMap);
    }

}