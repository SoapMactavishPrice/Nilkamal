@isTest
public class AllSchedulerTest {
        @isTest
        static void testScheduler() {
            // Prepare test data if required
            // For example you can create mock Accounts, Sales_Organizations__c, Division__c if needed
            
            Test.startTest();
            // Schedule the class
            String cronExp = '0 0 0 1 1 ? 2050'; // Dummy future date
            System.schedule('Test Schedule', cronExp, new allSchedular());
            Test.stopTest();
        }

}