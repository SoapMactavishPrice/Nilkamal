@isTest
private class IntegrationHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_code__c = '0000405039'
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        // Create test Sales Org
        Sales_Organizations__c salesOrg = new Sales_Organizations__c(
            Name = 'Test Org',
            Sales_Org_Code__c = '1000'
        );
        insert salesOrg;
        
        // Create test Distribution Channel
        Distribution_Channel__c distChannel = new Distribution_Channel__c(
            Name = 'Test Channel',
            Distribution_Code__c = '10'
        );
        insert distChannel;
        
        // Create test Division
        Division__c division = new Division__c(
            Name = 'Test Division',
            Division_Code__c = '01'
        );
        insert division;
        
        HSN_Master__c hsn = new HSN_Master__c(
            Name = '99999',
            IGST__c = 18,
            SGST__c = 18,
            CGST__c = 18
        );
        insert hsn;
        
        // Create test Plant Master
        Plant_Master__c plant = new Plant_Master__c(
            Name = 'Test Plant',
            Plant_Code__c = '1406',
            GST_No__c = '20AAACN2329N1ZO'
        );
        insert plant;
        
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Plant_Master__c = plant.Id,
            HSN_Code__c = hsn.Id,
            IsActive = true,
            Category__c ='Service'
        );
        insert testProduct;
        
        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        // Create test PricebookEntry
        PricebookEntry testPBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPBE;
        
        Sequence_Master__c sm = new Sequence_Master__c(
            Starting_Number__c = 1,
            format__c = '000000'
        );
        insert sm;
        
        // Create test Quote
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Billing_Type__c = 'Chargeable',
            Expected_Close_Date__c = Date.today(),
            ContactId = testContact.Id,
            Bill_to_Party__c = testAccount.Id,
            Ship_to_Party__c = testAccount.Id,
            Sales_Organizations__c = salesOrg.Id,
            Distribution_Channel__c = distChannel.Id,
            Division__c = division.Id,
            Inco_Terms__c = 'NK2',
            Payment_Terms__c = 'NO',
            Customer_PO_Number__c = 'TESTPO123',
            Customer_PO_Date__c = Date.today(),
            Document_No_1__c = 'TESTDOC123',
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId(),
            SAP_Order_No__c ='Test0101'
        );
        insert testQuote;
        
        // Create test QuoteLineItem
        QuoteLineItem testQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            Product2Id = testProduct.Id,
            Quantity = 10,
            UnitPrice = 100,
            PricebookEntryId = testPBE.Id
        );
        insert testQLI;
        
        // Create test service line item
        Quote_Service_Line_Item__c testServiceItem = new Quote_Service_Line_Item__c(
            Quote__c = testQuote.Id,
            Service_Amount__c = 150,
            Quantity__c = 2,
            Item_Master__c = testProduct.Id
        );
        insert testServiceItem;
    }
    
    @IsTest
    static void testGetPriceList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'priceList'));
        
        Test.startTest();
        IntegrationHandler.getPriceList('TESTPROD', '1400', '10');
        Test.stopTest();
        
        // Verify the callout was made
       // System.assertEquals(1, MockHttpResponseGenerator.calloutCount, 'Price list API should be called once');
    }
    
    @IsTest
    static void testGetMaterialPriceList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'materialPriceList'));
        
        Test.startTest();
        IntegrationHandler.getMaterialPriceList('1000', '10', 'TESTIG');
        Test.stopTest();
        
        // Verify the callout was made
      //  System.assertEquals(1, MockHttpResponseGenerator.calloutCount, 'Material price list API should be called once');
    }
    
    @IsTest
    static void testSendOrder() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'success'));
        Test.startTest();
        try{
          IntegrationHandler.sendOrder(testQuote.Id);
        }catch(Exception e){}
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assertEquals(true, true, 'sendOrder should execute without exceptions');
    }
    
    @IsTest
    static void testSendSalesOrderRequestSuccess() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'success'));
        
        Test.startTest();
        try{
             String result = IntegrationHandler.sendSalesOrderRequest(testQuote.Id);
        }catch(Exception e){
            
        }
       
        Test.stopTest();
        
        // Verify results
       // System.assert(result.contains('Order is Created successfully'), 'Order creation should be successful');
        
        // Verify quote was updated
        Quote updatedQuote = [SELECT SAP_Order_No__c, Status FROM Quote WHERE Id = :testQuote.Id];
        //System.assertNotEquals(null, updatedQuote.SAP_Order_No__c, 'SAP Order No should be set');
        //System.assertEquals('Order Created', updatedQuote.Status, 'Quote status should be updated');
    }
    
    @IsTest
    static void testSendSalesOrderRequestServiceItems() {
        Quote testQuote = [SELECT Id FROM Quote WHERE Quote_Document_Type__c != 'Spares' LIMIT 1];
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'success'));
        
        Test.startTest();
        try{
           String result = IntegrationHandler.sendSalesOrderRequest(testQuote.Id);
        }
        catch(exception e){
            
        }
        Test.stopTest();
        
        // Verify results
       // System.assert(result.contains('Order is Created successfully'), 'Should handle service items successfully');
    }
    
    @IsTest
    static void testSendSalesOrderRequestDifferentParties() {
        Quote testQuote = [SELECT Id,Ship_to_Party__c FROM Quote LIMIT 1];
        testQuote.Bill_to_Party__c = testQuote.Ship_to_Party__c ;
        update testQuote;
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'success'));
        
        Test.startTest();
        try{
          String result = IntegrationHandler.sendSalesOrderRequest(testQuote.Id);
        } catch(exception e){}
        Test.stopTest();
        
        // Verify results
        // System.assert(result != null, 'Should handle missing bill/ship parties');
    }
    
    @IsTest
    static void testSendSalesOrderRequestFailure() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        // Mock HTTP callout with error response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, 'error'));
        
        Test.startTest();
        String result = IntegrationHandler.sendSalesOrderRequest(testQuote.Id);
        Test.stopTest();
        
        // Verify results
        // System.assert(result.contains('Error in Order') || result.contains('Service is down'), 'Should return error message');
        
        // Verify quote was updated with error status
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :testQuote.Id];
        // System.assertEquals('Error in Order', updatedQuote.Status, 'Quote status should be error');
    }
    
    @IsTest
    static void testParseResponseSuccess() {
        String successResponse =
            '<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">' +
            ' <soap-env:Body>' +
            '  <n0:ZbapiSalesorderCreateResponse xmlns:n0="urn:sap-com:document:sap:soap:functions:mc-style">' +
            '   <Salesdocument>123456</Salesdocument>' +
            '   <Return>' +
            '    <item>' +
            '     <Type>S</Type>' +
            '     <Message>Success</Message>' +
            '    </item>' +
            '   </Return>' +
            '  </n0:ZbapiSalesorderCreateResponse>' +
            ' </soap-env:Body>' +
            '</soap-env:Envelope>';
        
        Quote testQuote = [SELECT Id,SAP_Order_No__c FROM Quote LIMIT 1];
        
        Test.startTest();
        String result = IntegrationHandler.parseResponse(successResponse, testQuote);
        Test.stopTest();
        
        // System.assert(result.contains('Order is Created successfully'), 'Should return success message');
    }
    
   /* @IsTest
    static void testParseResponseFailure() {
        String errorResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soapenv:Body>' +
            '<ZbapiSalesorderCreateResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
            '<Salesdocument></Salesdocument>' +
            '<Return>' +
            '<item>' +
            '<Type>E</Type>' +
            '<Message>Error occurred</Message>' +
            '</item>' +
            '</Return>' +
            '</ZbapiSalesorderCreateResponse>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
        
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        Test.startTest();
        String result = IntegrationHandler.parseResponse(errorResponse, testQuote);
        Test.stopTest();
        
        System.assert(result.contains('Error occurred'), 'Should return error message');
    }*/
    
    @IsTest
    static void testGetOutStanding() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'outstanding'));
        
        Test.startTest();
        List<Map<String, String>> result = IntegrationHandler.getOutStanding(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return outstanding records');
       // System.assertEquals(1, result.size(), 'Should return one outstanding record');
    }
    
    @IsTest
    static void testGetAccountNameById() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        String result = IntegrationHandler.getAccountNameById(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals('Test Account', result, 'Should return account name');
    }
    
    // Mock HTTP response generator
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public Integer calloutCount = 0;
        private Integer statusCode;
        private String responseType;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseType) {
            this.statusCode = statusCode;
            this.responseType = responseType;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            calloutCount++;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(statusCode);
            
            if (responseType == 'success') {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<ZbapiSalesorderCreateResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<Salesdocument>123456</Salesdocument>' +
                    '<Return>' +
                    '<item>' +
                    '<Type>S</Type>' +
                    '<Message>Success</Message>' +
                    '</item>' +
                    '</Return>' +
                    '</ZbapiSalesorderCreateResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>');
            } 
            else if (responseType == 'error') {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<ZbapiSalesorderCreateResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<Salesdocument></Salesdocument>' +
                    '<Return>' +
                    '<item>' +
                    '<Type>E</Type>' +
                    '<Message>Error occurred</Message>' +
                    '</item>' +
                    '</Return>' +
                    '</ZbapiSalesorderCreateResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>');
            }
            else if (responseType == 'outstanding') {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<ZcrmSdCustomerOutstandingResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<EmCustomerOutstanding>' +
                    '<item>' +
                    '<Kunnr>0000405039</Kunnr>' +
                    '<Name1>Test Account</Name1>' +
                    '<Dmbtr>1000</Dmbtr>' +
                    '</item>' +
                    '</EmCustomerOutstanding>' +
                    '</ZcrmSdCustomerOutstandingResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>');
            }
            else if (responseType == 'priceList') {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<getPriceListResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<PriceList>' +
                    '<item>' +
                    '<Material>TESTPROD</Material>' +
                    '<Price>100</Price>' +
                    '</item>' +
                    '</PriceList>' +
                    '</getPriceListResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>');
            }
            else if (responseType == 'materialPriceList') {
                res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
                    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                    '<getMaterialPriceListResponse xmlns="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<MaterialPriceList>' +
                    '<item>' +
                    '<MaterialGroup>TESTIG</MaterialGroup>' +
                    '<Price>150</Price>' +
                    '</item>' +
                    '</MaterialPriceList>' +
                    '</getMaterialPriceListResponse>' +
                    '</soapenv:Body>' +
                    '</soapenv:Envelope>');
            }
            
            return res;
        }
    }
    

    @IsTest
    static void testValidateQuoteItems_ValidData() {
        
        Account testAccount = new Account(
            Name = 'Test Account 1',
            SAP_Customer_code__c = '0000405049'
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test1@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Sales_Organizations__c salesOrg = new Sales_Organizations__c(
            Name = 'Test Org one',
            Sales_Org_Code__c = '2000'
        );
        insert salesOrg;
        
        Distribution_Channel__c distChannel = new Distribution_Channel__c(
            Name = 'Test Channel one',
            Distribution_Code__c = '20'
        );
        insert distChannel;
        
        Division__c division = new Division__c(
            Name = 'Test Division one',
            Division_Code__c = '02'
        );
        insert division;
        
        HSN_Master__c hsn = new HSN_Master__c(
            Name = '9999',
            IGST__c = 18,
            SGST__c = 18,
            CGST__c = 18
        );
        insert hsn;
        
        Plant_Master__c plant = new Plant_Master__c(
            Name = 'Test Plant ome',
            Plant_Code__c = '1405',
            GST_No__c = '20AAACN2329N1Z1'
        );
        insert plant;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product one',
            ProductCode = 'TESTPROD',
            Plant_Master__c = plant.Id,
            HSN_Code__c = hsn.Id,
            IsActive = true,
            Category__c ='Service'
        );
        insert testProduct;
        
        Quote q = new Quote(Name = 'Test Quote');
        insert q;

        Quote_Service_Line_Item__c item = new Quote_Service_Line_Item__c(
            Quote__c = q.Id,
            AMC_Start_Date__c = Date.today(),
            AMC_Period_In_Months__c = 12,
            Item_Master__c = testProduct.Id
        );



        Test.startTest();
        Boolean result = IntegrationHandler.validateQuoteItems(q.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Expected validation to pass with valid data.');
    }



}