@isTest
private class QuoteInvoicePDFControllerTest {

    @TestSetup
    static void setupTestData() {
        Profile profile = [select Id from Profile where Name = 'Service Engineer'];
        User u = new User();
        u.ProfileId = profile.Id;
        u.UserName = 'test' + Math.random() + '@gmail.com';
        u.Email = 'test' + Math.random() + '@gmail.com';
        u.LastName = 'Test';
        u.Alias = 'test';
        u.TimeZoneSidKey = 'Asia/Kolkata';
        u.LocaleSidKey = 'en_IN';
        u.EmailEncodingKey = 'UTF-8';
        u.LanguageLocaleKey = 'en_US';
        u.ManagerId = UserInfo.getUserId();
        insert u;

        Account testAccount = new Account(
            Name = 'Test Account 89',
            Street1__c = '123 Test St',
            City__c = 'Test City',
            Postal_code__c = '12345',
            Country__c = 'Test Country',
            GST_No__c = 'GST123456',
            SAP_Customer_code__c = 'CUST123'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact 90',
            Email = 'test.contact@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        Asset testAsset = new Asset(
            Name = 'Test Asset 842',
            SerialNumber = 'SN123456',
            //ProductCode = 'PROD123',
            Business_Vertical__c = 'MHE',
            AccountId = testAccount.Id
        );
        insert testAsset;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity 974',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id,
            Serial_Number__c = testAsset.Id,
            OwnerId = u.Id
        );
        insert testOpp;

        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            AccountId = testAccount.Id,
            AssetId = testAsset.Id
        );
        insert testCase;

        Service_Resource__c testServiceResource = new Service_Resource__c(
            User__c = u.Id,
            RSM__c = UserInfo.getUserId(),
            Coordinator__c = UserInfo.getUserId()
        );
        insert testServiceResource;

        Plant_Master__c testPlant = new Plant_Master__c(
            Name = 'Test Plant 192',
            Address__c = '123 Plant St',
            GST_No__c = '20AAACN2329N1ZO',
            Plant_Code__c = '1499'
        );
        insert testPlant;

        Partner_Function_Address_Information__c testPFAI = new Partner_Function_Address_Information__c(
            Customer_Name__c = testAccount.Id,
            Address_line_1__c = '123 Partner St',
            Address_line_2__c = 'Suite 100',
			Pan_No__c = 'GNRPP3799D'
        );
        insert testPFAI;

        Sequence_Master__c sm = new Sequence_Master__c (format__c= '000000',Starting_Number__c = 1);
        insert sm;
        HSN_Master__c hc = new HSN_Master__c(Name = '998717',IGST__c=9,CGST__c=9,sGST__c=18);
        insert hc;

        Product2 prod = new Product2(Name = 'AMC Product', IsActive = true,HSN_Code__c= hc.Id,Category__c ='Service');
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Quote testQuote = new Quote(
            Name = 'Test Quote 946',
            OpportunityId = testOpp.Id,
            //ContactId = testContact.Id,
            //AccountId = testAccount.Id,
            Email = 'test@example.com',
            Phone = '1234567890',
            Asset_Serial_Number__c = testAsset.Id,
            Business_Vertical__c = 'MHE',
            Quote_Document_Type__c = 'AMC',
            Payment_Terms__c = 'PT-30 - Net 30 Days',
            Delivery_Plant__c = testPlant.Id,
            Partner_Function_Address_Information__c = testPFAI.Id,
            Case__c = testCase.Id,
            OwnerId = u.Id,
            Service_GST_Value__c =20
        );
        insert testQuote;

        Quote_Service_Line_Item__c testQSLineItem = new Quote_Service_Line_Item__c(
            Quote__c = testQuote.Id,
            Service_Amount__c = 1000,
            Quantity__c = 1,
            AMC_Start_Date__c = Date.today(),
            AMC_Period_In_Months__c = 12,
            Item_Master__c = prod.Id
        );
        insert testQSLineItem;

        Quote_Terms_Conditons__c testTerms = new Quote_Terms_Conditons__c(
            Name = 'AMC',
            Business_Vertical__c = 'MHE',
            Terms_And_Conditions__c = '<p>Test Terms and Conditions</p>'
        );
        insert testTerms;

        Customer_Outstanding__c testOutstanding = new Customer_Outstanding__c(
            Account_Name__c = testAccount.Id,
            Accounting_Document_Number__c = 'DOC123',
            Amount_in_Local_Currency__c = 500
        );
        insert testOutstanding;
    }


    @isTest
    static void testConstructor() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
		Asset testAsset = new Asset(
            Name = 'Test1 Asset 935',
            SerialNumber = 'SN1123456',
            Business_Vertical__c = 'Printer',
            AccountId = testAccount.Id
        );
        insert testAsset;
        testQuote.Asset_Serial_Number__c = testAsset.Id;
        update testQuote;
        PageReference pageRef1 = Page.QuoteInvoicePdf;
        pageRef1.getParameters().put('id', testQuote.Id);
        pageRef1.getParameters().put('docType', 'ProformaInvoice');
        Test.setCurrentPage(pageRef1);

        testAsset.Business_Vertical__c = 'CNPL';
        update testAsset;
        testQuote.Asset_Serial_Number__c = testAsset.Id;
        update testQuote;
        PageReference pageRef2 = Page.QuoteInvoicePdf;
        pageRef2.getParameters().put('id', testQuote.Id);
        pageRef2.getParameters().put('docType', 'ProformaInvoice');
        Test.setCurrentPage(pageRef2);

        QuoteInvoicePDFController controller = new QuoteInvoicePDFController();
        Test.stopTest();

        System.assertNotEquals(null, controller.quoteRecord, 'Quote record should be loaded');
        System.assertEquals(true, controller.isValid, 'Controller should be valid');
        System.assertEquals(false, controller.formSubmitted, 'Form should not be submitted initially');
        System.assertEquals('test@example.com', controller.Emailid, 'Email should be set from quote');
    }

    @isTest
    static void testSaveMethod() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.QuoteInvoicePdf;
        pageRef.getParameters().put('id', testQuote.Id);
        Test.setCurrentPage(pageRef);

        QuoteInvoicePDFController controller = new QuoteInvoicePDFController();
        PageReference result = controller.save();
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendMethod() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];

        PageReference pageRef = Page.QuoteInvoicePdf;
        pageRef.getParameters().put('id', testQuote.Id);
        pageRef.getParameters().put('docType', 'ProformaInvoice');
        Test.setCurrentPage(pageRef);

        Test.startTest();

        QuoteInvoicePDFController controller = new QuoteInvoicePDFController();

        controller.Emailid = 'recipient@example.com';
        controller.subject = 'Test Subject';
        controller.body = 'This is a test email body.';
        controller.To_Addresses = 'external@example.com';
        controller.CC_Addresses = 'cc@example.com';
        controller.defaultToAddress = 'default@example.com';
        controller.defaultCCAddresses = 'defaultcc@example.com';

        PageReference result = controller.saveAndSend();

        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a page reference');
        System.assertEquals(true, controller.formSubmitted, 'Form should be submitted');
        System.assertEquals('/' + testQuote.Id, result.getUrl(), 'Should redirect to quote record');

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testQuote.Id];
        System.assert(links.size() > 0, 'A content document should be linked to the quote');
    }


    @isTest
    static void testCancelMethod() {
        Quote testQuote = [SELECT Id,Business_Vertical__c FROM Quote LIMIT 1];
        system.debug('testQuote'+ testQuote + testQuote.Business_Vertical__c);

        Test.startTest();
        PageReference pageRef = Page.QuoteInvoicePdf;
        pageRef.getParameters().put('id', testQuote.Id);
        Test.setCurrentPage(pageRef);
        QuoteInvoicePDFController controller = new QuoteInvoicePDFController();
        PageReference result = controller.cancel();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a PageReference');
        System.assertEquals('/' + testQuote.Id, result.getUrl(), 'Should redirect to quote page');
    }

}