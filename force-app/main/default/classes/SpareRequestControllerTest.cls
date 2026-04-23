@isTest
public class SpareRequestControllerTest {
    
    @isTest
    static void testGetSpareReturns() {
        List<Spare_Return__c> testData = new List<Spare_Return__c>();
        for (Integer i = 0; i < 5; i++) {
            testData.add(new Spare_Return__c(Name = 'Test Spare ' + i, Item_Description__c = 'Item ' + i));
        }
        insert testData;

        Test.startTest();
        List<Spare_Return__c> result = SpareRequestController.getSpareReturns();
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Spare returns should be returned');
        System.assert(result[0].Name.startsWith('Test Spare'), 'Result should include test data');
    }

    @isTest
    static void testUpdateSpareReturns() {
        Spare_Return__c sr = new Spare_Return__c(Name = 'Original Spare', Item_Description__c = 'Original Item');
        insert sr;

        sr.Item_Description__c = 'Updated Description';
        List<Spare_Return__c> updateList = new List<Spare_Return__c>{ sr };

        Test.startTest();
        SpareRequestController.updateSpareReturns(updateList);
        Test.stopTest();

        Spare_Return__c updated = [SELECT Item_Description__c FROM Spare_Return__c WHERE Id = :sr.Id];
        System.assertEquals('Updated Description', updated.Item_Description__c, 'The item description should be updated');
    }
}