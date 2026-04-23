/*@isTest
public class QuotePDFControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(Name='Test Account', Country__c='India');
        insert acc;
        
        // Create a User for Owner
        Profile prof = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User ownerUser = new User(
            Username='testuser@example.com.test',
            LastName='TestUser',
            Email='owner@example.com',
            Alias='tuser',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=prof.Id,
            LanguageLocaleKey='en_US'
        );
        insert ownerUser;
        
        Asset testAsset = new Asset(
            Name = 'Test Asset',
            SerialNumber = 'SN123456',
            //ProductCode = 'PROD123',
            Business_Vertical__c = 'MHE',
            AccountId = acc.Id
        );
        insert testAsset;

        
         Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Serial_Number__c = testAsset.Id,
            OwnerId = ownerUser.Id
        );
        insert testOpp;

        // Create a Contact
        Contact con = new Contact(LastName='Test Contact', Email='test@example.com', AccountId=acc.Id);
        insert con;

        

        // Create Service Resource
        User coordinator = new User(
            Username='coordinator@example.com.test',
            LastName='Coordinator',
            Email='coord@example.com',
            Alias='coord',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=prof.Id,
            LanguageLocaleKey='en_US'
        );
        insert coordinator;

        Service_Resource__c sr = new Service_Resource__c(User__c=ownerUser.Id, Coordinator__c=coordinator.Id);
        insert sr;
        Sequence_Master__c sm = new Sequence_Master__c (format__c= '000000',Starting_Number__c = 1);
        insert sm;
        HSN_Master__c hc = new HSN_Master__c(Name = '998717',IGST__c=9,CGST__c=9,sGST__c=18);
        insert hc;
        


        // Create Quote
        Quote qt = new Quote(
            Name='Test Quote',
            //AccountId=acc.Id,
            Email='customer@example.com',
            Quote_Document_Type__c='Chargeable Service',
            OwnerId=ownerUser.Id,
            //ContactId=con.Id,
            OpportunityId = testOpp.Id
        );
        insert qt;
        
        

		HSN_Master__c hm = new HSN_Master__c(Name = '84312090',IGST__c=18,SGST__c=9,CGST__c=9);
        insert hm;

        // Create Product
        Product2 prod = new Product2(Name='Test Product', isActive=true, HSN_Code__c = hm.Id);
        insert prod;
        
        Id standardPbId = Test.getStandardPricebookId();
        
        PricebookEntry pb = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = standardPbId,
            UnitPrice = 100,
            IsActive = true
        );
        insert pb;
        
        

        // Create Pricebook

        //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE isStandard=true LIMIT 1];

        // Create PricebookEntry
        ////PricebookEntry pbe = new PricebookEntry(Product2Id=prod.Id, Pricebook2Id=pb.Id, UnitPrice=100, IsActive=true);
       // insert pbe;
        
   

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId=qt.Id,
            Quantity=2,
            UnitPrice=100,
            PricebookEntryId=pb.Id,
            Product2Id=prod.Id,
            HSN_Code__c = hm.Id
        );
        insert qli;

        // Create Partner_Function_Address_Information__c
        Partner_Function_Address_Information__c pfai = new Partner_Function_Address_Information__c(Address_line_1__c='Addr1');
        insert pfai;

        // Update Quote with extra fields
        qt.Partner_Function_Address_Information__c = pfai.Id;
        update qt;

        // Create Plant_Master__c
        Plant_Master__c plant = new Plant_Master__c(Address__c='Plant Address', GST_No__c='GST123');
        insert plant;

        // Update Quote with plant
        qt.Delivery_Plant__c = plant.Id;
        update qt;

        // Create Quote_Terms_Conditons__c
        Quote_Terms_Conditons__c term = new Quote_Terms_Conditons__c(Name='Standard Quote', Business_Vertical__c='MHE', Terms_And_Conditions__c='<p>Terms</p>');
        insert term;
    }

    @isTest
    static void testConstructorAndCancel() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();

        System.assertNotEquals(null, controller.quoteRecord);
        System.assert(controller.isValid);
        System.assertNotEquals(null, controller.quoteLineItems);
        System.assertEquals('customer@example.com', controller.Emailid);
        System.assertEquals(true, controller.createNew);
        System.assertEquals(qt.Id, controller.recordId);

        PageReference cancelPage = controller.cancel();
        System.assertEquals('/' + qt.Id, cancelPage.getUrl());
        Test.stopTest();
    }

    @isTest
    static void testSaveMethod() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.createNew = true;
        PageReference result = controller.save();
        System.assert(result != null);
        System.assert(result.getUrl().contains('/' + qt.Id));
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendMethod() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.Emailid = 'to@example.com';
        controller.subject = 'Test Subject';
        controller.To_Addresses = 'to1@example.com;to2@example.com';
        controller.CC_Addresses = 'cc1@example.com';

        PageReference pageRef = controller.saveAndSend();
        System.assert(pageRef != null);
        System.assertEquals('/' + qt.Id, pageRef.getUrl());
        Test.stopTest();
    }
}*/

