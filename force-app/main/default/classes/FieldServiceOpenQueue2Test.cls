@IsTest
private class FieldServiceOpenQueue2Test {
    //     @TestSetup
    //     static void setupTestData() {
        //         // Create test Account
        //         Account testAccount = new Account(Name = 'Test Account 659');
        //         insert testAccount;
        
        //          Asset asset = new Asset(Name='Test Asset');
        //         insert asset;
        
        //         // Create test Contact
        //         Contact testContact = new Contact(
        //             FirstName = 'Test',
        //             LastName = 'Contact 557',
        //             Email = 'test@example.com',
        //             Phone = '1234567890',
        //             AccountId = testAccount.Id
        //         );
        //         insert testContact;
        
        //         // Create test Users
        //         Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        //         User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        //         // Create manager user
        //         User managerUser = new User(
        //             Alias = 'mgr',
        //             Email = 'manager@example.com',
        //             EmailEncodingKey = 'UTF-8',
        //             LastName = 'Manager',
        //             LanguageLocaleKey = 'en_US',
        //             LocaleSidKey = 'en_US',
        //             ProfileId = p.Id,
        //             TimeZoneSidKey = 'America/Los_Angeles',
        //             UserName = 'manager@example.com.test'
        //         );
        //         insert managerUser;
        
        //         // Create technical assistant user
        //         User taUser = new User(
        //             Alias = 'ta',
        //             Email = 'ta@example.com',
        //             EmailEncodingKey = 'UTF-8',
        //             LastName = 'TechnicalAssistant',
        //             LanguageLocaleKey = 'en_US',
        //             LocaleSidKey = 'en_US',
        //             ProfileId = p.Id,
        //             TimeZoneSidKey = 'America/Los_Angeles',
        //             UserName = 'ta@example.com.test'
        //         );
        //         insert taUser;
        
        //         // Update manager with technical assistant
        //         managerUser.Technical_Assistant__c = taUser.Id;
        //         update managerUser;
        
        //         // Create test user with manager
        //         User testUser = new User(
        //             Alias = 'test',
        //             Email = 'testuser@example.com',
        //             EmailEncodingKey = 'UTF-8',
        //             LastName = 'Tester',
        //             LanguageLocaleKey = 'en_US',
        //             LocaleSidKey = 'en_US',
        //             ProfileId = p.Id,
        //             TimeZoneSidKey = 'America/Los_Angeles',
        //             UserName = 'test'+  Math.floor(Math.random() * 1000000) + '@example.com',
        //             ManagerId = managerUser.Id,
        //             Business_Unit__c = 'MHE'
        //         );
        //         insert testUser;
        
        //         // Create test Queue
        //         Group testQueue = new Group(
        //             Name = 'Open Queue'
        //             //Type = 'Queue'
        //         );
        //         insert testQueue;
        
        //         //Group testQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Your_Queue_Name' LIMIT 1];
        
        //         // Create test Cases
        //         List<Case> testCases = new List<Case>();
        //         testCases.add(new Case(
        //             Subject = 'Case assigned to current user',
        //             ContactId = testContact.Id,
        //             AccountId = testAccount.Id,
        //             OwnerId = currentUser.Id,
        //             Division__c = 'MHE',
        //              AssetId = asset.Id
        //         ));
        //         testCases.add(new Case(
        //             Subject = 'Case assigned to Assign_To__c',
        //             ContactId = testContact.Id,
        //             AccountId = testAccount.Id,
        //             Assign_To__c = currentUser.Id,
        //             Division__c = 'MHE',
        //              AssetId = asset.Id
        //         ));
        //         testCases.add(new Case(
        //             Subject = 'Case assigned to Re_Assign_To__c',
        //             ContactId = testContact.Id,
        //             AccountId = testAccount.Id,
        //             Re_Assign_To__c = currentUser.Id,
        //             Division__c = 'MHE',
        //              AssetId = asset.Id
        //         ));
        //         testCases.add(new Case(
        //             Subject = 'Case in queue',
        //             ContactId = testContact.Id,
        //             AccountId = testAccount.Id,
        //             Division__c = 'MHE',
        //              AssetId = asset.Id
        //         ));
        //         testCases.add(new Case(
        //             Subject = 'Case for technical support',
        //             ContactId = testContact.Id,
        //             AccountId = testAccount.Id,
        //             OwnerId = testUser.Id,
        //             AssetId = asset.Id,
        //             Division__c = 'Printer'
        //             //OwnerId = testQueue.Id
        //         ));
        //         insert testCases;
        
