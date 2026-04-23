trigger SpareMaterialRequestTrigger on Spare_Material_Request__c(before insert, before update ) {

    if(Trigger.isBefore && Trigger.isInsert) {
        for(Spare_Material_Request__c smr : Trigger.new) {
            smr.Material_Required_Date__c = System.today();
        }
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        for(Spare_Material_Request__c smr : Trigger.new) {
            if(smr.Spare_Material_Code__c != null && smr.Spare_Material_Code__c != Trigger.oldMap.get(smr.Id).Spare_Material_Code__c) {
                if(smr.Status__c != 'Completed') {
                    smr.Status__c = 'Completed';
                }
                if(smr.Request_Completed_Date__c == null) {
                    smr.Request_Completed_Date__c = System.today();
                }
            }
        }
    }

    Set<Id> caseIds = new Set<Id>();
    for (Spare_Material_Request__c smr : Trigger.new) {
        if (smr.Case__c != null) {
            caseIds.add(smr.Case__c);
        }
    }

    if (!caseIds.isEmpty()) {
        Map<Id, String> caseIdToNumberMap = new Map<Id, String>();
        for (Case c : [
            SELECT Id, CaseNumber
            FROM Case
            WHERE Id IN :caseIds
        ]) {
            caseIdToNumberMap.put(c.Id, c.CaseNumber);
        }

        for (Spare_Material_Request__c smr : Trigger.new) {
            if (smr.Case__c != null && caseIdToNumberMap.containsKey(smr.Case__c)) {
                smr.Case_Name_Text__c = caseIdToNumberMap.get(smr.Case__c);
            } else {
                smr.Case_Name_Text__c = null;
            }
        }
    }

   
}