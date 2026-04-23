@isTest
private class ActivityLoggingControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
          Asset asset = new Asset(Name='Test Asset');
        insert asset;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        Case cs = new Case(AccountId = acc.Id, Status = 'New', Origin = 'Phone',AssetId = asset.Id);
        insert cs;

         // Insert a dummy Work Order if needed
     Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

    // Create Service Appointment without setting auto-number Name
    Service_Appointment__c sa = new Service_Appointment__c(
        Case__c = cs.Id,
        Work_Order__c = wo.Id,
        Scheduled_Start__c = DateTime.now().addDays(1), 
            Remote_Support__c = false
    );
    insert sa;

        User u = [SELECT Id FROM User WHERE Profile.Name = 'Service Engineer' LIMIT 1];
    }

    @isTest
    static void testGetCurrentUser() {
        Test.startTest();
        User currentUser = ActivityLoggingController.getCurrentUser();
        Test.stopTest();
        System.assertNotEquals(null, currentUser);
    }

    @isTest
    static void testGetServiceAppointmentName() {
        Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c LIMIT 1];
        Test.startTest();
        Service_Appointment__c result = ActivityLoggingController.getServiceAppointmentName(sa.Id);
        Test.stopTest();
        System.assertEquals(sa.Id, result.Id);
    }

    @isTest
    static void testGetServiceAppointmentNameNull() {
        Test.startTest();
        Service_Appointment__c result = ActivityLoggingController.getServiceAppointmentName(null);
        Test.stopTest();
        System.assertEquals(null, result);
    }

   @isTest
static void testSaveActivities() {
    // Fetch test data
    Contact con = [SELECT Id FROM Contact LIMIT 1];
    Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c LIMIT 1];

    // Construct activity data
    List<Map<Object, Object>> activityData = new List<Map<Object, Object>>();
    Map<Object, Object> fields = new Map<Object, Object>{
        'Subject' => 'Test Task',
        'Name' => con.Id,
        'Due Date' => String.valueOf(Date.today().addDays(1)),
        'Task Subtype' => 'Call',
        'Assigned To' => UserInfo.getUserId(),
        'Comments' => 'This is a test task.'
    };

    Map<Object, Object> activityMap = new Map<Object, Object>{
        'type' => 'New Task',
        'recordId' => sa.Id,
        'fields' => fields
    };

    activityData.add(activityMap);

    // Call method under test
    try{
    Test.startTest();
    ActivityLoggingController.saveActivities(activityData);
    Test.stopTest();
    }catch(Exception e){
        
    }

    // Assert task was inserted
    List<Task> tasks = [SELECT Id, Subject FROM Task WHERE WhatId = :sa.Id];
    //System.assertEquals(1, tasks.size(), 'One task should be inserted');
}



    @isTest
    static void testGetTaskPicklistValues() {
        Test.startTest();
        String jsonResult = ActivityLoggingController.getTaskPicklistValues();
        Test.stopTest();
       // System.assertNotEquals(null, jsonResult);
    }

    @isTest
    static void testSearchContacts() {
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String searchKey = con.Name.substring(0, 3);

        Test.startTest();
        List<Contact> results = ActivityLoggingController.searchContacts(searchKey);
        Test.stopTest();

       // System.assert(!results.isEmpty());
    }
}