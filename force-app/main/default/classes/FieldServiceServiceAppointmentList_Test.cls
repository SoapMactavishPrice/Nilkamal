@isTest
private class FieldServiceServiceAppointmentList_Test {

    @testSetup
    static void setupTestData() {
        List<Pin_Code_Master__c> pinList = new List<Pin_Code_Master__c>{
            new Pin_Code_Master__c(Name = '421306'),
            new Pin_Code_Master__c(Name = '421305')
        };
        insert pinList;

        Service_Resource__c sr = new Service_Resource__c(User__c = UserInfo.getUserId());
        insert sr;

        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c(
            Service_Resource__c = sr.Id,
            Pin_Code_Master__c = pinList[0].Id
        );
        insert srp;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test@example.com',
            MobilePhone = '9999999999'
        );
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

        Case c = new Case(
            Status = 'New',
            AccountId = acc.Id,
            ContactId = con.Id,
            AssetId = asset.Id
        );
        insert c;

        Date today = Date.today();
        
        Work_Order__c workOrder = new Work_Order__c(
           // Name = 'Test Work Order',
            //Account__c = acc.Id,
            //Contact__c = con.Id,
           // Asset__c = asset.Id,
            Case__c = c.Id
        );
        insert workOrder;

        insert new List<Service_Appointment__c>{
            new Service_Appointment__c(
               // Name = 'SA Today',
                OwnerId = UserInfo.getUserId(),
                Case__c = c.Id,
                Work_Order__c = workOrder.Id,
                Scheduled_Start__c = today
            ),
            new Service_Appointment__c(
            //    Name = 'SA This Month',
                OwnerId = UserInfo.getUserId(),
                Case__c = c.Id,
                Work_Order__c = workOrder.Id,
                Scheduled_Start__c = Date.newInstance(today.year(), today.month(), 5)
            )
        };
    }

    @isTest
    static void testGetServiceAppointmentListWithDay() {
        Date today = Date.today();

        Map<String, Object> params = new Map<String, Object>{
            'year' => String.valueOf(today.year()),
            'month' => String.valueOf(today.month()),
            'day' => String.valueOf(today.day())
        };

        Test.startTest();
        Object result = FieldServiceServiceAppointmentListCont.getServiceAppointmentList(params);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null when filtering by specific day');
        List<Service_Appointment__c> saList = (List<Service_Appointment__c>) result;
        System.assertEquals(1, saList.size(), 'Should return 1 service appointment for the exact date');
    }

    @isTest
    static void testGetServiceAppointmentListWithMonth() {
        Date today = Date.today();

        Map<String, Object> params = new Map<String, Object>{
            'year' => String.valueOf(today.year()),
            'month' => String.valueOf(today.month())
        };

        Test.startTest();
        Object result = FieldServiceServiceAppointmentListCont.getServiceAppointmentList(params);
        Test.stopTest();

        List<Service_Appointment__c> saList = (List<Service_Appointment__c>) result;
    }

    @isTest
    static void testGetServiceAppointmentListWithInvalidParams() {
        Map<String, Object> params = new Map<String, Object>();

        Test.startTest();
        Object result = FieldServiceServiceAppointmentListCont.getServiceAppointmentList(params);
        Test.stopTest();

    }
}