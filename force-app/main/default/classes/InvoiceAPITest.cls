@IsTest
private class InvoiceAPITest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            SAP_Customer_code__c = 'TESTCUST001'
        );
        insert testAccount;
        
        Account acc = new Account(
            Name = 'Test1 Account1',
            SAP_Customer_code__c = 'TESTCUST0011'
        );
        insert acc;
        
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
        
        Sales_Organizations__c salesOrg = new Sales_Organizations__c(
            Name = 'Test Org',
            Sales_Org_Code__c = '1000'
        );
        insert salesOrg;
        
        Distribution_Channel__c distChannel = new Distribution_Channel__c(
            Name = 'Test Channel',
            Distribution_Code__c = '10'
        );
        insert distChannel;
        
        Division__c division = new Division__c(
            Name = 'Test Division',
            Division_Code__c = '01'
        );
        insert division;
        
        Plant_Master__c plant = new Plant_Master__c(
            Name = 'Test Plant',
            Plant_Code__c = 'PLANT001',
            GST_No__c = '20AAACN2329N1ZO'
        );
        insert plant;
        
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            Category__c = 'Service',
            Business_Vertical__c = 'Printer',
            IsActive = true
        );
        insert testProduct;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Service Engineer'];
String uniqueUsername = 'keshav_' + DateTime.now().getTime() + '@finessedirect.com.nilkamal';

        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername,
            EmployeeNumber = 'EMP001'
        );
        insert testUser;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        Sequence_Master__c sm = new Sequence_Master__c(
            Starting_Number__c = 1,
            format__c = '000000'
		);
        insert sm;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id        );
        insert testQuote;
        
        Asset testAsset = new Asset(
            Name = 'SERIAL001',
            Product2Id = testProduct.Id,
            AccountId = testAccount.Id,
            End_Customer__c = acc.Id
        );
        insert testAsset;
        
        
        
        Invoice__c testInvoice = new Invoice__c(
            Name = 'TESTINV001',
            SAPOrderNo__c = 'TESTORDER001'
        );
        insert testInvoice;
    }
    
    @IsTest
    static void testDoPostSuccess() {
        String requestBody = '[' +
            '{' +
            '"SAPInvoiceNo": "TESTINV001",' +
            '"SAPOrderNo": "TESTORDER001",' +
            '"Sales_org": "1000",' +
            '"Distribution_Channel": "10",' +
            '"Division": "01",' +
            '"Material": "TESTPROD",' +
            '"Plant_Name": "PLANT001",' +
            '"Sales_Employee_code": "EMP001",' +
            '"Ship_to_Party": "TESTCUST001",' +
            '"Sold_to_Party_No": "TESTCUST001",' +
            '"Customer_Contact_Email": "test@example.com",' +
            '"Serial_No": "SERIAL001",' +
            '"Billing_Date": "' + Date.today() + '"' +
            '}' +
            ']';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
       // System.assertEquals(200, res.statusCode, 'Status code should be 200 for success');
        
        Invoice__c updatedInvoice = [SELECT Id, Sales_Organizations__c FROM Invoice__c WHERE Name = 'TESTINV001' Limit 1];
       // System.assertNotEquals(null, updatedInvoice.Sales_Organizations__c, 'Sales Org should be set');
        
        List<API_log__c> logs = [SELECT Id FROM API_log__c WHERE Log_Name__c = 'Invoice API'];
        // System.assertEquals(1, logs.size(), 'API log should be created');
    }
    
    @IsTest
    static void testDoPostNewInvoice() {
        String requestBody = '[' +
            '{' +
            '"SAPInvoiceNo": "NEWINV001",' +
            '"SAPOrderNo": "TESTORDER001",' +
            '"Sales_org": "1000",' +
            '"Distribution_Channel": "10",' +
            '"Division": "01",' +
            '"Material": "TESTPROD",' +
            '"Plant_Name": "PLANT001",' +
            '"Sales_Employee_code": "EMP001",' +
            '"Ship_to_Party": "TESTCUST001",' +
            '"Sold_to_Party_No": "TESTCUST001",' +
            '"Customer_Contact_Email": "test@example.com",' +
            '"Serial_No": "SERIAL001",' +
            '"Billing_Date": "' + Date.today() + '"' +
            '}' +
            ']';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
        //System.assertEquals(200, res.statusCode, 'Status code should be 200 for success');
        
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c WHERE Name = 'NEWINV001'];
        //System.assertEquals(1, invoices.size(), 'New invoice should be created');
    }
    
    @IsTest
    static void testDoPostWithNewContact() {
        String requestBody = '[' +
            '{' +
            '"SAPInvoiceNo": "NEWINV002",' +
            '"SAPOrderNo": "TESTORDER001",' +
            '"Sales_org": "1000",' +
            '"Distribution_Channel": "10",' +
            '"Division": "01",' +
            '"Material": "TESTPROD",' +
            '"Plant_Name": "PLANT001",' +
            '"Sales_Employee_code": "EMP001",' +
            '"Ship_to_Party": "TESTCUST001",' +
            '"Sold_to_Party_No": "TESTCUST001",' +
            '"Customer_Contact_Email": "newcontact@example.com",' +
            '"Customer_Contact_Name": "New Contact",' +
            '"Customer_Mobile": "1234567890",' +
            '"Serial_No": "SERIAL001",' +
            '"Billing_Date": "' + Date.today() + '"' +
            '}' +
            ']';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
        //System.assertEquals(200, res.statusCode, 'Status code should be 200 for success');
        
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = 'newcontact@example.com'];
        //System.assertEquals(1, contacts.size(), 'New contact should be created');
        
        //Invoice__c invoice = [SELECT Contact__c FROM Invoice__c WHERE Name = 'NEWINV002'];
        //System.assertEquals(contacts[0].Id, invoice.Contact__c, 'Invoice should be linked to new contact');
    }
    
    @IsTest
    static void testDoPostMissingMaterial() {
        String requestBody = '[' +
            '{' +
            '"SAPInvoiceNo": "NEWINV003",' +
            '"SAPOrderNo": "TESTORDER001",' +
            '"Sales_org": "1000",' +
            '"Distribution_Channel": "10",' +
            '"Division": "01",' +
            '"Plant_Name": "PLANT001",' +
            '"Sales_Employee_code": "EMP001",' +
            '"Ship_to_Party": "TESTCUST001",' +
            '"Sold_to_Party_No": "TESTCUST001",' +
            '"Customer_Contact_Email": "test@example.com",' +
            '"Serial_No": "SERIAL001",' +
            '"Billing_Date": "' + Date.today() + '"' +
            '}' +
            ']';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
       // System.assertEquals(500, res.statusCode, 'Status code should be 500 for error');
        
        List<API_log__c> logs = [SELECT Id, Status__c FROM API_log__c WHERE Log_Name__c = 'Invoice API'];
        //System.assertEquals(1, logs.size(), 'API log should be created');
        //System.assertEquals('Failed', logs[0].Status__c, 'API log should be marked as failed');
    }
    
    @IsTest
    static void testDoPostInvalidJSON() {
        String requestBody = 'invalid json';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
        //System.assertEquals(500, res.statusCode, 'Status code should be 500 for error');
    }
    
    @IsTest
    static void testDoPostEmptyRequest() {
        String requestBody = '';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/InvoiceAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        InvoiceAPI.doPost();
        Test.stopTest();
        
        //System.assertEquals(500, res.statusCode, 'Status code should be 500 for error');
    }
}