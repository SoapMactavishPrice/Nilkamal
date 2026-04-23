public without sharing class AssetTriggerHandlerWithoutSharing {

    public static void validateBeforeAssetTransfer(List<Asset> assets, Map<Id, Asset> oldMap) {
        Boolean isAssetTransferred = false;
        Set<Id> assetIds = new Set<Id>();
        for(Asset asset : assets) {
            Asset oldAsset = oldMap.get(asset.Id);
            if(asset.AccountId != oldAsset.AccountId || asset.End_Customer__c != oldAsset.End_Customer__c || asset.ContactId != oldAsset.ContactId) {
                isAssetTransferred = true;
                assetIds.add(asset.Id);
            }
        }

        if(isAssetTransferred == false) {
            return;
        }

        Map<Id, List<Case>> assetWiseOpenCases = new Map<Id, List<Case>>();
        for(Case caseRecord : [SELECT Id, CaseNumber,Case.AssetId, Owner.Name FROM Case WHERE IsClosed = false AND AssetId IN :assetIds]) {
            if(!assetWiseOpenCases.containsKey(caseRecord.AssetId)) {
                assetWiseOpenCases.put(caseRecord.AssetId, new List<Case>());
            }
            assetWiseOpenCases.get(caseRecord.AssetId).add(caseRecord);
        }

        for(Asset asset : assets) {
            if(assetIds.contains(asset.Id)) {
                if(assetWiseOpenCases.containsKey(asset.Id)) {
                    String msg;
                    if(assetWiseOpenCases.get(asset.Id).size() == 1) {
                        msg = 'Open case is associated with this asset, please close first. Case Number: ' + assetWiseOpenCases.get(asset.Id)[0].CaseNumber + ' Assigned to: ' + assetWiseOpenCases.get(asset.Id)[0].Owner.Name;
                    }
                    if(assetWiseOpenCases.get(asset.Id).size() > 1) {
                        msg = 'There are multiple open cases associated with this asset, please close all cases first.';
                    }
                    asset.addError(msg);
                }
            }
        }
    }


    public static void pushOwnerToWarrantyAndAMC(List<Asset> newRecords, Map<Id, Asset> oldMap) {
        Set<Id> assetIdsWhereOwnerChanged = new Set<Id>();
        Map<Id, Id> assetOwnerMap = new Map<Id, Id>();
        for(Asset asset : newRecords) {
            if(asset.OwnerId != oldMap.get(asset.Id).OwnerId) {
                assetIdsWhereOwnerChanged.add(asset.Id);
            }
            assetOwnerMap.put(asset.Id, asset.OwnerId);
        }

        if(!assetIdsWhereOwnerChanged.isEmpty()) {
            List<Asset_Warranty__c> warrantiesToUpdate = new List<Asset_Warranty__c>();
            List<Asset_AMC__c> amcsToUpdate = new List<Asset_AMC__c>();

            for(Asset_Warranty__c warranty : [
                SELECT Id, OwnerId, Asset__c
                FROM Asset_Warranty__c
                WHERE Asset__c IN :assetIdsWhereOwnerChanged
            ]) {
                System.debug('Warranty: ' + assetOwnerMap.get(warranty.Asset__c));
                warranty.OwnerId = assetOwnerMap.get(warranty.Asset__c);
                warrantiesToUpdate.add(warranty);
            }

            for(Asset_AMC__c amc : [
                SELECT Id, OwnerId, Asset__c
                FROM Asset_AMC__c
                WHERE Asset__c IN :assetIdsWhereOwnerChanged
            ]) {
                System.debug('AMC: ' + assetOwnerMap.get(amc.Asset__c));
                amc.OwnerId = assetOwnerMap.get(amc.Asset__c);
                amcsToUpdate.add(amc);
            }

            if(!warrantiesToUpdate.isEmpty()) {
                //UPDATE warrantiesToUpdate;
                Database.update(warrantiesToUpdate, true, AccessLevel.SYSTEM_MODE);
            }

            if(!amcsToUpdate.isEmpty()) {
                //UPDATE amcsToUpdate;
                Database.update(amcsToUpdate, true, AccessLevel.SYSTEM_MODE);
            }
        }
    }

}