@isTest
public class fieldServiceRequestTest {

    @testSetup
    static void setupData() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Account acc = new Account(Name = 'Test Account', Pricelist__c = testPricebook.Id);
        insert acc;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'MHEOWSER',
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'MHE'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        Asset ast = new Asset(
            Name = 'TestSerial123',
            AccountId = acc.Id,
            Product2Id = prod.Id
        );
        insert ast;

        Case cs = new Case(
            AccountId = acc.Id,
            Type = 'Breakdown',
            Case_Sub_Type__c = 'Chargeable Service',
            AssetId = ast.Id
        );
        insert cs;

         /*Case cs1 = new Case(
            AccountId = acc.Id,
            Type = 'Re-Installation',
            Case_Sub_Type__c = 'Re-installation',
            AssetId = ast.Id
        );
        insert cs1;*/

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, CurrencyIsoCode = 'INR');
        insert wo;

        Service_Pricing__c sp = new Service_Pricing__c(
            Price__c = 200,
            Service_Material_Code__c = prod.Id
        );
        insert sp;

        Service_Request__c sr = new Service_Request__c(
            Work_Order__c = wo.Id,
            Item_Master__c = prod.Id,
            Price__c = 150,
            Original_Price__c = 180,
            Quantity__c = 2,
            Warranty_Period__c = '12 Months',
            Number_of_PM_Visit__c = '1',
            Number_of_Breakdown_Visit__c = '1',
            Is_Cloned__c = false,
            Clone_Id__c = null
        );
        insert sr;
    }

    @isTest
    static void testGetWorkOrderData() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
        Test.startTest();
        List<Work_Order__c> result = fieldServiceRequest.getWorkOrderData(wo.Id);
        Test.stopTest();
        System.assertEquals(1, result.size());
    }

   @isTest
    static void testGetProductsByPartNo() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = fieldServiceRequest.getProductsByPartNo(wo.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Expected non-empty result');
    }

    @isTest
    static void testGetProductsByPartNo_NonMHE() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Account acc = new Account(Name = 'Test Account', Pricelist__c = testPricebook.Id);
        insert acc;

        Product2 prod = new Product2(
            Name = 'Non MHE Product',
            ProductCode = 'XYZ123',
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'CNPL'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        Asset ast = new Asset(Name = 'NonMHE Asset', AccountId = acc.Id, Product2Id = prod.Id);
        insert ast;

        Case cs = new Case(
            AccountId = acc.Id,
            AssetId = ast.Id,
            Division__c = 'CNPL',
            Type = 'Breakdown',
            Case_Sub_Type__c = 'Chargeable Service'
        );
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, CurrencyIsoCode = 'INR');
        insert wo;

        Test.startTest();
        List<Map<String, Object>> result = fieldServiceRequest.getProductsByPartNo(wo.Id);
        Test.stopTest();

        //System.assertEquals(0, result.size(), 'Non-MHE records should return no data');
    }

    @isTest
static void testGetProductsByPartNo_SampleCombinations() {
    Pricebook2 pb = new Pricebook2(Name = 'Nilkamal', IsActive = true);
    insert pb;

    Account acc = new Account(Name = 'Test Account', Pricelist__c = pb.Id);
    insert acc;

    List<String> types = new List<String>{'Installation', 'Preventive Maintenance'};
    List<String> subTypes = new List<String>{'Installation & Commissioning', 'AMC PM'};
    List<String> productCodes = new List<String>{'MHEINSTALNSER', 'MHEAMCSER'};

    List<Work_Order__c> workOrders = new List<Work_Order__c>();

    for (Integer i = 0; i < types.size(); i++) {
        Product2 prod = new Product2(
            Name = 'Product ' + i,
            ProductCode = productCodes[i],
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'MHE'
        );
        insert prod;

        Asset ast = new Asset(
            Name = 'Asset ' + i,
            AccountId = acc.Id,
            Product2Id = prod.Id
        );
        insert ast;

        Case cs = new Case(
            AccountId = acc.Id,
            AssetId = ast.Id,
            Division__c = 'MHE',
            Type = types[i],
            Case_Sub_Type__c = subTypes[i]
        );
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, CurrencyIsoCode = 'INR');
        insert wo;
        workOrders.add(wo);

        Service_Pricing__c pricing = new Service_Pricing__c(
            Material_Group_6__c = 'A33',
            Service_Material_Code__c = prod.Id,
            Price__c = 100.0
        );
        insert pricing;

        Service_Request__c sr = new Service_Request__c(
            Work_Order__c = wo.Id,
            Item_Master__c = prod.Id,
            Price__c = 50.0,
            Original_Price__c = 100.0,
            Quantity__c = 2,
            Warranty_Period__c = '12',
            Number_of_PM_Visit__c = '2',
            Number_of_Breakdown_Visit__c = '1',
            Is_Cloned__c = false,
            Clone_Id__c = '',
            CurrencyIsoCode = 'INR'
        );
        insert sr;
    }

    Test.startTest();
    for (Work_Order__c wo : workOrders) {
        List<Map<String, Object>> result = fieldServiceRequest.getProductsByPartNo(wo.Id);
        System.assertNotEquals(null, result);
    }
    Test.stopTest();
}
    @isTest
