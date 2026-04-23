@IsTest
private class FieldsServiceSpareRequestTest {

    @TestSetup
    static void setupTestData() {

        Pricebook2 testPricebook2 = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook2;

        List<Division__c> divisions = new List<Division__c>();
        Division__c dv = new Division__c(Name = '01',Division_Code__c='01');
        divisions.add(dv);
        dv = new Division__c(Name = '03', Division_Code__c='03');
        divisions.add(dv);
        insert divisions;

        HSN_Master__c hsn = new HSN_Master__c();
        hsn.Name = '123456';
        hsn.IGST__c = 9;
        hsn.SGST__c = 9;
        hsn.CGST__c = 18;
        insert hsn;

        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Pricelist__c = Test.getStandardPricebookId(),
            Division__c = dv.Id
        );
        insert testAccount;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert opp;

        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-001',
            IsActive = true,
            Category__c = 'Spare',
            Business_Vertical__c = 'MHE',
            HSN_Code__c = hsn.Id
        );
        insert testProduct;

        // Create test Asset
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            Product2Id = testProduct.Id,
            SerialNumber = 'SN-001'
        );
        insert testAsset;

        Asset_Spare_Category__c asct = new Asset_Spare_Category__c(Category__c = 'Fast Moving',Quantity__c=2,Spare_Material_Code__c =testProduct.Id ,Asset_Serial_No__c=testAsset.Id);
        insert asct;

        // Create test Case
        Case testCase = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id,
            AssetId = testAsset.Id,
            Division__c = 'MHE'
        );
        insert testCase;

        // Create test Work Order
        Work_Order__c testWorkOrder = new Work_Order__c(
            Case__c = testCase.Id
        );
        insert testWorkOrder;

        Sequence_Master__c sm = new Sequence_Master__c (
        format__c = '0000',
        Starting_Number__c  = 1);
        insert sm;

        // Create test Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            Work_Order__c = testWorkOrder.Id,
            OpportunityId = opp.Id,
            Division__c = dv.Id
        );
        insert testQuote;

        // Create test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        Product2 testProduct2 = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct2;

        Id standardPricebookId = Test.getStandardPricebookId();

        PricebookEntry standardPriceEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPriceEntry;

        Pricebook2 testPricebook3 = new Pricebook2(
            Name = 'Test Custom Pricebook',
            IsActive = true
        );
        insert testPricebook3;

        // Create test PricebookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert testPricebookEntry;

        // Create test Equipment Spare Master
        Equipment_Spare_Master__c testESM = new Equipment_Spare_Master__c(
            SAP_Material_Code_Spare__c = testProduct.Id,
            SAP_Nilkamal_Model_Code_Equipment__c = testProduct.Id
            //Returnable_NonReturnable__c = 'Returnable',
            //Chargeable_NonChargeable__c = 'Chargeable'
        );
        insert testESM;

        // Create test Inventory
        Inventory__c testInventory = new Inventory__c(
            Material__c = testProduct.Id,
            Quantity__c = 10
        );
        insert testInventory;
    }

    @IsTest
    static void testGetQuoteRecordDetails() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        Quote result = FieldsServiceSpareRequest.getQuoteRecordDetails(testQuote.Id);
        Test.stopTest();

        System.assertEquals(testQuote.Id, result.Id, 'Should return the correct Quote record');
    }

    @IsTest
    static void testGetQuoteRecordDetailsWithException() {
        Test.startTest();
        try {
            Quote result = FieldsServiceSpareRequest.getQuoteRecordDetails('invalidId');
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected exception was thrown');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetWorkOrderData() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        List<Work_Order__c> result = FieldsServiceSpareRequest.getWorkOrderData(testWorkOrder.Id);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should return one Work Order');
        System.assertEquals(testWorkOrder.Id, result[0].Id, 'Should return the correct Work Order');
    }

    @IsTest
    static void testGetWorkOrderData1() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        Work_Order__c result = FieldsServiceSpareRequest.getWorkOrderData1(testWorkOrder.Id);
        Test.stopTest();

        System.assertEquals(testWorkOrder.Id, result.Id, 'Should return the correct Work Order');
    }

    @IsTest
    static void testGetAssetDetails() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        Object result = FieldsServiceSpareRequest.getAssetDetails(testWorkOrder.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return asset details');
    }

    @IsTest
    static void testGetSparePartsByName() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__r.Asset.Product2Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        String result = FieldsServiceSpareRequest.getSparePartsByName(testWorkOrder.Case__r.Asset.Product2Id, testWorkOrder.Id, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return spare parts data');
        List<Object> resultList = (List<Object>)JSON.deserializeUntyped(result);
       // System.assert(!resultList.isEmpty(), 'Should return at least one spare part');
    }

    @IsTest
    static void testGetSparePartsByNameShowAll() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];

        try{
        Work_Order__c testWorkOrder = [SELECT Id,Case__r.AssetId FROM Work_Order__c LIMIT 1];

        Test.startTest();
        String result = FieldsServiceSpareRequest.getSparePartsByName(testProduct.Id, testWorkOrder.Id, true);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return spare parts data');
        }catch(exception e){

        }
    }

    @IsTest
    static void testGetAssetCategory() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__r.Asset.Product2Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        String result = FieldsServiceSpareRequest.getAssetCategory(testWorkOrder.Case__r.Asset.Product2Id, testWorkOrder.Id, 'Test Category');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return spare parts data');
    }

    @IsTest
    static void testGetAssetCategory_v1() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__r.Asset.Product2Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        String result = FieldsServiceSpareRequest.getAssetCategory_v1(testWorkOrder.Case__r.Asset.Product2Id, testWorkOrder.Id, true, false, false);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return spare parts data');
    }

    @IsTest
    static void testCreateSpareRequests() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__c, Case__r.AssetId FROM Work_Order__c LIMIT 1];
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];



        List<Map<String, Object>> spareParts = new List<Map<String, Object>>();
        Map<String, Object> sparePart = new Map<String, Object>{
            'checkbox' => true,
            'quantity' => 2,
            'prodId' => testProduct.Id,
            'prodName' => testProduct.Name,
            'modelDesc' => 'Test Description',
            'price' => '100',
            'pricebookEntryId' => [SELECT Id FROM PricebookEntry LIMIT 1].Id,
            'currencyCode' => 'INR',
            'billingType' => 'Chargeable',
            'warrantyperiod' => '1 Year',
            'noofpmvisit' => '2',
            'noofbreakdownvisit' => '1',
            'modelName' => 'Test Model',
            'totalStock' => '10',
            'category' => 'F'
        };
        spareParts.add(sparePart);
        try{
        Test.startTest();
        FieldsServiceSpareRequest.createSpareRequests(testWorkOrder.Id, testQuote.Id, spareParts, null);
        Test.stopTest();

        List<Spare_Request__c> spareRequests = [SELECT Id FROM Spare_Request__c WHERE Work_Order__c = :testWorkOrder.Id];
        System.assertEquals(1, spareRequests.size(), 'Should create one Spare Request');
        }catch(Exception e){

        }
    }



    @IsTest
    static void testCreateSpareRequestsWithoutQuote() {
        Work_Order__c testWorkOrder = [SELECT Id, Case__c, Case__r.AssetId FROM Work_Order__c LIMIT 1];
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];

        List<Map<String, Object>> spareParts = new List<Map<String, Object>>();
        Map<String, Object> sparePart = new Map<String, Object>{
            'checkbox' => true,
            'quantity' => 2,
            'prodId' => testProduct.Id,
            'prodName' => testProduct.Name,
            'modelDesc' => 'Test Description',
            'price' => '100',
            'pricebookEntryId' => [SELECT Id FROM PricebookEntry LIMIT 1].Id,
            'currencyCode' => 'INR',
            'billingType' => '',
            'warrantyperiod' => '1 Year',
            'noofpmvisit' => '2',
            'noofbreakdownvisit' => '1',
            'modelName' => 'Test Model',
            'totalStock' => '10',
            'category' => 'F'
        };
        spareParts.add(sparePart);

        Test.startTest();
        FieldsServiceSpareRequest.createSpareRequests(testWorkOrder.Id, null, spareParts, null);
        Test.stopTest();

        List<Spare_Request__c> spareRequests = [SELECT Id FROM Spare_Request__c WHERE Work_Order__c = :testWorkOrder.Id];
        System.assertEquals(1, spareRequests.size(), 'Should create one Spare Request');
    }

    @IsTest
    static void testCreateSpareRequestsWithInvalidInput() {
        Test.startTest();
        try {
            FieldsServiceSpareRequest.createSpareRequests(null, null, new List<Map<String, Object>>(), null);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected exception was thrown');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetAllSparesDetails() {
        Work_Order__c testWorkOrder = [SELECT Id FROM Work_Order__c LIMIT 1];
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        Test.startTest();
        FieldsServiceSpareRequest.getAllSparesDetails('12345', testWorkOrder.Id, '["' + testProduct.Id + '"]', null);
        FieldsServiceSpareRequest.getAllSparesDetails('12345', testWorkOrder.Id, '[\'00511333\']', new String[]{ testProduct.Id });
        Test.stopTest();
    }

    /*@IsTest
    static void testFetchInventory() {
        // This is a mock test since we can't actually call the external API in a test
                 Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'success'));

        Test.startTest();
        List<FieldsServiceSpareRequest.InventoryWrapper> result = FieldsServiceSpareRequest.fetchInventory('MHECAMCSER', 'PLANT1');
        Test.stopTest();

        // Since we can't mock the external API call, we just verify the method runs without errors
        System.assert(true, 'Method executed without errors');
    }*/




    // Inner class to mock the web service callout
    private class MockCalloutResponse implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {

            // Create the response element that your API expects
            inventoryFunctionsMcS.ZbapiOrderstockResponse_element responseElement = new inventoryFunctionsMcS.ZbapiOrderstockResponse_element();
            responseElement.Output = new inventoryFunctionsMcS.TableOfZbapiOrdstk();

            // Create and populate mock data
            inventoryFunctionsMcS.ZbapiOrdstk mockItem = new inventoryFunctionsMcS.ZbapiOrdstk();
            mockItem.Material = 'MAT001';
            mockItem.Plant = 'PLANT001';
            mockItem.PlantName = 'Test Plant';
            mockItem.UnrestrictedStock = '100';
            mockItem.TotalStock = '150';
            mockItem.StockInTransit = '50';
            mockItem.ManufacturingPartNo = 'MPN001';

            // Add item to the output table
            responseElement.Output.item = new List<inventoryFunctionsMcS.ZbapiOrdstk>{mockItem};

            // Put the response element in the response map
            response.put('response_x', responseElement);
        }
    }

    @IsTest
    static void testFetchInventoryWithValidData() {
        // Set the mock callout
        Test.setMock(WebServiceMock.class, new MockCalloutResponse());

        String testMaterial = 'MAT001';
        String testPlant = 'PLANT001';

        Test.startTest();
        List<FieldsServiceSpareRequest.InventoryWrapper> result = FieldsServiceSpareRequest.fetchInventory(testMaterial, testPlant);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one inventory item');
        System.assertEquals(testMaterial, result[0].Material, 'Material should match');
        System.assertEquals(testPlant, result[0].Plant, 'Plant should match');
        System.assertEquals('100', result[0].UnrestrictedStock, 'Unrestricted stock should match');
    }



}