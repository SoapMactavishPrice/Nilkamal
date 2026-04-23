@isTest
public class DeleteAllOutstandingsBatchTest {

    @testSetup
    static void setupData() {
        List<Customer_Outstanding__c> outstandingRecords = new List<Customer_Outstanding__c>();
        for (Integer i = 0; i < 10; i++) {
            outstandingRecords.add(new Customer_Outstanding__c(
            ));
        }
        insert outstandingRecords;
    }

    @isTest
    static void testBatchDeletesRecords() {
        Integer countBefore = [SELECT count() FROM Customer_Outstanding__c];
        System.assert(countBefore > 0, 'Test data should exist before batch runs');

        Test.startTest();
        DeleteAllOutstandingsBatch batch = new DeleteAllOutstandingsBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Customer_Outstanding__c];
        System.assertEquals(0, countAfter, 'All Customer_Outstanding__c records should be deleted');
    }

    @isTest
    static void testBatchWithNoRecords() {
        delete [SELECT Id FROM Customer_Outstanding__c];

        Test.startTest();
        DeleteAllOutstandingsBatch batch = new DeleteAllOutstandingsBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Customer_Outstanding__c];
        System.assertEquals(0, countAfter, 'No Customer_Outstanding__c records should exist');
    }
}