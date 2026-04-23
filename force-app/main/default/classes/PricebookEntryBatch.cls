global class PricebookEntryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    
    private Set<String> processedProducts = new Set<String>();
    //private Set<String> matprocessedProducts = new Set<String>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all active Product2 records that have a ProductCode
        return Database.getQueryLocator('SELECT Id, ProductCode,Item_Group_Text__c,Item_Group__c,Item_Group__r.Item_Group_Code__c, Sales_Organizations__r.Sales_Org_Code__c,Distribution_Channel__r.Distribution_Code__c FROM Product2 WHERE ProductCode != NULL');
    }

    global void execute(Database.BatchableContext BC, List<Product2> productList) {
        /*for (Product2 product : productList) {
            if (!processedProducts.contains(product.ProductCode)) {
                try {
                    // Call the API for each unique ProductCode
                    if(product.Sales_Organizations__r.Sales_Org_Code__c =='1000'){
                        IntegrationHandler.getPriceList(product.ProductCode, product.Sales_Organizations__r.Sales_Org_Code__c, product.Distribution_Channel__r.Distribution_Code__c);
                        processedProducts.add(product.ProductCode);
                    }else if(product.Sales_Organizations__r.Sales_Org_Code__c =='4000' && product.Item_Group_Text__c!=null){
                        IntegrationHandler.getMaterialPriceList(product.Sales_Organizations__r.Sales_Org_Code__c, product.Distribution_Channel__r.Distribution_Code__c,product.Item_Group_Text__c);
                        
                    }
                    
                    
                    // Adding a small delay to avoid hitting API limits (optional)
                    System.debug('API Called for Product: ' + product.ProductCode);
                    
                } catch (Exception e) {
                    System.debug('Error processing product: ' + product.ProductCode + ' - ' + e.getMessage());
                }
            }
        }*/
        for (Product2 product : productList) {
            if (!processedProducts.contains(product.ProductCode)) {
                processedProducts.add(product.ProductCode);
            }
        }
        sapComDocumentSapRfcFunctions.getPriceList(processedProducts,'1000','10');
       
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch execution completed. Processed ' + processedProducts.size() + ' unique products.');
    }
}