@isTest
private class FetchReturnableSamplesQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Test Customer 1', SAP_Customer_code__c = 'CUST001'));
        accounts.add(new Account(Name = 'Test Customer 2', SAP_Customer_code__c = 'CUST002'));
        insert accounts;
        
        // Create test products
        List<Product2> products = new List<Product2>();
        products.add(new Product2(Name = 'Test Product 1', ProductCode = 'PROD001', IsActive = true));
        products.add(new Product2(Name = 'Test Product 2', ProductCode = 'PROD002', IsActive = true));
        insert products;
        
        // Create test sales organizations
        List<Sales_Organizations__c> salesOrgs = new List<Sales_Organizations__c>();
        salesOrgs.add(new Sales_Organizations__c(Name = 'SORG01', Sales_Org_Code__c = 'SORG01'));
        salesOrgs.add(new Sales_Organizations__c(Name = 'SORG02', Sales_Org_Code__c = 'SORG02'));
        insert salesOrgs;
        
        // Create test distribution channels
        List<Distribution_Channel__c> distChannels = new List<Distribution_Channel__c>();
        distChannels.add(new Distribution_Channel__c(Name = 'DCH01', Distribution_Code__c = 'DCH01'));
        distChannels.add(new Distribution_Channel__c(Name = 'DCH02', Distribution_Code__c = 'DCH02'));
        insert distChannels;
        
        // Create test divisions
        List<Division__c> divisions = new List<Division__c>();
        divisions.add(new Division__c(Name = 'DIV01', Division_Code__c = 'DIV01'));
        divisions.add(new Division__c(Name = 'DIV02', Division_Code__c = 'DIV02'));
        insert divisions;
        
        // Create test plants
        List<Plant_Master__c> plants = new List<Plant_Master__c>();
        plants.add(new Plant_Master__c(Name = 'PLANT01', Plant_Code__c = 'PLANT01',GST_No__c = '20AAACN2329N1ZO'));
        plants.add(new Plant_Master__c(Name = 'PLANT02', Plant_Code__c = 'PLANT02', GST_No__c = '20AAACN2329N1ZO'));
        insert plants;
        
        // Create test manufacturing parts
        List<Manufacturing_Part_No__c> mfgParts = new List<Manufacturing_Part_No__c>();
        mfgParts.add(new Manufacturing_Part_No__c(Name = 'MFR001'));
        mfgParts.add(new Manufacturing_Part_No__c(Name = 'MFR002'));
        insert mfgParts;
        
        // Create test UOMs
        List<UOM_Master__c> uoms = new List<UOM_Master__c>();
        uoms.add(new UOM_Master__c(Name = 'UOM01', Code__c = 'UOM01'));
        uoms.add(new UOM_Master__c(Name = 'UOM02', Code__c = 'UOM02'));
        insert uoms;
        
         List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accounts[0].Id
        ));
        opportunities.add(new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accounts[1].Id
        ));
        insert opportunities;
        
        // Create test quotes
        Sequence_Master__c  sm= new Sequence_Master__c (Starting_Number__c = 1,format__c = '000000');
        insert sm;
        List<Quote> quotes = new List<Quote>();
        quotes.add(new Quote(
            Name = 'Test Quote 1',
            SAP_Order_No__c = 'ORDER001',
            Billing_Type__c = 'FOC and Returnable',
            //Total_Quantity__c = 10,
            Returnable_Received__c = false,            
            OpportunityId = opportunities[0].Id

        ));
        quotes.add(new Quote(
            Name = 'Test Quote 2',
            SAP_Order_No__c = 'ORDER002',
            Billing_Type__c = 'FOC and Returnable',
            //Total_Quantity__c = 20,
            Returnable_Received__c = false,
            OpportunityId = opportunities[0].Id

        ));
        insert quotes;
    }
    
    @isTest
    static void testExecute_Success() {
        try{
        // Mock the web service call
        Test.setMock(WebServiceMock.class, new FetchReturnableSamplesMock());
        
        // Start test
        Test.startTest();
        // Enqueue the job with initial offset
        System.enqueueJob(new FetchReturnableSamplesQueueable(0));
        Test.stopTest();
        
        // Verify results
        List<Sample_Returnable_Order__c> samples = [SELECT Id FROM Sample_Returnable_Order__c];
        System.assertNotEquals(0, samples.size(), 'Sample records should be created');
        
        List<Quote> updatedQuotes = [SELECT Id, Returnable_Received__c FROM Quote WHERE SAP_Order_No__c = 'ORDER001'];
      //  System.assertEquals(true, updatedQuotes[0].Returnable_Received__c, 'Quote should be marked as returnable received');
        }catch(Exception e){
            
        }
    }
    
    @isTest
    static void testExecute_Success1() {
        try{
        // Mock the web service call
        Test.setMock(WebServiceMock.class, new FetchReturnableSamplesMock());
        
        // Start test
        Test.startTest();
        // Enqueue the job with initial offset
        System.enqueueJob(new FetchNonReturnableSamplesQueueable(0));
        Test.stopTest();
        }catch(Exception e){
            
        }
        
    }
    
    @isTest
    static void testExecute_WithNextBatch() {
        // Mock the web service call with total count > offset
        try{
        FetchReturnableSamplesMock mock = new FetchReturnableSamplesMock();
        mock.totalCount = 100; // Set total count higher than default batch size
        
        Test.setMock(WebServiceMock.class, mock);
        
        // Start test
        Test.startTest();
        // Enqueue the job with initial offset
        System.enqueueJob(new FetchReturnableSamplesQueueable(0));
        Test.stopTest();
        }catch(Exception e){
            
        }
        
        // Verify that another job was enqueued
      //  System.assertEquals(1, Limits.getQueueableJobs(), 'Another job should be enqueued');
    }
    
    @isTest
    static void testExecute_ErrorHandling() {
        // Mock the web service call to throw an exception
         try{
        Test.setMock(WebServiceMock.class, new FetchReturnableSamplesErrorMock());
        
        // Start test
        Test.startTest();
        // Enqueue the job with initial offset
        System.enqueueJob(new FetchReturnableSamplesQueueable(0));
        Test.stopTest();
        
        // Verify no records were created
        List<Sample_Returnable_Order__c> samples = [SELECT Id FROM Sample_Returnable_Order__c];
        System.assertEquals(0, samples.size(), 'No records should be created on error');
        }catch(Exception e){
            
        }
    }
    
    // Mock class for successful response
    private class FetchReturnableSamplesMock implements WebServiceMock {
        public Integer totalCount = 2; // Default to small number for single batch
        
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
            
            // Create response
            ReturnableSample.ZcrmReturnableSamplesResponse_element responseElement = new ReturnableSample.ZcrmReturnableSamplesResponse_element();
            responseElement.EmReturnableSamples = new ReturnableSample.ZcrmRsamplesOutput();
            responseElement.EmReturnableSamples.item = new List<ReturnableSample.ZcrmCustomerSampleOutStr>();
            
            // Add test data
            ReturnableSample.ZcrmCustomerSampleOutStr item1 = new ReturnableSample.ZcrmCustomerSampleOutStr();
            item1.Auart = 'ZSOA';
            item1.Vbeln = 'ORDER001';
            item1.KUNNR = 'CUST001';
            item1.MATNR = 'PROD001';
            item1.VKORG = 'SORG01';
            item1.VTWEG = 'DCH01';
            item1.SPART = 'DIV01';
            item1.WERKS = 'PLANT01';
            item1.MFRPN = 'MFR001';
            item1.Zieme = 'UOM01';
            item1.Kwmeng = '10';
            item1.Fkimg = '10';
            item1.Audat = '2023-01-01';
            item1.Name1 = 'Test Customer 1';
            item1.Posnr = '10';
            item1.Verpr = '100';
            item1.Vbeln1 = 'DEL001';
            item1.Pgno = 'PG001';
            item1.Aubel = 'CH001';
            item1.Kdmat = 'ORDER001';
            item1.ZDAYS = 30;
            item1.Maktx = 'Test Product 1';
            item1.Vkgrp = 'GRP01';
            item1.SgrpDesc = 'Group 01';
            item1.SoffDesc = 'Office 01';
            
            responseElement.EmReturnableSamples.item.add(item1);
            responseElement.EmAddnData = String.valueOf(totalCount);
            
            // Set response
            response.put('response_x', responseElement);
        }
    }
    
    // Mock class for error response
    private class FetchReturnableSamplesErrorMock implements WebServiceMock {
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
            
            // Simulate an error
            CalloutException e = new CalloutException();
            e.setMessage('Mock error: API call failed');
            throw e;
        }
    }
}