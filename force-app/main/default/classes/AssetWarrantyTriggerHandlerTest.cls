@isTest
private class AssetWarrantyTriggerHandlerTest {

    @isTest
    static void testUpdateWarrantyEndDate() {
        Asset_Warranty__c aw = new Asset_Warranty__c();
        aw.Warranty_Start_Date__c = Date.today().addMonths(-1);
        aw.Warranty_Period__c = 6;
        aw.Asset_Warranty_PO_Status__c = null;

        List<Asset_Warranty__c> listAW = new List<Asset_Warranty__c>{aw};

        Test.startTest();
        AssetWarrantyTriggerHandler.updateWarrantyEndDate(listAW);
        Test.stopTest();
    }

    @isTest
    static void testUpdateWarrantyStatusAndAssetType() {
        Asset asset = new Asset(Name='Test Asset');
        insert asset;

        Asset_Warranty__c aw = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today(),
            Warranty_End_Date__c = Date.today().addDays(5),
            Warranty_Period__c = 12
        );
        insert aw;

        List<Asset_Warranty__c> listAW = [SELECT Id, Asset__c, Warranty_End_Date__c FROM Asset_Warranty__c WHERE Id = :aw.Id];

        Test.startTest();
        AssetWarrantyTriggerHandler.updateWarrantyStatusAndAssetType(listAW);
        Test.stopTest();

        Asset updatedAsset = [SELECT Type__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals('Within Warranty', updatedAsset.Type__c);
    }

    @isTest
    static void testCreateAssetVisit() {
        Asset asset = new Asset(Name='Test Asset');
        insert asset;

        Asset_Warranty__c aw = new Asset_Warranty__c(
            Warranty_Period__c = 6,
            PM_Visit_Allowed__c = 3,
            Warranty_Start_Date__c = Date.today(),
            Asset__c = asset.Id
        );
        insert aw;

        List<Asset_Warranty__c> listAW = [SELECT Id, Warranty_Period__c, PM_Visit_Allowed__c, Warranty_Start_Date__c, Asset__c FROM Asset_Warranty__c WHERE Id = :aw.Id];

        Test.startTest();
        AssetWarrantyTriggerHandler.createAssetVisit(listAW);
        Test.stopTest();

        List<Asset_Visits__c> visits = [SELECT Id, Name, Planned_Visit_Date__c FROM Asset_Visits__c WHERE Asset_Warranty__c = :aw.Id];
    }

    @isTest
    static void testUpdateAsset() {
        Asset asset = new Asset(Name='Test Asset for Update');
        insert asset;

        Asset_Warranty__c aw = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addMonths(-2),
            Warranty_End_Date__c = Date.today().addMonths(4),
            Warranty_Period__c = 6
        );
        insert aw;

        Map<Id, Asset_Warranty__c> awMap = new Map<Id, Asset_Warranty__c>{aw.Id => aw};

        Test.startTest();
        AssetWarrantyTriggerHandler.updateAsset(awMap);
        Test.stopTest();

        Asset updatedAsset = [SELECT Warranty_Start_Date__c, Warranty_End_Date__c, Warranty_Period_Months__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(aw.Warranty_Start_Date__c, updatedAsset.Warranty_Start_Date__c);
        System.assertEquals(aw.Warranty_End_Date__c, updatedAsset.Warranty_End_Date__c);
        System.assertEquals(aw.Warranty_Period__c, updatedAsset.Warranty_Period_Months__c);
    }

}