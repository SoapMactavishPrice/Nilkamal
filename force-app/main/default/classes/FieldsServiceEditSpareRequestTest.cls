@isTest
public class FieldsServiceEditSpareRequestTest {

    @testSetup
static void setupData() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    
      Asset asset = new Asset(Name='Test Asset');
        insert asset;

    Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
    insert prod;

    HSN_Master__c hsn = new HSN_Master__c(Name = 'HSN001', CGST__c = 5, SGST__c = 5);
    insert hsn;

    Case cs = new Case(AccountId = acc.Id, AssetId =asset.Id);
    insert cs;

    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

    List<Schema.PicklistEntry> picklistEntries = Spare_Request__c.Spare_Status__c.getDescribe().getPicklistValues();
    String validStatus = picklistEntries[0].getValue();

    System.assertNotEquals(null, validStatus, 'Spare Status picklist must not be null');

    Spare_Request__c sr = new Spare_Request__c(
        Name = 'Test Spare Request',
        Work_Order__c = wo.Id,
        Quantity_Required__c = 2,
        Billed_Value__c = 100,
        Item_Master__c = prod.Id,
        Spare_Status__c = 	'Requested'
    );
    insert sr;
}


    @isTest
    static void testGetStatusList() {
        Test.startTest();
        String resultJson = FieldsServiceEditSpareRequest.getStatusList();
        Test.stopTest();

        System.assertNotEquals(null, resultJson, 'Status list should not be null');
        System.assert(resultJson.contains('label'), 'JSON should contain label');
    }

    @isTest
    static void testGetSpareRequestsByWorkOrder() {
        Account acc = new Account(Name = 'Test Account');
    insert acc;
          Asset asset = new Asset(Name='Test Assetq');
        insert asset;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
    insert prod;
        
         Case cs = new Case(AccountId = acc.Id, AssetId = asset.Id);
    insert cs;

    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;
       
Spare_Request__c sr = new Spare_Request__c(
        Name = 'Test Spare Request',
        Work_Order__c = wo.Id,
        Quantity_Required__c = 2,
        Billed_Value__c = 100,
        Item_Master__c = prod.Id,
        Spare_Status__c = 	'Requested'
    );
    insert sr;
        Test.startTest();
        List<Spare_Request__c> result = FieldsServiceEditSpareRequest.getSpareRequestsByWorkOrder(wo.Id);
        Test.stopTest();

        System.debug('Spare Requests returned from method: ' + result.size());

        System.assertEquals(1, result.size(), 'Should return 1 spare request');
        System.assertEquals(wo.Id, result[0].Work_Order__c, 'Work order ID should match');
    }

    @isTest
    static void testDeleteSpareRequest() {
        Spare_Request__c sr = [SELECT Id FROM Spare_Request__c LIMIT 1];

        Test.startTest();
        FieldsServiceEditSpareRequest.deleteSpareRequest(sr.Id);
        Test.stopTest();

        List<Spare_Request__c> remaining = [SELECT Id FROM Spare_Request__c WHERE Id = :sr.Id];
        System.assertEquals(0, remaining.size(), 'Spare request should be deleted');
    }

    @isTest
    static void testSaveSpareRequestChanges() {
        Spare_Request__c sr = [SELECT Id, Quantity_Required__c FROM Spare_Request__c LIMIT 1];
        sr.Quantity_Required__c = 5;

        Test.startTest();
        FieldsServiceEditSpareRequest.saveSpareRequestChanges(new List<Spare_Request__c>{sr});
        Test.stopTest();

        Spare_Request__c updated = [SELECT Quantity_Required__c FROM Spare_Request__c WHERE Id = :sr.Id];
        System.assertEquals(5, updated.Quantity_Required__c, 'Quantity should be updated to 5');
    }
}