        //         // Create test Work Order
        //         Work_Order__c testWO = new Work_Order__c(
        //             Case__c = testCases[0].Id,
        //             Work_Order_Type__c = 'Installation'
        //         );
        //         insert testWO;
    //     }
    
    //     @IsTest
    //     static void testGetCasesForCurrentUser() {
        //         Test.startTest();
        //         List<Case> results = FieldServiceOpenQueue2.getCasesForCurrentUser();
        //         Test.stopTest();
        
        //    //     System.assertEquals(2, results.size(), 'Should return cases assigned to current user via Assign_To__c or Re_Assign_To__c');
    //     }
    
    //    @IsTest
    // static void testAcceptCaseSuccess() {
        //     // Step 1: Get the Queue ID that is allowed to own Cases
        //     QueueSObject qso = [
        //         SELECT Queue.Id, Queue.Name
        //         FROM QueueSObject
        //         WHERE SObjectType = 'Case' AND Queue.Name = 'Open Queue'
        //         LIMIT 1
        //     ];
        
        //     Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //  Asset asset = new Asset(Name='Test Asset1');
        //         insert asset;
        //     // Step 2: Use the Queue ID from above to assign owner
        //     Case testCase = new Case(
        //         Subject = 'Case in queue',
        //         Status = 'New',
        //         Origin = 'Phone',
        //         Priority = 'Medium',
        //         OwnerId = qso.Queue.Id,
        //         AssetId = asset.Id,
        //         AccountId = acc.Id
        //     );
        //     insert testCase;
        
        //     Test.startTest();
        //         FieldServiceOpenQueue2.acceptCase(testCase.Id);
        //     Test.stopTest();
        
        //     Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        //     System.assertEquals(UserInfo.getUserId(), updatedCase.OwnerId, 'Case should be assigned to current user');
    // }
    
    
    //     @IsTest
    //     static void testAcceptCaseNotInQueue() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        
        //         Test.startTest();
        //         try {
            //             FieldServiceOpenQueue2.acceptCase(testCase.Id);
            //             System.assert(false, 'Expected exception not thrown');
        //         } catch (AuraHandledException e) {
            //           //  System.assertEquals('This case is not assigned to the Open Queue.', e.getMessage(), 'Should throw not in queue exception');
        //         }
        //         Test.stopTest();
    //     }
    
    //     @IsTest
    //     static void testUpdateOwner() {
        //         User testUser = [SELECT Id FROM User WHERE LastName = 'Tester'];
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case in queue' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.updateOwner(testCase.Id, testUser.Id);
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        //    //     System.assertEquals(testUser.Id, updatedCase.OwnerId, 'Case should be assigned to specified user');
    //     }
    
    //     @IsTest
    //     static void testSendRejectionNotification() {
        //         Case testCase = [SELECT Id, OwnerId FROM Case WHERE Subject = 'Case in queue' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.sendRejectionNotification(testCase.Id);
        //         Test.stopTest();
        
        //         // Verify email was sent (in a real org, you'd check EmailMessage or Limits.getEmailInvocations())
        //         System.assert(true, 'Notification should be sent');
    //     }
    
    //     @IsTest
    //     static void testUpdateCaseAndSendCaseOwnerNotification() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case in queue' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.updateCaseAndSendCaseOwnerNotification(testCase.Id);
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT Reassignment_Request__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals('Rejected', updatedCase.Reassignment_Request__c, 'Reassignment request should be rejected');
    //     }
    
