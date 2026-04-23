global class DeleteAllOutstandingsBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all records you want to delete
        return Database.getQueryLocator('SELECT Id FROM Customer_Outstanding__c');
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        // Delete records in scope
        if (!scope.isEmpty()) {
            delete scope;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Finished deleting Returnable Samples.');
    }
}