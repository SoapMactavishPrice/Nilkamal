@isTest
public class ServiceResourceLeaveHandlerTest {
    @isTest
    static void testProcessActiveAndPlannedLeaves() {
        // Create a Service Resource
        Service_Resource__c sr = new Service_Resource__c(Name = 'Test Resource');
        insert sr;

        // Create an active leave for today
        Service_Resource_Leave__c activeLeave = new Service_Resource_Leave__c(
            Service_Resource__c = sr.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert activeLeave;

        // Run the handler logic
        Test.startTest();
        ServiceResourceLeaveHandler.processActiveLeaves(new List<Service_Resource_Leave__c>{ activeLeave });
        Test.stopTest();

        // Verify the Leave__c field is updated
        Service_Resource__c updatedSR = [SELECT Leave__c FROM Service_Resource__c WHERE Id = :sr.Id];
        System.assertNotEquals(null, updatedSR.Leave__c, 'Leave__c should be set for active leave');
        System.assertEquals(Date.today().format(), updatedSR.Leave__c, 'Leave__c should match the leave date');
    }

    @isTest
    static void testClearLeaveWhenNoActiveOrPlannedLeaves() {
        // Create a Service Resource
        Service_Resource__c sr = new Service_Resource__c(Name = 'Test Resource', Leave__c = 'Dummy Leave');
        insert sr;

        // Create an old/expired leave
        Service_Resource_Leave__c expiredLeave = new Service_Resource_Leave__c(
            Service_Resource__c = sr.Id,
            Start_Date__c = Date.today().addDays(-10),
            End_Date__c = Date.today().addDays(-5)
        );
        insert expiredLeave;

        // Run the handler logic
        Test.startTest();
        ServiceResourceLeaveHandler.processActiveLeaves(new List<Service_Resource_Leave__c>{ expiredLeave });
        Test.stopTest();

        // Verify Leave__c is cleared
        Service_Resource__c updatedSR = [SELECT Leave__c FROM Service_Resource__c WHERE Id = :sr.Id];
    }

    @isTest
    static void testPreferredActiveOverPlannedLeave() {
        Service_Resource__c sr = new Service_Resource__c(Name = 'Mixed Case Resource');
        insert sr;

        // Planned leave
        Service_Resource_Leave__c plannedLeave = new Service_Resource_Leave__c(
            Service_Resource__c = sr.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1)
        );
        insert plannedLeave;

        // Active leave (should be preferred)
        Service_Resource_Leave__c activeLeave = new Service_Resource_Leave__c(
            Service_Resource__c = sr.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(1)
        );
        insert activeLeave;

        // Run the handler
        Test.startTest();
        ServiceResourceLeaveHandler.processActiveLeaves(new List<Service_Resource_Leave__c>{ plannedLeave, activeLeave });
        Test.stopTest();

        // Assert active leave is chosen
        Service_Resource__c updatedSR = [SELECT Leave__c FROM Service_Resource__c WHERE Id = :sr.Id];
        String expected = Date.today().format() + ' - ' + Date.today().addDays(1).format();
        System.assertEquals(expected, updatedSR.Leave__c, 'Active leave should be selected over planned');
    }
}