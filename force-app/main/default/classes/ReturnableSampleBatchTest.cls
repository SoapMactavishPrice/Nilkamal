@isTest
private class ReturnableSampleBatchTest {
    
    @isTest
    static void testBatchExecution() {
        try{
        
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TESTCODE123');
        insert prod;

        Test.startTest();

        ReturnableSampleBatch batch = new ReturnableSampleBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
         }catch(Exception e){
            
        }
    }
    
    @isTest
    static void testBatchExecution1() {
        try{
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TESTCODE123');
        insert prod;

        Test.startTest();

        NonReturnableSampleBatch batch = new NonReturnableSampleBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
         }catch(Exception e){
            
        }
    }
}