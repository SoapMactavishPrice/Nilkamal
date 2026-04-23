public with sharing class SpareRequestController {
    @AuraEnabled(cacheable=true)
    public static List<Spare_Return__c> getSpareReturns() {
        return [SELECT Id, Name, Item_Description__c, CreatedDate FROM Spare_Return__c LIMIT 100];
    }

    @AuraEnabled
    public static void updateSpareReturns(List<Spare_Return__c> spareReturns) {
        try {
            update spareReturns;
        } catch (Exception e) {
            throw new AuraHandledException('Error updating records: ' + e.getMessage());
        }
    }
}