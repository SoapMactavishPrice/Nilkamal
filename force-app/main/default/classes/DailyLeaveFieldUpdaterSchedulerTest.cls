@isTest
private class DailyLeaveFieldUpdaterSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
        String cronExp = '0 0 0 1 1 ? 2050'; // Schedule for 1 Jan 2050 at 00:00

        Test.startTest();
        String jobId = System.schedule('Test DailyLeave Scheduler', cronExp, new DailyLeaveFieldUpdaterScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        System.assertEquals(cronExp, ct.CronExpression);
    }
}