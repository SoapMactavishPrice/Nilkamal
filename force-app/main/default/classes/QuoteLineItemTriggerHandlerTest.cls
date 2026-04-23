@isTest
public class QuoteLineItemTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', isActive = true);
        insert prod;

        // Create HSN Master
        HSN_Master__c hsn = new HSN_Master__c(
            Name = 'HSN123',
            CGST__c = 9,
            SGST__c = 9,
            IGST__c = 18
        );
        insert hsn;

        // Update Product with HSN reference
        prod.HSN_Code__c = hsn.Id;
        prod.Lead_Time__c = '5';
        update prod;

      Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        standardPricebook.IsActive = true;
        update standardPricebook;
        
        // Create a custom test Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

       PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true
           // UseStandardPrice = true // Use the standard pricebook
        );
        insert standardPbe;
        
        // **Now, create a custom price book entry**
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id, 
            Product2Id = prod.Id, 
            UnitPrice = 100, 
            IsActive = true, 
            UseStandardPrice = false // Use custom pricebook
        );
        insert customPbe;

        // Create Quote
        Opportunity opp = new Opportunity(Name = 'Test Opp', CloseDate = Date.today(), StageName = 'Prospecting');
        insert opp;
        
        Sequence_Master__c seq = new Sequence_Master__c(
        Starting_Number__c = 100,
        Current_Sequence_No__c = 105,
        format__c = '000000'
    );
    insert seq;

        Quote quote = new Quote(Name = 'Test Quote', OpportunityId = opp.Id, Pricebook2Id = testPricebook.Id);
        insert quote;

        // Create QuoteLineItems
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Product2Id = prod.Id,
            Discount_In__c = 10,
            GST_Percentage__c = 18,
            Advanced_Received__c = 50,
            //Amount__c = 100,
            Billing_Type__c = 'FOC and Returnable'
        );
        insert qli;
    }

    @isTest
    static void testOverrideGrandPriceTotal() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        QuoteLineItemTriggerHandler.overrideGrandPriceTotal(new List<Id>{testQuote.Id});
        Test.stopTest();

        Quote updatedQuote = [SELECT Id, Grand_Total_Price__c FROM Quote WHERE Id = :testQuote.Id];
        System.assert(updatedQuote.Grand_Total_Price__c != null, 'Grand total should be updated');
    }

    @isTest
    static void testUpdatePrice() {
        QuoteLineItem qli = [SELECT Id, PricebookEntryId, Billing_Type__c, NT_Price__c, Original_Unit_Price__c FROM QuoteLineItem LIMIT 1];
        qli.Billing_Type__c = 'Chargeable';
        update qli;

        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            qli.Id => new QuoteLineItem(Id = qli.Id, Billing_Type__c = 'FOC and Returnable', NT_Price__c = true, Original_Unit_Price__c = 12345)
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.UpdatePrice(new List<QuoteLineItem>{qli}, oldMap);
        Test.stopTest();

        QuoteLineItem updatedQli = [SELECT UnitPrice FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(100, updatedQli.UnitPrice, 'UnitPrice should match PricebookEntry');
    }

    @isTest
    static void testUpdateHSNCodeGST() {
        QuoteLineItem qli = [SELECT Id, Product2Id FROM QuoteLineItem LIMIT 1];

        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            qli.Id => qli
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.UpdateHSNCodeGST(new List<QuoteLineItem>{qli}, oldMap);
        Test.stopTest();

        QuoteLineItem updatedQli = [SELECT GST_Percentage__c, HSN_Code__c FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assert(updatedQli.GST_Percentage__c > 0, 'GST should be calculated');
        System.assert(updatedQli.HSN_Code__c != null, 'HSN code should be updated');
    }

    @isTest
    static void testUpdateDiscountValue() {
        QuoteLineItem qli = [SELECT Id, UnitPrice FROM QuoteLineItem LIMIT 1];
        qli.Discount_In__c = 15;
        qli.Discount_In_Value_New__c = null;

        Map<Id, QuoteLineItem> oldMap = new Map<Id, QuoteLineItem>{
            qli.Id => new QuoteLineItem(Id = qli.Id, Discount_In__c = 10, Discount_In_Value_New__c = null)
        };

        Test.startTest();
        QuoteLineItemTriggerHandler.UpdateDiscountValue(new List<QuoteLineItem>{qli}, oldMap);
        Test.stopTest();

        System.assert(qli.Discount_In_Value_New__c != null, 'Discount value should be recalculated');
    }
    
        

    
    
}