@isTest
public class FieldServiceInsSerceReportTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        Product2 prod = new Product2(Name = 'Test Product');
        insert prod;

        Asset ast = new Asset(Name = 'AST123', Product2Id = prod.Id, Is_Temp_Serial_Number__c = true);
        insert ast;

        Case cse = new Case(ContactId = con.Id, AssetId = ast.Id,AccountId = acc.Id);
        insert cse;

        Work_Order__c wo = new Work_Order__c(Case__c = cse.Id);
        insert wo;

        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cse.Id,
           Work_Order__c = wo.Id,Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false
           );
        insert sa;

        Installation_Report__c ir = new Installation_Report__c(Case__c = cse.Id, Work_Order__c = wo.Id, Installation_Asset_Serial_Number__c = ast.Name);
        insert ir;

        Service_Report__c sr = new Service_Report__c(Case__c = cse.Id, Work_Order__c = wo.Id, Service_Appointment__c = sa.Id);
        insert sr;

        Service_Report_Observation__c sro = new Service_Report_Observation__c(Service_Report__c = sr.Id,Actual_Observation_by_Engineer__c = 'Test', Cause__c = 'Test1', Sub_Cause__c = 'Test3');
        insert sro;
    }

    @isTest
    static void testGetReportDetails_Installation() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
        Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c LIMIT 1];

        Test.startTest();
        Object result = FieldServiceInstallationAndServiceReport.getReportDetails(wo.Id, sa.Id, 'InstallationReport');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

   @isTest
static void testGetReportDetails_Service() {
Account acc = new Account(Name = 'Test Account');
        insert acc;
    
    Asset asset = new Asset(Name='Test1 Asset1');
        insert asset;

        Case cse = new Case(AccountId = acc.Id, AssetId = asset.Id);
        insert cse;

        Work_Order__c wo = new Work_Order__c(Case__c = cse.Id);
        insert wo;
        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cse.Id,Work_Order__c = wo.Id,
              Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false
              );
        insert sa;

    Test.startTest();
    Object result = FieldServiceInstallationAndServiceReport.getReportDetails(wo.Id, sa.Id, 'ServiceReport');
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result from getReportDetails should not be null');
}

    @isTest
    static void testPreviewReport_Installation() {
        Installation_Report__c ir = [SELECT Id, Name FROM Installation_Report__c LIMIT 1];

        Test.startTest();
        Object result = FieldServiceInstallationAndServiceReport.previewReport(ir, null, 'InstallationReport');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testPreviewReport_Service() {
        Service_Report__c sr = [SELECT Id, Name FROM Service_Report__c LIMIT 1];

        Test.startTest();
        Object result = FieldServiceInstallationAndServiceReport.previewReport(null, sr, 'ServiceReport');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

   @isTest
static void testSaveReport_Installation() {
    Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = 'SAP123');
    insert acc;

    Product2 prod = new Product2(Name = 'Test Product', OEM_Material_Code__c = 'OEM123');
    insert prod;

    Asset ast = new Asset(Name = 'Test Asset', SerialNumber = 'SN123', Product2Id = prod.Id, OEM_Serial_Number__c = 'OEMSN123', Invoice_Number__c = 'INV123', Is_Temp_Serial_Number__c = true);
    insert ast;

    Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
    insert con;

    Case cs = new Case(AccountId = acc.Id, ContactId = con.Id, AssetId = ast.Id);
    insert cs;

    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

    List<Work_Order_Checklist__c> checklistItems = new List<Work_Order_Checklist__c>{
        new Work_Order_Checklist__c(Work_Order__c = wo.Id),
        new Work_Order_Checklist__c(Work_Order__c = wo.Id)
    };
    insert checklistItems;

    Installation_Report__c ir = new Installation_Report__c(
        Case__c = cs.Id,
        Item_Master__c = prod.Id,
        Installation_Start_Date__c = Date.today(),
        Installation_End_Date__c = Date.today().addDays(1),
        Signature__c = '<img src="test.png" />',
        Work_Order__c = wo.Id,
        Installation_Asset_Serial_Number__c = 'AssetSN123'
    );
    insert ir;

    Test.startTest();
    Object result = FieldServiceInstallationAndServiceReport.saveReport(ir, null, 'InstallationReport', new List<Service_Report_Observation__c>(), checklistItems, null);
    Test.stopTest();

    System.assertNotEquals(null, result);
}


    @isTest
static void testSaveReport_Service() {
    
    Account acc = new Account(Name = 'Test Account');
        insert acc;
    
     Asset asset = new Asset(Name='Test1 Asset1');
        insert asset;

        Case cse = new Case(AccountId = acc.Id, AssetId = asset.Id);
        insert cse;

        Work_Order__c wo = new Work_Order__c(Case__c = cse.Id);
        insert wo;
        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cse.Id,Work_Order__c = wo.Id,
               Scheduled_Start__c = DateTime.now().addDays(1), 
            Remote_Support__c = false                                               
             );
        insert sa;
    
    Service_Report__c sr = new Service_Report__c(
        Service_Appointment__c = sa.Id,
        Work_Order__c = wo.Id
    );
    insert sr;
    
    

Service_Report_Observation__c sro = new Service_Report_Observation__c(Service_Report__c = sr.Id,Actual_Observation_by_Engineer__c = 'Test', Cause__c = 'Test1', Sub_Cause__c = 'Test3');
        insert sro;   
    List<Work_Order_Checklist__c> checklistList = new List<Work_Order_Checklist__c>();

    Test.startTest();
    Object result = FieldServiceInstallationAndServiceReport.saveReport(
        null, 
        sr, 
        'ServiceReport', 
       new List<Service_Report_Observation__c>{sro},
        checklistList, 
        sr.Service_Appointment__c
    );
    Test.stopTest();

    System.assertNotEquals(null, result, 'The saveReport method should return a non-null result.');
}


    @isTest
    static void testDeleteRecord() {
        Service_Report_Observation__c sro = [SELECT Id FROM Service_Report_Observation__c LIMIT 1];

        Test.startTest();
        String result = FieldServiceInstallationAndServiceReport.deleteRecord(sro.Id);
        Test.stopTest();

        System.assertEquals('Success', result);
    }

    @isTest
    static void testGetDocumentId_Installation() {
        Installation_Report__c ir = [SELECT Id FROM Installation_Report__c LIMIT 1];

        Test.startTest();
        Object result = FieldServiceInstallationAndServiceReport.getDocumentId(ir.Id, 'InstallationReport');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetDocumentId_Service() {
        Service_Report__c sr = [SELECT Id FROM Service_Report__c LIMIT 1];

        Test.startTest();
        Object result = FieldServiceInstallationAndServiceReport.getDocumentId(sr.Id, 'ServiceReport');
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}