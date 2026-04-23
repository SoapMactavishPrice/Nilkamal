global class OutstandingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, ProductCode FROM Product2 WHERE ProductCode != NULL LIMIT 1');
    }
    
     global void execute(Database.BatchableContext BC, List<Product2> productList) {
        //  IntegrationHandler.getReturnableSample();
         // Just initiating the first queueable with default offset
         System.enqueueJob(new FetchOutstandingQueuable(1));
     }
     global void finish(Database.BatchableContext BC) {
        System.debug('Batch execution completed. Processed ');
    }
}