@isTest
public class ServiceResourceLeaveBatchTest {
    
    @isTest
    static void testBatchExecution() {
        // Create test service resources
        List<Service_Resource__c> srList = new List<Service_Resource__c>();
        for (Integer i = 0; i < 3; i++) {
            srList.add(new Service_Resource__c(Name = 'SR ' + i));
        }
        insert srList;

        // Assign one valid active leave to each resource
        List<Service_Resource_Leave__c> leaveList = new List<Service_Resource_Leave__c>();
        leaveList.add(new Service_Resource_Leave__c(
            Service_Resource__c = srList[0].Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        ));
        leaveList.add(new Service_Resource_Leave__c(
            Service_Resource__c = srList[1].Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1)
        ));
        // This one is expired
        leaveList.add(new Service_Resource_Leave__c(
            Service_Resource__c = srList[2].Id,
            Start_Date__c = Date.today().addDays(-5),
            End_Date__c = Date.today().addDays(-2)
        ));
        insert leaveList;

        // Run the batch class
        Test.startTest();
        ServiceResourceLeaveBatch batch = new ServiceResourceLeaveBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Validate updates
        List<Service_Resource__c> updatedSRs = [SELECT Id, Leave__c FROM Service_Resource__c WHERE Id IN :srList];

        // SR 0 should have today's date
        System.assertEquals(Date.today().format(), updatedSRs[0].Leave__c);

        // SR 1 should have date range
        String expectedRange = Date.today().format() + ' to ' + Date.today().addDays(1).format();
        System.assertEquals(expectedRange, updatedSRs[1].Leave__c);

        // SR 2 had expired leave, should be null
        System.assertEquals(null, updatedSRs[2].Leave__c);
    }
}