global class ProductBatchWithCallout implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all active products
        return Database.getQueryLocator([
            SELECT Id, Name, ProductCode, IsActive, Sales_Organizations__r.Sales_Org_Code__c,Distribution_Channel__r.Distribution_Code__c
            FROM Product2
            WHERE IsActive = true
        ]);
	}

    global void execute(Database.BatchableContext bc, List<Product2> scope) {
        for (Product2 product : scope) {
            IntegrationHandler.getPriceList(product.ProductCode, product.Sales_Organizations__r.Sales_Org_Code__c, product.Distribution_Channel__r.Distribution_Code__c);
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch process completed.');
    }

}