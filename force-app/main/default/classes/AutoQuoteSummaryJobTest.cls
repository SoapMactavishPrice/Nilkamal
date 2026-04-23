@isTest
public with sharing class AutoQuoteSummaryJobTest {

     @isTest
    static void test_ScheduleExecution() {
        AutoQuoteSummaryJob job = new AutoQuoteSummaryJob();

        Test.startTest();
        String cronExp = '0 0 * * 1-5 ? *';
        Test.stopTest();

        String jobId = System.schedule('Test AssetWarrantyAMCNotificationJob', cronExp, job);

        System.assertNotEquals(null, jobId, 'Scheduled job ID should not be null');
    }
}