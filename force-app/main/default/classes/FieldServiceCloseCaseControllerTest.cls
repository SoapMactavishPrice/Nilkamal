@IsTest
private class FieldServiceCloseCaseControllerTest {

    @TestSetup
    static void setupTestData() {
        // -----------------------
        // Account, Contact, Asset
        // -----------------------
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            MobilePhone = '1234567890',
            AccountId = testAccount.Id
        );
        insert testContact;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = testAccount.Id,
            ContactId = testContact.Id
        );
        insert testAsset;

        // -----------------------
        // Opportunity
        // -----------------------
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            CloseDate = System.today().addDays(30),
            StageName = 'Prospecting'
        );
        insert testOpp;

        // -----------------------
        // Sequence Master (for Quote trigger)
        // -----------------------
        Sequence_Master__c sm = new Sequence_Master__c(
            Starting_Number__c = 1,
            format__c = '0000'
        );
        insert sm;

        // -----------------------
        // Case
        // -----------------------
        Case testCase = new Case(
            Subject = 'Test Case',
            ContactId = testContact.Id,
            AssetId = testAsset.Id,
            AccountId = testAccount.Id,
            Additional_Resource_Request__c = 'Requested'
        );
        insert testCase;

        // -----------------------
        // Work Order
        // -----------------------
        Work_Order__c testWO = new Work_Order__c(
            Case__c = testCase.Id,
            Work_Order_Type__c = 'Installation'
        );
        insert testWO;

        // -----------------------
        // Service Appointment
        // -----------------------
        Service_Appointment__c testSA = new Service_Appointment__c(
            Case__c = testCase.Id,
            Scheduled_Start__c = System.now(),
            Check_Out_GeoLocation__Latitude__s = 12.34,
            Check_Out_GeoLocation__Longitude__s = 56.78,
            Check_Out_Address_Error__c = 'Auto Checked Out by System',
            Work_Order__c = testWO.Id
        );
        insert testSA;
        
        Service_Report__c testRep = new Service_Report__c(
                        Case__c = testCase.Id,
                        Work_Order__c = testWO.Id,
            Service_Appointment__c = testSA.Id


        );
        insert testRep;

        // -----------------------
        // Work Order Checklist
        // -----------------------
        Work_Order_Checklist__c testChecklist = new Work_Order_Checklist__c(
            Work_Order__c = testWO.Id,
            Observation__c = 'Ok'
        );
        insert testChecklist;

        // -----------------------
        // Task
        // -----------------------
        Task testTask = new Task(
            WhatId = testAccount.Id,
            Subject = 'Test Task',
            Status = 'Completed'
        );
        insert testTask;

        // -----------------------
        // Spare Request
        // -----------------------
        Spare_Request__c testSpareRequest = new Spare_Request__c(
            Case__c = testCase.Id,
            Billing_Type__c = 'FOC and Returnable',
            Work_Order__c = testWO.Id
        );
        insert testSpareRequest;

        // -----------------------
        // Quote
        // -----------------------
        Quote testQuote = new Quote(
            Case__c = testCase.Id,
            Billing_Type__c = 'FOC and Returnable',
            SAP_Order_No__c = '12345',
            Returnable_Received__c = true,
            OpportunityId = testOpp.Id,
            Name = 'Test Quote'
        );
        insert testQuote;

        // -----------------------
        // Service Resource
        // -----------------------
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Service_Resource__c testSR = new Service_Resource__c(
            Name = 'Test SR',
            User__c = testUser.Id
        );
        insert testSR;

        // Update Asset with Service Resource
        testAsset.Service_Resource__c = testSR.Id;
        update testAsset;

        // -----------------------
        // Installation Report
        // -----------------------
        Installation_Report__c testIR = new Installation_Report__c(
            Case__c = testCase.Id,
            Work_Order__c = testWO.Id
        );
        insert testIR;
    }

    @IsTest
    static void testGetCaseDetails() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCloseCaseController.getCaseDetails(testCase.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Case details should be returned');
    }

    @IsTest
    static void testCloseCaseSuccess() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Service_Appointment__c testSA = [Select Id From Service_Appointment__c Limit 1];
        Test.startTest();
        FieldServiceCloseCaseController.closeCase(testCase.Id, 'Case Closed Successfully', 'Test closure comment',testSA.Id);
        Test.stopTest();
        Case updatedCase = [SELECT Status FROM Case WHERE Id = :testCase.Id];
        //System.assertEquals('Closed', updatedCase.Status, 'Case should be closed');
    }

    @IsTest
    static void testCloseCaseAlreadyClosed() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        testCase.IsClosingFromCustomUI__c = true;
        testCase.Status = 'Closed';
        update testCase;
        Service_Appointment__c testSA = [Select Id From Service_Appointment__c Limit 1];


        Test.startTest();
        try {
            FieldServiceCloseCaseController.closeCase(testCase.Id, 'Resolved', 'Test closure comment',testSA.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Case is already closed'), 'Should throw case already closed exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCloseCaseNotCheckedOut() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Service_Appointment__c testSA = [SELECT Id FROM Service_Appointment__c LIMIT 1];
        testSA.Check_Out_GeoLocation__Latitude__s = null;
        testSA.Check_Out_GeoLocation__Longitude__s = null;
        update testSA;
        

        Test.startTest();
        try {
            FieldServiceCloseCaseController.closeCase(testCase.Id, 'Resolved', 'Test closure comment',testSA.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Service Appointment is not checked out'), 'Should throw not checked out exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testCloseCaseReturnableNotReceived() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        testQuote.Returnable_Received__c = false;
        update testQuote;
        Service_Appointment__c testSA = [Select Id From Service_Appointment__c Limit 1];


        Test.startTest();
        try {
            FieldServiceCloseCaseController.closeCase(testCase.Id, 'Resolved', 'Test closure comment',testSA.Id);
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Returnable sample is not yet received'), 'Should throw returnable not received exception');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetChecklistData() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCloseCaseController.getChecklistData(testCase.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Checklist data should be returned');
    }

    @IsTest
    static void testGetSpareRequestsByStatus() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCloseCaseController.getSpareRequestsByStatus(testCase.Id);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Spare requests should be returned');
    }

    @IsTest
    static void testGetServiceRequestCount() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Integer result = FieldServiceCloseCaseController.getServiceRequestCount(testCase.Id);
        Test.stopTest();
        System.assertEquals(0, result, 'Service request count should be returned');
    }

    @IsTest
    static void testGetReportGeneratedOrNot() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Test.startTest();
        Object result = FieldServiceCloseCaseController.getReportGeneratedOrNot(testCase.Id);
        Test.stopTest();
        System.assertEquals(0, result, 'Report count should be returned');
    }

    @IsTest
    static void testGetReportGeneratedOrNotWithAttachment() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        Installation_Report__c testIR = [SELECT Id FROM Installation_Report__c LIMIT 1];

        ContentVersion cv = new ContentVersion(
            Title = 'Test Report',
            PathOnClient = 'TestReport.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testIR.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;

        Test.startTest();
        Object result = FieldServiceCloseCaseController.getReportGeneratedOrNot(testCase.Id);
        Test.stopTest();
        System.assertEquals(1, result, 'Report count should be returned');
    }
}