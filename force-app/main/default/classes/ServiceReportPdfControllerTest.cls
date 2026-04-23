@isTest
private class ServiceReportPdfControllerTest {

    @isTest
    static void testServiceReportPdfController() {
        // Create supporting data
        Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = 'CUST001');
        insert acc;

        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john@example.com', AccountId = acc.Id);
        insert con;

        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'P001', IsActive = true);
        insert prod;

        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id, SerialNumber = 'SN123', OEM_Serial_Number__c = 'OEM123');
        insert asset;

        Case cs = new Case(
            AccountId = acc.Id,
            ContactId = con.Id,
            Status = 'New',
            Subject = 'Test Case',
            AssetId = asset.Id,
            Description = 'Test Description'
        );
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

         Service_Appointment__c sa = new Service_Appointment__c(Case__c = cs.Id,
            Check_In_Date_Time__c = System.now().addHours(-2),
            Check_Out_Date_Time__c = System.now(),
             Work_Order__c = wo.Id,
             Scheduled_Start__c = DateTime.now().addDays(1), 
            Remote_Support__c = false
               );                                                  
                                                                
        insert sa;
        
        Service_Report__c sr = new Service_Report__c(
            Case__c = cs.Id,
            Work_Order__c = wo.Id,
            Product__c = prod.Id,
            Service_Appointment__c = sa.Id,
            Customer_Feedback__c = 'Excellent',
            Signature__c = '<img src="signature.png">',
            Signature_by__c = 'Customer'
        );
        insert sr;

        /*Service_Appointment__c sa = new Service_Appointment__c(
            Case__c = cs.Id,
            Check_In_Date_Time__c = System.now().addHours(-2),
            Check_Out_Date_Time__c = System.now(),
            Work_Order__c = wo.id
        );
        insert sa;*/

        Service_Report_Observation__c obs = new Service_Report_Observation__c(
            Service_Report__c = sr.Id,
            Cause__c = 'Cause A',
            Sub_Cause__c = 'Sub Cause A',
            Actual_Observation_by_Engineer__c = 'Observation',
            Correction__c = 'Correction'
        );
        insert obs;

        Work_Order_Checklist__c checklist = new Work_Order_Checklist__c(
            Work_Order__c = wo.Id,
            Checklist_Category__c = 'Operational Check Points',
            Observation__c = 'Yes'
        );
        insert checklist;

        Spare_Request__c spare = new Spare_Request__c(
            Work_Order__c = wo.Id,
            Case__c = cs.Id,
            Item_Description__c = 'Spare Item',
            Quantity_Required__c = 2
        );
        insert spare;

        Service_Resource__c srRes = new Service_Resource__c(
            User__c = cs.OwnerId,
            Signature__c = '<img src="engineer-signature.png">'
        );
        insert srRes;

        // Simulate Visualforce page parameters
        Test.startTest();
        PageReference pageRef = Page.ServiceReportPdf; // Replace with your actual VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', sr.Id);
        ApexPages.currentPage().getParameters().put('isPreview', 'true');

        // Instantiate controller
        ServiceReportPdfController controller = new ServiceReportPdfController();
        Test.stopTest();
    }
}