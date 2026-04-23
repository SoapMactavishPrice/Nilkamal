public with sharing class AMCListDataController {

    @AuraEnabled
    public static String getAssetRecords() {
        List<Map<String, Object>> assetWrapperList = new List<Map<String, Object>>();

        try {
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            System.debug('Starting the getAssetRecords method.');
            List<Asset> assets = [
                SELECT Id, Name, Account.Name, SerialNumber, Invoice_Number__c, ContactId, Contact.Name, Business_Vertical__c
                FROM Asset
                WHERE Pin_Code_Master__c IN :pincodeIds
            ];

            System.debug('Assets retrieved: ' + assets);

            if (assets.isEmpty()) {
                System.debug('No assets found.');
                return JSON.serialize(assetWrapperList);
            }

            List<Asset_Warranty__c> assetWarranties = [
                SELECT Id, Asset__c, Date_of_Commissioning__c, Warranty_Start_Date__c, Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__c IN :assets AND Warranty_End_Date__c > TODAY
            ];

            System.debug('Asset warranties retrieved: ' + assetWarranties);

            List<Asset_AMC__c> assetAMCs = [
                SELECT Id, Asset__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__c IN :assets AND AMC_End_Date__c > TODAY

            ];

            System.debug('Asset AMCs retrieved: ' + assetAMCs);

            Map<Id, List<Asset_Warranty__c>> warrantiesByAssetId = new Map<Id, List<Asset_Warranty__c>>();
            Map<Id, List<Asset_AMC__c>> amcsByAssetId = new Map<Id, List<Asset_AMC__c>>();

            for (Asset_Warranty__c warranty : assetWarranties) {
                if (!warrantiesByAssetId.containsKey(warranty.Asset__c)) {
                    warrantiesByAssetId.put(warranty.Asset__c, new List<Asset_Warranty__c>());
                }
                warrantiesByAssetId.get(warranty.Asset__c).add(warranty);
            }

            System.debug('Warranties by Asset ID: ' + warrantiesByAssetId);

            for (Asset_AMC__c amc : assetAMCs) {
                if (!amcsByAssetId.containsKey(amc.Asset__c)) {
                    amcsByAssetId.put(amc.Asset__c, new List<Asset_AMC__c>());
                }
                amcsByAssetId.get(amc.Asset__c).add(amc);
            }

            System.debug('AMCs by Asset ID: ' + amcsByAssetId);

            for (Asset asset : assets) {
                List<Asset_Warranty__c> warranties = warrantiesByAssetId.get(asset.Id);
                List<Asset_AMC__c> amcs = amcsByAssetId.get(asset.Id);
                if ((warranties != null && !warranties.isEmpty()) || (amcs != null && !amcs.isEmpty())) {

                    Map<String, Object> assetMap = new Map<String, Object>();
                    assetMap.put('asset', asset);
                    assetMap.put('warranties', warranties);
                    assetMap.put('amcs', amcs);

                    assetWrapperList.add(assetMap);
                }
            }

            System.debug('Final Asset Data as Map: ' + assetWrapperList);

        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while fetching asset records.');
        }

        return JSON.serialize(assetWrapperList);
    }


}