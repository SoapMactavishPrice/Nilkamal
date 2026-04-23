@isTest
private class FieldServiceCreateCaseControllerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(
            Name = 'Test Account',
            Street_House_Number__c = '123',
            Street1__c = 'Main St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Postal_code__c = '123456',
            SAP_Customer_code__c = 'SAP123',
            Customer_Blocked__c = false
        );
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert testContact;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            SerialNumber = 'SN12345'
        );
        insert testAsset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Test Warranty',
            Asset__c = testAsset.Id,
            Warranty_Start_Date__c = Date.today(),
            Warranty_End_Date__c = Date.today().addYears(1),
            Asset_Warranty_PO_Status__c = 'Active',
            Warranty_Period__c = 1
        );
        insert warranty;

        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'Test AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = Date.today(),
            AMC_End_Date__c = Date.today().addMonths(6),
            Asset_AMC_PO_Status__c = 'Active',
            AMC_Period_In_Months__c = 1,
            Product_Category_Type__c = 'AMC'
        );
        insert amc;

        Case cs = new Case(
            AccountId = acc.Id,
            AssetId = testAsset.Id, 
            Status = 'New',
            Origin = 'Phone'
        );
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.Business_Unit__c = 'Unit A';
        update currentUser;
    }

    @isTest
    static void testGetCasePriorities() {
        Test.startTest();
        List<Case_Priority__mdt> priorities = FieldServiceCreateCaseController.getCasePriorities();
        Test.stopTest();
        System.assertNotEquals(null, priorities);
    }

    @isTest
    static void testGetAssetsByCustomer() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCreateCaseController.getAssetsByCustomer(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetAssetDetails() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCreateCaseController.getAssetDetails(asset.Id);
        try {
            FieldServiceCreateCaseController.getAssetDetails('');
        }
        catch(Exception e) {}
        Test.stopTest();
        System.assert(result != null);
    }

    @isTest
    static void testCheckForExistingCase() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Test.startTest();
        Case existingCase = FieldServiceCreateCaseController.checkForExistingCase(asset.Id);
        Test.stopTest();
        System.assertNotEquals(null, existingCase); 
    }

    @isTest
    static void testGetAccountDetails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCreateCaseController.getAccountDetails(acc.Id);
        Test.stopTest();
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testCreateCase() {
        Account acc = new Account(Name = 'Test1 Account');
        insert acc;
        
        Asset testAsset1 = new Asset(Name = 'Tes1t Asset',AccountId =acc.Id);
        insert testAsset1;
        
        Case caseRecord = new Case(
            Subject = 'Create Case Test',
            Status = 'New',
            Origin = 'Phone',
            AssetId = testAsset1.Id,
            AccountId = acc.Id
        );
        Test.startTest();
        String workOrderId = FieldServiceCreateCaseController.createCase(caseRecord);
        Test.stopTest();
        System.assertNotEquals(null, workOrderId);
    }

    @isTest
    static void testGetUserBusinessUnit() {
        Test.startTest();
        String businessUnit = FieldServiceCreateCaseController.getUserBusinessUnit();
        Test.stopTest();
        System.assertNotEquals(null, businessUnit);
    }
}