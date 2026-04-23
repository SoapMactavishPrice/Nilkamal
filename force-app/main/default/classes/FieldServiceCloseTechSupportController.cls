public with sharing class FieldServiceCloseTechSupportController {

    @AuraEnabled
    public static String closeTechSupport(String recordId) {
        try {
            Case caseRecord = [SELECT Id, Tech_Support_Status__c,Technical_Support_Response_DateTime__c FROM Case WHERE Id = :recordId LIMIT 1];
            if(String.isBlank(caseRecord.Tech_Support_Status__c)) {
                return 'Technical Support request is not opened';
            }
            if(caseRecord.Tech_Support_Status__c == 'Closed by Tech Support	') {
                return 'Technical Support request is already closed';
            }
            else if(caseRecord.Tech_Support_Status__c == 'Closed by Tech Support') {
                return 'Technical Support request is already closed';
            }
            else {
                caseRecord.Tech_Support_Status__c = 'Closed by Tech Support';
                caseRecord.Technical_Support_Response_DateTime__c = System.now(); //09-12-2025
                update caseRecord;
                return 'Success';
            }
        }
        catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}