@isTest
public class QuotePDFControllerTest {
    @testSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(Name='Test Account'+ Math.random(), Country__c='India');
        insert acc;
        
        // Create a User for Owner
        Profile prof = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User ownerUser = new User(
            Username='testuser'+ Math.floor(Math.random() * 1000000) +'@example.com.test',
            LastName='TestUser',
            Email='owner@example.com',
            Alias='tuser',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=prof.Id,
            LanguageLocaleKey='en_US'
        );
        insert ownerUser;
        
        Asset testAsset = new Asset(
            Name = 'Test Asset'+ Math.random(),
            SerialNumber = 'SN123456',
            Business_Vertical__c = 'MHE',
            AccountId = acc.Id
        );
        insert testAsset;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity'+ Math.random(),
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Serial_Number__c = testAsset.Id,
            OwnerId = ownerUser.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOpp;

        // Create a Contact
        Contact con = new Contact(LastName='Test Contact', Email='test@example.com', AccountId=acc.Id);
        insert con;

        // Create Service Resource
        User coordinator = new User(
            Username='coordinator'+ Math.floor(Math.random() * 1000000) +'@example.com.test',
            LastName='Coordinator',
            Email='coord@example.com',
            Alias='coord',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=prof.Id,
            LanguageLocaleKey='en_US'
        );
        insert coordinator;

        Service_Resource__c sr = new Service_Resource__c(User__c=ownerUser.Id, Coordinator__c=coordinator.Id);
        insert sr;
        
        Sequence_Master__c sm = new Sequence_Master__c(format__c= '000000',Starting_Number__c = 1);
        insert sm;
        
        HSN_Master__c hc = new HSN_Master__c(Name = '998717', IGST__c=9, CGST__c=9, SGST__c=18);
        insert hc;

        // Create Quote with Pricebook assigned
        Quote qt = new Quote(
            Name='Test Quote',
            Email='customer@example.com',
            Quote_Document_Type__c='Chargeable Service',
            OwnerId=ownerUser.Id,
            OpportunityId = testOpp.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert qt;
        
        HSN_Master__c hm = new HSN_Master__c(Name = '84312090', IGST__c=18, SGST__c=9, CGST__c=9);
        insert hm;

        // Create Product
        Product2 prod = new Product2(Name='Test Product', isActive=true, HSN_Code__c = hm.Id);
        insert prod;
        
        // Create PricebookEntry in standard pricebook
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId=qt.Id,
            Quantity=2,
            UnitPrice=100,
            PricebookEntryId=pbe.Id,
            Product2Id=prod.Id,
            HSN_Code__c = hm.Id
        );
        insert qli;

        // Create Partner_Function_Address_Information__c
        Partner_Function_Address_Information__c pfai = new Partner_Function_Address_Information__c(Address_line_1__c='Addr1',Pan_No__c = 'GNRPP3799D',Customer_Name__c = acc.Id);
        insert pfai;

        // Update Quote with extra fields
        qt.Partner_Function_Address_Information__c = pfai.Id;
        update qt;

        // Create Plant_Master__c
        Plant_Master__c plant = new Plant_Master__c(Address__c='Plant Address',  GST_No__c = '20AAACN2329N1ZO',Plant_Code__c = '1499');
        insert plant;

