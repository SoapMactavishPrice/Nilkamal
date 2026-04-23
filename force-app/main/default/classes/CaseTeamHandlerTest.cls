@isTest
public class CaseTeamHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Username = 'johndoe1@example.com.test' + System.currentTimeMillis(),
            Alias = 'jdoe1',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
          Asset asset = new Asset(Name='Test Asset');
        insert asset;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Case cs = new Case(
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Phone',
            Subject = 'Test Case',
            AssetId = asset.Id
            
        );
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        Service_Appointment__c saLinked = new Service_Appointment__c(
            //Name = 'Linked SA',
            Case__c = cs.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false
        );
        insert saLinked;
        
        Service_Appointment__c saDirect = new Service_Appointment__c(
            // Name = 'Direct Case SA',
            Case__c = cs.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(2), 
            Remote_Support__c = false
        );
        insert saDirect;
        
        Case_Team__c ct = new Case_Team__c(
            Case__c = cs.Id,
            Member__c = u.Id,
            Access_Level__c = 'Read'
        );
        insert ct;
    }
    
    @isTest
    static void testManageSharingOnInsertUpdate() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'johndoe1@example.com.test%' LIMIT 1];
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        
        Case_Team__c ct = new Case_Team__c(
            Case__c = testCase.Id,
            Member__c = testUser.Id,
            Access_Level__c = 'Read'
        );
        insert ct;
        
        Test.startTest();
        CaseTeamHandler.manageSharingOnInsertUpdate(new List<Case_Team__c>{ct}, null);
        
        ct.Access_Level__c = 'Edit';
        update ct;
        
        Map<Id, Case_Team__c> oldMap = new Map<Id, Case_Team__c>{
            ct.Id => new Case_Team__c(Id = ct.Id, Case__c = testCase.Id, Member__c = testUser.Id, Access_Level__c = 'Read')
                };
                    CaseTeamHandler.manageSharingOnInsertUpdate(new List<Case_Team__c>{ct}, oldMap);
        Test.stopTest();
    }
    
    @isTest
    static void testManageSharingOnDelete() {
        Case_Team__c ct = [SELECT Id, Case__c, Member__c FROM Case_Team__c LIMIT 1];
        
        Test.startTest();
        CaseTeamHandler.manageSharingOnDelete(new List<Case_Team__c>{ct});
        Test.stopTest();
    }
    
    @isTest
    static void testShareServiceAppointment() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'johndoe1@example.com.test%' LIMIT 1];
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        
        Case_Team__c ct = new Case_Team__c(
            Case__c = testCase.Id,
            Member__c = testUser.Id,
            Access_Level__c = 'Edit'
        );
        insert ct;
        
        //Test.startTest();
        //CaseTeamHandler.shareServiceAppointment(new List<Case_Team__c>{ct});
        //Test.stopTest();
        
        List<Service_Appointment__Share> shares = [
            SELECT Id, UserOrGroupId, ParentId, AccessLevel
            FROM Service_Appointment__Share 
            WHERE UserOrGroupId = :testUser.Id
        ];
        System.assert(!shares.isEmpty(), 'Expected service appointment sharing records');
    }
}