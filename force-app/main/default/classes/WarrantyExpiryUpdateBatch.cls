public with sharing class WarrantyExpiryUpdateBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c
            FROM Asset_Warranty__c
            WHERE Warranty_End_Date__c = :System.today().addDays(-1)
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Asset_Warranty__c> scope) {
        for (Asset_Warranty__c record : scope) {
            record.Asset_Warranty_PO_Status__c = 'Expired';
        }
        update scope;
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Add logic to send notifications or log completion
    }

}