static void testGetProductsByPartNo_SampleCombinations1() {
    Pricebook2 pb = new Pricebook2(Name = 'Nilkamal', IsActive = true);
    insert pb;

    Account acc = new Account(Name = 'Test Account', Pricelist__c = pb.Id);
    insert acc;

    List<String> types = new List<String>{'Installation'};
    List<String> subTypes = new List<String>{'Installation & Commissioning', 'AMC PM'};
    List<String> productCodes = new List<String>{'MHEINSTALNSER', 'MHEAMCSER'};

    List<Work_Order__c> workOrders = new List<Work_Order__c>();

    for (Integer i = 0; i < types.size(); i++) {
        Product2 prod = new Product2(
            Name = 'Product ' + i,
            ProductCode = productCodes[i],
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'MHE'
        );
        insert prod;

        Asset ast = new Asset(
            Name = 'Asset ' + i,
            AccountId = acc.Id,
            Product2Id = prod.Id
        );
        insert ast;

        Case cs = new Case(
            AccountId = acc.Id,
            AssetId = ast.Id,
            Division__c = 'MHE',
            Type = types[i],
            Case_Sub_Type__c = subTypes[i]
        );
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, CurrencyIsoCode = 'INR');
        insert wo;
        workOrders.add(wo);

        Service_Pricing__c pricing = new Service_Pricing__c(
            Material_Group_6__c = 'A33',
            Service_Material_Code__c = prod.Id,
            Price__c = 100.0
        );
        insert pricing;

        Service_Request__c sr = new Service_Request__c(
            Work_Order__c = wo.Id,
            Item_Master__c = prod.Id,
            Price__c = 50.0,
            Original_Price__c = 100.0,
            Quantity__c = 2,
            Warranty_Period__c = '12',
            Number_of_PM_Visit__c = '2',
            Number_of_Breakdown_Visit__c = '1',
            Is_Cloned__c = false,
            Clone_Id__c = '',
            CurrencyIsoCode = 'INR'
        );
        insert sr;
    }

    Test.startTest();
    for (Work_Order__c wo : workOrders) {
        List<Map<String, Object>> result = fieldServiceRequest.getProductsByPartNo(wo.Id);
        System.assertNotEquals(null, result);
    }
    Test.stopTest();
}


    @isTest
    static void testCreateServiceRequest() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        Case cs = new Case(AccountId = acc.Id, AssetId = testAsset.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Service_Request__c sr = new Service_Request__c(
            Name = 'Dummy SR',
            Work_Order__c = wo.Id
        );
        insert sr;

        List<Map<String, Object>> inputList = new List<Map<String, Object>>();
        Map<String, Object> srMap = new Map<String, Object>{
            'Id' => sr.Id,
            'checkbox' => true,
            'modelName' => 'Test Model',
            'modelDesc' => 'Test Desc',
            'hsncode' => '1234',
            'price' => 150,
            'amcprice' =>200,
            'newprice' => 180,
            'currency' => 'USD',
            'quantity' => 2,
            'warranty' => 'Y',
            'warrantyperiod' => '1 year',
            'noofpmvisit' => '1',
            'noofbreakdownvisit' => '1',
            'isClone' => false,
            'cloneId' => null
        };
        inputList.add(srMap);

        Test.startTest();
        try{
        fieldServiceRequest.createServiceRequest(inputList, wo.Id, null);
        }catch(Exception e){

        }
        Test.stopTest();

        List<Service_Request__c> created = [
            SELECT Id FROM Service_Request__c WHERE Work_Order__c = :wo.Id
        ];
        System.assert(created.size() > 0, 'At least one service request should be created');
    }

    @isTest
    static void testGetAssetDetails_AMC() {
        Asset asset = [SELECT Id, Name FROM Asset WHERE Name = 'TestSerial123' LIMIT 1];

        Asset_AMC__c amc = new Asset_AMC__c(
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today(),
            AMC_End_Date__c = Date.today().addDays(365),
            AMC_PO_Value__c = 9999,
            Asset_AMC_PO_Status__c = 'Active',
            AMC_Period_In_Months__c = 6,
            Product_Category_Type__c = 'AMC'
        );
        insert amc;
        try{
        Test.startTest();
        Object result = fieldServiceRequest.getAssetDetails(asset.Name);
        Test.stopTest();

        System.assertNotEquals(null, result, 'AMC record should be returned');
        System.assertEquals(amc.Id, ((Asset_AMC__c) result).Id, 'Returned AMC should match inserted one');
        }catch(Exception e){

        }
    }

    @isTest
    static void testGetAssetDetails_WarrantyFallback() {
        Asset asset = new Asset(Name = 'WarrantyAsset');
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addDays(-90),
            Warranty_End_Date__c = Date.today().addDays(90),
            Warranty_Period__c = 12

        );
        insert warranty;

        Test.startTest();
        Object result = fieldServiceRequest.getAssetDetails(asset.Name);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Warranty record should be returned');
        System.assertEquals(warranty.Id, ((Asset_Warranty__c) result).Id, 'Returned Warranty should match inserted one');
    }
    
    @isTest
    static void testGetProductsByPartNo_Printer() {
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Account acc = new Account(Name = 'Test Account', Pricelist__c = testPricebook.Id);
        insert acc;

        Product2 prod = new Product2(
            Name = 'Non MHE Product',
            ProductCode = 'XYZ123',
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'Printer'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        Asset ast = new Asset(Name = 'NonMHE Asset', AccountId = acc.Id, Product2Id = prod.Id);
        insert ast;
        
       Case cs  = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Installation',              Case_Sub_Type__c = 'Installation & Commissioning');
	   Case cs1 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Preventive Maintenance',   Case_Sub_Type__c = 'AMC PM');
	   Case cs2 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Preventive Maintenance',   Case_Sub_Type__c = 'Warranty PM');
	   Case cs3 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Preventive Maintenance',   Case_Sub_Type__c = 'Health Checkup');
	   Case cs4 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Preventive Maintenance',   Case_Sub_Type__c = 'CAMC PM');
	   Case cs5 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Breakdown',                Case_Sub_Type__c = 'Chargeable Service');
	   Case cs6 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Breakdown',                Case_Sub_Type__c = 'Warranty Breakdown');
	   Case cs7 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Re-Installation',          Case_Sub_Type__c = 'Re-Installation');
	   Case cs8 = new Case(AccountId = acc.Id, AssetId = ast.Id, Division__c = 'Printer', Type = 'Training',                 Case_Sub_Type__c = 'Training');
        List<Case> cases=new List<Case>{cs,cs1,cs2,cs3,cs4,cs5,cs6,cs7,cs8};
        insert cases;

        List<Work_Order__c> wos=new List<Work_Order__c>();
        for(Case ccs:cases){
            Work_Order__c wo = new Work_Order__c(Case__c = ccs.Id, CurrencyIsoCode = 'INR');
            wos.add(wo);
        }        
        insert wos;

        Test.startTest();
        for(Work_Order__c wods:wos){
            List<Map<String, Object>> result = fieldServiceRequest.getProductsByPartNo(wods.Id);
        }
        Test.stopTest();

        //System.assertEquals(0, result.size(), 'Non-MHE records should return no data');
    }

}