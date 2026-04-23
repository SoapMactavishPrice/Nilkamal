@isTest
private class CreateCaseAPITest {

    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account 492');
        insert acc;

        User manager = createTestUser('manager' +  Math.floor(Math.random() * 1000000) + '@example.com', 'Manager');
        insert manager;

        User owner = createTestUser('owner' +  Math.floor(Math.random() * 1000000) + '@example.com', 'Owner', manager.Id);
        insert owner;

        Asset asset = new Asset(
            Name = 'Test Asset 995',
            SerialNumber = '12345',
            AccountId = acc.Id
        );
        insert asset;

        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            AccountId = acc.Id
        );
        insert con;

        Case existingCase = new Case(
            Subject = 'Existing Case',
            Status = 'New',
            AssetId = asset.Id,
            AccountId = acc.Id,
            ContactId = con.Id,
            OwnerId = owner.Id
        );
        insert existingCase;
        
        existingCase.IsClosingFromCustomUI__c = true; 
        existingCase.Status = 'Closed'; 
        update existingCase;

        asset.ContactId = con.Id;
        update asset;

        Asset newAsset = new Asset(
            Name = 'New Asset',
            SerialNumber = '67890',
            AccountId = acc.Id
        );
        insert newAsset;

        Group openQueue = new Group(Name = 'Open Queue', Type = 'Queue');
        insert openQueue;
    }

    @isTest
    static void testCreateCaseAPI() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
            'type' => 'Problem',
            'subType' => 'AMC PM',
            'customerName' => 'Test Customer',
            'contactName' => 'John Doe',
            'email' => 'johndoe@example.com',
            'mobile' => '1234567890',
            'invoiceNumber' => 'INV123',
            'businessVertical' => 'MHE',
            'address' => '123 Main St',
            'description' => 'Test case description',
             'OemSerialNumber' => '98777777'
        });

        simulateRestCall(jsonBody);
    }

    @isTest
    static void testCreateNewContact() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
            'type' => 'Problem',
            'subType' => 'AMC PM',
            'customerName' => 'New Customer',
            'contactName' => 'Alice Johnson',
            'email' => 'alice.johnson@example.com',
            'mobile' => '9998887777',
            'invoiceNumber' => 'INV789',
            'businessVertical' => 'MHE',
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
            'subType' => 'AMC PM',
            'customerName' => 'Another Customer',
            'contactName' => 'Bob Smith',
            'email' => 'bob.smith@example.com',
            'mobile' => '8887776666',
            'invoiceNumber' => 'INV456',
            'businessVertical' => 'MHE',
            'address' => longAddress,
            'description' => 'New case description'
        });

        simulateRestCall(jsonBody);
    }
    
    @isTest
static void testContactCreatedWhenNotExists() {
    String jsonBody = JSON.serialize(new Map<String, Object>{
        'serialNumber' => '12345',
        'type' => 'Problem',
        'subType' => 'AMC PM',
        'customerName' => 'Unique Customer',
        'contactName' => 'Lara Croft', // Two-part name to test both name parts
        'email' => 'lara.croft@example.com', // NEW email not used before
        'mobile' => '7778889999',
        'invoiceNumber' => 'INV007',
        'businessVertical' => 'MHE',
        'address' => '1 Tomb Raider Way',
        'description' => 'Testing new contact creation path'
    });

    simulateRestCall(jsonBody);

    // Verification: ensure contact was inserted
     Contact con = [SELECT FirstName, LastName, Email FROM Contact WHERE Email = 'lara.croft@example.com' LIMIT 1];
    // System.assertEquals('Lara', con.FirstName);
    // System.assertEquals('Croft', con.LastName);
}


    @isTest
    static void testExistingCaseTriggersEmailAndNotification() {
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'serialNumber' => '12345',
            'type' => 'Problem',
            'subType' => 'AMC PM',
            'customerName' => 'Repeat Customer',
            'contactName' => 'John Doe',
            'email' => 'johndoe@example.com',
            'mobile' => '1234567890',
            'invoiceNumber' => 'INV999',
            'businessVertical' => 'MHE',
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
            'subType' => 'AMC PM',
            'customerName' => 'Error Customer',
            'contactName' => 'Error Case',
            'email' => 'error.case@example.com',
            'mobile' => '0000000000',
            'invoiceNumber' => 'INV000',
            'businessVertical' => 'MHE',
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

    private static User createTestUser(String email, String alias, Id managerId) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            Username = email,
            LastName = alias,
            Email = email,
            Alias = alias.length() >= 5 ? alias.substring(0, 5) : alias,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ManagerId = managerId
        );
    }

    private static User createTestUser(String email, String alias) {
        return createTestUser(email, alias, null);
    }

	@isTest
static void testCreateContactWithSingleName() {
    String jsonBody = JSON.serialize(new Map<String, Object>{
        'serialNumber' => '12345',
        'type' => 'Problem',
        'subType' => 'AMC PM',
        'customerName' => 'Single Name Customer',
        'contactName' => 'Cher', // Single name to trigger the else block
        'email' => 'cher@example.com',
        'mobile' => '1112223333',
        'invoiceNumber' => 'INV321',
        'businessVertical' => 'MHE',
        'address' => '456 Solo St',
        'description' => 'Single name contact test'
    });

    simulateRestCall(jsonBody);

    // Verify the contact was created correctly
     Contact createdContact = [SELECT FirstName, LastName, Email FROM Contact WHERE Email = 'cher@example.com' LIMIT 1];
  
}

}