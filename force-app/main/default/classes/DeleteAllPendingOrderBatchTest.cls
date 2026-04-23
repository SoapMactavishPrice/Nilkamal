@isTest
public class DeleteAllPendingOrderBatchTest {

    @testSetup
    static void setupTestData() {
        // Create test Pending_Order__c records
        List<Pending_Order__c> orders = new List<Pending_Order__c>();
        for (Integer i = 0; i < 5; i++) {
            orders.add(new Pending_Order__c(
                // Add other required fields here if any
            ));
        }
        insert orders;
    }

    @isTest
    static void testBatchDeletesAllRecords() {
        Integer countBefore = [SELECT count() FROM Pending_Order__c];
        System.assert(countBefore > 0, 'Pending Orders should exist before batch execution');

        Test.startTest();
        DeleteAllPendingOrderBatch batch = new DeleteAllPendingOrderBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Pending_Order__c];
        System.assertEquals(0, countAfter, 'All Pending Orders should be deleted after batch execution');
    }

    @isTest
    static void testBatchWithNoRecords() {
        delete [SELECT Id FROM Pending_Order__c];

        Test.startTest();
        DeleteAllPendingOrderBatch batch = new DeleteAllPendingOrderBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Pending_Order__c];
        System.assertEquals(0, countAfter, 'No Pending Orders should exist');
    }
}