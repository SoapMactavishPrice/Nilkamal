public with sharing class FieldsServiceEditSpareRequest {

    @AuraEnabled
    public static String getStatusList(){
        List<Map<String,String>> pickListValuesList= new List<Map<String,String>>();
        Schema.DescribeFieldResult fieldResult = Spare_Request__c.Spare_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            Map<String,String> mp=new Map<String,String>();
            mp.put('label',pickListVal.getLabel());
            mp.put('value',pickListVal.getValue());
            pickListValuesList.add(mp);
        }
        return JSON.serialize(pickListValuesList);
    }

    @AuraEnabled
    public static List<Spare_Request__c> getSpareRequestsByWorkOrder(String workOrderId) {
        try {
            return [SELECT Id,Category__c,OEM_Material_Code__c,Warranty_Period__c,Number_of_PM_Visit__c,Number_of_Breakdown_Visit__c, Name,Work_Order__c,Work_Order__r.Name,Quantity_Required__c,Billed_Value__c,Total_Value__c,Item_Master__c,Spare_Status__c,Item_Description__c,
                    Reason_for_Spare_Request__c,Billing_Type__c,Item_Master__r.HSN_Code__r.Name , Item_Master__r.Warranty__c
                    FROM Spare_Request__c
                    WHERE Work_Order__c = :workOrderId AND Quote__c = null
                    AND Quote_Line_Item__c = null];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching spare requests: ' + e.getMessage());
        }
    }

    // @AuraEnabled
    // public static void saveSpareRequestChanges(List<Spare_Request__c> spareRequests) {
    //     try {
    //         update spareRequests;
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Error saving spare requests: ' + e.getMessage());
    //     }
    //     try {
    //     Database.SaveResult[] results = Database.update(spareRequests, false);

    //     for (Database.SaveResult result : results) {
    //         if (result.isSuccess()) {
    //             System.debug('Successfully saved record: ' + result.getId());
    //         } else {
    //             for (Database.Error err : result.getErrors()) {
    //                 System.debug('Error saving record: ' + err.getMessage());
    //             }
    //         }
    //     }
    // } catch (Exception e) {
    //     throw new AuraHandledException('Error saving spare requests: ' + e.getMessage());
    // }
    // }

    @AuraEnabled
    public static void deleteSpareRequest(String recordId) {
        try {
            delete [SELECT Id FROM Spare_Request__c WHERE Id = :recordId];
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting record: ' + e.getMessage());
        }
    }

       @AuraEnabled
    public static void saveSpareRequestChanges(List<Spare_Request__c> spareRequests) {
        try {
            update spareRequests;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving records: ' + e.getMessage());
        }
    }
}