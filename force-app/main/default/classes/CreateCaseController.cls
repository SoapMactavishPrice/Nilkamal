public without sharing class CreateCaseController {  

	/*
    @AuraEnabled
    public static Map<String, Object> fetchDataBySerialNumber(String serialNumber) {
        
        if (String.isBlank(serialNumber)) {
            throw new AuraHandledException('Serial number cannot be empty');
        }
        
        try {
            List<Asset> assets  = [SELECT Id, Name, Account.Name, SerialNumber,Invoice_Number__c,ContactId,Contact.Name,Business_Vertical__c
                                   FROM Asset
                                   WHERE SerialNumber = :serialNumber
                                   LIMIT 1];
            
            
            
            if (assets.isEmpty()) {
                throw new AuraHandledException('Asset with the specified serial number not found.');
            }
            
            Asset asset = assets[0];
            
            Asset_Warranty__c latestWarranty;
            String warrantyStatus = 'Inactive';
            List<Asset_Warranty__c> assetWarranties = [
                SELECT Id,Date_of_Commissioning__c,Warranty_Start_Date__c,Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__c = :asset.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            Date todayDate = System.today();
            
            if (!assetWarranties.isEmpty()) {
                latestWarranty = assetWarranties[0];
                // Date today = Date.today();
                // latestWarranty.Status__c = (latestWarranty.Warranty_End_Date__c != null && latestWarranty.Warranty_End_Date__c >= today) ? 'Active' : 'Inactive';
                if (latestWarranty.Warranty_End_Date__c != null && latestWarranty.Warranty_End_Date__c >= todayDate) {
                    warrantyStatus = 'Active';
                }
            }
            
            Asset_AMC__c latestAMC;
            String amcStatus = 'Inactive';
            List<Asset_AMC__c> assetAMCs = [
                SELECT Id,AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__c = :asset.Id
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (!assetAMCs.isEmpty()) {
                latestAMC = assetAMCs[0];
                if (latestAMC.AMC_End_Date__c != null && latestAMC.AMC_End_Date__c >= todayDate) {
                    amcStatus = 'Active';
                }
            }
            
            Map<String, Object> response = new Map<String, Object>();
            response.put('asset', asset);
            response.put('assetWarranty', latestWarranty);
            response.put('warrantyStatus', warrantyStatus);
            response.put('assetAMC', latestAMC);
            response.put('amcStatus', amcStatus);
            return response;
            
            // return new AssetWrapper(asset, assetWarranties, assetAMCs);
            
            
            //return asset;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching data: ' + e.getMessage() + ' (Line: ' + e.getLineNumber() + ')');
        }
    }
    
    
    public class AssetWrapper {
        @AuraEnabled public Asset asset;
        @AuraEnabled public List<Asset_Warranty__c> assetWarranties;
        @AuraEnabled public List<Asset_AMC__c> assetAMCs;
        
        
        public AssetWrapper(Asset asset, List<Asset_Warranty__c> assetWarranties,List<Asset_AMC__c> assetAMCs) {
            this.asset = asset;
            this.assetWarranties = assetWarranties;
            this.assetAMCs = assetAMCs;
            
        }
    }
    
    
    @AuraEnabled
    public static Asset fetchDataByInvoiceAndSerialNumber(String invoiceNumber, String serialNumber) {
        try {
            Asset asset;
            
            if (String.isNotBlank(serialNumber) && String.isNotBlank(invoiceNumber)) {
                asset = [SELECT Id, Name, SerialNumber, Invoice_Number__c, Account.Name
                         FROM Asset
                         WHERE SerialNumber = :serialNumber 
                         AND Invoice_Number__c = :invoiceNumber
                         LIMIT 1];
                
            } else if (String.isNotBlank(serialNumber)) {
                asset = [SELECT Id, Name, SerialNumber, Invoice_Number__c, Account.Name
                         FROM Asset
                         WHERE SerialNumber = :serialNumber
                         LIMIT 1];
                
            } else if (String.isNotBlank(invoiceNumber)) {
                asset = [SELECT Id, Name, SerialNumber, Invoice_Number__c, Account.Name
                         FROM Asset
                         WHERE Invoice_Number__c = :invoiceNumber
                         LIMIT 1];
                
            } else {
                // throw new AuraHandledException('Both Serial Number and Invoice Number cannot be blank.');
                return null;
            }
            
            return asset;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching asset: ' + e.getMessage() +e.getLineNumber());
        }
    }
    
    
    @AuraEnabled
    public static void saveCaseData(Map<String, Object> caseData) {
        try {
            Case newCase = new Case();
            
            newCase.Description = (String) caseData.get('comment');
            newCase.Type = (String) caseData.get('issue');
            newCase.Location__c = (String) caseData.get('location');
            newCase.Division__c = (String) caseData.get('businessVertical');
            newCase.Priority = 'Medium';
            newCase.Origin = 'Web';
            newCase.Reason='New problem';
            newCase.Case_Comments__c = (String) caseData.get('serialNumber') + ' ' +(String) caseData.get('customerName') + ' ' +(String) caseData.get('invoiceNumber') + ' ' +(String) caseData.get('assetName') + ' ' +(String) caseData.get('name') + ' ' + (String) caseData.get('email') + ' ' + (String) caseData.get('contactNo');
            
            
            String assetId = (String) caseData.get('assetId');
            String contactId = (String) caseData.get('contactId');
            String email = (String) caseData.get('email');
            String contactNo = (String) caseData.get('contactNo');
            
            if (assetId != null) {
                newCase.AssetId = assetId;
            }
            // if(contactId != null){
            //     newCase.ContactId = contactId;
            // }
            if (contactId == null || contactId == '') {
                if (email != null || contactNo != null) {
                    List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email OR MobilePhone = :contactNo LIMIT 1];
                    if (!contacts.isEmpty()) {
                        newCase.ContactId = contacts[0].Id;
                    } else {
                        throw new AuraHandledException('No contact found with the provided email or phone number.');
                    }
                } else {
                    throw new AuraHandledException('No contact ID, email, or phone number provided.');
                }
            } else {
                newCase.ContactId = contactId;
            }
            
            
            insert newCase;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error saving case: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static Map<String, Object> verifyRecaptcha(String token) {
        String secretKey = '6LcN_dUqAAAAAAVHhMuBTpbBSE1w_0OxwI4SE6Es';
        String apiUrl = 'https://www.google.com/recaptcha/api/siteverify';
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody('secret=' + secretKey + '&response=' + token);
        
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if ((Boolean) jsonResponse.get('success')) {
                return new Map<String, Object>{ 'success' => true };
                    } else {
                        return new Map<String, Object>{ 'success' => false, 'message' => jsonResponse.get('error-codes') };
                            }
        } else {
            return new Map<String, Object>{ 'success' => false, 'message' => 'API call failed' };
                }
    }
	*/
    
}