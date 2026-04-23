@isTest
public class CaseManagementTest {

    @testSetup
    static void setup() {
        // Query the Queue for Case named 'Open Queue'
        Group openQueue = [SELECT Id FROM Group WHERE Name = 'Open Queue' AND Type = 'Queue' LIMIT 1];

        // Create an Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset asset = new Asset(Name='Test1 Asset');
        insert asset;

        Contact cont = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Phone = '1234567890', AccountId = acc.Id);
        insert cont;

        // Create Case owned by Open Queue
        Case caseOwnedByQueue = new Case(
            Subject = 'Case owned by Open Queue',
            OwnerId = openQueue.Id,
            ContactId = cont.Id,
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id
            
        );
        insert caseOwnedByQueue;
        
        Asset asset1 = new Asset(Name='Test1 1Asset');
        insert asset1;

        // Create Case with OwnerId = null (System will assign default owner)
        Case caseWithNoOwner = new Case(
            Subject = 'Case with no owner',
            AccountId = acc.Id,
            Status = 'New',
            Origin = 'Email',
             AssetId = asset1.Id
        );
        insert caseWithNoOwner;
    }

    @isTest
    static void testGetOpenQueueCases() {
        List<Case> results = CaseManagement.getOpenQueueCases();
        System.assertNotEquals(0, results.size(), 'Expected some cases to be returned');

        for (Case c : results) {
            System.assertNotEquals(null, c.Subject, 'Subject should not be null');
        }
    }
}