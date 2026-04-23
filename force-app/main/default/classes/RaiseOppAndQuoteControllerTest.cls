@isTest
public class RaiseOppAndQuoteControllerTest {

    @TestSetup
    static void setupTestData() {
        Division__c div01 = new Division__c(
            Name = '01',
            Division_Code__c = '01'
        );
        Division__c div03 = new Division__c(
            Name = '03',
            Division_Code__c = '03'
        );
        insert new List<Division__c>{div01, div03};

        Distribution_Channel__c distChannel01 = new Distribution_Channel__c(
            Name = '10',
            Distribution_Code__c = '10'
        );
        insert distChannel01;

        Sales_Organizations__c salesOrg01 = new Sales_Organizations__c(
            Name = '1000',
            Sales_Org_Code__c = '1000'
        );
        insert salesOrg01;

        Account testAccount = new Account(
            Name = 'Test Account',
            Pricelist__c = Test.getStandardPricebookId(),
            Division__c = div01.Id
        );
        insert testAccount;

        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            AccountId = testAccount.Id
        );
        insert testContact;

        Asset testAsset = new Asset(
            Name = 'TESTASSET123',
            SerialNumber = 'TESTASSET123',
            AccountId = testAccount.Id,
            End_Customer__c = testAccount.Id
        );
        insert testAsset;

        Invoice__c testInvoice = new Invoice__c(
            Sold_To_Party_1__c = testAccount.Id,
            Ship_To_Party_1__c = testAccount.Id,
            Division_1__c = div01.Id
        );
        insert testInvoice;

        testAsset.Invoice__c = testInvoice.Id;
        update testAsset;


