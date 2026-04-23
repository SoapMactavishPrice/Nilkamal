@isTest
public class priceBookScheduleClassTest {
    
    @isTest
    static void testSchedulerExecution() {
        // Simulate a scheduled job
        Test.startTest();
        priceBookScheduleClass scheduler = new priceBookScheduleClass();
        String jobId = System.schedule('Test Scheduler Job', '0 0 0 1 1 ? 2099', scheduler);
        Test.stopTest();
    }
}