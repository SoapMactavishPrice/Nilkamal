@isTest
private class InstallationReportPdfControllerTest {
    @isTest static void testControllerWithPreviewAndData() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = 'SAP123');
        insert acc;

        Product2 prod = new Product2(Name = 'Test Product', OEM_Material_Code__c = 'OEM123');
        insert prod;

        Asset ast = new Asset(Name = 'Test Asset', SerialNumber = 'SN123', Product2Id = prod.Id, OEM_Serial_Number__c = 'OEMSN123', Invoice_Number__c = 'INV123');
        insert ast;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Case cs = new Case(AccountId = acc.Id, ContactId = con.Id, AssetId = ast.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c =cs.Id);
        insert wo;

        Installation_Report__c ir = new Installation_Report__c(
            //Name = 'Test Installation Report',
            Case__c = cs.Id,
            Item_Master__c = prod.Id,  // Can't assign relationship in insert, set fields if needed
            Installation_Start_Date__c = Date.today(),
            Signature__c = '<img src="test.png" />',
            Work_Order__c = wo.Id,
            Installation_Asset_Serial_Number__c = 'AssetSN123'
        );
        insert ir;
        
        List<Work_Order_Checklist__c> checklistItems = new List<Work_Order_Checklist__c>();
        checklistItems.add(new Work_Order_Checklist__c(
            //Name = 'Mechanical Check 1',
            //Checklist_Category__c = 'Mechanical',
            Work_Order__c = wo.Id
        ));
        checklistItems.add(new Work_Order_Checklist__c(
            //Name = 'Operational Check 1',
            //Checklist_Category__c = 'Operational',
            Work_Order__c = wo.Id
        ));
        insert checklistItems;

        Test.setCurrentPage(Page.InstallationReportPdf); // create dummy page reference
        ApexPages.currentPage().getParameters().put('id', ir.Id);
        ApexPages.currentPage().getParameters().put('isPreview', 'true');

        Service_Resource__c sr = new Service_Resource__c(
            User__c = UserInfo.getUserId(),
            Signature__c = '<img src="sr.png" />'
        );
        insert sr;

        InstallationReportPdfController controller = new InstallationReportPdfController();

        System.assertEquals(ir.Id, controller.record.Id, 'The record should be loaded');
        System.assertEquals(true, controller.isPreview, 'isPreview should be true');
        System.assert(controller.serviceResource != null, 'Service Resource should be set');
        System.assert(controller.col1.size() > 0 || controller.col2.size() > 0, 'Columns should be balanced');
        System.assert(controller.getSignatureImage().startsWith('data:image/png;base64,'), 'Signature image string should be returned');

        controller.record.Signature__c = null;
        System.assertEquals('', controller.getSignatureImage());
    }
}