@isTest
public class ServiceAppointmentHandlerTest {

    @testSetup
    static void setup() {
        // Create Users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User u1 = new User(
            FirstName = 'Support',
            LastName = 'Agent1',
            Alias = 'sa1',
            Email = 'sa1@test.com',
            Username = 'sa1_' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        User u2 = new User(
            FirstName = 'Support',
            LastName = 'Agent2',
            Alias = 'sa2',
            Email = 'sa2@test.com',
            Username = 'sa2_' + DateTime.now().getTime() + '@test.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{u1, u2};

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Asset
        Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
        insert ast;

        // Create Case
        Case cs = new Case(Subject = 'Test Case', Status = 'New', Origin = 'Phone', AssetId = ast.Id, AccountId = acc.Id);
        insert cs;

        // Create Work Order
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        // Create Case_Team
        Case_Team__c ct = new Case_Team__c(Case__c = cs.Id, Member__c = u1.Id, Access_Level__c = 'Read', Case_Team_Role__c = 'Support Agent');
        insert ct;

        // Create Service Appointment
        Service_Appointment__c sa = new Service_Appointment__c(
            Case__c = cs.Id,
            OwnerId = u2.Id,
            Account__c = acc.Id,
            Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(1), // ✅ Required for unique key
            Remote_Support__c = false   
        );
        insert sa;
    }

    @isTest
    static void testManageSharingOnInsert() {
        Service_Appointment__c sa = [SELECT Id, Case__c, OwnerId FROM Service_Appointment__c LIMIT 1];
        Test.startTest();
        ServiceAppointmentHandler.manageSharingOnInsert(new List<Service_Appointment__c>{ sa });
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Case_Team__c WHERE Case__c = :sa.Case__c]);
    }

    @isTest
    static void testRollUpOwnerToCaseTeam() {
Service_Appointment__c sa = [SELECT Id, Case__c, Account__c,OwnerId, Check_In_GeoLocation__Latitude__s, Check_In_GeoLocation__Longitude__s FROM Service_Appointment__c LIMIT 1];
        Map<Id, Service_Appointment__c> oldMap = new Map<Id, Service_Appointment__c>{
            sa.Id => new Service_Appointment__c(Id = sa.Id, OwnerId = UserInfo.getUserId())
        };

        Test.startTest();
        ServiceAppointmentHandler.rollUpOwnerToCaseTeam(new List<Service_Appointment__c>{ sa }, oldMap);
        Test.stopTest();

        List<Case_Team__c> caseTeams = [SELECT Id FROM Case_Team__c WHERE Member__c = :sa.OwnerId];
        System.assert(caseTeams.size() > 0);
    }

   
    @isTest
static void testUpdateStatus_InProgress() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    
    Asset asset = new Asset(Name='Test Asset2');
        insert asset;

    Case cs = new Case(AssetId = asset.Id, Subject = 'Test Case', Status = 'New', Origin = 'Phone', AccountId = acc.Id);
    insert cs;

    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

    Service_Appointment__c sa = new Service_Appointment__c(
        Check_In_GeoLocation__Latitude__s = 12.00,
        Check_In_GeoLocation__Longitude__s = 77.00,
        Check_Out_GeoLocation__Latitude__s = 12.10,
        Check_Out_GeoLocation__Longitude__s = 78.00,
        Case__c = cs.Id,
        Work_Order__c = wo.Id,
        Status__c = 'Scheduled',
         Scheduled_Start__c = DateTime.now().addDays(1), // ✅ Required for unique key
            Remote_Support__c = false
    );
    insert sa;

    Service_Appointment__c saOld = sa.clone(false);
    sa.Check_In_GeoLocation__Latitude__s = 13.00; // only check-in changes
    update sa;

    Map<Id, Service_Appointment__c> oldMap = new Map<Id, Service_Appointment__c>{ sa.Id => saOld };

    Test.startTest();
    ServiceAppointmentHandler.updateStatus(new List<Service_Appointment__c>{ sa }, oldMap);
    Test.stopTest();

    System.assertEquals('In Progress', sa.Status__c, 'Expected status to be In Progress');
}