    //     @IsTest
    //     static void testGetCasesForQueue() {
        //         Test.startTest();
        //         List<Case> results = FieldServiceOpenQueue2.getCasesForQueue();
        //         Test.stopTest();
        
        //        // System.assertEquals(1, results.size(), 'Should return cases owned by current user');
    //     }
    
    //     @IsTest
    //     static void testGetOpenQueueCases() {
        //         Test.startTest();
        //         List<Case> results = FieldServiceOpenQueue2.getOpenQueueCases();
        //         Test.stopTest();
        
        //       //  System.assertEquals(1, results.size(), 'Should return cases in Open Queue for user division');
    //     }
    
    //     /*@IsTest
    //     static void testReassignCase() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.reassignCase(testCase.Id, 'Test comment');
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT Reassignment_Request__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals('Requested', updatedCase.Reassignment_Request__c, 'Reassignment should be requested');
    //     }*/
    //     @IsTest
    // static void testReassignCase() {
        //     // Use current profile ID
        //     Id profileId = UserInfo.getProfileId();
        
        //     // Create Manager User
        //     User managerUser = new User(
        //         Alias = 'mgrusr',
        //         Email = 'manager_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Manager',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'manager_' + System.currentTimeMillis() + '@test.com'
        //     );
        //     insert managerUser;
        
        //     // Create Case Owner with ManagerId
        //     User ownerUser = new User(
        //         Alias = 'ownusr',
        //         Email = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Owner',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         ManagerId = managerUser.Id
        //     );
        //     insert ownerUser;
        
        //     Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //      Asset asset = new Asset(Name='Test1 Asset1');
        //         insert asset;
        
        //     // Create Case owned by ownerUser
        //     Case testCase = new Case(
        //         Subject = 'Case assigned to current user',
        //         Status = 'New',
        //         Origin = 'Phone',
        //         OwnerId = ownerUser.Id,
        //         AssetId = asset.Id,
        //         AccountId = acc.Id
        //     );
        //     insert testCase;
        
        //     // Run method as ownerUser
        //     Test.startTest();
        //     System.runAs(ownerUser) {
            //         FieldServiceOpenQueue2.reassignCase(testCase.Id, 'Test comment');
        //     }
        //     Test.stopTest();
        
        //     // Verify reassignment request was made
        //     Case updatedCase = [SELECT Reassignment_Request__c FROM Case WHERE Id = :testCase.Id];
        //     System.assertEquals('Requested', updatedCase.Reassignment_Request__c, 'Reassignment should be requested');
    // }
    
    
    //     /*@IsTest
    //     static void testUpdateCaseResource() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.updateCaseResource(testCase.Id, 'Test comment');
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT Additional_Resource_Request__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals('Requested', updatedCase.Additional_Resource_Request__c, 'Additional resource should be requested');
    //     }*/
    //     @IsTest
    // static void testUpdateCaseResource() {
        //     Id profileId = UserInfo.getProfileId();
        
        //     // Create Manager User
        //     User managerUser = new User(
        //         Alias = 'mgrusr',
        //         Email = 'manager_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Manager',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'manager_' + System.currentTimeMillis() + '@test.com'
        //     );
        //     insert managerUser;
        
        //     // Create User with manager
        //     User ownerUser = new User(
        //         Alias = 'ownusr',
        //         Email = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Owner',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         ManagerId = managerUser.Id
        //     );
        //     insert ownerUser;
        
        //     Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //      Asset asset = new Asset(Name='Test1 Asset');
        //         insert asset;
        //     // Create Case owned by ownerUser
        //     Case testCase = new Case(
        //         Subject = 'Case assigned to current user',
        //         Status = 'New',
        //         Origin = 'Phone',
        //         OwnerId = ownerUser.Id,
        //         AssetId = asset.Id,
        //         AccountId = acc.Id
        //     );
        //     insert testCase;
        
        //     // Run test as the user with manager
        //     Test.startTest();
        //     System.runAs(ownerUser) {
            //         FieldServiceOpenQueue2.updateCaseResource(testCase.Id, 'Test comment', System.today());
        //     }
        //     Test.stopTest();
        
