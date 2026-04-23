@isTest
public class CaseTriggerHandlerWithoutSharingTest {
    
    @IsTest
    static void testSaveCaseWithNewOwner() {
        Id profileId = UserInfo.getProfileId();
        
        // Create Manager user
        User managerUser = new User(
            Alias = 'mgrusr',
            Email = 'manager_' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'manager_' + System.currentTimeMillis() + '@test.com'
        );
        insert managerUser;
        
        // Create current owner user with Manager
        User currentOwner = new User(
            Alias = 'ownusr',
            Email = 'owner_' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'owner_' + System.currentTimeMillis() + '@test.com',
            ManagerId = managerUser.Id
        );
        insert currentOwner;
        
        // Create new owner user
        User newOwner = new User(
            Alias = 'newusr',
            Email = 'newowner_' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NewOwner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'newowner_' + System.currentTimeMillis() + '@test.com'
        );
        insert newOwner;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test Contact', Email = 'test@example.com', AccountId = acc.Id);
        insert con;
        
        Product2 prod = new Product2(Name = 'Test Product');
        insert prod;
        
        Asset ast = new Asset(Name = 'AST123', Product2Id = prod.Id);
        insert ast;
        
        // Create a Case owned by currentOwner
        Case cs = new Case(
            Subject = 'Case to be reassigned',
            Status = 'New',
            Origin = 'Phone',
            OwnerId = currentOwner.Id,
            AssetId = ast.Id,
            AccountId = acc.Id
        );
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cs.Id,Work_Order__c = wo.Id,Scheduled_Start__c = DateTime.now().addDays(1),
                                                               Remote_Support__c = false);
        insert sa;
        
        // Map Case Id to new Owner Id
        Map<Id, Id> caseIdToOwnerMap = new Map<Id, Id>{ cs.Id => newOwner.Id };
            
            // Run test logic as currentOwner
            Test.startTest();
        System.runAs(currentOwner) {
            FieldServiceOpenQueue2.saveCaseWithNewOwner(caseIdToOwnerMap);
        }
        Test.stopTest();
        
        // Assert case has been reassigned
        Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :cs.Id];
        System.assertEquals(newOwner.Id, updatedCase.OwnerId, 'Case should be reassigned to new owner');
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
            Scheduled_Start__c = DateTime.now().addDays(1),
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
            Status__c = 'Completed',
            Scheduled_Start__c = DateTime.now().addDays(1),
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
    
    @isTest
    static void testCheckoutAppointmentsWhenCaseIsTransferred() {
        Id profileId = UserInfo.getProfileId();
        
        User user1 = new User(
            Alias = 'user1',
            Email = 'user1' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'user1' + System.currentTimeMillis() + '@test.com'
        );
        insert user1;
        
        User user2 = new User(
            Alias = 'user2',
            Email = 'user2' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'user2' + System.currentTimeMillis() + '@test.com'
        );
        insert user2;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset ast = new Asset(Name = 'Test Asset', AccountId = acc.Id);
        insert ast;
        
        Case cs = new Case(
            Subject = 'Case for Checkout Test',
            Status = 'New',
            Origin = 'Phone',
            OwnerId = user1.Id,
            AccountId = acc.Id,
            AssetId = ast.Id
        );
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        Service_Appointment__c sa = new Service_Appointment__c(
            Case__c = cs.Id,
            Work_Order__c = wo.Id,
            Status__c = 'Scheduled',
            Account__c = acc.Id,
            Scheduled_Start__c = DateTime.now(),
            Remote_Support__c = false
        );
        insert sa;
        
        Service_Appointment_Check_In_and_Out__c saCheck = new Service_Appointment_Check_In_and_Out__c(
            Service_Appointment__c = sa.Id
            //IsCheckedOut__c = false
        );
        insert saCheck;
        
        // Change Case owner to trigger checkout
        cs.OwnerId = user2.Id;
        update cs;
        
        // Prepare map for old cases
        Map<Id, Case> oldMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id = :cs.Id]);
        
        Test.startTest();
        CaseTriggerHandlerWithoutSharing.checkoutAppointmentsWhenCaseIsTransferred(new List<Case>{cs}, oldMap);
        Test.stopTest();
        
        // Assert the SA Check-In/Out was updated
        saCheck = [SELECT Id, Is_auto_checked_out_by_system_on_Transf__c FROM Service_Appointment_Check_In_and_Out__c WHERE Id = :saCheck.Id];
        System.assertEquals(true, saCheck.Is_auto_checked_out_by_system_on_Transf__c, 'SA should be auto checked out');
    }
    
    @isTest
    static void testGetAssetDetailsByCaseIds() {
        Account acc = new Account(Name = 'Account for Asset Test');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product');
        insert prod;
        
        Asset ast = new Asset(Name = 'Test Asset', Product2Id = prod.Id);
        insert ast;
        
        Case cs = new Case(
            Subject = 'Case for Asset Test',
            Status = 'New',
            Origin = 'Phone',
            AccountId = acc.Id,
            AssetId = ast.Id
        );
        insert cs;
        
        Test.startTest();
        //Map<Id, Asset> result = CaseTriggerHandlerWithoutSharing.getAssetDetailsByCaseIds(new List<Case>{cs});
        Test.stopTest();
        
        //System.assert(result.containsKey(cs.Id), 'Result should contain the Case Id');
        //System.assertEquals(ast.Id, result.get(cs.Id).Id, 'Returned asset should match the inserted asset');
    }
    
    
}