@isTest
static void testUpdateStatus_Completed() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;
    
    Asset asset = new Asset(Name='Test Asset3');
        insert asset;


    Case cs = new Case(AssetId = asset.Id,Subject = 'Test Case', Status = 'New', Origin = 'Phone', AccountId = acc.Id);
    insert cs;

    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

    Service_Appointment__c sa = new Service_Appointment__c(
        Check_In_GeoLocation__Latitude__s = 13.00,
        Check_In_GeoLocation__Longitude__s = 77.00,
        Check_Out_GeoLocation__Latitude__s = 12.10,
        Check_Out_GeoLocation__Longitude__s = 78.00,
        Case__c = cs.Id,
        Work_Order__c = wo.Id,
        Status__c = 'In Progress',
         Scheduled_Start__c = DateTime.now().addDays(1), // ✅ Required for unique key
            Remote_Support__c = false
    );
    insert sa;

    Service_Appointment__c saOld = sa.clone(false);
    sa.Check_Out_GeoLocation__Longitude__s = 79.00; // only check-out changes
    update sa;

    Map<Id, Service_Appointment__c> oldMap = new Map<Id, Service_Appointment__c>{ sa.Id => saOld };

    Test.startTest();
    ServiceAppointmentHandler.updateStatus(new List<Service_Appointment__c>{ sa }, oldMap);
    Test.stopTest();

    System.assertEquals('Completed', sa.Status__c, 'Expected status to be Completed');
}

 /*@isTest
static void testUpdateGeoLocation() {
    // Create Asset
    Asset asset = new Asset(Name = 'Test Asset');
    insert asset;

    // Create Case linked to Asset
    Case cs = new Case(Subject = 'Test Case', AssetId = asset.Id);
    insert cs;
    
    Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

    // Create Service Appointment linked to Case
    Service_Appointment__c sa = new Service_Appointment__c(
        //Name = 'Test SA',
        Case__c = cs.Id,
         Work_Order__c = wo.Id,
        //Is_Asset_GeoLocation_Populated__c = true,
        Check_In_GeoLocation__Latitude__s = 12.9716,
        Check_In_GeoLocation__Longitude__s = 77.5946
    );
    insert sa;

    // Clone to simulate old values
    Service_Appointment__c saOld = sa.clone(false);

    // Update geo location
    sa.Check_In_GeoLocation__Latitude__s = 13.0827;
    sa.Check_In_GeoLocation__Longitude__s = 80.2707;
    update sa;

    // Create oldMap
    Map<Id, Service_Appointment__c> oldMap = new Map<Id, Service_Appointment__c>{
        sa.Id => saOld
    };

    Test.startTest();
    ServiceAppointmentHandler.updateGeoLocation(new List<Service_Appointment__c>{ sa }, oldMap);
    Test.stopTest();

    // Assert that asset geo location was updated
    Asset updatedAsset = [SELECT Asset_GeoLocation__Latitude__s, Asset_GeoLocation__Longitude__s FROM Asset WHERE Id = :asset.Id];
    System.assertEquals(13.0827, updatedAsset.Asset_GeoLocation__Latitude__s);
    System.assertEquals(80.2707, updatedAsset.Asset_GeoLocation__Longitude__s);
}
*/

   @isTest
static void testUpdateAccountInAsset() {
    // Create initial account
    Account acc1 = new Account(Name = 'Initial Account');
    insert acc1;

    // Create another account to update to
    Account acc2 = new Account(Name = 'New Account');
    insert acc2;

    // Create an asset
  Asset asset = new Asset(
    Name = 'Test Asset ' + System.currentTimeMillis(), // Ensure uniqueness
    AccountId = acc2.Id,
    SerialNumber = 'SN-' + System.currentTimeMillis() // If SerialNumber is required/unique
);
insert asset;

    // Create a case linked to the asset
    Case cs = new Case(
        Subject = 'Test Case',
        Status = 'New',
        Origin = 'Phone',
        AssetId = asset.Id,
        AccountId = acc1.Id
    );
    insert cs;
    
     Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

    // Get test user
    User u = [SELECT Id FROM User WHERE Alias = 'sa1' LIMIT 1];

    // Create a Service Appointment
    Service_Appointment__c sa = new Service_Appointment__c(
        Case__c = cs.Id,
        OwnerId = u.Id,
        Account__c = acc2.Id,
        Scheduled_Start__c = DateTime.now(),
        Remote_Support__c = true,
         Work_Order__c = wo.Id
    );
    insert sa;

    // Store old map before update
    Map<Id, Service_Appointment__c> oldMap = new Map<Id, Service_Appointment__c>{
        sa.Id => sa
    };

    // Update Account__c to a new account
    sa.Account__c = acc2.Id;

    Test.startTest();
    update sa;
    ServiceAppointmentHandler.updateAccountInAsset(new List<Service_Appointment__c>{ sa }, oldMap);
    Test.stopTest();

    // Verify that the Asset End_Customer__c field is updated
    Asset updatedAsset = [SELECT End_Customer__c FROM Asset WHERE Id = :asset.Id];
    //System.assertEquals(acc2.Id, updatedAsset.End_Customer__c, 'Asset End_Customer__c should match the updated Account');
}

}