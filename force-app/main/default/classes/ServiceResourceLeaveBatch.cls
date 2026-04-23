global class ServiceResourceLeaveBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Service_Resource__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Service_Resource__c> srList) {
        Set<Id> srIds = new Set<Id>();
        for (Service_Resource__c sr : srList) {
            srIds.add(sr.Id);
        }

        List<Service_Resource_Leave__c> leaveList = [
            SELECT Id, Service_Resource__c, Start_Date__c, End_Date__c,
                   Is_Active__c, Is_Leave_Active_or_Planned__c
            FROM Service_Resource_Leave__c
            WHERE Service_Resource__c IN :srIds
            AND (Is_Active__c = true OR Is_Leave_Active_or_Planned__c = true)
            ORDER BY Start_Date__c ASC
        ];

        Map<Id, Service_Resource_Leave__c> nextLeaveMap = new Map<Id, Service_Resource_Leave__c>();
        Date today = Date.today();

        for (Service_Resource_Leave__c leave : leaveList) {
            // Skip expired leaves
            if (leave.End_Date__c < today) continue;

            Id srId = leave.Service_Resource__c;
            if (!nextLeaveMap.containsKey(srId)) {
                nextLeaveMap.put(srId, leave); // first valid leave is the nearest
            } else {
                Service_Resource_Leave__c existing = nextLeaveMap.get(srId);
                // Prefer active leave if same Start_Date
                if (!existing.Is_Active__c && leave.Is_Active__c) {
                    nextLeaveMap.put(srId, leave);
                }
            }
        }

        List<Service_Resource__c> updateList = new List<Service_Resource__c>();

        for (Service_Resource__c sr : srList) {
            if (nextLeaveMap.containsKey(sr.Id)) {
                Service_Resource_Leave__c leave = nextLeaveMap.get(sr.Id);
                String formattedLeave;
                if (leave.Start_Date__c == leave.End_Date__c) {
                    formattedLeave = leave.Start_Date__c.format();
                } else {
                    formattedLeave = leave.Start_Date__c.format() + ' to ' + leave.End_Date__c.format();
                }
                sr.Leave__c = formattedLeave;
            } else {
                sr.Leave__c = null;
            }
            updateList.add(sr);
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}