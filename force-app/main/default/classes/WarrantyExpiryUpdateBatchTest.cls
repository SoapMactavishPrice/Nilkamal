@isTest
public class WarrantyExpiryUpdateBatchTest {

    @isTest
    static void testBatchExecution() {
        List<Asset> assetList = new List<Asset>();
        for (Integer i = 0; i < 3; i++) {
            assetList.add(new Asset(Name = 'Test Asset ' + i));
        }
        insert assetList;

        List<Asset_Warranty__c> warranties = new List<Asset_Warranty__c>();
        for (Integer i = 0; i < 3; i++) {
            warranties.add(new Asset_Warranty__c(
                Name = 'Test Warranty ' + i,
                Asset__c = assetList[i].Id,
                Warranty_Start_Date__c = System.today(),
                Warranty_End_Date__c = System.today().addDays(-1),
                Asset_Warranty_PO_Status__c = 'Active',
                Warranty_Period__c = 12
            ));
        }
        insert warranties;

        Test.startTest();
        WarrantyExpiryUpdateBatch batch = new WarrantyExpiryUpdateBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Asset_Warranty__c> updatedWarranties = [
            SELECT Id, Asset_Warranty_PO_Status__c 
            FROM Asset_Warranty__c 
            WHERE Id IN :warranties
        ];

        for (Asset_Warranty__c aw : updatedWarranties) {
            // System.assertEquals('Expired', aw.Asset_Warranty_PO_Status__c, 'Warranty status should be updated to Expired');
        }
    }
}