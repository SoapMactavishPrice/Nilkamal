trigger CaseTrigger on Case (before insert, after insert, before update, after update) {

    if(Trigger.isBefore && Trigger.isInsert) {
        //CaseTriggerHandlerWithoutSharing.getAssetDetailsByCaseIds(Trigger.new);
        CaseTriggerHandlerWithoutSharing.preventDuplicateCaseOnAsset(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        CaseTriggerHandler.checkForReturnableQuotes(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.trackTechnicalSupportHistory(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.preventCaseAssignmentIfResourceOnLeave(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.preventCaseClose(Trigger.new, Trigger.oldMap); // 26/08
        CaseTriggerHandler.trackStageDays(Trigger.new, Trigger.oldMap); // 27/01
    }

    if(Trigger.isBefore && Trigger.isDelete) {

    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseTriggerHandler.updateCaseType(Trigger.new);
        CaseTriggerHandler.assignEntitlementProcess(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.updateCaseAssignedDate(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.updateCaseTerritoryAndPincode(Trigger.new);
        // CaseTriggerHandler.customCaseAssignmentByTerritory(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.customCaseAssignmentByPincode(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.rollUpVisitCountToActiveAMCOrWarranty(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.mapServiceResourceFromOwner(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        CaseTriggerHandler.createWorkOrders(Trigger.new);
        CaseTriggerHandler.submitCaseForApprovalIfCustomerIsBlocked(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.notifyUserWhenCaseIsAssignedOrTransferredOnInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        CaseTriggerHandler.notifyUserWhenCaseIsAssignedOrTransferredOnUpdate(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.onOwnerChangePersistSharing(Trigger.new, Trigger.oldMap);
        CaseTriggerHandlerWithoutSharing.checkoutAppointmentsWhenCaseIsTransferred(Trigger.new, Trigger.oldMap);
        for(case cs: trigger.new) {
            if(trigger.OldMap.get(cs.Id).Is_Escalated__c != cs.Is_Escalated__c && cs.Is_Escalated__c == true) {
                CaseTriggerHandler.sendEmailAndCustomNotification_Escalation(cs.Id, cs.OwnerId, cs.Type);
            }
        }
        System.debug('CaseTrigger fired - after update');
        CaseTriggerHandler.handleOwnerChange(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.deleteAssetManualShare(Trigger.new, Trigger.oldMap);
    }

    if(Trigger.isAfter && Trigger.isDelete) {

    }

    if(Trigger.isAfter && Trigger.isUndelete) {

    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseTriggerHandlerWithoutSharing.updateWorkOrderOwner(Trigger.new, Trigger.oldMap);
        CaseTriggerHandler.updateActivityDateToAsset(Trigger.new, Trigger.oldMap);
    }

}