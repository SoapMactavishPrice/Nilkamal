@isTest
public class AmcExprityUpdateBatchTest {
    @isTest
    static void testAmcExpiryBatch() {
        Date today = System.today();

        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        List<Asset_AMC__c> amcList = new List<Asset_AMC__c>();

        amcList.add(new Asset_AMC__c(
            Name = 'Expired AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = today.addMonths(-2),
            AMC_Period_In_Months__c = 1,
            AMC_End_Date__c = today.addDays(-1),
            Asset_AMC_PO_Status__c = 'Active',
            Product_Category_Type__c = 'AMC'
        ));

        amcList.add(new Asset_AMC__c(
            Name = 'Active AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = today.addDays(-5),
            AMC_Period_In_Months__c = 1,
            AMC_End_Date__c = today.addDays(25),
            Asset_AMC_PO_Status__c = 'Planned',
            Product_Category_Type__c = 'AMC'
        ));

        amcList.add(new Asset_AMC__c(
            Name = 'Planned AMC',
            Asset__c = testAsset.Id,
            AMC_Start_Date__c = today.addDays(10),
            AMC_Period_In_Months__c = 1,
            AMC_End_Date__c = today.addDays(40),
            Asset_AMC_PO_Status__c = 'Active',
            Product_Category_Type__c = 'AMC'
        ));

        insert amcList;

        Test.startTest();
        AmcExprityUpdateBatch batch = new AmcExprityUpdateBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        Map<String, Asset_AMC__c> results = new Map<String, Asset_AMC__c>();
        for (Asset_AMC__c amc : [SELECT Name, Asset_AMC_PO_Status__c FROM Asset_AMC__c WHERE Id IN :amcList]) {
            results.put(amc.Name, amc);
        }

        System.assertEquals('Expired', results.get('Expired AMC').Asset_AMC_PO_Status__c, 'Expired AMC should be Expired');
        System.assertEquals('Active', results.get('Active AMC').Asset_AMC_PO_Status__c, 'Active AMC should be Active');
        System.assertEquals('Planned', results.get('Planned AMC').Asset_AMC_PO_Status__c, 'Planned AMC should be Planned');
    }
}