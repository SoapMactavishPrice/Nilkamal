@isTest
public class AccountTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        
        Pricebook2 pb = new Pricebook2(Name = 'Nilkamal Pricebook', IsActive = true);
        insert pb;

        Pin_Code_Master__c pin1 = new Pin_Code_Master__c(Name = '400001', Region__c = 'West', State__c = 'Maharashtra');
        Pin_Code_Master__c pin2 = new Pin_Code_Master__c(Name = '400002', Region__c = 'West', State__c = 'Maharashtra');
        insert new List<Pin_Code_Master__c>{pin1, pin2};
            
           Territory_Master__c territory = new Territory_Master__c(
    Name = 'North Zone',
    Region__c = 'Test Region' 
            );
            insert territory;

        Territory_Pincode_Mapping__c mapping1 = new Territory_Pincode_Mapping__c(
            Pin_Code_Master__c = pin1.Id,
            Territory_Master__c = territory.Id
        );
        insert mapping1;
    }

    @isTest
    static void testHandleTerritoryUpdate() {
        Pin_Code_Master__c pin = [SELECT Id, Name FROM Pin_Code_Master__c WHERE Name = '400001' LIMIT 1];

        Account acc = new Account(
            Name = 'Test Account',
            Pin_Code__c = pin.Id,
            Postal_Code__c = pin.Name
        );
        insert acc;

        Test.startTest();
        List<Account> accList = [SELECT Id, Pin_Code__c, Postal_Code__c FROM Account WHERE Id = :acc.Id];
        AccountTriggerHandler.handleTerritoryUpdate(accList, true, false);
        Test.stopTest();

        // Asserting updated values in memory
        //System.assertEquals('Territory001', accList[0].Territory_Master__c);
        //System.assertEquals('Maharashtra', accList[0].state__c);
    }

    @isTest
    static void testUpdatePriceList() {
        Account acc = new Account(Name = 'Price List Test Account');
        insert acc;

        List<Account> accList = [SELECT Id FROM Account WHERE Id = :acc.Id];

        Test.startTest();
        AccountTriggerHandler.updatePriceList(accList);
        Test.stopTest();

        System.assertNotEquals(null, accList[0].Pricelist__c);
    }

    @isTest
    static void testUpdatePinCode() {
        Pin_Code_Master__c pin = [SELECT Id, Name FROM Pin_Code_Master__c WHERE Name = '400002' LIMIT 1];

        Account acc = new Account(Name = 'PinCode Update Account', Postal_Code__c = pin.Name);
        insert acc;

        acc = [SELECT Id, Postal_Code__c FROM Account WHERE Id = :acc.Id];

        Map<Id, Account> oldMap = new Map<Id, Account>{acc.Id => acc};

        List<Account> updatedAccounts = new List<Account>{
            new Account(Id = acc.Id, Postal_Code__c = pin.Name)
        };

        Test.startTest();
        AccountTriggerHandler.updatePinCode(updatedAccounts, oldMap);
        Test.stopTest();

        System.assertEquals(pin.Id, updatedAccounts[0].Pin_Code__c);
    }

    @isTest
    static void testUpdatePinCodeWithInvalidPin() {
        Account acc = new Account(Name = 'Invalid Pincode', Postal_Code__c = '999999');
        insert acc;

        Map<Id, Account> oldMap = new Map<Id, Account>{acc.Id => acc};
        List<Account> accList = new List<Account>{
            new Account(Id = acc.Id, Postal_Code__c = '999999')
        };

        Test.startTest();
        try {
            AccountTriggerHandler.updatePinCode(accList, oldMap);
        } catch (Exception e) {
        }
        Test.stopTest();

        System.assertEquals(null, accList[0].Pin_Code__c);
    }
}