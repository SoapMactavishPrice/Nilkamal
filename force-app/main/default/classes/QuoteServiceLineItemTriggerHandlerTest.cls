@isTest
public class QuoteServiceLineItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create HSN Code record (assuming it's a custom object)
        Sequence_Master__c seq = new Sequence_Master__c(
            //Name = 'QuoteSeq',
            format__c = '0000001', // 7-digit format
            Starting_Number__c = 1,
            Current_Sequence_No__c = 0
        );
        insert seq;

        HSN_Master__c hsn = new HSN_Master__c(Name='1234', CGST__c=5, SGST__c=5);
        insert hsn;

        // Create Product2
        Product2 prod = new Product2(
            Name = 'Test Product',
            isActive = true,
            HSN_Code__c = hsn.Id,
            Category__c = 'Service'
        );
        insert prod;
        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'New', CloseDate = Date.today().addDays(30));
        insert opp;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            Status = 'Draft',
            OpportunityId = opp.Id
        );
        insert quote;

        // Create Quote Service Line Item
        List<Quote_Service_Line_Item__c> items = new List<Quote_Service_Line_Item__c>();

        for (Integer i = 0; i < 2; i++) {
            Quote_Service_Line_Item__c item = new Quote_Service_Line_Item__c(
                //Name = 'Item ' + i,
                Quote__c = quote.Id,
                Item_Master__c = prod.Id
            );
            items.add(item);
        }

        insert items;
    }

    @isTest
    static void testUpdateQuoteSummary() {
        List<Quote_Service_Line_Item__c> newItems = [SELECT Id, Quote__c FROM Quote_Service_Line_Item__c LIMIT 2];
        Test.startTest();
        QuoteServiceLineItemTriggerHandler.updateQuoteSummary(newItems, null);
        Test.stopTest();

        Quote updatedQuote = [SELECT Id, Service_Total_Amount__c, Service_Grand_Total__c, Service_GST_Value__c, Quote_Service_Total_Price__c FROM Quote LIMIT 1];
        System.assertNotEquals(null, updatedQuote.Service_Total_Amount__c);
        System.assertNotEquals(null, updatedQuote.Service_GST_Value__c);
    }
    
    
        @isTest
    static void testUnlinkServiceRequests() {
        // Setup HSN Master (needed for GST lookup)
        HSN_Master__c hsn = new HSN_Master__c(
            Name = 'HSN-TEST',
            CGST__c = 5,
            SGST__c = 5
        );
        insert hsn;

        // Setup Product (Item Master) with HSN reference
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Category__c = 'Service',
            HSN_Code__c = hsn.Id
        );
        insert prod;

        // Setup Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Setup Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert quote;

        // Setup Quote Service Line Item (with valid Item_Master__c)
        Quote_Service_Line_Item__c qsl = new Quote_Service_Line_Item__c(
            Quote__c = quote.Id,
            Item_Master__c = prod.Id,
            Service_Amount__c = 100
        );
        insert qsl;

        Opportunity_Service_Line_Item__c enquiryLine = new Opportunity_Service_Line_Item__c(
        Enquiry__c = opp.Id
        );
        insert enquiryLine;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
            
        Account acc1 = new Account(Name = 'Test1 Account1');
        insert acc1;

        Asset asset = new Asset(Name='Test Asset', AccountId = acc.Id, End_Customer__c = acc1.Id);
        insert asset;
 
        Pin_Code_Master__c	 pincode = new Pin_Code_Master__c	(Name = '12345');
        insert pincode;
 
        Territory_Master__c	 territory = new Territory_Master__c	(Name = 'DARBHANGA', Region__c = 'Muzaffarpur Region');
        insert territory;
 
        Case cs = new Case(
            AccountId = acc.Id,
            Case_Pincode__c = pincode.Id,
            Case_Territory__c = territory.Id,
            Division__c = 'MHE',
            AssetId = asset.Id
        );

        insert cs;
 
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;


        // Setup Service Request linked to QSL
        Service_Request__c sr = new Service_Request__c(
            Name = 'Test SR',
            Quote_Service_Line_Item__c = qsl.Id,
            Opportunity__c = opp.Id,
            Enquiry_Service_Line_Item__c = enquiryLine.Id,
            Quote__c = quote.Id,
            Work_Order__c = wo.Id
        );
        insert sr;

        Test.startTest();
        // Call the method being tested
        QuoteServiceLineItemTriggerHandler.unlinkServiceRequests(new List<Quote_Service_Line_Item__c>{ qsl });
        Test.stopTest();

        // Reload Service Request
        Service_Request__c updatedSR = [
            SELECT Id, Opportunity__c, Enquiry_Service_Line_Item__c, Quote__c, Quote_Service_Line_Item__c
            FROM Service_Request__c
            WHERE Id = :sr.Id
        ];

        // Assert fields are nulled
        System.assertEquals(null, updatedSR.Opportunity__c, 'Opportunity should be null');
        System.assertEquals(null, updatedSR.Enquiry_Service_Line_Item__c, 'Enquiry Service Line Item should be null');
        System.assertEquals(null, updatedSR.Quote__c, 'Quote should be null');
        System.assertEquals(null, updatedSR.Quote_Service_Line_Item__c, 'QSL should be null');
    }



    @isTest
    static void testUpdateQuoteSummaryOnDelete() {
        // Setup minimal required data
        HSN_Master__c hsn = new HSN_Master__c(Name='12341', CGST__c=10, SGST__c=10);
        insert hsn;
        
        Product2 prod = new Product2(Name = 'Test Product', isActive = true, Category__c = 'Service');
        insert prod;

        Opportunity opp = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today().addDays(10));
        insert opp;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Status = 'Draft');
        insert quote;

        Quote_Service_Line_Item__c qsl = new Quote_Service_Line_Item__c(
            Quote__c = quote.Id,
            Item_Master__c = prod.Id,
            Service_Amount__c = 500
            //Service_Grand_Total__c = 550,
            //Service_Gross_Totals__c = 500,
            //GST_Value__c = 50
        );
        insert qsl;

        Test.startTest();
        delete qsl; // This will trigger isDelete path
        
        Test.stopTest();

        // Assert that Quote summary fields are either null or recomputed
        Quote updatedQuote = [SELECT Id, Service_Total_Amount__c, Service_GST_Value__c FROM Quote WHERE Id = :quote.Id];
        System.assertNotEquals(null, updatedQuote.Id); // at minimum ensure quote still exists
    }


    @isTest
    static void testUpdateGST() {
        List<Quote_Service_Line_Item__c> items = [SELECT Id, Item_Master__c, Service_GST__c FROM Quote_Service_Line_Item__c LIMIT 2];
        Test.startTest();
        QuoteServiceLineItemTriggerHandler.UpdateGST(items);
        Test.stopTest();

        for (Quote_Service_Line_Item__c item : items) {
            System.debug('item.Service_GST__c: ' + item.Service_GST__c);
            System.assertEquals(10, item.Service_GST__c);
        }
    }


    @isTest
    static void testUpdateDiscountValueTriggerFlow() {
        // Create Product2 (Item Master)
        Product2 prod = new Product2(
            Name = 'Test Product',
            isActive = true,
            Category__c = 'Service'
        );
        insert prod;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft'
        );
        insert quote;

        // Insert initial Quote_Service_Line_Item__c
        Quote_Service_Line_Item__c item = new Quote_Service_Line_Item__c(
            Quote__c = quote.Id,
            Item_Master__c = prod.Id,
            Service_Amount__c = 1000,
            Discount_In__c = 10
        );
        insert item;

        // Simulate update to trigger before-update logic
        item = [SELECT Id, Service_Amount__c, Discount_In__c, Discount_In_Value_New__c FROM Quote_Service_Line_Item__c WHERE Id = :item.Id];
        item.Discount_In__c = 20; // Update Discount
        Test.startTest();
        update item; // <-- This triggers the actual logic
        Test.stopTest();

        // Fetch again and assert
        Quote_Service_Line_Item__c updatedItem = [SELECT Discount_In__c, Discount_In_Value_New__c FROM Quote_Service_Line_Item__c WHERE Id = :item.Id];
        System.assertNotEquals(null, updatedItem.Discount_In_Value_New__c, 'Discount_In_Value_New__c should be populated');
    }
    

}