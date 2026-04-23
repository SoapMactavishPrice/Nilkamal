@isTest
private class SpareMaterialRequestTriggerTest {

    private static void setupTestData() {
        User u1 = new User(
            FirstName = 'Support',
            LastName = 'Agent1',
            Alias = 'sa1',
            Email = 'sa1@test.com',
            Username = 'sa1_' + DateTime.now().getTime() + '@test.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Coordinator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = UserInfo.getUserId(),
            Is_Service_User__c = true
        );
        insert u1;

        User u2 = new User(
            FirstName = 'Support',
            LastName = 'Agent2',
            Alias = 'sa2',
            Email = 'sa2@test.com',
            Username = 'sa2_' + DateTime.now().getTime() + '@test.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name='RSM' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = u1.Id,
            Is_Service_User__c = true
        );
        insert u2;

        User u3 = new User(
            FirstName = 'Support',
            LastName = 'Agent3',
            Alias = 'sa2',
            Email = 'sa2@test.com',
            Username = 'sa2_' + DateTime.now().getTime() + '@test.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Service Engineer' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = u2.Id,
            Is_Service_User__c = true
        );
        insert u3;

        Service_Resource__c sr = new Service_Resource__c();
        sr.User__c = u3.Id;
        sr.RSM__c = u2.Id;
        sr.Coordinator__c = u1.Id;
        sr.isActive__c = true;
        insert sr;
    }

    @isTest
    static void testInsertSetsMaterialRequiredDate() {
        setupTestData();
        User u3 = [SELECT Id FROM User WHERE LastName = 'Agent3' LIMIT 1];

        System.runAs(u3) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id,AccountId= acc.Id);
            insert cs;

            Test.startTest();
            Spare_Material_Request__c smr = new Spare_Material_Request__c(
                Case__c = cs.Id,
                Status__c = 'New'
            );
            insert smr;
            Test.stopTest();

            smr = [SELECT Material_Required_Date__c FROM Spare_Material_Request__c WHERE Id = :smr.Id];
            System.assertEquals(Date.today(), smr.Material_Required_Date__c, 'Material Required Date should be set to today on insert');
        }
    }

    @isTest
    static void testUpdateWhenSpareMaterialCodeChangesFromNullToValue() {
        setupTestData();
        User u3 = [SELECT Id FROM User WHERE LastName = 'Agent3' LIMIT 1];

        System.runAs(u3) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id,AccountId = acc.Id);
            insert cs;

            Spare_Material_Request__c smr = new Spare_Material_Request__c(
                Case__c = cs.Id,
                Status__c = 'New',
                Spare_Material_Code__c = null
            );
            insert smr;

            Test.startTest();
            smr.Spare_Material_Code__c = 'MAT-001';
            update smr;
            Test.stopTest();

            smr = [SELECT Status__c, Request_Completed_Date__c FROM Spare_Material_Request__c WHERE Id = :smr.Id];
            System.assertEquals('Completed', smr.Status__c, 'Status should be set to Completed when Spare Material Code changes from null to value');
            System.assertEquals(Date.today(), smr.Request_Completed_Date__c, 'Request Completed Date should be set to today when Spare Material Code changes from null to value');
        }
    }

    @isTest
    static void testUpdateWhenSpareMaterialCodeChangesFromOneValueToAnother() {
        setupTestData();
        User u3 = [SELECT Id FROM User WHERE LastName = 'Agent3' LIMIT 1];

        System.runAs(u3) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id,AccountId = acc.Id);
            insert cs;

            Spare_Material_Request__c smr = new Spare_Material_Request__c(
                Case__c = cs.Id,
                Status__c = 'New',
                Spare_Material_Code__c = 'MAT-001'
            );
            insert smr;

            Test.startTest();
            smr.Spare_Material_Code__c = 'MAT-002';
            update smr;
            Test.stopTest();

            smr = [SELECT Status__c, Request_Completed_Date__c FROM Spare_Material_Request__c WHERE Id = :smr.Id];
        }
    }

    @isTest
    static void testUpdateWhenSpareMaterialCodeDoesNotChange() {
        setupTestData();
        User u3 = [SELECT Id FROM User WHERE LastName = 'Agent3' LIMIT 1];

        System.runAs(u3) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id,AccountId = acc.Id);
            insert cs;

            Spare_Material_Request__c smr = new Spare_Material_Request__c(
                Case__c = cs.Id,
                Status__c = 'New',
                Spare_Material_Code__c = 'MAT-001',
                Request_Completed_Date__c = null
            );
            insert smr;

            Test.startTest();
            smr.Status__c = 'Completed';
            update smr;
            Test.stopTest();

            smr = [SELECT Status__c, Request_Completed_Date__c FROM Spare_Material_Request__c WHERE Id = :smr.Id];
        }
    }

    @isTest
    static void testUpdateDoesNotOverrideExistingCompletedDate() {
        setupTestData();
        User u3 = [SELECT Id FROM User WHERE LastName = 'Agent3' LIMIT 1];

        System.runAs(u3) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert ast;

            Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id, AccountId = acc.Id);
            insert cs;

            Date testDate = Date.today().addDays(-5);
            Spare_Material_Request__c smr = new Spare_Material_Request__c(
                Case__c = cs.Id,
                Status__c = 'New',
                Spare_Material_Code__c = null,
                Request_Completed_Date__c = testDate
            );
            insert smr;

            Test.startTest();
            smr.Spare_Material_Code__c = 'MAT-001';
            update smr;
            Test.stopTest();

            smr = [SELECT Request_Completed_Date__c FROM Spare_Material_Request__c WHERE Id = :smr.Id];
            System.assertEquals(testDate, smr.Request_Completed_Date__c, 'Existing Request Completed Date should not be overwritten when Spare Material Code changes');
        }
    }
}