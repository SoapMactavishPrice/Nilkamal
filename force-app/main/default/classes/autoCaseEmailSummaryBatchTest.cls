@isTest
public class autoCaseEmailSummaryBatchTest {
    
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
        //insert testCase;
        
        Case testRenewCase = new Case(
            Subject = 'Test Case',
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            AssetId = testAsset.Id,
            Division__c = 'MHE',
            Type = 'Breakdown',
            Case_Sub_Type__c = 'Chargeable Service'
        );
        insert testRenewCase;

        List<Work_Order__c> testWorkOrder = [SELECT Id FROM Work_Order__c];

        Sequence_Master__c sm = new Sequence_Master__c (
        format__c = '0000',
        Starting_Number__c  = 1);
        insert sm;

        HSN_Master__c hm = new HSN_Master__c(Name='test',IGST__c=18,SGST__c= 9,CGST__c=9);
        insert hm;


        Product2 serviceProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TESTPROD',
            IsActive = true,
            Category__c = 'Service',
            HSN_Code__c =  hm.Id,
            Warranty__c = 'Y'
        );
        insert serviceProduct;

        PricebookEntry servicePBE = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = serviceProduct.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert servicePBE;


        List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
        serviceRequests.add(new Service_Request__c(
            Work_Order__c = testWorkOrder[0].Id,
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
            Work_Order__c = testWorkOrder[0].Id,
            Item_Master__c = serviceProduct.Id,
            Pricebook_Entry_Id__c = servicePBE.Id,
            Quantity__c = 2,
            Price__c = 0.00,
            Original_Price__c = 0.00,
            Warranty_Period__c = '24',
            Number_of_PM_Visit__c = '4',
            Number_of_Breakdown_Visit__c = '5'
        ));
        insert serviceRequests;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        ));
        insert opportunities;
        
        List<Quote> quotes = new List<Quote>();
        quotes.add(new Quote(
            Name = 'Test Quote 1',
            SAP_Order_No__c = 'ORDER001',
            Billing_Type__c = 'FOC and Returnable',
            //Total_Quantity__c = 10,
            Returnable_Received__c = false,            
            OpportunityId = opportunities[0].Id,
            Case__c =testRenewCase.Id
        ));
        
        Asset_Warranty__c aw = new Asset_Warranty__c(Asset__c = testAsset.Id, Warranty_Start_Date__c = System.today(),Warranty_End_Date__c=System.today().addDays(30),Renewal_Case__c=testRenewCase.Id, Warranty_Period__c = 1);
        insert aw;

        Asset_AMC__c amc = new Asset_AMC__c(Asset__c = testAsset.Id, AMC_Start_Date__c = System.today(),AMC_End_Date__c=System.today().addDays(30), AMC_Period_In_Months__c = 1,Renewal_Case__c=testRenewCase.Id, Product_Category_Type__c = 'AMC');
        insert amc;
    }
    
    @isTest
    static void autoEmailBatcht() {
        Database.executeBatch(new autoCaseEmailSummaryBatch(), 200);
    }

}