public with sharing class FieldServiceTroubleshootingController {

    @AuraEnabled(cacheable=true)
    public static Object searchForErrorCode(String searchTerm) {
        try {
            searchTerm = '%'+searchTerm+'%';
            return [SELECT Id, Name, Product_Name__c //, Error_Code__c, Programmer_LCD_Display__c, Possible_Cause__c
                    FROM Troubleshooting_Master__c
                    WHERE product_Name__c LIKE :searchTerm OR Error_Code__c LIKE :searchTerm
                    ORDER BY Product_Name__c, Error_Code__c];
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}