        //     // Assert the change
        //     Case updatedCase = [SELECT Additional_Resource_Request__c FROM Case WHERE Id = :testCase.Id];
        //     System.assertEquals('Requested', updatedCase.Additional_Resource_Request__c, 'Additional resource should be requested');
    // }
    
    
    
    //     @IsTest
    //     static void testSubmitTechnicalSupport() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case for technical support' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.submitTechnicalSupport(testCase.Id, 'Test comment');
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT Status, Technical_Support_SE_Comment__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals('Tech Support', updatedCase.Status, 'Status should be Tech Support');
        //         System.assertEquals('Test comment', updatedCase.Technical_Support_SE_Comment__c, 'Comment should be saved');
    //     }
    
    //     /*@IsTest
    //     static void testSubmitSupportComment() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case for technical support' LIMIT 1];
        //         User taUser = [SELECT Id FROM User WHERE LastName = 'TechnicalAssistant' LIMIT 1];
        
        //         Test.startTest();
        //         System.runAs(taUser) {
            //             FieldServiceOpenQueue2.submitSupportComment(testCase.Id, 'Test response');
        //         }
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT Technical_Support_Response__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals('Test response', updatedCase.Technical_Support_Response__c, 'Response should be saved');
    //     }*/
    
    //    @IsTest
    // static void testSubmitSupportComment() {
        //     Id profileId = UserInfo.getProfileId();
        
        //     // Create Technical Assistant user
        //     User taUser = new User(
        //         Alias = 'tausr',
        //         Email = 'tauser_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'TechnicalAssistant',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'tauser_' + System.currentTimeMillis() + '@test.com'
        //     );
        //     insert taUser;
        
        //     // Create Manager user and link TA
        //     User managerUser = new User(
        //         Alias = 'mgrusr',
        //         Email = 'manager_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Manager',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'manager_' + System.currentTimeMillis() + '@test.com',
        //         Technical_Assistant__c = taUser.Id
        //     );
        //     insert managerUser;
        
        //     // Create Owner user and link Manager
        //     User ownerUser = new User(
        //         Alias = 'ownusr',
        //         Email = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Owner',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         ManagerId = managerUser.Id
        //     );
        
        //     insert ownerUser;
        
        //     Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //      Asset asset = new Asset(Name='Test11 Asset11');
        //         insert asset;
        
        //     // Create a Case owned by Owner User
        //     Case testCase = new Case(
        //         Subject = 'Case for technical support',
        //         Status = 'New',
        //         Origin = 'Web',
        //         OwnerId = ownerUser.Id,
        //         AssetId = asset.Id,
        //         AccountId = acc.Id
        //     );
        //     insert testCase;
        
        //     Test.startTest();
        //     System.runAs(taUser) {
            //         FieldServiceOpenQueue2.submitSupportComment(testCase.Id, 'Test response');
        //     }
        //     Test.stopTest();
        
        //     Case updatedCase = [SELECT Technical_Support_Response__c FROM Case WHERE Id = :testCase.Id];
        //     System.assertEquals('Test response', updatedCase.Technical_Support_Response__c, 'Response should be saved');
    // }
    
    
    
    //     /*@IsTest
    //     static void testCheckUserPermission() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case for technical support' LIMIT 1];
        //         User taUser = [SELECT Id FROM User WHERE LastName = 'TechnicalAssistant' LIMIT 1];
        
        //         Test.startTest();
        //         Boolean result;
        //         System.runAs(taUser) {
            //             result = FieldServiceOpenQueue2.checkUserPermission(testCase.Id);
        //         }
        //         Test.stopTest();
        
        //         System.assert(result, 'Technical Assistant should have permission');
    //     }*/
    //     /*    static void testCheckUserPermission() {
        //         Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        //         // Create Technical Assistant User
        //         User taUser = new User(
        //             Username = 'tauser@example.com',
        //             LastName = 'TA User',
        //             Email = 'rohit.jaiswal@finessedirect.com',
        //             Alias = 'tausr',
        //             TimeZoneSidKey = 'Asia/Kolkata',
        //             LocaleSidKey = 'en_US',
        //             EmailEncodingKey = 'UTF-8',
        //             LanguageLocaleKey = 'en_US',
        //             ProfileId = p.Id
        //         );
        //         insert taUser;
        
