public class ServiceResourceLeaveHandler {
    public static void processActiveLeaves(List<Service_Resource_Leave__c> leaveList) {
        Set<Id> serviceResourceIds = new Set<Id>();

        for(Service_Resource_Leave__c leave : leaveList) {
            if ((leave.Is_Active__c || leave.Is_Leave_Active_or_Planned__c) && leave.Service_Resource__c != null) {
                serviceResourceIds.add(leave.Service_Resource__c);
            }
        }

        if (serviceResourceIds.isEmpty()) return;

        // Fetch active or planned leaves
        List<Service_Resource_Leave__c> allRelevantLeaves = [
            SELECT Id, Service_Resource__c, Start_Date__c, End_Date__c, Is_Active__c, Is_Leave_Active_or_Planned__c
            FROM Service_Resource_Leave__c
            WHERE Service_Resource__c IN :serviceResourceIds
            AND (Is_Active__c = true OR Is_Leave_Active_or_Planned__c = true)
            ORDER BY Start_Date__c ASC
        ];

        Map<Id, Service_Resource_Leave__c> selectedLeaveMap = new Map<Id, Service_Resource_Leave__c>();

        for (Service_Resource_Leave__c leave : allRelevantLeaves) {
            Id srId = leave.Service_Resource__c;

            // If we already chose a leave, skip unless this one is more qualified
            if (!selectedLeaveMap.containsKey(srId)) {
                selectedLeaveMap.put(srId, leave);
            } else {
                Service_Resource_Leave__c existing = selectedLeaveMap.get(srId);
                // Prefer active over planned if both exist with same date
                if (!existing.Is_Active__c && leave.Is_Active__c) {
                    selectedLeaveMap.put(srId, leave);
                }
            }
        }

        List<Service_Resource__c> srToUpdate = new List<Service_Resource__c>();

        for (Id srId : selectedLeaveMap.keySet()) {
            Service_Resource_Leave__c leave = selectedLeaveMap.get(srId);
            String leaveText;

            if (leave.Start_Date__c == leave.End_Date__c) {
                leaveText = leave.Start_Date__c.format();
            } else {
                leaveText = leave.Start_Date__c.format() + ' - ' + leave.End_Date__c.format();
            }

            srToUpdate.add(new Service_Resource__c(Id = srId, Leave__c = leaveText));
        }

        // Clear Leave__c if no active/planned leaves remain
        for (Id srId : serviceResourceIds) {
            if (!selectedLeaveMap.containsKey(srId)) {
                srToUpdate.add(new Service_Resource__c(Id = srId, Leave__c = null));
            }
        }

        if (!srToUpdate.isEmpty()) {
            update srToUpdate;
        }
    }
}