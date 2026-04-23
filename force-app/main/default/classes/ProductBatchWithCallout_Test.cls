@isTest
private class ProductBatchWithCallout_Test {

    public class MockIntegrationHandler implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testProductBatchWithCallout() {
        Test.setMock(HttpCalloutMock.class, new MockIntegrationHandler());

        List<Product2> testProducts = new List<Product2>();
        for (Integer i = 1; i <= 1; i++) { // Only 1 record to avoid multiple batch contexts
            testProducts.add(new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'P00' + i,
                IsActive = true
            ));
        }
        insert testProducts;

        Test.startTest();
        Database.executeBatch(new ProductBatchWithCallout(), 1);
        Test.stopTest();

        System.debug('ProductBatchWithCallout test executed.');
    }
}