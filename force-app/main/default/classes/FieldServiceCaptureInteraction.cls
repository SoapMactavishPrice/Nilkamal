public without sharing class FieldServiceCaptureInteraction {
    
    @AuraEnabled
    public static List<Service_Appointment__c> getServiceAppointmentsByServiceAppointmentId(String serviceAppointmentId) {
        try {
            Service_Appointment__c serviceAppointment = [SELECT id,Case__c,WO_Type__c,Case__r.AccountId,Due_Date__c FROM Service_Appointment__c
                                                        WHERE Id = :serviceAppointmentId
                                                        LIMIT 1];
            List<Service_Appointment__c> serviceAppointments = [SELECT Id, Name, Case__c,Case__r.AccountId,Scheduled_End__c,Status__c,Work_Order__c,Due_Date__c
                                                                FROM Service_Appointment__c
                                                                WHERE Case__c = :serviceAppointment.Case__c
                                                                AND Due_Date__c != null
                                                                AND Due_Date__c < :serviceAppointment.Due_Date__c ORDER BY Due_Date__c DESC LIMIT 3];
            return serviceAppointments;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Service_Appointment__c getServiceAppointment(String recordId) {
        Service_Appointment__c sa = [
            SELECT Id,Name,Account__c,Contact__c,Check_In__c,Meeting_Interaction_Note__c,WO_Type__c,Status__c,Case__r.Status,Due_Date__c
            FROM Service_Appointment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return sa;
    }
    
    
    @AuraEnabled
    public static List<Work_Order_Checklist__c> getChecklistData(String workOrderId) {
        try {
            system.debug('workOrderId'+workOrderId);
            Work_Order__c workOrder = [SELECT Id, Case__r.Asset.Product2.Material_Group_6__c FROM Work_Order__c WHERE Id = :workOrderId];
            
            Map<Id, Work_Order_Checklist__c> workOrderChecklistMapByChecklistMaster = new Map<Id, Work_Order_Checklist__c>();
            List<Work_Order_Checklist__c> workOrderChecklists = [SELECT Id, Check_Point__c, Checklist_Category__c, Checklist_Master__c, Observation__c
                                                                FROM Work_Order_Checklist__c
                                                                WHERE Work_Order__c =: workOrderId
                                                                ORDER BY Checklist_Category__c, Check_Point__c
                                                                ];
            
            system.debug('workOrderChecklists'+workOrderChecklists.size());
            for(Work_Order_Checklist__c workOrderChecklist : workOrderChecklists) {
                workOrderChecklistMapByChecklistMaster.put(workOrderChecklist.Checklist_Master__c, workOrderChecklist);
            }
            
            String materialGroup = workOrder.Case__r?.Asset?.Product2?.Material_Group_6__c;
            
            List<Checklist_Master__c> checklistMasterData = new List<Checklist_Master__c>();
            System.debug('Material Group: ' + materialGroup);      // Only query Checklist_Master__c if materialGroup is not null
            if (String.isNotBlank(materialGroup)) {
                checklistMasterData = [SELECT Id, Check_Point__c, Checklist_Category__c
                                      FROM Checklist_Master__c
                                      WHERE IsActive__c = TRUE AND Material_Group__c INCLUDES (:materialGroup)];
            }
            for(Checklist_Master__c checklistMaster : checklistMasterData) {
                if(!workOrderChecklistMapByChecklistMaster.containsKey(checklistMaster.Id)) {
                    workOrderChecklistMapByChecklistMaster.put(checklistMaster.Id, new Work_Order_Checklist__c(
                        Checklist_Master__c = checklistMaster.Id,
                    Checklist_Category__c = checklistMaster.Checklist_Category__c,
                    Check_Point__c = checklistMaster.Check_Point__c,
                    Work_Order__c = workOrderId
                        ));
                }
            }
            return workOrderChecklistMapByChecklistMaster.values();
        } catch (Exception e) {
            system.debug(e.getlineNumber()+ ' + '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static void saveChecklistData(Map<String, Object> formData, List<Work_Order_Checklist__c> workOrderChecklist, Id serviceAppointmentId) {
        try {
            if (formData != null && !formData.isEmpty()) {
                Service_Appointment__c serviceAppointment = new Service_Appointment__c();
                serviceAppointment.Id = formData.get('recordId') != null ? (String) formData.get('recordId') : null;
                serviceAppointment.Check_In__c = formData.containsKey('Check_In__c') ? (String) formData.get('Check_In__c') : null;
                serviceAppointment.Account__c = formData.containsKey('Account__c') ? (String) formData.get('Account__c') : null;
                serviceAppointment.Contact__c = formData.containsKey('Contact__c') ? (String) formData.get('Contact__c') : null;
                serviceAppointment.Meeting_Interaction_Note__c = formData.containsKey('Additional_Information__c') ? (String) formData.get('Additional_Information__c') : null;
                update serviceAppointment;
            }
            // if (workOrderChecklist != null && !workOrderChecklist.isEmpty()) {
                //     upsert workOrderChecklist;
            // }
            if (workOrderChecklist != null && !workOrderChecklist.isEmpty()) {
                Set<Id> checklistIds = new Set<Id>();
                for (Work_Order_Checklist__c checklist : workOrderChecklist) {
                    if (checklist.Id != null) {
                        checklistIds.add(checklist.Id);
                    }
                    checklist.Service_Appointment__c = serviceAppointmentId;
                }
                
                // Query only existing records
                Map<Id, Work_Order_Checklist__c> existingRecords = new Map<Id, Work_Order_Checklist__c>(
                    [SELECT Id FROM Work_Order_Checklist__c WHERE Id IN :checklistIds]
                    );
                
                List<Work_Order_Checklist__c> recordsToUpdate = new List<Work_Order_Checklist__c>();
                List<Work_Order_Checklist__c> recordsToInsert = new List<Work_Order_Checklist__c>();
                
                for (Work_Order_Checklist__c checklist : workOrderChecklist) {
                    if (checklist.Id != null && existingRecords.containsKey(checklist.Id)) {
                        recordsToUpdate.add(checklist);
                    } else {
                        recordsToInsert.add(checklist);
                    }
                }
                
                // Perform DML operations
                if (!recordsToUpdate.isEmpty()) {
                    update recordsToUpdate;
                }
                if (!recordsToInsert.isEmpty()) {
                    insert recordsToInsert;
                }
            }
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage() +e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}