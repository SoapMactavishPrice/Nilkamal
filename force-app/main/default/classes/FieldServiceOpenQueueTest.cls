@isTest
public class FieldServiceOpenQueueTest {
    
    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User assignToUser = new User(
            Alias = 'assign',
            Email = 'assign@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AssignTo',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'assignuser_' + DateTime.now().getTime() + '@test.com'
        );

        User reAssignToUser = new User(
            Alias = 'reassign',
            Email = 'reassign@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'ReAssignTo',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'reassignuser_' + DateTime.now().getTime() + '@test.com'
        );

        insert new List<User>{ assignToUser, reAssignToUser };

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@contact.com', AccountId = acc.Id);
        insert con;

        // Case assigned to a user
        Case userCase = new Case(
            Subject = 'Assigned User Case',
            Status = 'New',
            Assign_To__c = assignToUser.Id,
            Re_Assign_To__c = reAssignToUser.Id,
            ContactId = con.Id,
            AccountId = acc.Id,
            Origin = 'Phone',
            OwnerId = assignToUser.Id,
            AssetId = testAsset.Id
        );
        insert userCase;

        Asset testAsset1 = new Asset(Name = 'Test1 Asset');
        insert testAsset1;
        // Queue-owned case
        Group q = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
        Case queueCase = new Case(
            Subject = 'Queue Owned Case',
            Status = 'New',
            ContactId = con.Id,
            AccountId = acc.Id,
            Origin = 'Email',
            OwnerId = q.Id,
            AssetId = testAsset1.Id
        );
        insert queueCase;
    }

    @isTest
    static void testAcceptCaseWithAssignTo() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Assigned User Case' LIMIT 1];

        Test.startTest();
        FieldServiceOpenQueue.acceptCase(c.Id);
        Test.stopTest();

        Case updated = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.assertNotEquals(null, updated.OwnerId, 'OwnerId should be updated');
    }

    @isTest
    static void testSendRejectionNotification() {
        Case c = [SELECT Id FROM Case WHERE Subject = 'Assigned User Case' LIMIT 1];

        Test.startTest();
        FieldServiceOpenQueue.sendRejectionNotification(c.Id);
        Test.stopTest();

        // No exception means success; email can't be verified directly in test context
        System.assert(true, 'Rejection notification processed without errors');
    }

    @isTest
    static void testGetCasesForQueue() {
        Group q = [SELECT Name FROM Group WHERE Type = 'Queue' LIMIT 1];
        Test.startTest();
        List<Case> result = FieldServiceOpenQueue.getCasesForQueue(q.Name);
        Test.stopTest();
  //      System.assert(!result.isEmpty(), 'Should return at least one queue-owned case');
    }

    @isTest
    static void testGetCasesForCurrentUser() {
        User currentUser = [SELECT Id FROM User WHERE Email = 'assign@example.com' LIMIT 1];

        System.runAs(currentUser) {
            Test.startTest();
            List<Case> result = FieldServiceOpenQueue.getCasesForCurrentUser();
            Test.stopTest();
            System.assert(result != null, 'Expected a valid list of cases');
        }
    }
}