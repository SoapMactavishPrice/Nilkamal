@isTest
public class DeleteAllReturnableSamplesBatchTest {

    @testSetup
    static void setupTestData() {
        List<Sample_Returnable_Order__c> samples = new List<Sample_Returnable_Order__c>();
        for (Integer i = 0; i < 5; i++) {
            samples.add(new Sample_Returnable_Order__c(
            ));
        }
        insert samples;
    }

    @isTest
    static void testBatchDeletesAllRecords() {
        Integer countBefore = [SELECT count() FROM Sample_Returnable_Order__c];
        System.assert(countBefore > 0, 'Returnable Samples should exist before batch execution');

        Test.startTest();
        DeleteAllReturnableSamplesBatch batch = new DeleteAllReturnableSamplesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Sample_Returnable_Order__c];
        System.assertEquals(0, countAfter, 'All Returnable Samples should be deleted after batch execution');
    }

    @isTest
    static void testBatchWithNoRecords() {
        delete [SELECT Id FROM Sample_Returnable_Order__c];

        Test.startTest();
        DeleteAllReturnableSamplesBatch batch = new DeleteAllReturnableSamplesBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        Integer countAfter = [SELECT count() FROM Sample_Returnable_Order__c];
        System.assertEquals(0, countAfter, 'No Returnable Samples should exist');
    }
}