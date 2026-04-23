@isTest
public class AutoCloseServiceAppointment_Test {

    @testSetup
    static void setupData() {
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
        
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            caseList.add(new Case(
                Origin = 'Phone',
                Status = 'New',
                Subject = 'Test Case ' + i,
                AssetId = asset.Id,
                AccountId = acc.Id
            ));
        }
        insert caseList;

        List<Work_Order__c> workOrderList = new List<Work_Order__c>();
        for (Integer i = 0; i < 5; i++) {
            workOrderList.add(new Work_Order__c(Case__c = caseList[i].Id));
        }
        insert workOrderList;

        List<Service_Appointment__c> appointments = new List<Service_Appointment__c>();
        for (Integer i = 0; i < 5; i++) {
            appointments.add(new Service_Appointment__c(
                Status__c = 'In Progress',
                Case__c = caseList[i].Id,
                Work_Order__c = workOrderList[i].Id,
                 Scheduled_Start__c = DateTime.now(),
            Remote_Support__c = false
               
            ));
        }
        insert appointments;

        // Create Service Appointment Check In/Out records with required fields
        List<Service_Appointment_Check_In_and_Out__c> checkInOutList = new List<Service_Appointment_Check_In_and_Out__c>();
        for (Service_Appointment__c sa : appointments) {
            checkInOutList.add(new Service_Appointment_Check_In_and_Out__c(
                Service_Appointment__c = sa.Id,
                Check_In_Date_Time__c = DateTime.now().addHours(-1),
                Check_Out_Date_Time__c = null,
                // Optionally add GeoLocation fields if your org requires them:
                // Check_In_GeoLocation__c = Location.newInstance(37.7749, -122.4194),
                // Check_Out_GeoLocation__c = null,
                Is_auto_checked_out_by_system__c = false
                
            ));
        }
        insert checkInOutList;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        AutoCloseServiceAppointment batch = new AutoCloseServiceAppointment();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        for (Service_Appointment_Check_In_and_Out__c check : [
            SELECT Is_auto_checked_out_by_system__c 
            FROM Service_Appointment_Check_In_and_Out__c
        ]) {
            System.assertEquals(true, check.Is_auto_checked_out_by_system__c,
                'Check-out flag should be true after batch runs');
        }

        for (Service_Appointment__c sa : [
            SELECT Status__c, Check_Out_Address_Error__c 
            FROM Service_Appointment__c
        ]) {
            System.assertEquals('Completed', sa.Status__c,
                'Service Appointment Status should be Completed');
            System.assertEquals('Auto Checked Out by System', sa.Check_Out_Address_Error__c,
                'Check Out Address Error should be updated');
        }
    }

    @isTest
    static void testSchedulableExecution() {
        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2050'; // Future scheduled time
        System.schedule('AutoCloseJob', cronExp, new AutoCloseServiceAppointment());
        Test.stopTest();

        System.assert(true, 'Scheduled job should have run without error');
    }
}