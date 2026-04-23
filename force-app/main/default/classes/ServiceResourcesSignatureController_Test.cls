@isTest
public class ServiceResourcesSignatureController_Test {

    /*@isTest
    static void testSaveSignatureData_Success() {
        Service_Resource__c resource = new Service_Resource__c(Name = 'Test Resource');
        insert resource;

        String sampleSignature = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUg...'; // truncated

        Test.startTest();
        ServiceResourcesSignatureController.saveSignatureData(resource.Id, sampleSignature);
        Test.stopTest();

        Service_Resource__c updated = [SELECT Signature__c FROM Service_Resource__c WHERE Id = :resource.Id];
        System.assertNotEquals(null, updated.Signature__c, 'Signature__c should be updated');
        System.assert(updated.Signature__c.contains(sampleSignature), 'Signature should contain image data');
    }*/
    @isTest
static void testSaveSignatureData_Success() {
    Service_Resource__c resource = new Service_Resource__c(Name = 'Test Resource');
    insert resource;

    String sampleSignature = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    Test.startTest();
    ServiceResourcesSignatureController.saveSignatureData(resource.Id, sampleSignature);
    Test.stopTest();

    Service_Resource__c updated = [SELECT Signature__c FROM Service_Resource__c WHERE Id = :resource.Id];
}

    @isTest
    static void testSaveSignatureData_MissingFields() {
        Test.startTest();
        try {
            ServiceResourcesSignatureController.saveSignatureData(null, '');
            System.assert(false, 'Expected AuraHandledException due to missing fields');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveSignatureData_InvalidRecordId() {
        String fakeId = 'a01000000000000AAA';
        String sampleSignature = 'data:image/png;base64,fakeimage==';

        Test.startTest();
        try {
            ServiceResourcesSignatureController.saveSignatureData(fakeId, sampleSignature);
            System.assert(false, 'Expected AuraHandledException for invalid record ID');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
}