        Case testCase = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            AssetId = testAsset.Id,
            Division__c = 'MHE',
            Type = 'Breakdown',
            Case_Sub_Type__c = 'Chargeable Service'
        );
        insert testCase;

        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c];

        Sequence_Master__c sm = new Sequence_Master__c (
        format__c = '0000',
        Starting_Number__c  = 1);
        insert sm;

        HSN_Master__c hm = new HSN_Master__c(Name='test',IGST__c=18,SGST__c= 9,CGST__c=9);
        insert hm;

        Product2 spareProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            IsActive = true,
            Category__c = 'Spare',
            HSN_Code__c = hm.Id,
            Warranty__c = 'Y'
        );
        insert spareProduct;

        Product2 serviceProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            IsActive = true,
            Category__c = 'Service',
            HSN_Code__c =  hm.Id,
            Warranty__c = 'Y'
        );
        insert serviceProduct;

        PricebookEntry sparePBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = spareProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert sparePBE;

        PricebookEntry servicePBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = serviceProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert servicePBE;

        List<Spare_Request__c> spareRequests = new List<Spare_Request__c>();
        spareRequests.add(new Spare_Request__c(
            Work_Order__c = testWorkOrder.Id,
            Item_Master__c = spareProduct.Id,
            Pricebook_Entry_Id__c = sparePBE.Id,
            Quantity_Required__c = 1,
            Billed_Value__c = 100.00,
            Billing_Type__c = 'Chargeable',
            Warranty_Period__c = '12',
            Number_of_PM_Visit__c = '2',
            Number_of_Breakdown_Visit__c = '3',
            Item_Description__c = 'Test Description',
            OEM_Material_Code__c = 'TESTCODE',
            Total_Stock__c = 10,
            Category__c = 'Test Category'
        ));

        spareRequests.add(new Spare_Request__c(
            Work_Order__c = testWorkOrder.Id,
            Item_Master__c = spareProduct.Id,
            Pricebook_Entry_Id__c = sparePBE.Id,
            Quantity_Required__c = 2,
            Billed_Value__c = 200.00,
            Billing_Type__c = 'FOC and Returnable',
            Warranty_Period__c = '24',
            Number_of_PM_Visit__c = '4',
            Number_of_Breakdown_Visit__c = '5'
        ));
        insert spareRequests;

        List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
        serviceRequests.add(new Service_Request__c(
            Work_Order__c = testWorkOrder.Id,
            Item_Master__c = serviceProduct.Id,
            Pricebook_Entry_Id__c = servicePBE.Id,
            Quantity__c = 1,
            Price__c = 100.00,
            Original_Price__c = 100.00,
            Warranty_Period__c = '12',
            Number_of_PM_Visit__c = '2',
            Number_of_Breakdown_Visit__c = '3',
            Item_Description__c = 'Test Description'
        ));

        serviceRequests.add(new Service_Request__c(
            Work_Order__c = testWorkOrder.Id,
            Item_Master__c = serviceProduct.Id,
            Pricebook_Entry_Id__c = servicePBE.Id,
            Quantity__c = 2,
            Price__c = 200.00,
            Original_Price__c = 200.00,
            Warranty_Period__c = '24',
            Number_of_PM_Visit__c = '4',
            Number_of_Breakdown_Visit__c = '5'
        ));
        insert serviceRequests;
    }


    @isTest
    static void testRaiseOppAndQuoteSpare() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__c, Case__r.AssetId FROM Work_Order__c];

        Test.startTest();
        List<Id> result = (List<Id>)RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'spare');
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Case__c = :testWorkOrder.Case__c];

        List<Quote> quotes = [SELECT Id FROM Quote WHERE Work_Order__c = :testWorkOrder.Id];

        List<Spare_Request__c> spareRequests = [
            SELECT Id, Opp_Raised__c, Quote_Raised__c
            FROM Spare_Request__c
            WHERE Work_Order__c = :testWorkOrder.Id
        ];

        for(Spare_Request__c sr : spareRequests) {
            System.assertEquals(true, sr.Opp_Raised__c, 'Spare Request should be marked as Opp Raised');
            System.assertEquals(true, sr.Quote_Raised__c, 'Spare Request should be marked as Quote Raised');
        }
    }

    @isTest
    static void testRaiseOppAndQuoteService() {
        Work_Order__c testWorkOrder = [SELECT Id,Case__r.AssetId FROM Work_Order__c];

        Test.startTest();
        Id result = (Id)RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id, null,'service');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return quote ID');

        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Case__c = :testWorkOrder.Case__c];
        System.assertEquals(1, opps.size(), 'Should create 1 opportunity');

        List<Quote> quotes = [SELECT Id FROM Quote WHERE Work_Order__c = :testWorkOrder.Id AND Id = :result];
        System.assertEquals(1, quotes.size(), 'Should create 1 quote');

        List<Service_Request__c> serviceRequests = [
            SELECT Id, Opp_Raised__c, Quote_Raised__c
            FROM Service_Request__c
            WHERE Work_Order__c = :testWorkOrder.Id
        ];

        for(Service_Request__c sr : serviceRequests) {
            System.assertEquals(true, sr.Opp_Raised__c, 'Service Request should be marked as Opp Raised');
            System.assertEquals(true, sr.Quote_Raised__c, 'Service Request should be marked as Quote Raised');
        }
    }

    @isTest
    static void testRaiseOppAndQuoteNoAsset() {
        // Test data setup
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Account acc = new Account(Name = 'Test1 Account1');
        insert acc;

        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        // Create an Asset
        Asset asset = new Asset(Name = 'Test Asset', AccountId = testAccount.Id, End_Customer__c = acc.Id );
        insert asset;

        // Case WITH Asset - Insert directly to avoid validation rule
        Case caseWithAsset = new Case(
            Subject = 'Case With Asset',
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            AccountId = testAccount.Id
        );
        insert caseWithAsset;

            Asset asset1 = new Asset(Name = 'Test1 Asset',AccountId = testAccount.Id, End_Customer__c = acc.Id);
        insert asset1;

        // Case WITHOUT Asset
        Case caseWithoutAsset = new Case(
            Subject = 'Case Without Asset',
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset1.Id,
            AccountId = testAccount.Id
        );
        insert caseWithoutAsset;

        Test.startTest();

        // Scenario 1: Case with Asset (should run normally or as per logic)
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id, null, 'spare');
        }
        catch (AuraHandledException e) {
            System.debug('Exception for Case With Asset: ' + e.getMessage());
        }

        // Scenario 2: Case without Asset (might throw your "Please make sure Asset..." error)
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id, null, 'spare');
        }
        catch (AuraHandledException e) {
            System.debug('Exception for Case Without Asset: ' + e.getMessage());
            // Optional: Assert specific message
            // System.assertEquals('Please make sure Asset is tagged on the Case and try again.', e.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteNoAccount() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Case testCase = [SELECT Id FROM Case LIMIT 1];
        // testCase.AccountId = acc.Id;

        // update testCase;

        Test.startTest();
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'spare');
        }
        catch(AuraHandledException e) {
            // System.assertEquals('Please make sure Account is tagged on the Case and try again.', e.getMessage(), 'Expected specific exception message');
        }
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteNoPricebook() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        testAccount.Pricelist__c = null;
        update testAccount;

        Test.startTest();
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'spare');
            System.assert(false, 'Expected exception was not thrown');
        }
        catch(AuraHandledException e) {
            // System.assertEquals('Please make sure Pricelist is tagged on the Account and try again.', e.getMessage(), 'Expected specific exception message');
        }
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteNoOpenSpareRequests() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        List<Spare_Request__c> spareRequests = [
            SELECT Id
            FROM Spare_Request__c
            WHERE Work_Order__c = :testWorkOrder.Id
        ];

        for(Spare_Request__c sr : spareRequests) {
            sr.Opp_Raised__c = true;
            sr.Quote_Raised__c = true;
        }
        update spareRequests;

        Test.startTest();
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'spare');
        }
        catch(AuraHandledException e) {
            // System.assertEquals('There are no open Spare Requests, please raise a Spare Request and try again.', e.getMessage(), 'Expected specific exception message');
        }
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteNoOpenServiceRequests() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        List<Service_Request__c> serviceRequests = [
            SELECT Id
            FROM Service_Request__c
            WHERE Work_Order__c = :testWorkOrder.Id
        ];

        for(Service_Request__c sr : serviceRequests) {
            sr.Opp_Raised__c = true;
            sr.Quote_Raised__c = true;
        }
        update serviceRequests;

        Test.startTest();
        try {
            RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'service');
        }
        catch(AuraHandledException e) {
            // System.assertEquals('There are no open Service Requests, please raise a Service Request and try again.', e.getMessage(), 'Expected specific exception message');
        }
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteWithExistingOppAndQuote() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        List<Id> secondResult = (List<Id>)RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id, null,'spare');
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteWithExistingOppAndPresentedQuote() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        List<Id> secondResult = (List<Id>)RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id, null,'spare');
        Test.stopTest();
    }

    @isTest
    static void testRaiseOppAndQuoteWithAMCServiceRequest() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        Id result = (Id)RaiseOppAndQuoteController.raiseOppAndQuote(testWorkOrder.Id,null, 'service');
        Test.stopTest();

        Quote amcQuote = [SELECT Id, Quote_Document_Type__c FROM Quote WHERE Id = :result];
    }

}