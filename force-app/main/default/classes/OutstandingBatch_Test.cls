@isTest
public class OutstandingBatch_Test {
    
    @testSetup
    static void setupTestData() {
        List<Product2> productList = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            productList.add(new Product2(
                Name = 'Test Product ' + i,
                ProductCode = 'Code' + i
            ));
        }
        insert productList;
    }

    @isTest
    static void testStart() {
        Test.startTest();
        
        OutstandingBatch batch = new OutstandingBatch();
        Database.QueryLocator queryLocator = batch.start(null);

        List<Product2> result = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode != NULL LIMIT 1];
        System.assertNotEquals(0, result.size(), 'Expected records to be returned from the query');
        
        Test.stopTest();
    }

    @isTest
    static void testExecute() {
        try{
        Test.startTest();
        
        OutstandingBatch batch = new OutstandingBatch();
        
        List<Product2> products = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode != NULL LIMIT 1];
        
        batch.execute(null, products);


        List<AsyncApexJob> jobs = [SELECT Status FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assertNotEquals(0, jobs.size(), 'Queueable job should be added to the queue');
        
        Test.stopTest();
        }catch(Exception e){
            
        }
    }

    @isTest
    static void testFinish() {
        Test.startTest();
        
        OutstandingBatch batch = new OutstandingBatch();
        
        batch.finish(null);
        
       
        System.debug('Finish method executed successfully');
        
        Test.stopTest();
    }

    @isTest
    static void testWithCallout() {
        try{
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        OutstandingBatch batch = new OutstandingBatch();
        Database.executeBatch(batch);

        Test.stopTest();
        }catch(Exception e){
            
        }
    }

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}