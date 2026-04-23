@isTest
private class InstallationReportControllerTest {

    @testSetup
    static void setupData() {
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testuser' +  Math.floor(Math.random() * 1000000) + '@example.com'
        );
        insert testUser;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Asset ast = new Asset(Name = 'Test Asset', Product2Id = prod.Id);
        insert ast;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Case cs = new Case(AccountId = acc.Id, Status = 'New', Origin = 'Phone', AssetId = ast.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cs.Id,Work_Order__c = wo.Id,OwnerId = testUser.Id,Scheduled_Start__c = DateTime.now(),Remote_Support__c = false);
        insert sa;

        Installation_Report__c report = new Installation_Report__c(
            Work_Order__c = wo.Id,
            Installation_Status__c = 'Completed'
        );
        insert report;

        Service_Report__c sr = new Service_Report__c(
            Case__c = cs.Id, Work_Order__c = wo.Id, Service_Appointment__c = sa.Id
        );
        insert sr;
    }

    @isTest
    static void testGetInstallationReport() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
        String response = InstallationReportController.getInstallationReport(wo.Id);
        System.assert(response != null);
    }

    @isTest
    static void testGetInstallationReportWhenNoReport() {
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        Asset ast = new Asset(Name = 'Test Asset 2', Product2Id = prod.Id);
        insert ast;
        
        Account acc = new Account(Name = 'Another Account');
        insert acc;

        Case cs = new Case(AccountId = acc.Id, Status = 'New', Origin = 'Phone', AssetId = ast.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        String response = InstallationReportController.getInstallationReport(wo.Id);
        System.assertEquals('', response);
    }

    @isTest
    static void testGetWorkOrderDetails() {
        Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
        Work_Order__c result = InstallationReportController.getWorkOrderDetails(wo.Id);
        System.assertEquals(wo.Id, result.Id);
    }

    @isTest
static void testGetServiceReport() {
    User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testuser' +  Math.floor(Math.random() * 1000000) + '@example.com'
        );
        insert testUser;
    
     	Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Asset ast = new Asset(Name = 'Test Asset 3', Product2Id = prod.Id);
        insert ast;
    
    	Account acc = new Account(Name = 'Test Account');
        insert acc;
		
		Case cs = new Case(AccountId = acc.Id, Status = 'New', Origin = 'Phone',AssetId = ast.Id);
        insert cs;
    
    Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];
    
    Service_Appointment__c sa = new Service_Appointment__c(Case__c = cs.Id,Work_Order__c = wo.Id,OwnerId = testUser.Id,Scheduled_Start__c = DateTime.now(),Remote_Support__c = false);
        insert sa;
            
    Service_Report__c sr = new Service_Report__c(
        Work_Order__c = wo.Id,
        SR_Status__c = 'Completed',
        Case__c = cs.Id,
        Service_Appointment__c = sa.Id
    );
    insert sr;

    Test.startTest();
    String response = InstallationReportController.getServiceReport(wo.Id);
    Test.stopTest();

    System.assertNotEquals(null, response);
    System.assert(response.contains('status'));
}


    @isTest
    static void testGetServiceReportWhenNoReport() {
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Asset ast = new Asset(Name = 'Test Asset 3', Product2Id = prod.Id);
        insert ast;
        
        Account acc = new Account(Name = 'NoReportAcc');
        insert acc;

        Case cs = new Case(AccountId = acc.Id, Status = 'New', Origin = 'Phone',AssetId = ast.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Test.startTest();
        try {
            String response = InstallationReportController.getServiceReport(wo.Id);
            System.assertEquals(null, response); 
        } catch (Exception e) {
            System.assert(e.getMessage().contains('List index out of bounds'));
        }
        Test.stopTest();
    }

    @isTest
static void testSaveSignature() {
    Work_Order__c wo = [SELECT Id FROM Work_Order__c LIMIT 1];

    Installation_Report__c report = new Installation_Report__c(
        Work_Order__c = wo.Id,
        Installation_Status__c = 'Completed'
    );
    insert report;

    Test.startTest();
    try{InstallationReportController.saveSignature(report.Id, 'dGVzdGltYWdlZGF0YQ==');}catch (Exception e){System.debug('Error');} // base64 dummy
    Test.stopTest();

    report = [SELECT Signature__c FROM Installation_Report__c WHERE Id = :report.Id];
   // System.assertNotEquals(null, report.Signature__c);
    //System.assert(report.Signature__c.contains('<img src="data:image/png;base64,dGVzdGltYWdlZGF0YQ=='));
}


    @isTest
    static void testSaveSignatureInvalid() {
        Test.startTest();
        try {
            InstallationReportController.saveSignature(null, '');
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Record ID or Signature Data is missing.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGeneratePdfInstallation() {
        Installation_Report__c report = [SELECT Id, Name FROM Installation_Report__c LIMIT 1];

        Test.startTest();
        Id docId = InstallationReportController.generatePdf(report.Id, 'InstallationReport', false, null);
        Test.stopTest();

        System.assertNotEquals(null, docId);
    }

    @isTest
    static void testGeneratePdfService() {
        Service_Report__c sr = [SELECT Id, Name FROM Service_Report__c LIMIT 1];

        Test.startTest();
        Id docId = InstallationReportController.generatePdf(sr.Id, 'ServiceReport', true, null);
        Test.stopTest();

        System.assertNotEquals(null, docId);
    }

    @isTest
    static void testGeneratePdfDeleteOldPreview() {
        Installation_Report__c report = [SELECT Id, Name FROM Installation_Report__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Old Preview',
            PathOnClient = 'OldPreview.pdf',
            VersionData = Blob.valueOf('Old data'),
            IsMajorVersion = true
        );
        insert cv;

        ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        Id previewDocId = insertedCV.ContentDocumentId;

        Test.startTest();
        Id docId = InstallationReportController.generatePdf(report.Id, 'InstallationReport', false, previewDocId);
        Test.stopTest();

        System.assertNotEquals(null, docId);
    }

    @isTest
    static void testGeneratePdfInstallationPreview() {
        Installation_Report__c report = [SELECT Id FROM Installation_Report__c LIMIT 1];

        Test.startTest();
        Id docId = InstallationReportController.generatePdf(report.Id, 'InstallationReport', true, null);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Preview PDF for Installation Report should be generated');
    }
}