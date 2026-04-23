/*@isTest
public class AssetWarrantyAMCScheduledJob_Test {

    @isTest
    static void test_ScheduleExecution() {
        AssetWarrantyAMCScheduledJob job = new AssetWarrantyAMCScheduledJob();

        String cronExp = '0 0 0 1 1 ? 2025';
        String jobId = System.schedule('Test AssetWarrantyAMCScheduledJob', cronExp, job);

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @isTest
    static void test_RunUpdateLogic() {
        Test.startTest();
        AssetWarrantyAMCScheduledJob.runUpdateLogic();
        Test.stopTest();

        System.assert(true, 'Batch jobs should execute without exceptions');
    }
    


}*/
@isTest
private class TestAssetWarrantyAMCScheduledJob {

    @isTest
    static void testExecuteMethod() {
        // Minimal data setup (if your batches rely on any object)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Example: Insert Asset or Warranty records if needed for the batch
        // Asset testAsset = new Asset(Name = 'Test Asset', AccountId = acc.Id);
        // insert testAsset;

        Test.startTest();

        // Execute the scheduled job directly
        AssetWarrantyAMCScheduledJob job = new AssetWarrantyAMCScheduledJob();
        job.execute(null); // SchedulableContext not used

        Test.stopTest();
    }

    @isTest
    static void testScheduleJob() {
        Test.startTest();

        String jobId = System.schedule(
            'Test Scheduled Job',
            '0 0 12 * * ?',  // Every day at 12 PM
            new AssetWarrantyAMCScheduledJob()
        );

        System.assertNotEquals(null, jobId);
        Test.stopTest();
    }
}