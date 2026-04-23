public without sharing class MapResourceToAssetByPinCode implements System.Schedulable, Database.Batchable<SObject> {

    public void execute(SchedulableContext sc) {
        MapResourceToAssetByPinCode batch = new MapResourceToAssetByPinCode();
        Database.executeBatch(batch, 100);
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Pin_Code_Master__c, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c,
            (SELECT Id, OwnerId FROM Asset_Warranty__r WHERE Asset_Warranty_PO_Status__c = 'Active'),
            (SELECT Id, OwnerId FROM Asset_AMCs__r WHERE Asset_AMC_PO_Status__c IN ('Active', 'Planned'))
            FROM Asset
            WHERE Pin_Code_Master__c != null AND Business_Vertical__c = 'MHE' AND Owner.Name = 'Integration User'
            ORDER BY Pin_Code_Master__c
        ]);
    }


    @future
    public static void mapResourcesToAssets(Set<Id> assetIds) {
        new MapResourceToAssetByPinCode().execute(null, [
            SELECT Id, Name, Pin_Code_Master__c, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c,
            (SELECT Id, OwnerId FROM Asset_Warranty__r WHERE Asset_Warranty_PO_Status__c = 'Active'),
            (SELECT Id, OwnerId FROM Asset_AMCs__r WHERE Asset_AMC_PO_Status__c IN ('Active', 'Planned'))
            FROM Asset
            WHERE Id IN :assetIds
            ORDER BY Pin_Code_Master__c
        ]);
    }


    public void execute(Database.BatchableContext bc, List<Asset> scope) {
        Set<Id> pincodeIds = new Set<Id>();
        Set<Id> currentEngineerIds = new Set<Id>();
        Map<Id, String> serviceResourceIdToRole = new Map<Id, String>();

        for (Asset record : scope) {
            if (record.Pin_Code_Master__c != null) {
                pincodeIds.add(record.Pin_Code_Master__c);
            }
            if (record.Service_Engineer_Pincode_based__c != null) {
                currentEngineerIds.add(record.Service_Engineer_Pincode_based__c);
            }
        }

        List<Service_Resource_Pincode__c> activeResources = [
            SELECT Id, Service_Resource__c, Pin_Code_Master__c, Service_Resource__r.User__c, Service_Resource__r.isActive__c, Service_Resource__r.RSM__c, Service_Resource__r.Coordinator__c, Service_Resource__r.Role__c
            FROM Service_Resource_Pincode__c
            WHERE Pin_Code_Master__c IN :pincodeIds AND
            Is_Active__c = TRUE AND
            Service_Resource__r.isActive__c = TRUE AND
            Service_Resource__r.User__r.isActive = TRUE AND
            (Service_Resource__r.Role__c = 'Service Engineer' OR Service_Resource__r.Role__c = 'RSM' OR Service_Resource__r.Role__c = 'Coordinator')
            ORDER BY Service_Resource__r.Role__c DESC
        ];

        Map<Id, List<Service_Resource_Pincode__c>> pincodeToResources = new Map<Id, List<Service_Resource_Pincode__c>>();
        for (Service_Resource_Pincode__c srp : activeResources) {
            if (!pincodeToResources.containsKey(srp.Pin_Code_Master__c)) {
                pincodeToResources.put(srp.Pin_Code_Master__c, new List<Service_Resource_Pincode__c>());
            }
            pincodeToResources.get(srp.Pin_Code_Master__c).add(srp);
            serviceResourceIdToRole.put(srp.Service_Resource__c, srp.Service_Resource__r.Role__c);
        }

        Map<Id, Service_Resource__c> currentEngineers = new Map<Id, Service_Resource__c>();
        if (!currentEngineerIds.isEmpty()) {
            currentEngineers = new Map<Id, Service_Resource__c>(
                [SELECT Id, isActive__c FROM Service_Resource__c WHERE Id IN :currentEngineerIds]
            );
        }

        Map<Id, Service_Resource__c> userIdToServiceResource = new Map<Id, Service_Resource__c>();
        Service_Resource__c serviceHeadResource;
        for(Service_Resource__c sr : [SELECT Id, User__c, User__r.Email FROM Service_Resource__c WHERE IsActive__c = TRUE]) {
            userIdToServiceResource.put(sr.User__c, sr);
            if (sr.User__r.Email == 'nilesh.patil@nilkamal.com') {
                serviceHeadResource = sr;
            }
        }

        List<Asset> assetsToUpdate = new List<Asset>();
        List<Asset_Warranty__c> warrantiesToUpdate = new List<Asset_Warranty__c>();
        List<Asset_AMC__c> amcsToUpdate = new List<Asset_AMC__c>();

        for (Asset asset : scope) {
            Id pinCodeId = asset.Pin_Code_Master__c;
            Id currentEngineerId = asset.Service_Engineer_Pincode_based__c;

            if(!pincodeToResources.containsKey(pinCodeId)) {
                if(serviceHeadResource != null) {
                    asset.OwnerId = serviceHeadResource.User__c;
                    assetsToUpdate.add(asset);
                    for(Asset_Warranty__c aw : asset.Asset_Warranty__r) {
                        aw.OwnerId = serviceHeadResource.User__c;
                        warrantiesToUpdate.add(aw);
                    }
                    for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                        amc.OwnerId = serviceHeadResource.User__c;
                        amcsToUpdate.add(amc);
                    }
                }

                continue;
            }

            List<Service_Resource_Pincode__c> validResources = pincodeToResources.get(pinCodeId);
            Boolean hasActiveResource = validResources != null && !validResources.isEmpty();

            List<Id> availableEngineers = new List<Id>();
            List<Id> availableRSMs = new List<Id>();
            List<Id> availableCoordinators = new List<Id>();

            for(Service_Resource_Pincode__c srp : validResources) {
                String role = serviceResourceIdToRole.get(srp.Service_Resource__c);
                switch on role {
                    when 'Service Engineer' {
                        availableEngineers.add(srp.Service_Resource__r.User__c);
                        availableRSMs.add(srp.Service_Resource__r.RSM__c);
                        availableCoordinators.add(srp.Service_Resource__r.Coordinator__c);
                    }
                    when 'RSM' {
                        availableRSMs.add(srp.Service_Resource__r.User__c);
                        availableCoordinators.add(srp.Service_Resource__r.Coordinator__c);
                    }
                    when 'Coordinator' {
                        availableCoordinators.add(srp.Service_Resource__r.User__c);
                    }
                }
            }

            Boolean isCurrentValid = false;
            if (currentEngineerId != null && hasActiveResource) {
                Service_Resource__c currentEngineer = currentEngineers.get(currentEngineerId);
                if (currentEngineer != null && currentEngineer.isActive__c) {
                    for (Service_Resource_Pincode__c srp : validResources) {
                        if (srp.Service_Resource__c == currentEngineerId) {
                            isCurrentValid = true;
                            break;
                        }
                    }
                }
            }

            if (!isCurrentValid) {
                if (hasActiveResource) {
                    // System.debug('availableEngineers ' + availableEngineers + ' ' + userIdToServiceResource.containsKey(availableEngineers[0]));
                    // System.debug('availableRSMs ' + availableRSMs + ' ' + userIdToServiceResource.containsKey(availableRSMs[0]));
                    // System.debug('availableCoordinators ' + availableCoordinators + ' ' + userIdToServiceResource.containsKey(availableCoordinators[0]));

                    Service_Resource_Pincode__c srp = validResources[0];
                    asset.Service_Engineer_Pincode_based__c = availableEngineers.isEmpty() ? null : userIdToServiceResource.get(availableEngineers[0]).Id;
                    asset.RSM_Pincode_based__c = availableRSMs.isEmpty() ? null : userIdToServiceResource.get(availableRSMs[0]).Id;
                    asset.Coordinator_Pincode_based__c = availableCoordinators.isEmpty() ? null : userIdToServiceResource.get(availableCoordinators[0]).Id;
                    asset.Is_pincode_based_SE_tagged__c = true;

                    if(asset.Service_Engineer_Pincode_based__c != null) {
                        asset.OwnerId = availableEngineers[0];
                    }
                    else if(asset.RSM_Pincode_based__c != null) {
                        asset.OwnerId = availableRSMs[0];
                    }
                    else if(asset.Coordinator_Pincode_based__c != null) {
                        asset.OwnerId = availableCoordinators[0];
                    }

                    System.debug(asset.Service_Engineer_Pincode_based__c + ' ' + asset.RSM_Pincode_based__c + ' ' + asset.Coordinator_Pincode_based__c + ' ' + asset.OwnerId);

                    for(Asset_Warranty__c aw : asset.Asset_Warranty__r) {
                        if(aw.OwnerId != asset.OwnerId) {
                            aw.OwnerId = asset.OwnerId;
                            warrantiesToUpdate.add(aw);
                        }
                    }

                    for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                        if(amc.OwnerId != asset.OwnerId) {
                            amc.OwnerId = asset.OwnerId;
                            amcsToUpdate.add(amc);
                        }
                    }
                }
                else {
                    asset.Service_Engineer_Pincode_based__c = null;
                    asset.RSM_Pincode_based__c = null;
                    asset.Coordinator_Pincode_based__c = null;
                    asset.Is_pincode_based_SE_tagged__c  = false;
                }

                assetsToUpdate.add(asset);
            }
        }

        if (!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
        if(!warrantiesToUpdate.isEmpty()) {
            Database.update(warrantiesToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
        if(!amcsToUpdate.isEmpty()) {
            Database.update(amcsToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
    }


    public void finish(Database.BatchableContext bc) {

    }

}