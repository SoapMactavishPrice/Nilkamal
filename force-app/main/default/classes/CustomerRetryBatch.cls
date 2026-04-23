global class CustomerRetryBatch implements Database.Batchable<SObject> {

    String query;

    public CustomerRetryBatch() {}

    public CustomerRetryBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        if(String.isNotBlank(query)) {
            return Database.getQueryLocator(query);
        }
        return Database.getQueryLocator([
            SELECT Id, Request__c, Exception_Description__c
            FROM API_log__c
            WHERE Status__c = 'Failed' AND Log_Name__c = 'Customer Master'
            ORDER BY CreatedDate ASC
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<API_log__c> logsToUpdate = new List<API_log__c>();

        for(SObject sObj : scope) {
            API_log__c log = (API_log__c) sObj;
            System.debug('Log ------------> ' + log.Id + ' - ' + log.Request__c);

            if(log.Exception_Description__c.contains('Illegal unquoted character')) {
                continue;
            }

            Savepoint sp = Database.setSavepoint();

            try {
                RestRequest req = new RestRequest();
                req.requestUri = log.Request__c;
                req.httpMethod = 'POST';
                req.requestBody = Blob.valueOf(log.Request__c.subStringAfter('Total Size = '));

                RestResponse res = new RestResponse();
                RestContext.request = req;
                RestContext.response = res;

                List<IntegrationRequestBuilder.CustomerWrapper> jData = IntegrationRequestBuilder.customerMasterParse(log.Request__c.subStringAfter('Total Size = '));
                IntegrationRequestBuilder.CustomerWrapper firstItem = jData[0];

                if(Test.isRunningTest()) {
                    res.responseBody = Blob.valueOf('{"Status": "success"}');
                }
                else {
                    CustomerMasterAPI.processCustomerMaster();
                }

                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.responseBody.toString());

                if(response.get('Status') == 'success' || response.get('Status') == 'Success') {
                    String customerCode = firstItem.CUSTOMER_NO;
                    Account account = [SELECT Id FROM Account WHERE SAP_Customer_code__c = :customerCode LIMIT 1];

                    log.Status__c = 'Success';
                    log.Exception_Description__c = null;
                    log.Customer__c = account.Id;

                    logsToUpdate.add(log);
                }
            } catch (Exception e) {
                System.debug('Error ------------> ' + e.getMessage());
                Database.rollback(sp);
            }
        }

        if(!logsToUpdate.isEmpty()) {
            update logsToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Add any post-processing here (e.g., email notifications)
    }

}