@isTest
public class fieldServiceTransferAssetControllerTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(
            Name = 'Test Account',
            SAP_Customer_code__c = 'SAP123',
            Street_House_Number__c = '123',
            Street1__c = 'Main St',
            Street2__c = 'Suite 101',
            City__c = 'Cityville',
            State__c = 'CA',
            Postal_code__c = '12345',
            Country__c = 'USA'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'test@example.com',
            MobilePhone = '1234567890',
            AccountId = acc.Id
        );
        insert con;

        Asset ast = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            End_Customer__c = acc.Id,
            ContactId = con.Id,
            Ship_to_City__c = 'ShipCity',
            Bill_to_City__c = 'BillCity'
        );
        insert ast;

        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'New',
            AssetId = ast.Id,
              AccountId = acc.Id
        );
        insert cs;
    }

    @isTest
    static void testGetAssetDetails() {
        Asset ast = [SELECT Id FROM Asset LIMIT 1];
        Asset result = fieldServiceTransferAssetController.getAssetDetails(ast.Id);
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetCustomerDetails() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Account result = fieldServiceTransferAssetController.getCustomerDetails(acc.Id);
        System.assertEquals('Test Account', result.Name);
    }

    @isTest
    static void testGetContactDetails() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Contact result = fieldServiceTransferAssetController.getContactDetails(con.Id);
        System.assertEquals('Test Contact', result.Name);
    }
    
     @isTest
    static void testGetAccContactDetails() {
        Contact con = [SELECT Id,AccountId FROM Contact LIMIT 1];
        Contact result = fieldServiceTransferAssetController.getAccContactDetails(con.AccountId);
        System.assertEquals('Test Contact', result.Name);
    }


    @isTest
    static void testUpdateAssetWithoutCase() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Asset newAst = new Asset(
            Name = 'Asset No Case',
            AccountId = acc.Id,
            End_Customer__c = acc.Id,
            ContactId = con.Id
        );
        insert newAst;

        newAst.Bill_to_City__c = 'Updated City';

        Test.startTest();
        fieldServiceTransferAssetController.updateAsset(newAst);
        Test.stopTest();

        Asset updated = [SELECT Bill_to_City__c FROM Asset WHERE Id = :newAst.Id];
        System.assertEquals('Updated City', updated.Bill_to_City__c);
    }

}