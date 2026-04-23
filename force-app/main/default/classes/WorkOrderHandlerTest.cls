@isTest
public class WorkOrderHandlerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1];

        Account acc = new Account(Name='Test Account');
        insert acc;
    }

    @isTest
    static void testRollUpOwnerToCaseTeam() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1];
        String unique = String.valueOf(DateTime.now().getTime());

        User userA = new User(
            Alias = 'ua',
            Email = 'ua@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserA',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'ua_' + unique + '@test.com'
        );

        User userB = new User(
            Alias = 'ub',
            Email = 'ub@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserB',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'ub_' + unique + '@test.com'
        );

        insert new List<User>{userA, userB};

        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Asset asset = new Asset(
            Name = 'Test Asset 995',
            SerialNumber = '12345',
            AccountId = acc.Id
        );
        insert asset;

        Case cs = new Case(AccountId = acc.Id, AssetId = asset.Id, OwnerId = userA.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, OwnerId = userB.Id);
        insert wo;

        Map<Id, Work_Order__c> oldMap = new Map<Id, Work_Order__c>{
            wo.Id => new Work_Order__c(Id = wo.Id, Case__c = cs.Id, OwnerId = userA.Id)
        };

        Test.startTest();
        WorkOrderHandler.rollUpOwnerToCaseTeam(new List<Work_Order__c>{wo}, oldMap);
        Test.stopTest();

        List<Case_Team__c> teamRecords = [SELECT Id FROM Case_Team__c WHERE Case__c = :cs.Id AND Member__c = :userB.Id];
        System.assertEquals(1, teamRecords.size(), 'A Case_Team__c record should be created for the new WO owner.');
    }

    @isTest
    static void testManageSharingOnInsert() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String unique = String.valueOf(DateTime.now().getTime());

        User userA = new User(
            Alias = 'ua2',
            Email = 'ua2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserA2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'ua2_' + unique + '@test.com'
        );

        User userB = new User(
            Alias = 'ub2',
            Email = 'ub2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserB2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'ub2_' + unique + '@test.com'
        );

        insert new List<User>{userA, userB};

        Account acc = [SELECT Id FROM Account LIMIT 1];
        
         Asset asset = new Asset(
            Name = 'Test Asset 995',
            SerialNumber = '12345',
            AccountId = acc.Id
        );
        insert asset;

        Case cs = new Case(AccountId = acc.Id, AssetId = asset.Id, OwnerId = userA.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, OwnerId = userB.Id);
        insert wo;

        Test.startTest();
        WorkOrderHandler.manageSharingOnInsert(new List<Work_Order__c>{wo});
        Test.stopTest();

        List<Case_Team__c> teamRecords = [SELECT Id FROM Case_Team__c WHERE Case__c = :cs.Id AND Member__c = :userB.Id];
        System.assertEquals(1, teamRecords.size(), 'Case_Team__c should be created when WO owner differs from Case owner.');
    }

    @isTest
    static void testCreateWorkOrderFromCase() {
        WorkOrderTriggerHelper.isTriggerExecuting = false;

       Account acc = [SELECT Id FROM Account LIMIT 1];
        
         Asset asset = new Asset(
            Name = 'Test Asset 995',
            SerialNumber = '12345',
            AccountId = acc.Id
        );
        insert asset;
        
        
        Case cs = new Case(AccountId = acc.Id, AssetId = asset.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        List<Work_Order__c> workOrders = new List<Work_Order__c>{ wo };

        Test.startTest();
        WorkOrderHandler.createWorkOrderFromCase(workOrders);
        Test.stopTest();

        Work_Order__c updated = [SELECT Status__c FROM Work_Order__c WHERE Id = :wo.Id];
       // System.assertEquals('New', updated.Status__c);
    }
}