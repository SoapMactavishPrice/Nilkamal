@isTest
public class UserTriggerHandlerTest {

    @testSetup
    static void setupData() {
        UserRole coordinatorRole = new UserRole(Name = 'Coordinator');
        insert coordinatorRole;

        UserRole seRole = new UserRole(Name = 'Service Engineer');
        insert seRole;

        UserRole rsmRole = new UserRole(Name = 'RSM');
        insert rsmRole;

        User managerUser = new User(
            Username = 'manager@example.com.test',
            LastName = 'Manager',
            Email = 'manager@example.com',
            Alias = 'mgr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US',
            UserRoleId = coordinatorRole.Id,
            IsActive = true
        );
        insert managerUser;

        User serviceUser = new User(
            Username = 'serviceuser@example.com.test',
            LastName = 'Service',
            Email = 'serviceuser@example.com',
            Alias = 'srv',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US',
            Is_Service_User__c = true,
            UserRoleId = seRole.Id,
            ManagerId = managerUser.Id
            //Business_Unit__c = 'BU1'
        );
        insert serviceUser;
    }

    @isTest
    static void testCreateServiceResourcesAndHours() {
        User testUser = [SELECT Id, Is_Service_User__c FROM User WHERE Username = 'serviceuser@example.com.test'];

        Map<Id, User> oldMap = new Map<Id, User>();
        oldMap.put(testUser.Id, testUser.clone());
        
        testUser.Is_Service_User__c = true;

        Test.startTest();
        try{UserTriggerHandler.createServiceResourcesAndHours(new List<User>{testUser}, oldMap);}catch (Exception e){System.debug('Error');}
        Test.stopTest();

        List<Service_Resource__c> srList = [SELECT Id, User__c FROM Service_Resource__c WHERE User__c = :testUser.Id];
        System.assertEquals(1, srList.size());

        List<Service_Resource_Working_Hour__c> hrs = [SELECT Id FROM Service_Resource_Working_Hour__c WHERE Service_Resource__c = :srList[0].Id];
        System.assertEquals(5, hrs.size());
    }

    @isTest
    static void testUpdateServiceResources() {
        User testUser = [SELECT Id, FirstName, LastName, Business_Unit__c, ManagerId, UserRoleId FROM User WHERE Username = 'serviceuser@example.com.test'];

        Map<Id, User> oldMap = new Map<Id, User>();
        User oldUser = testUser.clone(false, true, true, true);
        oldUser.FirstName = 'OldFirst';
        oldUser.LastName = 'OldLast';
        oldUser.Business_Unit__c = 'OldBU';
        oldMap.put(testUser.Id, oldUser);

        testUser.FirstName = 'NewFirst';
        testUser.LastName = 'NewLast';
        update testUser;

        Test.startTest();
        UserTriggerHandler.updateServiceResources(new List<User>{testUser}, oldMap);
        Test.stopTest();

        List<Service_Resource__c> srList = [SELECT Id, Name FROM Service_Resource__c WHERE User__c = :testUser.Id];
        System.assert(srList[0].Name.contains('NewFirst'));
    }
}