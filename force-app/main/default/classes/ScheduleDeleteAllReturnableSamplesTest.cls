@isTest
private class ScheduleDeleteAllReturnableSamplesTest {

    @isTest
    static void testExecute_ScheduleJob() {
        ScheduleDeleteAllReturnableSamples job = new ScheduleDeleteAllReturnableSamples();

        Datetime dt = System.now().addMinutes(1);
        String cronExp = String.format('{0} {1} {2} {3} {4} ? {5}',
            new String[] {
                String.valueOf(dt.second()),     // Seconds
                String.valueOf(dt.minute()),     // Minutes
                String.valueOf(dt.hour()),       // Hours
                String.valueOf(dt.day()),        // Day of month
                String.valueOf(dt.month()),      // Month
                String.valueOf(dt.year())        // Year
            }
        );

        String jobId = System.schedule('Test Scheduled Delete All Returnable Samples', cronExp, job);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger 
                          WHERE Id = :jobId];

        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');
        System.assertNotEquals(null, ct.NextFireTime, 'NextFireTime should not be null');
    }
}