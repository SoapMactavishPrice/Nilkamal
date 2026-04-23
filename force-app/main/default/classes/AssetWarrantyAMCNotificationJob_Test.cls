@isTest
public class AssetWarrantyAMCNotificationJob_Test {

    @isTest
    static void test_ScheduleExecution() {
            AssetWarrantyAMCNotificationJob job = new AssetWarrantyAMCNotificationJob();

        Test.startTest();
        String cronExp = '0 0 * * 1-5 ? *';
        Test.stopTest();

        String jobId = System.schedule('Test AssetWarrantyAMCNotificationJob', cronExp, job);

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }

}