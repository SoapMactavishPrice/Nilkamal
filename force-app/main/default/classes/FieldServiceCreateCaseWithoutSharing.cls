public without sharing class FieldServiceCreateCaseWithoutSharing {

    public static Asset getAssetDetails(String assetId) {
        try {
            return [
                SELECT Id, Name, SerialNumber, End_Customer__c, End_Customer__r.Pan_No__c, ContactId, Business_Vertical__c, Pin_Code_Master__c, Territory_Master__c, Asset_Category__c,Type__c,
                (
                    SELECT Id, CaseNumber, Status, Owner.Name, CreatedDate
                    FROM Cases
                    WHERE IsClosed = false AND Type != 'Installation' AND Type != 'Preventive Maintenance'
                    ORDER BY CreatedDate DESC LIMIT 1
                ),
                (
                    SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Asset_Warranty_PO_Status__c
                    FROM Asset_Warranty__r
                    WHERE Asset_Warranty_PO_Status__c = 'Active'
                ),
                (
                    SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Asset_AMC_PO_Status__c, Product_Category_Type__c
                    FROM Asset_AMCs__r
                    WHERE Asset_AMC_PO_Status__c = 'Active'
                )
                FROM Asset
                WHERE Id = :assetId
            ];
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}