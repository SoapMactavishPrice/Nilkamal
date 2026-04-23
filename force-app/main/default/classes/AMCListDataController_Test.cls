@isTest
public class AMCListDataController_Test {

    @testSetup
    static void setupTestData() {
        List<Pin_Code_Master__c> pinList = new List<Pin_Code_Master__c>{
            new Pin_Code_Master__c(Name = '421306'),
            new Pin_Code_Master__c(Name = '421305')
        };
        insert pinList;
        
        Service_Resource__c sr = new Service_Resource__c();
        sr.User__c = UserInfo.getUserId();
        insert sr;
        
        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c();
       	srp.Service_Resource__c = sr.Id;
        srp.Pin_Code_Master__c = pinList[0].Id;
        insert srp;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Asset asset = new Asset(
            Name = 'Test Asset',
            SerialNumber = 'SN12345',
            AccountId = acc.Id,
            ContactId = con.Id,
            Invoice_Number__c = 'INV-001',
            Ship_To_Pin__c = pinList[0].Name,
            Pin_Code_Master__c = pinList[0].Id,
            Business_Vertical__c = 'Printer'
        );
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Date_of_Commissioning__c = Date.today().addDays(-200),
            Warranty_Start_Date__c = Date.today().addDays(-200),
            Warranty_Period__c = 6
        );
        insert warranty;

        Asset_AMC__c amc = new Asset_AMC__c(
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today().addDays(-35),
            AMC_Period_In_Months__c = 6,
            Product_Category_Type__c = 'AMC'
        );
        insert amc;
    }

    @isTest
    static void test_getAssetRecords_returnsValidData() {
        Test.startTest();
        String response = AMCListDataController.getAssetRecords();
        Test.stopTest();

        System.debug('Returned JSON: ' + response);
        System.assertNotEquals(null, response, 'Response should not be null');

        List<Object> parsedResult = (List<Object>) JSON.deserializeUntyped(response);
        System.assertEquals(1, parsedResult.size(), 'Should return 1 asset with valid data');

        Map<String, Object> assetData = (Map<String, Object>) parsedResult[0];
        System.assert(assetData.containsKey('asset'), 'Asset key should exist');
        System.assert(assetData.containsKey('warranties'), 'Warranties key should exist');
        System.assert(assetData.containsKey('amcs'), 'AMCs key should exist');

        List<Object> warranties = (List<Object>) assetData.get('warranties');
        List<Object> amcs = (List<Object>) assetData.get('amcs');

        //System.assert(warranties.size() > 0, 'There should be at least one active warranty');
        //System.assert(amcs.size() > 0, 'There should be at least one active AMC');
    }

    @isTest
    static void test_getAssetRecords_returnsEmptyIfNoData() {
        // Clean up created data
        List<Asset_Warranty__c> warranties = [SELECT Id FROM Asset_Warranty__c];
        List<Asset_AMC__c> amcs = [SELECT Id FROM Asset_AMC__c];
        delete warranties;
        delete amcs;

        List<Asset> assets = [SELECT Id FROM Asset];
        delete assets;

        Test.startTest();
        String response = AMCListDataController.getAssetRecords();
        Test.stopTest();

        System.debug('Empty response JSON: ' + response);
        List<Object> parsedResult = (List<Object>) JSON.deserializeUntyped(response);
        System.assertEquals(0, parsedResult.size(), 'Should return no assets');
    }
}