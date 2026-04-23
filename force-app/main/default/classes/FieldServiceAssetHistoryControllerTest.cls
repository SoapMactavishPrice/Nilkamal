@isTest
public class FieldServiceAssetHistoryControllerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'User', AccountId = acc.Id);
        insert con;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Asset asset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            ContactId = con.Id,
            Product2Id = prod.Id,
            InstallDate = Date.today(),
            SerialNumber = 'SN-001'
        );
        insert asset;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Test Warranty',
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addDays(-100),
            Warranty_End_Date__c = Date.today().addDays(100),
            Warranty_Period__c = 12
        );
        insert warranty;

        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'Test AMC',
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today().addDays(-30),
            AMC_End_Date__c = Date.today().addDays(30),
            Product_Category_Type__c = 'AMC',
            AMC_Period_In_Months__c = 12
        );
        insert amc;

        Case cs = new Case(Subject = 'Test Case', AssetId = asset.Id, AccountId = acc.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Service_Appointment__c sa = new Service_Appointment__c(Work_Order__c = wo.Id, Case__c = cs.Id,
            Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false);
        insert sa;

        Installation_Report__c ir = new Installation_Report__c(Work_Order__c = wo.Id, Case__c = cs.Id);
        insert ir;

        Service_Report__c sr = new Service_Report__c(Work_Order__c = wo.Id, Case__c = cs.Id, Service_Appointment__c = sa.Id);
        insert sr;
    }

    @isTest
    static void testGetAssetDataFromAsset() {
        Asset asset = [SELECT Id FROM Asset LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(asset.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Asset ID');
    }

    @isTest
    static void testGetAssetDataFromCase() {
        Case cs = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(cs.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Case ID');
    }

    @isTest
    static void testGetAssetDataFromWorkOrder() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(wo.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Work Order ID');
    }

    @isTest
    static void testGetAssetDataFromServiceAppointment() {
        Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(sa.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Service Appointment ID');
    }

    @isTest
    static void testGetAssetDataFromInstallationReport() {
        Installation_Report__c ir = [SELECT Id FROM Installation_Report__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(ir.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Installation Report ID');
    }

    @isTest
    static void testGetAssetDataFromServiceReport() {
        Service_Report__c sr = [SELECT Id FROM Service_Report__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceAssetHistoryController.getAssetData(sr.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected asset data for Service Report ID');
    }
}