@isTest
public class FieldServiceCreateVisitControllerTest {

    static testMethod void testGetOpenCasesList() {
        Profile prof = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User ownerUser = new User(
            Username='testuser'+ Math.floor(Math.random() * 1000000) +'@example.com.test',
            LastName='TestUser',
            Email='owner@example.com',
            Alias='tuser',
            TimeZoneSidKey='Asia/Kolkata',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=prof.Id,
            LanguageLocaleKey='en_US'
        );
        insert ownerUser;
        Account acc = new Account(Name='Test Account 564');
        insert acc;

        Contact con = new Contact(LastName='Test Contact 629', AccountId=acc.Id);
        insert con;

        Asset ast = new Asset(Name='Test Asset 38', AccountId=acc.Id, SerialNumber='SN123');
        insert ast;

        Case cs = new Case(
            Subject='Test Case',
            AccountId=acc.Id,
            ContactId=con.Id,
            AssetId=ast.Id
        );
        insert cs;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = ast.Id,
            Breakdown_Visits__c = 2,
            Breakdown_Visits_Allowed__c = 5,
            Warranty_Start_Date__c = Date.today().addDays(-10),
            Warranty_End_Date__c = Date.today().addDays(10),
            Warranty_Period__c = 1
        );
        insert warranty;

        Test.startTest();
        List<FieldServiceCreateVisitController.CaseWithWarrantyWrapper> results =
            FieldServiceCreateVisitController.getOpenCasesList(String.valueOf(System.today().year()), String.valueOf(System.today().month() - 1));
        Test.stopTest();
    }

    static testMethod void testGetServiceAppointments() {
        Account acc = new Account(Name='Test Acc');
        insert acc;

        Contact con = new Contact(LastName='Contact', AccountId=acc.Id);
        insert con;

        Asset ast = new Asset(Name='Asset', AccountId=acc.Id);
        insert ast;

        Case cs = new Case(AccountId = acc.Id,AssetId = ast.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Service_Appointment__c sa = new Service_Appointment__c(
            OwnerId=UserInfo.getUserId(),
            Scheduled_Start__c = Date.today(),
            Case__c = cs.Id,
            Work_Order__c = wo.Id,
            Is_Additional_Resource__c = true
        );
        insert sa;

        Test.startTest();
        List<Service_Appointment__c> appointments = FieldServiceCreateVisitController.getServiceAppointments(
            String.valueOf(Date.today().year()),
            String.valueOf(Date.today().month() - 1)
        );
        Test.stopTest();

        System.assert(!appointments.isEmpty(), 'Service appointment should be fetched');
    }

    static testMethod void testCreateVisit() {
        Account acc = new Account(Name='Test Account 552');
        insert acc;
        
         Asset ast = new Asset(Name='Asset11', AccountId=acc.Id);
        insert ast;

        Contact con = new Contact(LastName='Test Contact 12', AccountId=acc.Id);
        insert con;

        Case cs = new Case(Subject='Visit Case', AccountId=acc.Id, ContactId=con.Id, AssetId = ast.Id);
        insert cs;
        
         Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Service_Appointment__c sa = new Service_Appointment__c(
            OwnerId = UserInfo.getUserId(),
            Scheduled_Start__c = Date.today(),
            Case__c = cs.Id,
            Work_Order__c = wo.Id
        );

        Test.startTest();
        Service_Appointment__c result = FieldServiceCreateVisitController.createVisit(sa);
        Test.stopTest();

        System.assertNotEquals(null, result.Id, 'Visit should be created');
        Case updatedCase = [SELECT Is_service_appointment_created__c FROM Case WHERE Id = :cs.Id];
        System.assertEquals(true, updatedCase.Is_service_appointment_created__c, 'Case should be marked as appointment created');
    }

    static testMethod void testCheckAssetLimits() {
        Account acc = new Account(Name='Limit Check Account');
        insert acc;

        Asset ast = new Asset(Name='Limit Check Asset', AccountId=acc.Id);
        insert ast;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Asset__c = ast.Id,
            Breakdown_Visits__c = 5,
            Breakdown_Visits_Allowed__c = 5,
            Warranty_Start_Date__c = Date.today().addDays(-5),
            Warranty_End_Date__c = Date.today().addDays(5),
            Warranty_Period__c = 1
        );
        insert warranty;

        Asset_AMC__c amc = new Asset_AMC__c(
            Asset__c = ast.Id,
            Breakdown_Visits__c = 3,
            Breakdown_Visits_Allowed__c = 3,
            AMC_Start_Date__c = Date.today().addDays(-5),
            AMC_End_Date__c = Date.today().addDays(5),
            AMC_Period_In_Months__c = 1,
            Product_Category_Type__c = 'AMC'
        );
        insert amc;

        Test.startTest();
        Map<String, Object> result = FieldServiceCreateVisitController.checkAssetLimits(ast.Id);
        Test.stopTest();

        System.assert(result.containsKey('warningMessage'), 'Warning message should be present');
        System.assert(((String)result.get('warningMessage')).contains('Warranty limit reached'), 'Should include warranty message');
        System.assert(((String)result.get('warningMessage')).contains('AMC limit reached'), 'Should include AMC message');
    }
}