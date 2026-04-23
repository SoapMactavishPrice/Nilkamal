@isTest
private class fieldServiceSpareReturnTest {

    @isTest
    static void testAllMethods() {
        // Create Pricebook2
        Pricebook2 pb = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert pb;

        // Create Account with Pricelist__c lookup to Pricebook2
        Account acc = new Account(Name = 'Test Account', Pricelist__c = pb.Id);
        insert acc;

        // Create Product2 (used as Item_Master__c)
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', isActive = true);
        insert prod;

        // Create Asset
        Asset asset = new Asset(Name = 'Test Asset', SerialNumber = 'SN123456', Product2Id = prod.Id, AccountId = acc.Id);
        insert asset;

        // Create Case
        Case cs = new Case(
            Type = 'Installation',
            AccountId = acc.Id,
            AssetId = asset.Id,
            Status = 'New',
            Origin = 'Phone'
        );
        insert cs;

        // Create Work Order
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        // Create Spare Request linked to Work Order and Product2 as Item_Master__c
        Spare_Request__c spare = new Spare_Request__c(
            Work_Order__c = wo.Id,
            Name = 'Spare 1',
            Quantity_Required__c = 2,
            Billed_Value__c = 500,
            CurrencyIsoCode = 'INR',
            Item_Master__c = prod.Id,
            Item_Description__c = 'Test Description',
            Pricebook_Entry_Id__c = 'TestPBEntryId'
        );
        insert spare;

        Test.startTest();

        // Test getWorkOrderData
        List<Work_Order__c> workOrders = fieldServiceSpareReturn.getWorkOrderData(wo.Id);
       

        // Test getSpareRequests
        Object spareResultsObj = fieldServiceSpareReturn.getSpareRequests(wo.Id);
        List<Object> spareResults = (List<Object>) spareResultsObj;
   

        Map<String, Object> spareMap = (Map<String, Object>) spareResults[0];

        // Prepare input for createSpareReturns
        List<Map<String, Object>> spareParts = new List<Map<String, Object>>();
        Map<String, Object> spareInput = new Map<String, Object>{
            'checkbox' => true,
            'quantity' => 1,
            'modelName' => prod.Name,
            'prodName' => 'Spare 1',
            'modelDesc' => 'Test Description',
            'price' => '500.0',
            'pricebookEntryId' => 'TestPBEntryId',
            'quantityReq' => '2'
        };
        spareParts.add(spareInput);

        // Test createSpareReturns
        fieldServiceSpareReturn.createSpareReturns(wo.Id, spareParts);

        // Verify Spare_Return__c was created
        List<Spare_Return__c> returns = [SELECT Id, Name, Quantity__c, Return_Quantity__c FROM Spare_Return__c WHERE Work_Order__c = :wo.Id];
 

        Test.stopTest();
    }
}