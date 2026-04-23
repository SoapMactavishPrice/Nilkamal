@IsTest
public class FieldServiceEditSerRequControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset ast = new Asset(Name = 'Test Asset 1', AccountId = acc.Id);
        insert ast;
        
        Case cs = new Case(Status = 'New', AccountId = acc.Id, Subject = 'Test Case',AssetId = ast.Id);
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        List<Service_Request__c> srs = new List<Service_Request__c>();
        for(Integer i = 0; i < 2; i++) {
            Service_Request__c sr = new Service_Request__c(
                Work_Order__c = wo.Id,
                Asset__c = ast.Id,
                Case__c = cs.Id
                
            );
            srs.add(sr);
        }
        insert srs;
    }
    
    @isTest
    static void testGetServiceRequestsByWorkOrder() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset ast = new Asset(Name = 'Test Asset 2', AccountId = acc.Id);
        insert ast;
        
        Case cs = new Case(Status = 'New', AccountId = acc.Id, Subject = 'Test Case', AssetId = ast.Id);
        insert cs;
        
        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;
        
        // Create Service Request linked to Work Order
        Service_Request__c sr = new Service_Request__c(
            Name = 'Test SR',
            Work_Order__c = wo.Id,
            Asset__c = ast.Id,
            Case__c = cs.Id
        );
        insert sr;
        
        Test.startTest();
        List<Service_Request__c> results = FieldServiceEditServiceRequestController.getServiceRequestsByWorkOrder(wo.Id);
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should return Service Requests for Work Order');
    }
    
    @isTest
    static void testDeleteServiceRequest() {
        Service_Request__c sr = [SELECT Id FROM Service_Request__c LIMIT 1];
        Test.startTest();
        FieldServiceEditServiceRequestController.deleteServiceRequest(sr.Id);
        Test.stopTest();
        
        List<Service_Request__c> deletedSRList = [SELECT Id FROM Service_Request__c WHERE Id = :sr.Id LIMIT 1];
        System.assertEquals(0, deletedSRList.size(), 'Service Request should be deleted');
        
    }
    @isTest
    static void testSaveServiceRequests() {
        List<Service_Request__c> srs = [SELECT Id, Price__c, Quantity__c FROM Service_Request__c LIMIT 2];
        
        for(Service_Request__c sr : srs) {
            sr.Price__c = 100;
            sr.Quantity__c = 5;
        }
        
        Test.startTest();
        FieldServiceEditServiceRequestController.saveServiceRequests(srs);
        Test.stopTest();
        
        List<Service_Request__c> updatedSRs = [SELECT Total_Value__c FROM Service_Request__c WHERE Id IN :srs];
        for(Service_Request__c sr : updatedSRs) {
            System.assertEquals(500, sr.Total_Value__c, 'Total_Value__c should be Price * Quantity');
        }
    }
    
    
    @isTest
    static void testGetWarrantyMapping() {
        //Map<Integer, Map<String, Integer>> result = FieldServiceEditServiceRequestController.getWarrantyMapping();
        Map<String, Map<String, Integer>> result = FieldServiceEditServiceRequestController.getWarrantyMapping();
        System.assertNotEquals(null, result, 'Warranty mapping result should not be null');
    }
    
}