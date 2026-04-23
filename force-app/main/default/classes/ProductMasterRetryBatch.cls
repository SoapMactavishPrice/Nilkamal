global class ProductMasterRetryBatch implements Database.Batchable<SObject> {

    String query;

    public ProductMasterRetryBatch() {}

    public ProductMasterRetryBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(String.isNotBlank(query)) {
            return Database.getQueryLocator(query);
        }
        return Database.getQueryLocator([
            SELECT Id, Request__c, Exception_Description__c
            FROM API_log__c
            WHERE Status__c = 'Failed' AND Log_Name__c = 'Product_Master'
            ORDER BY CreatedDate ASC
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<API_log__c> logsToUpdate = new List<API_log__c>();

        for (SObject sObj : scope) {
            API_log__c log = (API_log__c) sObj;
            System.debug('Log ------------> ' + log.Id + ' - ' + log.Request__c);

            Savepoint sp = Database.setSavepoint();

            try {
                RestRequest req = new RestRequest();
                req.requestUri = log.Request__c;
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueOf(log.Request__c);

                RestResponse res = new RestResponse();
                RestContext.request = req;
                RestContext.response = res;

                List<IntegrationRequestBuilder.ProductMasterJson> jData = IntegrationRequestBuilder.itemMasterParse(log.Request__c);
                IntegrationRequestBuilder.ProductMasterJson firstItem = jData[0];

                if(firstItem.DISTRIBUTION_CHANNEL != '10') {
                    continue;
                }

                if(Test.isRunningTest()) {
                    res.responseBody = Blob.valueOf('{"Status": "success"}');
                }
                else {
                    ProductMasterAPI.doPost();
                }

                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

                if(response.get('Status') == 'success' || response.get('Status') == 'Success') {
                    String itemCode = firstItem.ITEM_NUMBER;
                    Product2 product = [SELECT Id FROM Product2 WHERE Name = :itemCode LIMIT 1];

                    log.Status__c = 'Success';
                    log.Exception_Description__c = null;
                    log.Item_Master__c = product.Id;

                    logsToUpdate.add(log);
                }
            } catch (Exception e) {
                System.debug('Error ------------> ' + e.getMessage());
                Database.rollback(sp);
            }
        }

        if (!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing here (e.g., email notifications)
    }

}