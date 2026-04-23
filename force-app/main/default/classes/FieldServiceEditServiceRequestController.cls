public with sharing class FieldServiceEditServiceRequestController {

    @AuraEnabled
    public static List<Service_Request__c> getServiceRequestsByWorkOrder(String workOrderId) {
        try {
            return [
                SELECT Id,Warranty_Period__c,Number_of_PM_Visit__c,Number_of_Breakdown_Visit__c, Name,Asset__c,Case__c,Work_Order__c,
                Item_Master__c,Item_Master__r.HSN_Code__r.Name,Item_Description__c,Price__c,Quantity__c,Total_Value__c
                FROM Service_Request__c
                WHERE Work_Order__c = :workOrderId AND
                Quote__c = null AND
                Quote_Line_Item__c = null
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching spare requests: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static void deleteServiceRequest(String recordId) {
        try {
            delete [SELECT Id FROM Service_Request__c WHERE Id = :recordId];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting record: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static void saveServiceRequests(List<Service_Request__c> serviceRequests) {
        try {
            update serviceRequests;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving records: ' + e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String, Map<String, Integer>> getWarrantyMapping() {
        Map<String, Map<String, Integer>> result = new Map<String, Map<String, Integer>>();
        for (Warranty_Mapping__mdt month : [
            SELECT Warranty_Period__c, Preventive_Visits__c, Breakdown_Visits__c,MG6_Descrption__c,MG6_Code__c FROM Warranty_Mapping__mdt
        ]) {
            String key = month.MG6_Code__c  + '-' + (month.Warranty_Period__c ?? 0).setScale(0);
            result.put(key,
                // Integer.valueOf(month.Warranty_Period__c),
                new Map<String, Integer>{
                    'PM' => Integer.valueOf(month.Preventive_Visits__c),
                    'BD' => Integer.valueOf(month.Breakdown_Visits__c)
                }
            );
        }
        return result;
    }

}