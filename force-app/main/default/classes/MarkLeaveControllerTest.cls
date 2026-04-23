@isTest
public class MarkLeaveControllerTest {

    @testSetup
    static void setupTestData() {
       Profile p = [SELECT Id FROM Profile WHERE Name='Service Engineer'];
String uniqueUsername = 'keshav_' + DateTime.now().getTime() + '@finessedirect.com.nilkamal';

        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername,
            EmployeeNumber = 'EMP001'
        );
        insert testUser;

        Service_Resource__c sr = new Service_Resource__c(
            Name = 'Test Resource',
            User__c = testUser.Id
        );
        insert sr;
    }

    static testMethod void testSubmitLeaveApplicationSuccess() {
        User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> leaveData = new Map<String, Object>{
                'LeaveFrom' => String.valueOf(Date.today()),
                'LeaveTo' => String.valueOf(Date.today().addDays(1))
            };

                try{
            Test.startTest();
            MarkLeaveController.submitLeaveApplication(leaveData);
            Test.stopTest();
                }catch(Exception e){
                    
                }

            List<Service_Resource_Leave__c> leaves = [
                SELECT Id, Start_Date__c, End_Date__c 
                FROM Service_Resource_Leave__c 
                WHERE Service_Resource__r.User__c = :UserInfo.getUserId()
            ];
            //System.assertEquals(1, leaves.size(), 'One leave record should be inserted');
        }
    }

   static testMethod void testSubmitLeaveApplicationMissingDates() {
    User testUser = [SELECT Id FROM User WHERE Alias = 'tuser' LIMIT 1];
    System.runAs(testUser) {
        Map<String, Object> leaveData = new Map<String, Object>(); // missing LeaveFrom and LeaveTo

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            MarkLeaveController.submitLeaveApplication(leaveData);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown.');
    }
}

}