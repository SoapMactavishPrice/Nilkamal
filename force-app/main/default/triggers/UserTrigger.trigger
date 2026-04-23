trigger UserTrigger on User (before insert, before update, after insert, after update) {

    if(Trigger.isBefore) {
        for(User u : Trigger.new) {
            u.Phone = u.MobilePhone;
        }
    }


    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            UserTriggerHandler.createServiceResourcesAndHours(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            UserTriggerHandler.updateServiceResources(Trigger.new, Trigger.oldMap);
        }
    }

}