@isTest
public class AssetAMCTriggerHandlerTest {

    static Id serviceEngineerProfileId;

    @testSetup
    static void setupTestData() {

        serviceEngineerProfileId = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1].Id;

        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        User seUserOld = new User(
            FirstName = 'Engineer',
            LastName = 'Old',
            Email = 'engineer.old@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'eold',
            ProfileId = serviceEngineerProfileId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert seUserOld;

        Asset_AMC__c amcOld = new Asset_AMC__c(
            Name = 'Old AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = Date.today().addMonths(-12),
            AMC_Period_In_Months__c = 6,
            AMC_PO_Value__c = 5000,
            SE_Name__c = seUserOld.Id,
            PM_Visit_Allowed__c = 2,
            Product_Category_Type__c = 'AMC'
        );
        insert amcOld;

        User seUserNew = new User(
            FirstName = 'Engineer',
            LastName = 'New',
            Email = 'engineer.new@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'enew',
            ProfileId = serviceEngineerProfileId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert seUserNew;

        Asset_AMC__c amcNew = new Asset_AMC__c(
            Name = 'New AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = Date.today(),
            AMC_Period_In_Months__c = 12,
            AMC_PO_Value__c = 10000,
            SE_Name__c = seUserNew.Id,
            PM_Visit_Allowed__c = 4,
            Product_Category_Type__c = 'AMC'
        );
        insert amcNew;
    }

    @isTest
    static void testUpdateAMCEndDates() {
        List<Asset_AMC__c> amcs = [SELECT Id, AMC_Start_Date__c, AMC_Period_In_Months__c, AMC_End_Date__c, Asset_AMC_PO_Status__c FROM Asset_AMC__c];

        Test.startTest();
        AssetAMCTriggerHandler.updateAMCEndDates(amcs);
        Test.stopTest();

        for (Asset_AMC__c amc : amcs) {
            System.assertNotEquals(null, amc.AMC_End_Date__c, 'AMC End Date should be calculated.');
            System.assertNotEquals(null, amc.Asset_AMC_PO_Status__c, 'AMC PO Status should be set.');
        }
    }

    @isTest
    static void testUpdateAMCStatusAndAssetType() {
        List<Asset_AMC__c> amcs = [SELECT Id, Asset__c FROM Asset_AMC__c];

        Test.startTest();
        AssetAMCTriggerHandler.updateAMCStatusAndAssetType(amcs);
        Test.stopTest();

        Asset updatedAsset = [SELECT Type__c FROM Asset WHERE Id = :amcs[0].Asset__c];
        System.assertNotEquals(null, updatedAsset.Type__c, 'Asset type should be updated based on AMC status.');
    }

    @isTest
    static void testCreateAssetVisit() {
        Invoice__c testInvoice = new Invoice__c(Name = '6145000794');
        insert testInvoice;

        Asset testAsset = new Asset(
            Name = '6145000797',
            Invoice__c = testInvoice.Id
        );
        insert testAsset;

        // Create Asset_AMC__c test record
        Asset_AMC__c targetAMC = new Asset_AMC__c(
            Name = 'New AMC',
            AMC_Start_Date__c = Date.today(),
            AMC_Period_In_Months__c = 12,
            PM_Visit_Allowed__c = 1,
            Asset__c = testAsset.Id,
            Product_Category_Type__c = 'AMC'
        );

        Test.startTest();
        insert targetAMC;
        Test.stopTest();

        List<Asset_Visits__c> visits = [
            SELECT Id FROM Asset_Visits__c
            WHERE Asset_Serial_No__c = :targetAMC.Asset__c
            AND Visit_Type__c = 'Preventive Maintenance'
        ];
        System.assertEquals(targetAMC.PM_Visit_Allowed__c, visits.size(), 'Visit count must match PM visits allowed.');
    }

}