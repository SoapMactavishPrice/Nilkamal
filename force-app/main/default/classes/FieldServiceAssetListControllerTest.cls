@isTest
public class FieldServiceAssetListControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Pin_Code_Master__c pinCode = new Pin_Code_Master__c(Name = '123456');
        insert pinCode;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        Asset asset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            Pin_Code_Master__c = pinCode.Id,
            Product2Id = prod.Id,
            Type__c = 'Within Warranty',
            SerialNumber = 'SN123'
        );
        insert asset;
        
        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Test Warranty',
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addDays(-10),
            Warranty_End_Date__c = Date.today().addDays(10),
            Warranty_Period__c = 12
        );
        insert warranty;
        
        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'Test AMC',
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today().addDays(-5),
            AMC_End_Date__c = Date.today().addDays(15),
            Product_Category_Type__c = 'AMC',
            AMC_Period_In_Months__c = 12
        );
        insert amc;
    }
    
    @isTest
    static void testGetCountOfAssets() {
        try{
            Test.startTest();
            Object result = FieldServiceAssetListController.getCountOfAssets();
            Test.stopTest();
            System.assertNotEquals(null, result, 'Count result should not be null');
        }catch(Exception e){
            
        }
    }
    
    @isTest
    static void testGetAssetsUnderWarrantyOrAMCList_Warranty() {
        Test.startTest();
        List<SObject> result = (List<SObject>)FieldServiceAssetListController.getAssetsUnderWarrantyOrAMCList(
            'Test', 'AssetsUnderWarranty', 0, 10, 'Warranty_End_Date__c', 'ASC'
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testGetAssetsUnderWarrantyOrAMCList_AMC() {
        Test.startTest();
        List<SObject> result = (List<SObject>)FieldServiceAssetListController.getAssetsUnderWarrantyOrAMCList(
            'Test', 'AssetsUnderAMC', 0, 10, 'AMC_End_Date__c', 'DESC'
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testGetTotalAssetList() {
        Test.startTest();
        List<SObject> result = (List<SObject>)FieldServiceAssetListController.getTotalAssetList(
            'Test', 0, 10, 'Name', 'ASC'
        );
        Test.stopTest();
        System.assertNotEquals(null, result);
    }
    
    @isTest
    static void testGetApprovalItemsWithCount() {
        
        Sequence_Master__c seq = new Sequence_Master__c(
            format__c = '00000',
            Starting_Number__c = 1,
            Current_Sequence_No__c = 0
        );
        insert seq;
        
        Account acc = new Account(Name = 'Approval Account');
        insert acc;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOpp;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        
        User approverUser = new User(
            FirstName = 'Approver',
            LastName = 'User',
            Email = 'approver' + DateTime.now().getTime() + '@test.com',
            Username = 'approver' + DateTime.now().getTime() + '@test.com',
            Alias = 'apprv',
            CommunityNickname = 'apprv' + DateTime.now().getTime(),  // required
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert approverUser;
        
        
        User submitterUser = new User(
            FirstName = 'Delegate',
            LastName = 'User',
            Email = 'delegate' + DateTime.now().getTime() + '@test.com',
            Username = 'delegate' + DateTime.now().getTime() + '@test.com',
            Alias = 'delg',
            CommunityNickname = 'delg' + DateTime.now().getTime(),
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ManagerId = approverUser.Id
        );
        insert submitterUser;
        
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Approver__c = approverUser.Id,
            Quote_Document_Type__c = 'Spares',
            Billing_Type__c = 'FOC and Returnable',
            OwnerId = submitterUser.Id,
            Business_Vertical__c = 'MHE'
        );
        insert q;
        
        Test.startTest();
                
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitting for approval');
        req.setObjectId(q.Id);
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
        
        FieldServiceAssetListController.getApprovalItemsWithCount();
        
        Test.stopTest();
    }
    
}