/**
 * @author Aditya Zagade
 * @since 10 Dec 2024
 *
 * @group Field Service
 */
public with sharing class FieldServiceCreateCaseController {

    /**
     * @description Method to get Case Priority metadata
     * @return `List<Case_Priority__mdt>`
     * @example
     * List<Case_Priority__mdt> casePriorities = FieldServiceCreateCaseController.getCasePriorities();
     */
    @AuraEnabled(cacheable=true)
    public static List<Case_Priority__mdt> getCasePriorities() {
        try {
            return [SELECT Id, DeveloperName, MasterLabel, Business_Vertical__c, Type__c, Case_Sub_Type__c, Case_Priority__c FROM Case_Priority__mdt];
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get assets by customer
     * @param accountId
     * @return  `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object assets = FieldServiceCreateCaseController.getAssetsByCustomer('0015g00000Ie2PfAAL');
     */
    @AuraEnabled(cacheable=true)
    public static Object getAssetsByCustomer(String accountId) {
        try {
            List<Asset> assets = [SELECT Id, Name, SerialNumber, Invoice__c, Invoice__r.Name,Type__c FROM Asset WHERE End_Customer__c = :accountId AND ParentId = null ORDER BY Invoice__r.Name, SerialNumber];
            return assets;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get Asset details
     * @param assetId
     * @return  `Asset`
     * @exception Throws an AuraHandledException
     * @example
     * Asset asset = FieldServiceCreateCaseController.getAssetDetails('a0d5g00000Ie2PfAAL');
     */
    @AuraEnabled
    public static Object getAssetDetails(String assetId) {
        try {
            Asset asset = FieldServiceCreateCaseWithoutSharing.getAssetDetails(assetId);

            List<Contact> contacts = [
                SELECT Id, Name, MobilePhone, Email
                FROM Contact
                WHERE AccountId = :asset.End_Customer__c OR (Account.Pan_No__c = :asset.End_Customer__r.Pan_No__c AND Account.Pan_No__c != null AND Account.Pan_No__c != 'DECLARATION')
                ORDER BY Name
            ];

            return new Map<String, Object> {
                'asset' => asset,
                'contacts' => contacts
            };
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to check if there is an existing open case for the asset
     * @param assetId
     * @return  `Boolean`
     * @exception Throws an AuraHandledException
     * @example
     * Case existingCase = FieldServiceCreateCaseController.checkForExistingCase('a0d5g00000Ie2PfAAL');
     */
    @AuraEnabled
    public static Case checkForExistingCase(String assetId) {
        try {
            List<Case> existingCase = [SELECT Id, CaseNumber, Status, Owner.Name, CreatedDate
                                    FROM Case
                                    WHERE AssetId = :assetId AND IsClosed = false
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1];
            return existingCase.isEmpty() ? null : existingCase[0];
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to get Account details
     * @param accountId
     * @return `Account`
     * @example
     * Account acc = FieldServiceCreateCaseController.getAccountDetails('a015g00000Ie2PfAAL');
     */
    @AuraEnabled
    public static Object getAccountDetails(String accountId) {
        try {
            Account acc =  [
                SELECT Id, Name, Street_House_Number__c, Street1__c, Street2__c, City__c, State__c, Country__c, Postal_code__c, SAP_Customer_code__c, Customer_Blocked__c, Pan_No__c
                FROM Account
                WHERE Id = :accountId
            ];

            List<Contact> contacts = [
                SELECT Id, Name, MobilePhone, Email
                FROM Contact
                WHERE AccountId = :accountId OR (Account.Pan_No__c = :acc.Pan_No__c AND Account.Pan_No__c != null AND Account.Pan_No__c != 'DECLARATION')
                ORDER BY Name
            ];

            return new Map<String, Object> {
                'account' => acc,
                'contacts' => contacts
            };
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to create case and return work order
     * @param caseRecord
     * @return  `string`
     * @exception Throws an AuraHandledException
     * @example
     * Case caseRecord = new Case();
     * caseRecord.Subject = 'Test';
     * caseRecord.Description = 'Test';
     * caseRecord.AccountId = '0015g00000Ie2PfAAL';
     * caseRecord.Division__c = 'Printer';
     * caseRecord.Type = 'Service';
     * string workOrderId = FieldServiceCreateCaseController.createCase(caseRecord);
     */
    @AuraEnabled
    public static string createCase(Case caseRecord) {
        try {
            insert caseRecord;

            return [SELECT Id FROM Work_Order__c WHERE Case__c = :caseRecord.Id].Id;
        }
        catch (DmlException e) {
            throw e;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getUserBusinessUnit() {
        // Query the current user using UserInfo.getUserId()
        User currentUser = [SELECT Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Return the Business Unit field value
        return currentUser.Business_Unit__c;
    }

}