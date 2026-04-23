global class PricebookEntryBatchProdPrice4000 implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    
    private Set<String> processedProducts = new Set<String>();
    //private Set<String> matprocessedProducts = new Set<String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all active Product2 records that have a ProductCode
        return Database.getQueryLocator('SELECT Id, ProductCode,Item_Group_Text__c,Item_Group__c,Item_Group__r.Item_Group_Code__c, Sales_Organizations__r.Sales_Org_Code__c,Distribution_Channel__r.Distribution_Code__c FROM Product2 WHERE ProductCode != NULL');
    }

    global void execute(Database.BatchableContext BC, List<Product2> productList) {
        for (Product2 product : productList) {
            if (!processedProducts.contains(product.ProductCode)) {
                processedProducts.add(product.ProductCode);
            }
        }
        sapComDocumentSapRfcFunctions.getPriceList(processedProducts,'4000','10');
       
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch execution completed. Processed ' + processedProducts.size() + ' unique products.');
    }
}