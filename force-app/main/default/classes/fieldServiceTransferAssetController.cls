public with sharing class fieldServiceTransferAssetController {

    @AuraEnabled
    public static Asset getAssetDetails(Id assetId) {
        return [
            SELECT Id, AccountId, End_Customer__c, ContactId,
            Bill_to_Address__c, Bill_to_City__c, Bill_to_Region__c, Bill_to_Pin__c, Bill_to_Country__c, Bill_to_Customer_Code__c,
            Ship_to_Address__c, Ship_to_City__c, Ship_to_Region__c, Ship_to_Pin__c, Ship_to_Country__c, Ship_to_Customer_Code__c,
            Contact.Name, Contact.Email, Contact.MobilePhone
            FROM Asset
            WHERE Id = :assetId];
    }

    @AuraEnabled
    public static Account getCustomerDetails(Id accountId) {
        return [
            SELECT Id, Name, SAP_Customer_code__c, Street_House_Number__c, Street1__c, Street2__c, City__c, State__c, Postal_code__c, Country__c
            FROM Account
            WHERE Id = :accountId];
    }

    @AuraEnabled
    public static Contact getContactDetails(Id contactId) {
        return [
            SELECT Id, Name, Email, MobilePhone
            FROM Contact
            WHERE Id = :contactId];
    }

    @AuraEnabled
    public static Contact getAccContactDetails(Id accId) {
        return [
            SELECT Id, Name, Email, MobilePhone
            FROM Contact
            WHERE AccountId = :accId Limit 1];
    }


    @AuraEnabled
    public static void updateAsset(Asset assetRecord) {
        try {
            List<Case> cases = [SELECT Id, CaseNumber, Owner.Name FROM Case WHERE IsClosed = false AND AssetId = :assetRecord.Id];
            if(cases.size() > 0) {
                throw new CustomException('There is open case for this asset, please close first. Case Number: ' + cases[0].CaseNumber + ' Assigned to: ' + cases[0].Owner.Name);
            }

            update assetRecord;
        }
        catch (Exception e) {
            System.debug('Error updating asset: ' + e.getMessage());
            throw new AuraHandledException('Error updating asset: ' + e.getMessage());
        }
    }

}