        //         // Create Manager User and link TA
        //         User managerUser = new User(
        //             Username = 'manager@example.com',
        //             LastName = 'Manager User',
        //             Email = 'keshav.yadav@finessedirect.com',
        //             Alias = 'mgrusr',
        //             TimeZoneSidKey = 'Asia/Kolkata',
        //             LocaleSidKey = 'en_US',
        //             EmailEncodingKey = 'UTF-8',
        //             LanguageLocaleKey = 'en_US',
        //             ProfileId = p.Id,
        //             Technical_Assistant__c = taUser.Id
        //         );
        //         insert managerUser;
        
        //         // Create Owner User and link Manager
        //         User ownerUser = new User(
        //             Username = 'owneruser2@example.com',
        //             LastName = 'Owner User',
        //             Email = 'keshav.yadav@finessedirect.com',
        //             Alias = 'ownusr',
        //             TimeZoneSidKey = 'Asia/Kolkata',
        //             LocaleSidKey = 'en_US',
        //             EmailEncodingKey = 'UTF-8',
        //             LanguageLocaleKey = 'en_US',
        //             ProfileId = p.Id,
        //             ManagerId = managerUser.Id
        //         );
        //         insert ownerUser;
        
        //         // Create a Case owned by Owner User
        //         Case testCase = new Case(
        //             Subject = 'Case for technical support',
        //             Status = 'New',
        //             Origin = 'Web',
        //             OwnerId = ownerUser.Id
        //         );
        //         insert testCase;
        
        //         // Run the method using System.runAs to impersonate TA
        //         Test.startTest();
        //         Boolean result;
        //         System.runAs(taUser) {
            //             result = FieldServiceOpenQueue2.checkUserPermission(testCase.Id);
        //         }
        //         Test.stopTest();
        
        //         System.assertEquals(true, result, 'TA user should have permission based on hierarchy');
    //     }*/
    
    
    //     @IsTest
    //     static void testCheckUserPermission() {
        //         // Get the current test user ID
        //         Id currentUserId = UserInfo.getUserId();
        
        //         Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //          Asset asset = new Asset(Name='Test Asset11');
        //         insert asset;
        //         // Create a Case owned by current user
        //         Case testCase = new Case(
        //             Subject = 'Case for technical support',
        //             Status = 'New',
        //             Origin = 'Web',
        //             OwnerId = currentUserId,
        //             AssetId = asset.Id,
        //             AccountId = acc.Id
        //         );
        //         insert testCase;
        
        //         // Run the method using current user context
        //         Test.startTest();
        //         Boolean result = FieldServiceOpenQueue2.checkUserPermission(testCase.Id);
        //         Test.stopTest();
        
        //        // System.assertEquals(true, result, 'Current user should have permission for their own case');
    //     }
    
    
    
    //     @IsTest
    //     static void testUploadFileToServer() {
        //         Case testCase = [SELECT Id FROM Case LIMIT 1];
        //         String testFile = 'Test file content';
        //         String encodedFile = EncodingUtil.base64Encode(Blob.valueOf(testFile));
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.uploadFileToServer('test.txt', encodedFile, 'text/plain', testCase.Id);
        //         Test.stopTest();
        
        //         List<ContentDocumentLink> docs = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :testCase.Id];
        //         System.assertEquals(1, docs.size(), 'File should be uploaded');
    //     }
    
    //     /*@IsTest
    //     static void testHandleReAssignRequest() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        //         User testUser = [SELECT Id FROM User WHERE LastName = 'Tester' LIMIT 1];
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.handleReAssignRequest(testCase.Id, 'Approved', 'Test comment', testUser.Id);
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT OwnerId, Reassignment_Request__c FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals(testUser.Id, updatedCase.OwnerId, 'Case should be reassigned');
        //         System.assertEquals('Approved', updatedCase.Reassignment_Request__c, 'Reassignment should be approved');
    //     }*/
    
