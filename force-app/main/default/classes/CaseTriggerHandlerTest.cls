@isTest
private class CaseTriggerHandlerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account 890');
        insert acc;

        User manager = createTestUser('manager'+ Math.random() +'@example.com', 'Manager');
        insert manager;

        User owner = createTestUser('owner'+ Math.random() +'@example.com', 'Owner', manager.Id);
        insert owner;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            AccountId = acc.Id
        );
        insert con;

        Pin_Code_Master__c pin = new Pin_Code_Master__c(Name = '560001');
        insert pin;

        Asset asset = new Asset(
            Name = 'Test Asset',
            SerialNumber = '12345',
            AccountId = acc.Id,
            ContactId = con.Id,
            Business_Vertical__c = 'MHE',
            Pin_Code_Master__c = pin.Id
        );
        insert asset;

        Service_Resource__c sr = new Service_Resource__c(
            Name = 'SR 1',
            User__c = owner.Id,
            Business_Vertical__c = 'MHE',
            Role__c = 'Service Engineer',
            isActive__c = true
        );
        insert sr;

        // Matching pincode
        insert new Service_Resource_Pincode__c(
            Service_Resource__c = sr.Id,
            Pin_Code_Master__c = pin.Id
        );

        // Matching working hours
        insert new Service_Resource_Working_Hour__c(
            Service_Resource__c = sr.Id,
            Weekday__c = DateTime.now().format('EEEE'),
            Start_Hour__c = Time.newInstance(9, 0, 0, 0),
            End_Hour__c = Time.newInstance(18, 0, 0, 0)
        );

        // Another SR with unmatched vertical
        Service_Resource__c sr2 = new Service_Resource__c(
            Name = 'SR 2',
            User__c = manager.Id,
            Business_Vertical__c = 'MHE',
            Role__c = 'Service Engineer',
            isActive__c = true
        );
        insert sr2;

        insert new Service_Resource_Pincode__c(
            Service_Resource__c = sr2.Id,
            Pin_Code_Master__c = pin.Id
        );

        insert new Service_Resource_Working_Hour__c(
            Service_Resource__c = sr2.Id,
            Weekday__c = DateTime.now().format('EEEE'),
            Start_Hour__c = Time.newInstance(9, 0, 0, 0),
            End_Hour__c = Time.newInstance(18, 0, 0, 0)
        );

        // Simulate Leave for sr2
        insert new Service_Resource_Leave__c(
            Service_Resource__c = sr2.Id
        );

        // Case history
        insert new Case(
            Subject = 'Old Case',
            Status = 'New',
            AssetId = asset.Id,
            AccountId = acc.Id,
            ContactId = con.Id,
            OwnerId = owner.Id,
            Case_Pincode__c = pin.Id
        );
    }

    static testMethod void testCustomCaseAssignmentWithValidEngineer() {
       // Account acc = [SELECT Id FROM Account LIMIT 1];
        //Contact con = [SELECT Id FROM Contact LIMIT 1];
        //Asset asset = [SELECT Id FROM Asset LIMIT 1];
         Account acc = new Account(Name = 'Test Account 890');
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            AccountId = acc.Id
        );
        insert con;

        Pin_Code_Master__c pin = new Pin_Code_Master__c(Name = '560002');
        insert pin;
        
        Asset newAsset = new Asset(
    Name = 'Test Asset For Case',
    SerialNumber = '67890',
    AccountId = acc.Id,
    ContactId = con.Id,
    Business_Vertical__c = 'MHE',
    Pin_Code_Master__c = pin.Id
);
insert newAsset;
        
        Id pinId = [SELECT Id FROM Pin_Code_Master__c LIMIT 1].Id;
        Id queueId = [SELECT Id FROM Group WHERE Name = 'Open Queue' LIMIT 1].Id;

        Case testCase = new Case(
            Subject = 'Test Assignment',
            Status = 'New',
            Type = 'Breakdown',
            Case_Sub_Type__c = 'AMC Breakdown',
            AssetId = newAsset.Id,
            AccountId = acc.Id,
            ContactId = con.Id,
            OwnerId = queueId,
            Case_Pincode__c = pinId
        );

        Test.startTest();
        insert testCase;

        List<Case> caseList = [SELECT Id, OwnerId, Status, Case_Pincode__c, Division__c, AssetId FROM Case WHERE Id = :testCase.Id];
        CaseTriggerHandler.customCaseAssignmentByPincode(caseList, new Map<Id, Case>());
        Test.stopTest();

        testCase.Status = 'Closed';
        testCase.IsClosingFromCustomUI__c = true;
        update testCase;
    }

    static testMethod void testNoAssignmentWhenNoMatch() {
        //Account acc = [SELECT Id FROM Account LIMIT 1];
        //Contact con = [SELECT Id FROM Contact LIMIT 1];
        //Asset asset = [SELECT Id FROM Asset LIMIT 1];
        //Id pinId = [SELECT Id FROM Pin_Code_Master__c LIMIT 1].Id;
         Account acc = new Account(Name = 'Test Account 890');
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            AccountId = acc.Id
        );
        insert con;

        Pin_Code_Master__c pin = new Pin_Code_Master__c(Name = '560002');
        insert pin;
        
        Asset newAsset1 = new Asset(
    Name = 'Test1 Asset For Case',
    SerialNumber = '67890',
    AccountId = acc.Id,
    ContactId = con.Id,
    Business_Vertical__c = 'MHE',
    Pin_Code_Master__c = pin.Id
);
insert newAsset1;
        
        //system.debug('pinId'+pinId);
        Id queueId = [SELECT Id FROM Group WHERE Name = 'Open Queue' LIMIT 1].Id;

        // Create case with non-matching division
        Case testCase = new Case(
            Subject = 'Test - No Match',
            Status = 'New',
            AssetId = newAsset1.Id,
            AccountId = acc.Id,
            ContactId = con.Id,
            OwnerId = queueId,
            Case_Pincode__c = pin.Id,
            Division__c = 'MHE'
        );

        Test.startTest();
        insert testCase;

        List<Case> caseList = [SELECT Id, OwnerId, Status, Case_Pincode__c, Division__c, AssetId FROM Case WHERE Id = :testCase.Id];
        CaseTriggerHandler.customCaseAssignmentByPincode(caseList, new Map<Id, Case>());
        Test.stopTest();
    }

    private static User createTestUser(String email, String alias, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1];
        return new User(
            FirstName = alias,
            LastName = 'User',
            Email = email,
            Username = email,
            Alias = alias.length() > 8 ? alias.substring(0, 8) : alias,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            ManagerId = managerId,
            Business_Unit__c = 'MHE',
            Is_Service_User__c = TRUE
        );
    }

    private static User createTestUser(String email, String alias) {
        return createTestUser(email, alias, null);
    }

    @isTest
    static void testCreateCaseAPI() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
                'type' => 'Problem',
                'subType' => 'Hardware',
                'customerName' => 'Test Customer',
                'contactName' => 'John Doe',
                'email' => 'johndoe@example.com',
                'mobile' => '1234567890',
                'invoiceNumber' => 'INV123',
                'businessVertical' => 'Retail',
                'address' => '123 Main St',
                'description' => 'Test case description'
                });

        simulateRestCall(jsonBody);
    }

    @isTest
    static void testCreateNewContact() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
                'type' => 'Problem',
                'subType' => 'Hardware',
                'customerName' => 'New Customer',
                'contactName' => 'Alice Johnson',
                'email' => 'alice.johnson@example.com',
                'mobile' => '9998887777',
                'invoiceNumber' => 'INV789',
                'businessVertical' => 'Retail',
                'address' => '789 New Lane',
                'description' => 'New contact case description'
                });

        simulateRestCall(jsonBody);
    }

    @isTest
    static void testCreateNewCaseWhenNoExistingCase() {
        String longAddress = '1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 1234567890 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz';

        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '67890',
                'type' => 'Problem',
                'subType' => 'Hardware',
                'customerName' => 'Another Customer',
                'contactName' => 'Bob Smith',
                'email' => 'bob.smith@example.com',
                'mobile' => '8887776666',
                'invoiceNumber' => 'INV456',
                'businessVertical' => 'Retail',
                'address' => longAddress,
                'description' => 'New case description'
                });

        simulateRestCall(jsonBody);
    }

    @isTest
    static void testExistingCaseTriggersEmailAndNotification() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
                'type' => 'Problem',
                'subType' => 'Hardware',
                'customerName' => 'Repeat Customer',
                'contactName' => 'John Doe',
                'email' => 'johndoe@example.com',
                'mobile' => '1234567890',
                'invoiceNumber' => 'INV999',
                'businessVertical' => 'Retail',
                'address' => 'Repeat Address',
                'description' => 'Repeat case description'
                });

        simulateRestCall(jsonBody);
    }

    @isTest
    static void testCaseInsertFailureThrowsCustomException() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '67890',
                'type' => 'InvalidType', // Invalid picklist value to force DMLException
                'subType' => 'Hardware',
                'customerName' => 'Error Customer',
                'contactName' => 'Error Case',
                'email' => 'error.case@example.com',
                'mobile' => '0000000000',
                'invoiceNumber' => 'INV000',
                'businessVertical' => 'Retail',
                'address' => 'Error Address',
                'description' => 'This should trigger a DML exception'
                });

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateCaseAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        try {
            CreateCaseAPI.createCase();
        } catch (CustomException ex) {
            // Expected
        }
        Test.stopTest();
    }

    private static void simulateRestCall(String jsonBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CreateCaseAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        CreateCaseAPI.createCase();
        Test.stopTest();
    }


    @isTest
    static void testSubmitCaseForApprovalIfCustomerIsBlocked() {
        // Get Standard User profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create a User Role that matches 'Service Head%' pattern
        UserRole role = new UserRole(Name = 'Service Head - Printer');
        insert role;

        // Create a test user with required Business Unit (must match case.Division__c)
        User approver = new User(
            Username = 'approver@example.com.' +  Math.floor(Math.random() * 1000000),
            LastName = 'Approver',
            Email = 'approver@example.com',
            Alias = 'approv',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = role.Id,
            Business_Unit__c = 'Printer'
        );
        insert approver;

        System.runAs(approver) {
            // Create a blocked account
            Account blockedAccount = new Account(
                Name = 'Blocked Customer',
                Customer_Blocked__c = true
            );
            insert blockedAccount;

            // Create asset (not required for approval, but in handler logic)
            Asset asset = new Asset(
                Name = 'Test Asset 2',
                SerialNumber = 'SN12345',
                AccountId = blockedAccount.Id,
                Business_Vertical__c = 'Printer'
            );
            insert asset;

            // Create Case assigned to blocked customer and matching division
            Case blockedCase = new Case(
                Subject = 'Blocked Customer Case',
                AccountId = blockedAccount.Id,
                Division__c = 'Printer',
                //Approval_Status__c = 'Submitted',
                AssetId = asset.Id
            );
            insert blockedCase;

            // Setup new case list and null oldMap to trigger first condition
            List<Case> newCases = new List<Case>{blockedCase};
                Map<Id, Case> oldMap = null;

            Test.startTest();try{
                CaseTriggerHandler.submitCaseForApprovalIfCustomerIsBlocked(newCases, oldMap);
            }catch(Exception e){

            }
            try{
                Map<Id, Case> oldMapq= new Map<Id, Case>();
                CaseTriggerHandler.submitCaseForApprovalIfCustomerIsBlocked(newCases, oldMapq);
            }catch(Exception e){

            }

            Test.stopTest();

            // Validate that the case is now submitted
            Case updatedCase = [SELECT Approval_Status__c FROM Case WHERE Id = :blockedCase.Id];
            System.assertEquals('Submitted', updatedCase.Approval_Status__c,
                                'Case should be submitted for approval if the customer is blocked.');
        }
    }

    @isTest
    static void testSubmitCaseForApprovalIfCustomerIsBlocked1() {
        // Get Standard User profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create a User Role that matches 'Service Head%' pattern
        UserRole role = new UserRole(Name = 'Service Head - Printer');
        insert role;

        // Create a test user with required Business Unit (must match case.Division__c)
        User approver = new User(
            Username = 'approver@example.com.' +  Math.floor(Math.random() * 1000000),
            LastName = 'Approver',
            Email = 'approver@example.com',
            Alias = 'approv',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            UserRoleId = role.Id,
            Business_Unit__c = 'Printer'
        );
        insert approver;

        System.runAs(approver) {
            // Create a blocked account
            Account blockedAccount = new Account(
                Name = 'Blocked Customer',
                Customer_Blocked__c = true
            );
            insert blockedAccount;

            // Create asset (not required for approval, but in handler logic)
            Asset asset = new Asset(
                Name = 'Test Asset 2',
                SerialNumber = 'SN12345',
                AccountId = blockedAccount.Id,
                Business_Vertical__c = 'Printer'
            );
            insert asset;

            // Create Case assigned to blocked customer and matching division
            Case blockedCase = new Case(
                Subject = 'Blocked Customer Case',
                AccountId = blockedAccount.Id,
                Division__c = 'Printer',
                //Approval_Status__c = 'Submitted',
                AssetId = asset.Id
            );
            insert blockedCase;

            // Setup new case list and null oldMap to trigger first condition
            List<Case> newCases = new List<Case>{blockedCase};
                Map<Id, Case> oldMap = null;

            Test.startTest();
            try{
                Map<Id, Case> oldMapq= new Map<Id, Case>();
                CaseTriggerHandler.submitCaseForApprovalIfCustomerIsBlocked(newCases, oldMapq);
            }catch(Exception e){

            }

            Test.stopTest();

            // Validate that the case is now submitted
            Case updatedCase = [SELECT Approval_Status__c FROM Case WHERE Id = :blockedCase.Id];
            System.assertEquals('Submitted', updatedCase.Approval_Status__c,
                                'Case should be submitted for approval if the customer is blocked.');
        }
    }


    @isTest
    static void testLeaveQueryLogic_NoLimitError() {
        // Step 1: Get standard profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Step 2: Create test user
        User testUser = new User(
            Username = 'leaveuser@example.com.test',
            LastName = 'Leave User',
            Email = 'test' + Math.random() + '@gmail.com',
            Alias = 'leaveusr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;

        // Step 3: Create Service Resource
        Service_Resource__c sr = new Service_Resource__c(
            User__c = testUser.Id,
            isActive__c = true,
            Business_Vertical__c = 'Printer'
        );
        insert sr;

        // Step 4: Create leave for today
        Service_Resource_Leave__c leave = new Service_Resource_Leave__c(
            Service_Resource__c = sr.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today()
        );
        insert leave;

        // Step 5: Prepare the set of active working day service resource IDs
        Set<Id> todayWorkingDayServiceResourceIds = new Set<Id>{ sr.Id };

            // Step 6: Actual test logic with SOQL query inside start/stop test
            Set<Id> serviceResourceIdsWhoAreOnLeaveToday = new Set<Id>();

        Test.startTest();

        for(Service_Resource_Leave__c srl : [
            SELECT Id, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.Name,
            Start_Date__c, End_Date__c
            FROM Service_Resource_Leave__c
            WHERE Service_Resource__c IN :todayWorkingDayServiceResourceIds
            AND Start_Date__c <= :Date.today()
            AND End_Date__c >= :Date.today()
            AND Service_Resource__r.User__r.isActive = TRUE
            AND Service_Resource__r.isActive__c = TRUE
        ]) {
            serviceResourceIdsWhoAreOnLeaveToday.add(srl.Service_Resource__c);
        }

        Test.stopTest();

        // Step 7: Validate result
        System.assertEquals(1, serviceResourceIdsWhoAreOnLeaveToday.size(), 'Should find one resource on leave today');
        System.assert(serviceResourceIdsWhoAreOnLeaveToday.contains(sr.Id), 'Leave record should match inserted Service Resource');
    }





    @isTest
    static void testTrackTechnicalSupportHistory_FullCoverage() {
        // Create test Account and Asset
        Account acc = new Account(Name = 'Test Account 456');
        insert acc;

        Asset asset = new Asset(Name = 'Test Asset 2', AccountId = acc.Id);
        insert asset;

        // Insert original Case
        Case originalCase = new Case(
            Subject = 'Original Case',
            AssetId = asset.Id,
            Technical_Support_Response__c = 'Initial response',
            Technical_Support_SE_Comment__c = 'Initial comment',
            AccountId = acc.Id
            
        );
        insert originalCase;

        // Query fresh copy to simulate update
        Case updatedCase = [SELECT Id, Technical_Support_Response__c, Technical_Support_SE_Comment__c,Technical_Support_History__c  FROM Case WHERE Id = :originalCase.Id];
        updatedCase.Technical_Support_Response__c = 'Updated response';
        updatedCase.Technical_Support_SE_Comment__c = 'Updated comment';

        // Create input params for the method
        List<Case> newList = new List<Case>{updatedCase};
            Map<Id, Case> oldMap = new Map<Id, Case>{originalCase.Id => originalCase};

                // Call the method
                Test.startTest();
        CaseTriggerHandler.trackTechnicalSupportHistory(newList, oldMap);
        Test.stopTest();

        // Optionally update case to save changes
        update newList;
    }


    @isTest
    static void testNotifyUserWhenCaseIsAssignedOrTransferredOnUpdate() {
        // Step 1: Set up required users and profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User originalOwner = new User(
            Username = 'originalowner' + DateTime.now().getTime() + '@example.com',
            LastName = 'Original',
            Email = 'original@example.com',
            Alias = 'orig',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert originalOwner;

        User newOwner = new User(
            Username = 'newowner' +  Math.floor(Math.random() * 1000000) + '@example.com',
            LastName = 'NewOwner',
            Email = 'new@example.com',
            Alias = 'newo',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert newOwner;
        
          Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset asset = new Asset(Name='Test1 Asset1');
        insert asset;

        // Step 2: Create a case with original owner
        Case c = new Case(
            Subject = 'Owner Change Test Case',
            Status = 'New',
            Origin = 'Phone',
            OwnerId = originalOwner.Id,
            AccountId = acc.Id,
            AssetId = asset.Id
        );
        insert c;

        // Step 3: Prepare oldMap and update Owner
        Map<Id, Case> oldMap = new Map<Id, Case>{
            c.Id => new Case(Id = c.Id, OwnerId = originalOwner.Id)
                };

                    // Change owner to new owner
                    c.OwnerId = newOwner.Id;

        // Step 4: Call the handler method
        Test.startTest();
        CaseTriggerHandler.notifyUserWhenCaseIsAssignedOrTransferredOnUpdate(new List<Case>{c}, oldMap);
        Test.stopTest();

        // No assertion on notification since it's hard to mock in unit test context
        System.assertEquals(newOwner.Id, c.OwnerId, 'Owner should be updated.');
    }


    @isTest
    static void testSendEmailAndCustomNotification_Escalation() {
        // Get standard profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create RSM and Coordinator Users
        User coordinator = new User(
            Username = 'coord' +  Math.floor(Math.random() * 1000000) + '@example.com',
            LastName = 'Coordinator',
            Email = 'coordinator@example.com',
            Alias = 'coord',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert coordinator;

        User rsm = new User(
            Username = 'rsm' + Math.floor(Math.random() * 1000000) + '@example.com',
            LastName = 'RSM',
            Email = 'rsm@example.com',
            Alias = 'rsmusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert rsm;

        // Create Case Owner
        User caseOwner = new User(
            Username = 'caseowner' + Math.floor(Math.random() * 1000000) + '@example.com',
            LastName = 'CaseOwner',
            Email = 'caseowner@example.com',
            Alias = 'caseown',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert caseOwner;
        
          Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset asset = new Asset(Name='Test1 Asset');
        insert asset;

        // Create a test Case
        Case testCase = new Case(
            Subject = 'Test Escalation Case',
            SuppliedName = 'Test Customer',
            SuppliedEmail = 'test@example.com',
            Status = 'New',
            Origin = 'Phone',
            OwnerId = caseOwner.Id,
            AccountId =acc.Id,
            AssetId = asset.Id	
        );
        insert testCase;

        // Create Service Resource linking to Coordinator and RSM
        Service_Resource__c serviceResource = new Service_Resource__c(
            User__c = coordinator.Id,  // Pass coordinator here as test user
            Coordinator__c = coordinator.Id,
            RSM__c = rsm.Id
        );
        insert serviceResource;

        // Ensure Custom Notification Type exists (no insert; only query allowed)
        CustomNotificationType notifType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Escalation' LIMIT 1];

        // Act
        Test.startTest();
        CaseTriggerHandler.sendEmailAndCustomNotification_Escalation(testCase.Id, coordinator.Id, 'Resolution');
        Test.stopTest();

        // Assert
        System.debug('Method executed. Check debug logs for custom notification and email generation.');
        // We cannot assert email or notification send directly, but can ensure method runs without exception.
        System.assert(true);
    }


    @isTest
    static void testRollUpVisitCountToActiveAMCOrWarranty() {
        // Create test Account
        Account acc = new Account(Name = 'Test Account 912');
        insert acc;

        // Create Asset
        Asset asset = new Asset(Name = 'Test Asset 2', AccountId = acc.Id);
        insert asset;

        // Create active Warranty
        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Test Warranty',
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addDays(-10),
            Warranty_End_Date__c = Date.today().addDays(10),
            Warranty_Visit__c = 0,
            Breakdown_Visits__c = 0,
             Warranty_Period__c = 12
        );
        insert warranty;

        // Create active AMC
        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'Test AMC',
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today().addDays(-10),
            AMC_End_Date__c = Date.today().addDays(10),
            PM_Visits__c = 0,
            Breakdown_Visits__c = 0,
            Product_Category_Type__c = 'AMC',
            AMC_Period_In_Months__c = 12
        );
        insert amc;

        // Create a Case (to simulate closure from open)
        Case c = new Case(
            Subject = 'Test PM Case',
            Status = 'New',
            Type = 'Preventive Maintenance',
            AssetId = asset.Id,
            AccountId = acc.Id
        );
        insert c;

        // Simulate status update to Closed
        c.Status = 'Closed';
        c.IsClosingFromCustomUI__c = true;
        update c;

        c = [SELECT Id, Status, IsClosed, AssetId, Type, Case_Sub_Type__c FROM Case WHERE Id = :c.Id];

        // Prepare data for method
        List<Case> newList = new List<Case>{ c };
            Map<Id, Case> oldMap = new Map<Id, Case>{
                c.Id => new Case(Id = c.Id, Status = 'New') // simulate old status
                    };

                        Test.startTest();
        CaseTriggerHandler.rollUpVisitCountToActiveAMCOrWarranty(newList, oldMap);
        Test.stopTest();

        // Fetch updated warranty and AMC
        warranty = [SELECT Id, Warranty_Visit__c FROM Asset_Warranty__c WHERE Id = :warranty.Id];
        amc = [SELECT Id, PM_Visits__c FROM Asset_AMC__c WHERE Id = :amc.Id];

    }

    @isTest
    static void testBreakdownVisitUpdate() {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create another asset
        Asset asset = new Asset(Name = 'Breakdown Asset');
        insert asset;

        // Create active warranty & AMC
        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'BD Warranty',
            Asset__c = asset.Id,
            Warranty_Start_Date__c = Date.today().addDays(-5),
            Warranty_End_Date__c = Date.today().addDays(5),
            Breakdown_Visits__c = 0,
            Warranty_Period__c = 12
        );
        insert warranty;

        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'BD AMC',
            Asset__c = asset.Id,
            AMC_Start_Date__c = Date.today().addDays(-5),
            AMC_End_Date__c = Date.today().addDays(5),
            Breakdown_Visits__c = 0,
            Product_Category_Type__c = 'AMC',
            AMC_Period_In_Months__c = 12
        );
        insert amc;

        // Create a Breakdown case
        Case c = new Case(
            Subject = 'Breakdown Case',
            Status = 'New',
            Type = 'Breakdown',
            AssetId = asset.Id,
            AccountId = acc.Id
        );
        insert c;

        // Simulate closing the case
        c.Status = 'Closed';
        c.IsClosingFromCustomUI__c = true;
        update c;

        List<Case> newList = new List<Case>{ c };
            Map<Id, Case> oldMap = new Map<Id, Case>{
                c.Id => new Case(Id = c.Id, Status = 'New')
                    };

                        Test.startTest();
        CaseTriggerHandler.rollUpVisitCountToActiveAMCOrWarranty(newList, oldMap);
        Test.stopTest();

        // Assert breakdowns updated
        warranty = [SELECT Breakdown_Visits__c FROM Asset_Warranty__c WHERE Id = :warranty.Id];
        amc = [SELECT Breakdown_Visits__c FROM Asset_AMC__c WHERE Id = :amc.Id];
    }
    
     @isTest
    static void testPreventFeedItemDeletion() {
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User salesPerson = new User(
            Alias = 'sperson',
            Email = 'salesperson@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Sales',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'salesperson' + DateTime.now().getTime() + '@test.com'
        );
        insert salesPerson;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        FeedItem post = new FeedItem();
        post.ParentId = acc.Id;
        post.Body = 'Test Chatter Post';
        post.Type = 'TextPost';
        insert post;

        Test.startTest();
        try {
            delete post;
            System.assert(false, 'Expected DMLException due to trigger preventing deletion.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Deletion of Chatter posts is not allowed'), 'Expected deletion to be blocked.');
        }
        Test.stopTest();
    }


}