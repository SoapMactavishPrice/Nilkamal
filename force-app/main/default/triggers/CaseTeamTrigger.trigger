trigger CaseTeamTrigger on Case_Team__c (before insert, before update, before delete, after insert, after update) {

    if(Trigger.isBefore && Trigger.isInsert) {

    }

    if(Trigger.isBefore && Trigger.isUpdate) {

    }

    if(Trigger.isBefore && Trigger.isDelete) {
        CaseTeamHandler.manageSharingOnDelete(Trigger.Old);
    }

    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        CaseTeamHandler.manageSharingOnInsertUpdate(Trigger.New, Trigger.oldMap);
    }



    if(Trigger.isAfter && Trigger.isInsert) {

    }

    if(Trigger.isAfter && Trigger.isUpdate) {

    }

    if(Trigger.isAfter && Trigger.isDelete) {

    }

    if(Trigger.isAfter && Trigger.isUndelete) {

    }

    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            CaseTeamHandler.handleCaseTeamChange(Trigger.new, Trigger.oldMap);
        }
    }

}