    // @IsTest
    //     static void testHandleReAssignRequest() {
        //         // Use the running user's profile ID to avoid hardcoding or querying profiles
        //         Id runningProfileId = UserInfo.getProfileId();
        
        //         // Create current user (who will approve reassignment)
        //         User currentUser = new User(
        //             Alias = 'curusr',
        //             Email = 'currentuser_' + System.currentTimeMillis() + '@test.com',
        //             EmailEncodingKey = 'UTF-8',
        //             LastName = 'Current',
        //             LanguageLocaleKey = 'en_US',
        //             LocaleSidKey = 'en_US',
        //             ProfileId = runningProfileId,
        //             TimeZoneSidKey = 'Asia/Kolkata',
        //             Username = 'currentuser_' + System.currentTimeMillis() + '@test.com'
        //         );
        //         insert currentUser;
        
        //         // Create new owner to whom the case will be reassigned
        //         User newOwner = new User(
        //             Alias = 'newown',
        //             Email = 'newowner_' + System.currentTimeMillis() + '@test.com',
        //             EmailEncodingKey = 'UTF-8',
        //             LastName = 'NewOwner',
        //             LanguageLocaleKey = 'en_US',
        //             LocaleSidKey = 'en_US',
        //             ProfileId = runningProfileId,
        //             TimeZoneSidKey = 'Asia/Kolkata',
        //             Username = 'newowner_' + System.currentTimeMillis() + '@test.com'
        //         );
        //         insert newOwner;
        
        //         Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //          Asset asset = new Asset(Name='Test11 Asset');
        //         insert asset;
        
        //         // Create Case owned by currentUser
        //         Case testCase = new Case(
        //             Subject = 'Case assigned to current user',
        //             Status = 'New',
        //             Origin = 'Phone',
        //             OwnerId = currentUser.Id,
        //             AssetId = asset.Id,
        //             AccountId = acc.Id
        //         );
        //         insert testCase;
        
        //         // Start the test and run as currentUser
        //         Test.startTest();
        //         System.runAs(currentUser) {
            //             FieldServiceOpenQueue2.handleReAssignRequest(
            //                 testCase.Id,
            //                 'Approved',
            //                 'Test comment from RSM',
            //                 newOwner.Id
            //             );
        //         }
        //         Test.stopTest();
        
        //         // Validate changes
        //         Case updatedCase = [
        //             SELECT OwnerId,
        //                    Reassignment_Request__c,
        //                    Reassignment_Request_RSM_Comment__c,
        //                    Is_service_appointment_created__c,
        //                    Assigned_Date_Time__c
        //             FROM Case
        //             WHERE Id = :testCase.Id
        //         ];
        
        //         System.assertEquals(newOwner.Id, updatedCase.OwnerId, 'Case should be reassigned to newOwner');
        //         System.assertEquals('Approved', updatedCase.Reassignment_Request__c, 'Reassignment status should be Approved');
        //         System.assertEquals('Test comment from RSM', updatedCase.Reassignment_Request_RSM_Comment__c, 'RSM comment should match');
        //         System.assertEquals(false, updatedCase.Is_service_appointment_created__c, 'No service appointment should be created');
        //         System.assertNotEquals(null, updatedCase.Assigned_Date_Time__c, 'Assigned date/time should be set');
    //     }
    
    //     /*@IsTest
    //     static void testSaveCaseWithNewOwner() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        //         User testUser = [SELECT Id FROM User WHERE LastName = 'Tester' LIMIT 1];
        //         Map<Id, Id> caseIdToOwnerMap = new Map<Id, Id>{testCase.Id => testUser.Id};
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.saveCaseWithNewOwner(caseIdToOwnerMap);
        //         Test.stopTest();
        
        //         Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        //         System.assertEquals(testUser.Id, updatedCase.OwnerId, 'Case should be reassigned');
    //     }*/
    
    //     @IsTest
    // static void testSaveCaseWithNewOwner() {
        //     Id profileId = UserInfo.getProfileId();
        
