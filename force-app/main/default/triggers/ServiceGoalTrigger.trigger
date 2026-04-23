trigger ServiceGoalTrigger on Service_Goal__c (before insert, after insert, before update, after update) {

    if(Trigger.isAfter  && Trigger.isInsert) {
        Set<Id> serviceResourceIds = new Set<Id>();

        for(Service_Goal__c serviceGoal : Trigger.new) {
            serviceResourceIds.add(serviceGoal.Service_Resource__c);
        }

        Map<Id, Service_Resource__c> serviceResourceMap = new Map<Id, Service_Resource__c>([SELECT Id, User__c FROM Service_Resource__c WHERE Id IN :serviceResourceIds]);

        List<Service_Goal__Share> serviceGoalShareList = new List<Service_Goal__Share>();
        for(Service_Goal__c serviceGoal : Trigger.new) {
            if(serviceGoal.Service_Resource__c == null) {
                continue;
            }
            Service_Goal__Share serviceGoalShare = new Service_Goal__Share();
            serviceGoalShare.ParentId = serviceGoal.Id;
            serviceGoalShare.UserOrGroupId = serviceResourceMap.get(serviceGoal.Service_Resource__c).User__c;
            serviceGoalShare.AccessLevel = 'Read';
            serviceGoalShare.RowCause = Schema.Service_Goal__Share.RowCause.Manual;
            serviceGoalShareList.add(serviceGoalShare);
        }

        Database.insert(serviceGoalShareList, false);
    }


    if(Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> serviceResourceIds = new Set<Id>();
        Set<Id> serviceGoalIds = new Set<Id>();

        for(Service_Goal__c serviceGoal : Trigger.old) {
            // if(serviceGoal.Service_Resource__c != Trigger.newMap.get(serviceGoal.Id).Service_Resource__c) {
                serviceResourceIds.add(serviceGoal.Service_Resource__c);
                serviceGoalIds.add(serviceGoal.Id);
            // }
        }

        delete [SELECT Id FROM Service_Goal__Share WHERE ParentId IN :serviceGoalIds AND RowCause = 'Manual'];

        Map<Id, Service_Resource__c> serviceResourceMap = new Map<Id, Service_Resource__c>([SELECT Id, User__c FROM Service_Resource__c WHERE Id IN :serviceResourceIds]);

        List<Service_Goal__Share> serviceGoalShareList = new List<Service_Goal__Share>();
        for(Service_Goal__c serviceGoal : Trigger.new) {
            if(serviceGoal.Service_Resource__c == null) {
                continue;
            }
            Service_Goal__Share serviceGoalShare = new Service_Goal__Share();
            serviceGoalShare.ParentId = serviceGoal.Id;
            serviceGoalShare.UserOrGroupId = serviceResourceMap.get(serviceGoal.Service_Resource__c).User__c;
            serviceGoalShare.AccessLevel = 'Read';
            serviceGoalShare.RowCause = Schema.Service_Goal__Share.RowCause.Manual;
            serviceGoalShareList.add(serviceGoalShare);
        }

        List<Database.SaveResult> result = Database.insert(serviceGoalShareList, false);
        for(Database.SaveResult saveResult : result) {
            System.debug(saveResult);
        }
    }


    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        ServiceGoalTriggerHandler.updateStartAndEndDate(Trigger.new, Trigger.oldMap);
    }

}