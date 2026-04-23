@isTest
private class FieldServiceHomeControllerTest {

    static User createTestUser(String roleName, String alias) {
        UserRole role = new UserRole(Name = roleName);
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = alias,
            Email = alias + '@test.com',
            Username = alias + '@test.com.' + System.currentTimeMillis(),
            Alias = alias.substring(0, Math.min(4, alias.length())),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = role.Id
        );
        insert u;
        return u;
    }

    static void setupData() {
        User user = createTestUser('Service Head', 'svcHead');

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Asset asset = new Asset(Name='Test1 Asset');
        insert asset;

        System.runAs(user) {
            Case cs = new Case(
                OwnerId = user.Id,
                Status = 'New',
                Assigned_Date_Time__c = System.today(),
                Is_Service_Appointment_Created__c = false,
                AssetId = asset.Id,
                AccountId = acc.Id
            );
            insert cs;

            Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
            insert wo;

            Service_Appointment__c sa = new Service_Appointment__c(
                OwnerId = user.Id,
                Case__c = cs.Id,
                Scheduled_Start__c = System.today(),
                Work_Order__c = wo.Id
            );
            insert sa;
        }
    }

    @isTest
    static void testGetCaseSummary() {
        Test.startTest();
        Map<String, Integer> summary = FieldServiceHomeController.getCaseSummary();
        Test.stopTest();

        System.assert(summary.containsKey('newCases'), 'Missing newCases key');
        System.assert(summary.containsKey('missedCases'), 'Missing missedCases key');
        System.assert(summary.containsKey('todaysActions'), 'Missing todaysActions key');
        System.assert(summary.containsKey('openCases'), 'Missing openCases key');
    }

    @isTest
    static void testGetEventsList() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
        insert ast;

        Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id, AccountId = acc.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Service_Appointment__c sa1 = new Service_Appointment__c(
            Case__c = cs.Id,
            OwnerId = UserInfo.getUserId(),
            Account__c = acc.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now(),
            Remote_Support__c = false
        );

        Service_Appointment__c sa2 = new Service_Appointment__c(
            Case__c = cs.Id,
            OwnerId = UserInfo.getUserId(),
            Account__c = acc.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(-1),
            Remote_Support__c = false
        );

        Service_Appointment__c sa3 = new Service_Appointment__c(
            Case__c = cs.Id,
            OwnerId = UserInfo.getUserId(),
            Account__c = acc.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false
        );

        insert new List<Service_Appointment__c>{sa1, sa2, sa3};

        Test.startTest();
        Object result = FieldServiceHomeController.getEventsList();
        Test.stopTest();

        System.assert(result != null, 'Event list should not be null');
    }

    @isTest
    static void testGetDashboardId_AllRoles() {
        List<String> roles = new List<String>{
            'Service Head', 'System Administrator', 'Coordinator', 'RSM', 'Service Engineer'
        };

        Test.startTest();
        for (String roleName : roles) {
            String alias = roleName.substring(0, Math.min(4, roleName.length())).toLowerCase();

            User testUser = createTestUser(roleName, alias);

            System.runAs(testUser) {
                Id dashboardId = null;
                try {
                    dashboardId = FieldServiceHomeController.getDashboardId();
                } catch (AuraHandledException e) {
                    System.debug('Handled Exception for role ' + roleName + ': ' + e.getMessage());
                }

                if (dashboardId != null) {
                    System.assert(String.valueOf(dashboardId).startsWith('01Z'), 'Dashboard ID should start with 01Z');
                }
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testGetNewCaseCountForRSM() {
        // First insert setup objects
        UserRole role = new UserRole(Name = 'RSM - West');
        insert role;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'RSM',
            Email = 'rsm@test.com',
            Username = 'rsm_user_' + System.currentTimeMillis() + '@test.com',
            Alias = 'rsmu',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = role.Id
        );
        insert testUser;

        // Now perform non-setup object DML inside System.runAs()
        System.runAs(testUser) {
            Account acc = new Account(Name = 'Test Acc RSM');
            insert acc;

            Asset asset = new Asset(Name='Test Asset');
            insert asset;

            Case cs = new Case(
                OwnerId = testUser.Id,
                Status = 'New',
                AccountId = acc.Id,
                AssetId = asset.Id
            );
            insert cs;

            Test.startTest();
            Integer count = FieldServiceHomeController.getNewCaseCountForRSM();
            Test.stopTest();

            System.assertEquals(1, count, 'Expected case count for RSM is 1');
        }
    }

    @isTest
    static void testGetSummarizedData() {
        Test.startTest();
        Object result = FieldServiceHomeController.getSummarizedData();
        System.debug(result);
        Test.stopTest();
    }

    @IsTest
    static void testGetCountOfCasesAndFeedItems() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'TestUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com.' + System.currentTimeMillis(),
            Alias = 'testusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserRoleId = [SELECT Id FROM UserRole LIMIT 1].Id,
            Technical_Assistant__c = UserInfo.getUserId()
        );
        insert u;

        System.runAs(u) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id, AccountId = acc.Id);
            insert cs;

            FeedItem feedItem = new FeedItem(ParentId = cs.Id, Body = 'Test Feed Item');
            insert feedItem;

            Test.startTest();
            Integer result = FieldServiceHomeController.getCountOfCasesAndFeedItems();
            Test.stopTest();
        }
    }

}