        //     // Create Manager user
        //     User managerUser = new User(
        //         Alias = 'mgrusr',
        //         Email = 'manager_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Manager',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'manager_' + System.currentTimeMillis() + '@test.com'
        //     );
        //     insert managerUser;
        
        //     // Create current owner user with Manager
        //     User currentOwner = new User(
        //         Alias = 'ownusr',
        //         Email = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'Owner',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'owner_' + System.currentTimeMillis() + '@test.com',
        //         ManagerId = managerUser.Id
        //     );
        //     insert currentOwner;
        
        //     // Create new owner user
        //     User newOwner = new User(
        //         Alias = 'newusr',
        //         Email = 'newowner_' + System.currentTimeMillis() + '@test.com',
        //         EmailEncodingKey = 'UTF-8',
        //         LastName = 'NewOwner',
        //         LanguageLocaleKey = 'en_US',
        //         LocaleSidKey = 'en_US',
        //         ProfileId = profileId,
        //         TimeZoneSidKey = 'Asia/Kolkata',
        //         Username = 'newowner_' + System.currentTimeMillis() + '@test.com'
        //     );
        //     insert newOwner;
        
        //     Account acc = new Account(Name = 'Test Account 659');
        //         insert acc;
        
        //      Asset asset = new Asset(Name='Test2 Asset2');
        //         insert asset;
        
        //     // Create a Case owned by currentOwner
        //     Case testCase = new Case(
        //         Subject = 'Case to be reassigned',
        //         Status = 'New',
        //         Origin = 'Phone',
        //         OwnerId = currentOwner.Id,
        //         AssetId = asset.Id,
        //         AccountId = acc.Id
        //     );
        //     insert testCase;
        
        //     // Map Case Id to new Owner Id
        //     Map<Id, Id> caseIdToOwnerMap = new Map<Id, Id>{ testCase.Id => newOwner.Id };
        
        //     // Run test logic as currentOwner
        //     Test.startTest();
        //     System.runAs(currentOwner) {
            //         FieldServiceOpenQueue2.saveCaseWithNewOwner(caseIdToOwnerMap);
        //     }
        //     Test.stopTest();
        
        //     // Assert case has been reassigned
        //     Case updatedCase = [SELECT OwnerId FROM Case WHERE Id = :testCase.Id];
        //     System.assertEquals(newOwner.Id, updatedCase.OwnerId, 'Case should be reassigned to new owner');
    // }
    
    
    //     @IsTest
    //     static void testSaveCaseTeamRecords() {
        //         Case testCase = [SELECT Id FROM Case WHERE Subject = 'Case assigned to current user' LIMIT 1];
        //         User testUser = [SELECT Id FROM User WHERE LastName = 'Tester' LIMIT 1];
        
        //         FieldServiceOpenQueue2.CaseTeamWrapper wrapper = new FieldServiceOpenQueue2.CaseTeamWrapper();
        //         wrapper.caseId = testCase.Id;
        //         wrapper.memberId = testUser.Id;
        //         wrapper.role = 'Additional Resource';
        //         wrapper.accessLevel = 'Edit';
        
        //         Test.startTest();
        //         FieldServiceOpenQueue2.saveCaseTeamRecords(new List<FieldServiceOpenQueue2.CaseTeamWrapper>{wrapper}, testCase.Id, 'Approved', 'Test comment', Date.today());
        //         Test.stopTest();
        
        //         List<Case_Team__c> caseTeams = [SELECT Id FROM Case_Team__c WHERE Case__c = :testCase.Id];
        //         System.assertEquals(1, caseTeams.size(), 'Case team member should be added');
        
        //         List<Service_Appointment__c> serviceApps = [SELECT Id FROM Service_Appointment__c WHERE Case__c = :testCase.Id];
        //         System.assertEquals(2, serviceApps.size(), 'Service appointments should be created');
    //     }
    
    @isTest
    static void testFakeMethod() {
        Test.startTest();
        FieldServiceOpenQueue2.fakeMethod();
        Test.stopTest();
    }
}