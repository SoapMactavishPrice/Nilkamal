global class PricebookEntryBatchForMaterialGrp implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    
    private Set<String> processedProducts = new Set<String>();
    private Set<String> matprocessedProducts = new Set<String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all active Product2 records that have a ProductCode
        return Database.getQueryLocator('SELECT Id, ProductCode,Item_Group__c,Item_Group__r.Item_Group_Code__c FROM Product2 WHERE ProductCode != NULL AND Item_Group__c!=null');
    }

    global void execute(Database.BatchableContext BC, List<Product2> productList) {
        for (Product2 product : productList) {
            if(product.Item_Group__c!=null){
            	if (!matprocessedProducts.contains(product.Item_Group__c)) {
                try {
                    // Call the API for each unique ProductCode
                    IntegrationHandler.getMaterialPriceList('4000','10',product.Item_Group__r.Item_Group_Code__c);
                    matprocessedProducts.add(product.Item_Group__c);
                    
                    // Adding a small delay to avoid hitting API limits (optional)
                    System.debug('API Called for Item_Group__c: ' + product.Item_Group__c);
                    
                } catch (Exception e) {
                    System.debug('Error processing Item_Group__c: ' + product.Item_Group__c + ' - ' + e.getMessage());
                }
            }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch execution completed. Processed ' + processedProducts.size() + ' unique products.');
    }
}