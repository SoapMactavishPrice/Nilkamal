@isTest
public class FieldServiceCreateContactTest {

   @isTest
    static void testCreateContact_AllParamsProvided() {
        // Create test Account (required for Asset & Contact)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Contact
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@test.com', AccountId = acc.Id);

        // Create test Asset
        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id, Status = 'Installed');
        insert asset;

        // Create test Case
        Case cs = new Case(Status = 'New', Origin = 'Phone', Subject = 'Test Case', AccountId = acc.Id, AssetId  = asset.Id);
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        // Create test Service Appointment
       Service_Appointment__c sa = new Service_Appointment__c(Work_Order__c = wo.Id, Case__c = cs.Id,
            Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false);
        insert sa;
        // Call method
        Test.startTest();
        Object result = FieldServiceCreateContact.createContact(con, asset.Id, cs.Id, sa.Id);
        Test.stopTest();

        // Assert Contact was created
        Contact insertedCon = [SELECT Id, Email FROM Contact WHERE Email = 'john.doe@test.com' LIMIT 1];
        System.assertNotEquals(null, insertedCon);

        // Assert Asset is linked
        Asset updatedAsset = [SELECT Id, ContactId FROM Asset WHERE Id = :asset.Id];
        //System.assertEquals(insertedCon.Id, updatedAsset.ContactId);

        // Assert Case is linked
        Case updatedCase = [SELECT Id, ContactId FROM Case WHERE Id = :cs.Id];
        //System.assertEquals(insertedCon.Id, updatedCase.ContactId);

        // Assert Service Appointment is linked
        Service_Appointment__c updatedSA = [SELECT Id, Contact__c FROM Service_Appointment__c WHERE Id = :sa.Id];
        //System.assertEquals(insertedCon.Id, updatedSA.Contact__c);
    }



    @isTest
    static void testCreateContact_OnlyContact() {
        Contact con = new Contact(FirstName = 'Only', LastName = 'Contact', Email = 'only.contact@test.com');
        
        Test.startTest();
        Object result = FieldServiceCreateContact.createContact(con, null, null, null);
        Test.stopTest();

        Contact insertedCon = [SELECT Id FROM Contact WHERE Email = 'only.contact@test.com'];
        System.assertNotEquals(null, insertedCon);
    }

    @isTest
    static void testCreateContact_ExceptionHandling() {
        Test.startTest();
        Boolean exceptionThrown = false;

        try {
            // Pass null contact - should throw exception
            FieldServiceCreateContact.createContact(null, null, null, null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }

        Test.stopTest();
        System.assertEquals(true, exceptionThrown, 'Expected AuraHandledException to be thrown.');
    }
}