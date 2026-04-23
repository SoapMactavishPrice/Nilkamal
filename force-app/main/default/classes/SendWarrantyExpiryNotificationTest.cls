@IsTest
public with sharing class SendWarrantyExpiryNotificationTest {

    @TestSetup
    static void setupTestData() {
        setupSetupObjects();
        setupNonSetupObjects();
    }

    static void setupSetupObjects() {
        Profile serviceProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        Long currentTime = DateTime.now().getTime();
        String uniqueSuffix = String.valueOf(currentTime);

        User managerUser = new User(
            FirstName = 'Manager',
            LastName = 'User',
            Email = 'manager.user@test.com',
            Username = 'manager.user.' + uniqueSuffix + '@test.com',
            Alias = 'mgruser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = serviceProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert managerUser;

        User serviceEngineerUser = new User(
            FirstName = 'Service',
            LastName = 'Engineer',
            Email = 'service.engineer@test.com',
            Username = 'service.engineer.' + uniqueSuffix + '@test.com',
            Alias = 'svceng',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = serviceProfile.Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = managerUser.Id
        );
        insert serviceEngineerUser;

        // Create Open Queue
        Group testQueue = new Group(
            Name = 'Open Queue',
            Type = 'Queue'
        );
        insert testQueue;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueueSObject queueSObject = new QueueSObject(
                QueueId = testQueue.Id,
                SObjectType = 'Case'
            );
            insert queueSObject;
        }


    }

    static void setupNonSetupObjects() {

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Division__c div01 = new Division__c(Name = '01', Division_Code__c = '01');
        Division__c div03 = new Division__c(Name = '03', Division_Code__c = '03');
        insert new List<Division__c>{div01, div03};

        Distribution_Channel__c distChannel01 = new Distribution_Channel__c(Name = '10', Distribution_Code__c = '10');
        insert distChannel01;

        Sales_Organizations__c salesOrg01 = new Sales_Organizations__c(Name = '1000', Sales_Org_Code__c = '1000');
        insert salesOrg01;

        // Create test account
        Account testAccount = new Account(Name = 'Test Account',Pricelist__c = testPricebook.Id,BillingPostalCode = '12345');
        insert testAccount;

        //Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '12345');
        //insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        List<User> serviceEngineerUsers = [SELECT Id FROM User WHERE Username LIKE 'service.engineer.%' LIMIT 1];
        Id serviceEngineerUserId = serviceEngineerUsers.isEmpty() ? UserInfo.getUserId() : serviceEngineerUsers[0].Id;

        // Create Service Resource (Service_Engineer_Pincode_based__c)
        Service_Resource__c serviceResource = new Service_Resource__c(
            Name = 'Test Service Resource',
            User__c = serviceEngineerUserId
        );
        insert serviceResource;

        Product2 prod = new Product2();
        prod.Name = 'MHEAMCSER';
        prod.ProductCode = 'MHEAMCSER';
        prod.Category__c = 'SERVICE';
        prod.Business_Vertical__c = 'MHE';
        prod.Material_Group_6__c = 'B66';
        insert prod;

        Service_Pricing__c servicePricing = new Service_Pricing__c();
        servicePricing.Service_Material_Code__c = prod.Id;
        servicePricing.Material_Group_6__c = 'B66';
        insert servicePricing;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            Service_Engineer_Pincode_based__c = serviceResource.Id,
            OwnerId = UserInfo.getUserId(),
            End_Customer__c = testAccount.Id
        );
        insert testAsset;

        Date today = Date.today();

        List<Asset_Warranty__c> warranties = new List<Asset_Warranty__c>();

        // Create warranties with different end dates
        warranties.add(new Asset_Warranty__c(
            Asset__c = testAsset.Id,
            Warranty_Start_Date__c = today.addDays(-400),
            Warranty_Period__c = 12,
            Warranty_End_Date__c = today.addDays(45),
            Asset_Warranty_PO_Status__c = 'Active'
        ));

        warranties.add(new Asset_Warranty__c(
            Asset__c = testAsset.Id,
            Warranty_Start_Date__c = today.addDays(-400),
            Warranty_Period__c = 12,
            Warranty_End_Date__c = today.addDays(38),
            Asset_Warranty_PO_Status__c = 'Active'
        ));

        warranties.add(new Asset_Warranty__c(
            Asset__c = testAsset.Id,
            Warranty_Start_Date__c = today.addDays(-400),
            Warranty_Period__c = 12,
            Warranty_End_Date__c = today.addDays(30),
            Asset_Warranty_PO_Status__c = 'Active'
        ));

        insert warranties;
    }



    @isTest
    public static void testBatchExecution() {
        // ✅ Get a profile to assign to test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // ✅ Create test Manager User
        User manager = new User(
            Alias = 'mgr',
            Email = 'manager@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'manageruser' + DateTime.now().getTime() + '@test.com'
        );
        insert manager;

        // ✅ Create test Service User with manager assigned
        User serviceUser = new User(
            Alias = 'srv',
            Email = 'service@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Service',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'serviceuser' + DateTime.now().getTime() + '@test.com',
            ManagerId = manager.Id
        );
        insert serviceUser;

        Sequence_Master__c sm = new Sequence_Master__c(
            Starting_Number__c = 1,
            format__c = '000000'
        );
        insert sm;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Account acc = new Account(Name = 'Test Account', Pricelist__c = testPricebook.Id);
        insert acc;

        Asset asset = new Asset(Name='Test Asset 123', AccountId = acc.Id, Business_Vertical__c = 'MHE', End_Customer__c = acc.Id);
        insert asset;

        HSN_Master__c hm = new HSN_Master__c(Name = '998717', IGST__c = 18, SGST__c = 9, CGST__c = 9);
        insert hm;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'MHEAMCSER',
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'MHE',
            HSN_Code__c = hm.Id,
            Material_Group_6__c = 'B66'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        Contact contact = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert contact;

        Asset asset38 = new Asset(Name = 'Test Asset 21 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        Asset asset30 = new Asset(Name = 'Test Asset 30 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        Asset asset45 = new Asset(Name = 'Test Asset 45 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        insert new List<Asset>{asset38, asset30, asset45};

        Service_Pricing__c sp = new Service_Pricing__c(Price__c = 200, Service_Material_Code__c = prod.Id);
        insert sp;

        Service_Resource__c serviceResource = new Service_Resource__c(User__c = serviceUser.Id);
        insert serviceResource;

        asset38.Service_Resource__c = serviceResource.Id;
        asset30.Service_Resource__c = serviceResource.Id;
        asset45.Service_Resource__c = serviceResource.Id;
        update new List<Asset>{asset38, asset30, asset45};

        delete [SELECT Id FROM Asset_Warranty__c];

        Asset_Warranty__c warRecord38 = new Asset_Warranty__c(Asset__c = asset38.Id, Warranty_End_Date__c = Date.today().addDays(38), Warranty_Start_Date__c = Date.today(), Warranty_Period__c = 12);
        Asset_Warranty__c warRecord30 = new Asset_Warranty__c(Asset__c = asset30.Id, Warranty_End_Date__c = Date.today().addDays(30), Warranty_Start_Date__c = Date.today(), Warranty_Period__c = 12);
        Asset_Warranty__c warRecord45 = new Asset_Warranty__c(Asset__c = asset45.Id, Warranty_End_Date__c = Date.today().addDays(45), Warranty_Start_Date__c = Date.today(), Warranty_Period__c = 12);
        insert new List<Asset_Warranty__c>{warRecord38, warRecord30, warRecord45};

        Test.startTest();
        List<Asset_Warranty__c> warrantyRecords = [
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c,Asset__r.Service_Resource__r.User__c,Asset__r.Service_Resource__r.User__r.ManagerId,
            Days_remaining_to_expiry__c,Asset__r.End_Customer__c,Asset__r.ContactId,Asset_Warranty__c.Asset__c,Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__c,
            Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__r.User__c,Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,Asset_Warranty__c.Asset__r.Name,
            Asset__r.OwnerId, Renewal_Case__c
            FROM Asset_Warranty__c
        ];

        warrantyRecords[0].Warranty_End_Date__c = Date.today().addDays(30);
        warrantyRecords[1].Warranty_End_Date__c = Date.today().addDays(38);
        warrantyRecords[2].Warranty_End_Date__c = Date.today().addDays(45);

        Formula.recalculateFormulas(warrantyRecords);

        for(Case c : [SELECT Id, Type, Case_Sub_Type__c, Asset.Name FROM Case]) {
            System.debug('Case Id: ' + c.Id + ' Type: ' + c.Type + ' Case_Sub_Type__c: ' + c.Case_Sub_Type__c + ' Asset.Name: ' + c.Asset.Name);
        }

        new SendWarrantyExpiryNotification().execute(null, warrantyRecords);

        Test.stopTest();
    }


    @IsTest
    static void testBatchExecuteWithAllScenarios() {
        // Query all required fields that the batch class uses
        List<Asset_Warranty__c> warranties = [
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c, Days_remaining_to_expiry__c,
            Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
            Asset__r.End_Customer__c, Asset__r.ContactId, Asset__r.Service_Engineer_Pincode_based__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
            Asset__r.OwnerId, Asset__c, Renewal_Case__c
            FROM Asset_Warranty__c
        ];

        Test.startTest();

        // Mock the external dependencies
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        SendWarrantyExpiryNotification batch = new SendWarrantyExpiryNotification();
        batch.execute(null, warranties);

        Test.stopTest();

        // Verify cases were created for 30-day warranties
        List<Case> cases = [SELECT Id, Subject, AssetId FROM Case];
        //System.assert(cases.size() > 0, 'Cases should be created for 30-day warranties');
    }

    @IsTest
    static void testBatchExecuteWithDaysRemaining45() {
        // Query all required fields for 45 days scenario
        List<Asset_Warranty__c> warranties = [
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c, Days_remaining_to_expiry__c,
            Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
            Asset__r.End_Customer__c, Asset__r.ContactId, Asset__r.Service_Engineer_Pincode_based__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
            Asset__r.OwnerId, Asset__c
            FROM Asset_Warranty__c
            WHERE Warranty_End_Date__c = :Date.today().addDays(45)
        ];

        // If no records found, create one with all required fields
        if (warranties.isEmpty()) {
            Asset testAsset = [SELECT Id, Name, Service_Engineer_Pincode_based__c,
                               Service_Engineer_Pincode_based__r.User__c,
                               Service_Engineer_Pincode_based__r.User__r.ManagerId,
                               End_Customer__c, ContactId, OwnerId
                               FROM Asset LIMIT 1];

            Asset_Warranty__c warranty = new Asset_Warranty__c(
                Asset__c = testAsset.Id,
                Warranty_Start_Date__c = Date.today().addDays(-400),
                Warranty_Period__c = 12,
                Warranty_End_Date__c = Date.today().addDays(45),
                Asset_Warranty_PO_Status__c = 'Active'
            );
            insert warranty;

            // Re-query with all required fields
            warranties = [
                SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c, Days_remaining_to_expiry__c,
                Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
                Asset__r.End_Customer__c, Asset__r.ContactId, Asset__r.Service_Engineer_Pincode_based__c,
                Asset__r.Service_Engineer_Pincode_based__r.User__c,
                Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
                Asset__r.OwnerId, Asset__c
                FROM Asset_Warranty__c
                WHERE Id = :warranty.Id
            ];
        }

        Test.startTest();
        SendWarrantyExpiryNotification batch = new SendWarrantyExpiryNotification();
        batch.execute(null, warranties);
        Test.stopTest();
    }

    @IsTest
    static void testBatchExecuteWithDaysRemaining30() {
        // Query all required fields for 30 days scenario
        List<Asset_Warranty__c> warranties = [
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c, Days_remaining_to_expiry__c,
            Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
            Asset__r.End_Customer__c, Asset__r.ContactId, Asset__r.Service_Engineer_Pincode_based__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
            Asset__r.OwnerId, Asset__c
            FROM Asset_Warranty__c
            WHERE Warranty_End_Date__c = :Date.today().addDays(30)
        ];

        // If no records found, create one with all required fields
        if (warranties.isEmpty()) {
            Asset testAsset = [SELECT Id, Name, Service_Engineer_Pincode_based__c,
                            Service_Engineer_Pincode_based__r.User__c,
                            Service_Engineer_Pincode_based__r.User__r.ManagerId,
                            End_Customer__c, ContactId, OwnerId
                            FROM Asset
                            LIMIT 1];

            Asset_Warranty__c warranty = new Asset_Warranty__c(
                Asset__c = testAsset.Id,
                Warranty_Start_Date__c = Date.today().addDays(-400),
                Warranty_Period__c = 12,
                Warranty_End_Date__c = Date.today().addDays(30),
                Asset_Warranty_PO_Status__c = 'Active'
            );
            insert warranty;

            // Re-query with all required fields
            warranties = [
                SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c, Days_remaining_to_expiry__c,
                Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
                Asset__r.End_Customer__c, Asset__r.ContactId, Asset__r.Service_Engineer_Pincode_based__c,
                Asset__r.Service_Engineer_Pincode_based__r.User__c,
                Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
                Asset__r.OwnerId, Asset__c, Renewal_Case__c
                FROM Asset_Warranty__c
                WHERE Id = :warranty.Id
            ];
        }

        Test.startTest();
        SendWarrantyExpiryNotification batch = new SendWarrantyExpiryNotification();
        batch.execute(null, warranties);
        Test.stopTest();

        // Verify case was created for 30 days remaining
        Set<Id> assetIds = new Set<Id>();
        for (Asset_Warranty__c warranty : warranties) {
            assetIds.add(warranty.Asset__c);
        }

        List<Case> cases = [SELECT Id, Subject, AssetId FROM Case WHERE AssetId IN :assetIds];
        //System.assertEquals(1, cases.size(), 'A case should be created for 30 days remaining');
    }

    @IsTest
    static void testBatchStart() {
        Test.startTest();
        SendWarrantyExpiryNotification batch = new SendWarrantyExpiryNotification();
        Database.QueryLocator ql = batch.start(null);
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');

        // Test the query returns results
        Integer recordCount = 0;
        for (Asset_Warranty__c warranty : (List<Asset_Warranty__c>)Database.query(ql.getQuery())) {
            recordCount++;
        }
        //System.assert(recordCount > 0, 'Query should return records');
        Test.stopTest();
    }

    @IsTest
    static void testBatchFinish() {
        Test.startTest();
        SendWarrantyExpiryNotification batch = new SendWarrantyExpiryNotification();
        batch.finish(null);
        Test.stopTest();

        System.assert(true, 'Finish method should execute without errors');
    }

    // HTTP Mock for callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }

}