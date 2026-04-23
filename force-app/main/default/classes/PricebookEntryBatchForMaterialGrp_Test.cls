@isTest
private class PricebookEntryBatchForMaterialGrp_Test {

    public class MockIntegrationHandler implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void setupTestData() {
        Item_Group_Master__c itemGroup = new Item_Group_Master__c(
            Name = 'Test Group',
            Item_Group_Code__c = 'IG1001'
        );
        insert itemGroup;

        Product2 p = new Product2(
            Name = 'Product Test',
            ProductCode = 'PC001',
            IsActive = true,
            Item_Group__c = itemGroup.Id
        );
        insert p;
    }

    @isTest
    static void testBatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockIntegrationHandler());

        setupTestData();

        Test.startTest();
        Database.executeBatch(new PricebookEntryBatchForMaterialGrp(), 1);
        Test.stopTest();

        System.debug('Batch executed successfully.');
    }
}