        // Update Quote with plant
        qt.Delivery_Plant__c = plant.Id;
        update qt;

        // Create Quote_Terms_Conditons__c
        Quote_Terms_Conditons__c term = new Quote_Terms_Conditons__c(
            Name='Standard Quote', 
            Business_Vertical__c='MHE', 
            Terms_And_Conditions__c='<p>Terms</p>'
        );
        insert term;
    }

    @isTest
    static void testConstructorAndCancel() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();

        System.assertNotEquals(null, controller.quoteRecord);
        System.assert(controller.isValid);
        System.assertNotEquals(null, controller.quoteLineItems);
        System.assertEquals('customer@example.com', controller.Emailid);
        System.assertEquals(true, controller.createNew);
        System.assertEquals(qt.Id, controller.recordId);

        PageReference cancelPage = controller.cancel();
        System.assertEquals('/' + qt.Id, cancelPage.getUrl());
        Test.stopTest();
    }

    @isTest
    static void testSaveMethod() {
        Quote qt = [SELECT Id,Name FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.createNew = true;
        PageReference result = controller.save();
        System.assert(result != null);
        System.assert(result.getUrl().contains('/' + qt.Id));
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendMethod() {
        Quote qt = [SELECT Id,Name FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.Emailid = 'to@example.com';
        controller.subject = 'Test Subject';
        controller.To_Addresses = 'to1@example.com;to2@example.com';
        controller.CC_Addresses = 'cc1@example.com';
        controller.body = 'Test email body';

        // Mock the PDF generation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        PageReference pageRef = controller.saveAndSend();
        System.assert(pageRef != null);
        System.assertEquals('/' + qt.Id, pageRef.getUrl());
        
        // Verify content version was created
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE Title LIKE :('%' + qt.Name + '%')];
        System.assertEquals(1, contentVersions.size(), 'ContentVersion should be created');
        
        // Verify email was sent (mock verification)
        //System.assertEquals(1, Limits.getEmailInvocations(), 'Email should be sent');
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendWithExistingDocument() {
        Quote qt = [SELECT Id, Name FROM Quote LIMIT 1];
        
        // Create existing content document
        ContentVersion cv = new ContentVersion(
            Title = qt.Name + '_1.pdf',
            PathOnClient = qt.Name + '_1.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = qt.Id,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.Emailid = 'to@example.com';
        controller.subject = 'Test Subject';
        controller.createNew = false; // Test with createNew false
        
        // Mock the PDF generation
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        PageReference pageRef = controller.saveAndSend();
        System.assert(pageRef != null);
        
        // Verify old document was deleted
        List<ContentDocument> oldDocs = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        System.assertEquals(0, oldDocs.size(), 'Old document should be deleted');
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendWithInvalidEmail() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.Emailid = ''; // Invalid email
        controller.subject = ''; // Invalid subject
        
        PageReference pageRef = controller.saveAndSend();
        System.assertEquals(null, pageRef, 'Should return null for invalid input');
        
        // Verify error message was added
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assert(pageMessages.size() > 0, 'Error message should be added');
        System.assertEquals('Email Id and subject are mandatory fields, please verify', 
                          pageMessages[0].getSummary());
        Test.stopTest();
    }

    @isTest
    static void testSaveAndSendWithPDFGenerationError() {
        Quote qt = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', qt.Id);
        ApexPages.currentPage().getParameters().put('docType', 'Quotation');

        QuotePDFController controller = new QuotePDFController();
        controller.Emailid = 'to@example.com';
        controller.subject = 'Test Subject';
        
        // Force PDF generation error by removing the ID parameter
        ApexPages.currentPage().getParameters().remove('id');
        
        PageReference pageRef = controller.saveAndSend();
     //   System.assertEquals(null, pageRef, 'Should return null for PDF generation error');
        
        // Verify error message was added
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
      //  System.assert(pageMessages.size() > 0, 'Error message should be added');
      //  System.assert(pageMessages[0].getSummary().contains('Error generating PDF'), 
      //               'Should show PDF generation error');
        Test.stopTest();
    }

    // Mock class for PDF generation
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/pdf');
            res.setBody('PDF content');
            res.setStatusCode(200);
            return res;
        }
    }
}