public with sharing class FieldServiceAssetListController {

    @AuraEnabled(cacheable=true)
    public static Object getCountOfAssets() {
        try {
            // Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            String warrantyQuery = 'SELECT COUNT() FROM Asset_Warranty__c WHERE Asset__r.Type__c IN (\'Within Warranty\') AND Warranty_Start_Date__c <= TODAY AND Warranty_End_Date__c >= TODAY';
            String amcQuery = 'SELECT COUNT() FROM Asset_AMC__c WHERE Asset__r.Type__c IN (\'Within AMC\', \'Within CAMC\') AND AMC_Start_Date__c <= TODAY AND AMC_End_Date__c >= TODAY';
            String assetCount = 'SELECT COUNT() FROM Asset WHERE Type__c != \'Scraped\' ';
            string rentalAssetCount ='SELECT COUNT() FROM Asset WHERE Type__c = \'Rental\' AND Business_Vertical__c = \'Printer\' ';
             String assetDetailsQuery = 'SELECT Id, Name, Account.Name, Pin_Code_Master__r.Name, Type__c, ' +
                               '(SELECT Id, Warranty_Start_Date__c, Warranty_End_Date__c FROM Asset_Warranty__r ORDER BY Warranty_Start_Date__c DESC LIMIT 1), ' +
                               '(SELECT Id, AMC_Start_Date__c, AMC_End_Date__c FROM Asset_AMCs__r ORDER BY AMC_Start_Date__c DESC LIMIT 1) ' +
                               'FROM Asset ' +
                               'WHERE Type__c != \'Scraped\'';
    
            List<Asset> assetDetails = Database.query(assetDetailsQuery);

            return new Map<String, Object> {
                'warrantyCount' => Database.countQuery(warrantyQuery),
                'amcCount' => Database.countQuery(amcQuery),
                'assetCount' => Database.countQuery(assetCount),
                'rentalAssetCount' => Database.countQuery(rentalAssetCount),
                'expiredAssetCount' => assetDetails.size()
            };
        }
        catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }



    @AuraEnabled
    public static Object getAssetsUnderWarrantyOrAMCList(String searchString, String target, Integer offset, Integer lmt, String sortBy, String sortDirection) {
        try {
            // Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();


            String queryString = '';


            List<String> assetTypes = new List<String>();
            if(target == 'AssetsUnderWarranty') {
                assetTypes.add('Within Warranty');

                queryString = 'SELECT Id, Warranty_Start_Date__c, Warranty_End_Date__c, ' +
                            'Asset__c, Asset__r.Name, Asset__r.Account.Name, Asset__r.Pin_Code_Master__r.Name ' +
                            'FROM Asset_Warranty__c ' +
                            'WHERE Asset__r.Type__c IN :assetTypes AND Warranty_End_Date__c >= TODAY AND Warranty_Start_Date__c <= TODAY ';
            }
            else if(target == 'AssetsUnderAMC') {
                assetTypes.add('Within AMC');
                assetTypes.add('Within CAMC');

                queryString = 'SELECT Id, AMC_Start_Date__c, AMC_End_Date__c, ' +
                            'Asset__c, Asset__r.Name, Asset__r.Account.Name, Asset__r.Pin_Code_Master__r.Name ' +
                            'FROM Asset_AMC__c ' +
                            'WHERE Asset__r.Type__c IN :assetTypes AND AMC_End_Date__c >= TODAY AND AMC_Start_Date__c <= TODAY ';
            }

            if(String.isNotBlank(searchString)) {
                searchString = '%' + searchString + '%';
                queryString += 'AND (Asset__r.Product2.Name LIKE :searchString OR Asset__r.Name LIKE :searchString OR Asset__r.Account.Name LIKE :searchString OR Asset__r.Pin_Code_Master__r.Name LIKE :searchString) ';
            }
            queryString += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' LIMIT :lmt OFFSET :offset ';

            System.debug('queryString: ' + queryString);

            return Database.query(queryString);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Object getTotalRentalAssets(String searchString, String target, Integer offset, Integer lmt, String sortBy, String sortDirection) { 
        try {
            // Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();
            String queryString = 'SELECT Id, Name, Account.Name, Pin_Code_Master__r.Name, Type__c ' +
                            'FROM Asset ' +
                            'WHERE Type__c IN (\'Rental\') And Business_Vertical__c = \'Printer\' ';

            if(String.isNotBlank(searchString)) {
                searchString = '%' + searchString + '%';
                queryString += 'AND (Product2.Name LIKE :searchString OR SerialNumber LIKE :searchString OR Account.Name LIKE :searchString OR Pin_Code_Master__r.Name LIKE :searchString) ';
            }
            queryString += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' LIMIT :lmt OFFSET :offset ';

            System.debug('queryString: ' + queryString);

            return Database.query(queryString);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Object getExpiredAssetList(String searchString, Integer offset, Integer lmt, String sortBy, String sortDirection) {
        try {
            // Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            String queryString = 'SELECT Id, Name, Account.Name, Pin_Code_Master__r.Name, Type__c, ' +
                            '(SELECT Id, Warranty_Start_Date__c, Warranty_End_Date__c FROM Asset_Warranty__r ORDER BY Warranty_Start_Date__c DESC LIMIT 1), '+
                            '(SELECT Id, AMC_Start_Date__c, AMC_End_Date__c FROM Asset_AMCs__r ORDER BY AMC_Start_Date__c DESC LIMIT 1) '+
                            'FROM Asset ' +
                            'WHERE Type__c != \'Scraped\' AND (Warranty_End_Date__c < TODAY OR AMC_End_Date__c < TODAY) ';

            if(String.isNotBlank(searchString)) {
                searchString = '%' + searchString + '%';
                queryString += 'AND (Product2.Name LIKE :searchString OR SerialNumber LIKE :searchString OR Account.Name LIKE :searchString OR Pin_Code_Master__r.Name LIKE :searchString) ';
            }
            queryString += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' LIMIT :lmt OFFSET :offset ';

            System.debug('queryString: ' + queryString);

            return Database.query(queryString);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Object getTotalAssetList(String searchString, Integer offset, Integer lmt, String sortBy, String sortDirection) {
        try {
            // Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            String queryString = 'SELECT Id, Name, Account.Name, Pin_Code_Master__r.Name, Type__c, ' +
                            '(SELECT Id, Warranty_Start_Date__c, Warranty_End_Date__c FROM Asset_Warranty__r ORDER BY Warranty_Start_Date__c DESC LIMIT 1), '+
                            '(SELECT Id, AMC_Start_Date__c, AMC_End_Date__c FROM Asset_AMCs__r ORDER BY AMC_Start_Date__c DESC LIMIT 1) '+
                            'FROM Asset ' +
                            'WHERE Type__c != \'Scraped\' ';

            if(String.isNotBlank(searchString)) {
                searchString = '%' + searchString + '%';
                queryString += 'AND (Product2.Name LIKE :searchString OR SerialNumber LIKE :searchString OR Account.Name LIKE :searchString OR Pin_Code_Master__r.Name LIKE :searchString) ';
            }
            queryString += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' LIMIT :lmt OFFSET :offset ';

            System.debug('queryString: ' + queryString);

            return Database.query(queryString);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getApprovalItemsWithCount() {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Id currentUserId = UserInfo.getUserId();
    
            List<Id> delegateApproverIds = new List<Id>();
            for(User u : [SELECT Id FROM User WHERE delegatedApproverId = :currentUserId]) {
                delegateApproverIds.add(u.Id);
            }

            
    
            List<ProcessInstanceWorkitem> items = [
                SELECT Id,
                       ProcessInstanceId,
                       OriginalActorId,
                       OriginalActor.Name,
                       ActorId,
                       Actor.Name,
                       CreatedDate,
                       ProcessInstance.TargetObject.Name
                FROM ProcessInstanceWorkitem
                WHERE OriginalActorId = :currentUserId OR OriginalActorId IN :delegateApproverIds
            ];
    
            result.put('items', items);
            result.put('count', items.size());
    
        } catch (Exception e) {
            System.debug('Error in getApprovalItemsWithCount: ' + e.getMessage());
            result.put('items', new List<ProcessInstanceWorkitem>());
            result.put('count', 0);
        }
    
        return result;
    }


}