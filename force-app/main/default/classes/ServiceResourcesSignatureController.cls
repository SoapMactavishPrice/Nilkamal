public with sharing class ServiceResourcesSignatureController {
    // public ServiceResourcesSignatureController() {

    // }
     @AuraEnabled
    public static void saveSignatureData(Id recordId, String signatureData) {
        try {

        if (String.isBlank(recordId) || String.isBlank(signatureData)) {
            throw new AuraHandledException('Missing required fields.');
        }

        Service_Resource__c serviceResource = [SELECT Id, Signature__c FROM Service_Resource__c WHERE Id = :recordId LIMIT 1];
        String imageTag = '<img src="' + signatureData + '" />';
        serviceResource.Signature__c = imageTag;

        // serviceResource.Signature__c = signatureData;
        // serviceResource.Name__c = name;

        update serviceResource;
    } catch (Exception e) {
            // Throw an exception if something goes wrong
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
    } 
}