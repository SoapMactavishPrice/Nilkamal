public with sharing class AssetTriggerHandler {

    public static void updateAssetSerialNumber(List<Asset> assets, Map<Id, Asset> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Asset>();
        }
        Set<Id> assetsIds = new Set<Id>();
        for (Asset ast : assets) {
            if(oldMap.containsKey(ast.Id) && ast.Type__c != oldMap.get(ast.Id).Type__c && ast.Type__c == 'Scraped') {
                assetsIds.add(ast.Id);
            }
            if(ast.Name.toLowercase().contains('temp')) {
                ast.Is_Temp_Serial_Number__c = true;
            }
            else {
                ast.Is_Temp_Serial_Number__c = false;
            }
        }

        List<Case> cs = new List<Case>();
        if(assetsIds.size() > 0) {
            cs = [SELECT Id,AssetId,Status,Asset.Type__c FROM Case where AssetId IN:assetsIds AND IsClosed=false];
        }

        for (Asset asset : assets) {
            if(asset.Asset_Level__c != asset.AssetLevel) {
                asset.Asset_Level__c = asset.AssetLevel;
            }
            if(oldMap.containsKey(asset.Id)) {
                if(asset.Name != oldMap.get(asset.Id).Name) {
                    asset.Name = asset.Name.trim();
                    asset.SerialNumber = asset.Name;
                    asset.External_Id__c = asset.Name;
                }
                else if(asset.SerialNumber != oldMap.get(asset.Id).SerialNumber) {
                    asset.Name = asset.SerialNumber.trim();
                    asset.External_Id__c = asset.SerialNumber;
                }

                if(asset.External_Id__c != asset.Name || asset.External_Id__c != asset.SerialNumber) {
                    asset.External_Id__c = asset.Name.trim();
                }
            }
            else {
                asset.Name = asset.Name.trim();
                asset.SerialNumber = asset.Name;
                asset.External_Id__c = asset.Name;
            }

            if(oldMap != null && oldMap.containsKey(asset.Id)) {
                if(asset.Type__c != oldMap.get(asset.Id).Type__c) {
                    if(asset.Type__c == 'Scraped' && cs.size()>0) {
                        asset.Type__c.addError('Case is open you can not make it as Scraped');
                    }
                }
            }
        }
    }


    public static void updateAssetBusinessVertical(List<Asset> assets) {
        Set<Id> productIds = new Set<Id>();
        for(Asset asset : assets) {
            if(asset.Product2Id != null) {
                productIds.add(asset.Product2Id);
            }
        }

        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Business_Vertical__c FROM Product2 WHERE Id IN :productIds]);

        for (Asset asset : assets) {
            if(products.containsKey(asset.Product2Id)) {
                asset.Business_Vertical__c = products.get(asset.Product2Id).Business_Vertical__c;
            }
        }
    }


    public static void createCase(List<Asset> assets) {
        Set<Id> productIds = new Set<Id>();
        for(Asset asset : assets) {
            if(asset.Product2Id != null) {
                productIds.add(asset.Product2Id);
            }
        }

        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id, Name, Installation_Required__c,Material_Group_6__c FROM Product2 WHERE Id IN :productIds]);

        Set<String> materialGroups = new Set<String>();
        for (Product2 p : products.values()) {
            if (String.isNotBlank(p.Material_Group_6__c)) {
                materialGroups.add(p.Material_Group_6__c);
            }
        }

        Map<String, MG6_Mapping__mdt> mg6TypeToMapping = new Map<String, MG6_Mapping__mdt>();
        for (MG6_Mapping__mdt mapping : [SELECT QualifiedApiName, Installation_Required__c, MG6_Type__c FROM MG6_Mapping__mdt WHERE MG6_Type__c IN :materialGroups]) {
            mg6TypeToMapping.put(mapping.MG6_Type__c, mapping);
        }

        if(!products.isEmpty()) {
            Set<String> shipToPinCodes = new Set<String>();
            Set<String> businessVerticals = new Set<String>();

            for (Asset asset : assets) {
                if(asset.Pin_Code_Master__c == null) {
                    if(String.isNotBlank(asset.Ship_to_Pin__c)) {
                        shipToPinCodes.add(asset.Ship_to_Pin__c);
                    }
                }
                if(String.isNotBlank(asset.Business_Vertical__c)) {
                    businessVerticals.add(asset.Business_Vertical__c);
                }
            }

            Map<String, Pin_Code_Master__c> pincodeMap = new Map<String, Pin_Code_Master__c>();
            for (Pin_Code_Master__c pincode : [SELECT Id, Name, Region__c FROM Pin_Code_Master__c WHERE Name IN :shipToPinCodes]) {
                pincodeMap.put(pincode.Name, pincode);
            }

            Set<Id> shipToPinCodeIds = new Set<Id>();
            for(Asset asset : assets) {
                if(asset.Pin_Code_Master__c == null) {
                    if(pincodeMap.containsKey(asset.Ship_to_Pin__c)) {
                        asset.Pin_Code_Master__c = pincodeMap.get(asset.Ship_to_Pin__c).Id;
                    }
                }
                shipToPinCodeIds.add(asset.Pin_Code_Master__c);
            }

            System.debug('shipToPinCodeIds ' + shipToPinCodeIds);
            System.debug('businessVerticals ' + businessVerticals);

            List<Service_Resource_Pincode__c> serviceResourcePinCodes = [
                SELECT Id, Pin_Code_Master__c, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.Name,
                Service_Resource__r.RSM__c, Service_Resource__r.RSM__r.Name, Service_Resource__r.Business_Vertical__c
                FROM Service_Resource_Pincode__c
                WHERE Pin_Code_Master__c IN :shipToPinCodeIds AND
                Is_Active__c = true AND
                Service_Resource__r.isActive__c = true AND
                Service_Resource__r.User__r.isActive = true AND
                Service_Resource__r.Business_Vertical__c IN :businessVerticals AND
                Service_Resource__r.Role__c = 'Service Engineer'
            ];

            Map<String, Map<Id, List<Service_Resource__c>>> verticalWisePincodeWiseServiceResources = new Map<String, Map<Id, List<Service_Resource__c>>>();
            for (Service_Resource_Pincode__c srp : serviceResourcePinCodes) {
                String vertical = srp.Service_Resource__r.Business_Vertical__c;
                Id pincode = srp.Pin_Code_Master__c;

                if(verticalWisePincodeWiseServiceResources.containsKey(vertical)) {
                    if(verticalWisePincodeWiseServiceResources.get(vertical).containsKey(pincode)) {
                        verticalWisePincodeWiseServiceResources.get(vertical).get(pincode).add(srp.Service_Resource__r);
                    } else {
                        verticalWisePincodeWiseServiceResources.get(vertical).put(pincode, new List<Service_Resource__c>{srp.Service_Resource__r});
                    }
                } else {
                    verticalWisePincodeWiseServiceResources.put(vertical, new Map<Id, List<Service_Resource__c>>{pincode => new List<Service_Resource__c>{srp.Service_Resource__r}});
                }
            }


            Id openQueueId;
            Map<String, Group> groupsByName = DataCls.getGroupsByName();
            if(groupsByName.containsKey('Open Queue')) {
                openQueueId = groupsByName.get('Open Queue').Id;
            }
            else {
                throw new CustomException('Open Queue not found.');
            }


            List<Case> casesToBeCreated = new List<Case>();
            List<Asset> assetsToUpdate = new List<Asset>();
            for (Asset asset : assets) {
                System.debug('Material_Group_6 ' + products.get(asset.Product2Id).Material_Group_6__c);
                System.debug('Material_Group_6__c ' + mg6TypeToMapping.containsKey(products.get(asset.Product2Id).Material_Group_6__c));
                System.debug('Material_Group_6__c:2 ' + mg6TypeToMapping.get(products.get(asset.Product2Id).Material_Group_6__c));
                System.debug('Installation_Case_To_Be_Created ' + Label.Installation_Case_To_Be_Created);
                System.debug('InstallationCaseBillingDateCutoff ' + Date.valueOf(Label.InstallationCaseBillingDateCutoff));

                if(
                    String.isNotBlank(products.get(asset.Product2Id).Material_Group_6__c) &&
                    mg6TypeToMapping.get(products.get(asset.Product2Id).Material_Group_6__c).Installation_Required__c == 'Yes' &&
                    Label.Installation_Case_To_Be_Created == 'Yes' && asset.PurchaseDate > Date.valueOf(Label.InstallationCaseBillingDateCutoff)
                ) {
                    Case caseObj = new Case();
                    caseObj.CurrencyIsoCode = asset.CurrencyIsoCode;
                    caseObj.AssetId = asset.Id;
                    caseObj.AccountId = asset.End_Customer__c;// 26/08
                    caseObj.ContactId = asset.ContactId;
                    caseObj.Status = 'New';
                    caseObj.Type = 'Installation';
                    caseObj.Case_Sub_Type__c = 'Installation & Commissioning';
                    caseObj.Case_Territory__c = asset.Territory_Master__c;
                    caseObj.Case_Pincode__c = asset.Pin_Code_Master__c;
                    caseObj.Division__c = asset.Business_Vertical__c;
                    caseObj.Subject = 'Installation & Commissioning ' + System.now().format('dd MMM yyyy');
                    caseObj.Description = 'Installation for ' + products.get(asset.Product2Id).Name;
                    caseObj.Origin = 'Raised By Engineer';

                    String businessVertical = asset.Business_Vertical__c;
                    String pincode = asset.Pin_Code_Master__c;

                    System.debug(JSON.serialize(verticalWisePincodeWiseServiceResources) + ' ' + verticalWisePincodeWiseServiceResources.containsKey(businessVertical));

                    if(verticalWisePincodeWiseServiceResources.containsKey(businessVertical) && verticalWisePincodeWiseServiceResources.get(businessVertical).containsKey(pincode)) {
                        if(verticalWisePincodeWiseServiceResources.get(businessVertical).get(pincode).size() > 1) {
                            Service_Resource__c serviceResource = verticalWisePincodeWiseServiceResources.get(businessVertical).get(pincode)[0];
                            caseObj.OwnerId = serviceResource.RSM__c;
                            System.debug('assigned to RSM');
                        }
                        else {
                            Service_Resource__c serviceResource = verticalWisePincodeWiseServiceResources.get(businessVertical).get(pincode)[0];
                            caseObj.OwnerId = serviceResource.User__c;
                            caseObj.Status = 'Assigned';
                            System.debug('assigned to User');
                        }
                    } else {
                        caseObj.OwnerId = openQueueId;
                    }

                    casesToBeCreated.add(caseObj);

                    assetsToUpdate.add(new Asset(Id = asset.Id, Is_Installation_Required__c = 'Yes'));
                }
                else {
                    assetsToUpdate.add(new Asset(Id = asset.Id, Is_Installation_Required__c = 'No'));
                }
            }

            if(!casesToBeCreated.isEmpty()) {
                INSERT casesToBeCreated;
            }

            if(!assetsToUpdate.isEmpty()) {
                UPDATE assetsToUpdate;
            }
        }
    }


    public static void updateShipToPinCode(List<Asset> assets, Map<Id, Asset> oldMap) {
        Set<Id> shipToPinCodeIds = new Set<Id>();
        Set<String> shipToPinCodes = new Set<String>();
        for (Asset asset : assets) {
            if(asset.Pin_Code_Master__c != null) {
                shipToPinCodeIds.add(asset.Pin_Code_Master__c);
            }
            if(String.isNotBlank(asset.Ship_to_Pin__c)) {
                shipToPinCodes.add(asset.Ship_to_Pin__c);
            }
        }

        Map<String, Pin_Code_Master__c> pincodeMap = new Map<String, Pin_Code_Master__c>();
        for (Pin_Code_Master__c pincode : [SELECT Id, Name, Region__c FROM Pin_Code_Master__c WHERE Id IN :shipToPinCodeIds OR Name IN :shipToPinCodes]) {
            pincodeMap.put(pincode.Name, pincode);
        }

        for(Asset asset : assets) {
            if(asset.Ship_to_Pin__c != oldMap.get(asset.Id).Ship_to_Pin__c) {
                if(String.isBlank(asset.Ship_to_Region__c)) {
                    asset.Ship_to_Region__c = pincodeMap.containsKey(asset.Ship_to_Pin__c) ? pincodeMap.get(asset.Ship_to_Pin__c).Region__c : null;
                }
                else if(asset.Ship_to_Region__c == oldMap.get(asset.Id).Ship_to_Region__c) {
                    asset.Ship_to_Region__c = pincodeMap.containsKey(asset.Ship_to_Pin__c) ? pincodeMap.get(asset.Ship_to_Pin__c).Region__c : null;
                }
            }
            else if(String.isBlank(asset.Ship_to_Region__c) && String.isNotBlank(asset.Ship_to_Pin__c)) {
                asset.Ship_to_Region__c = pincodeMap.containsKey(asset.Ship_to_Pin__c) ? pincodeMap.get(asset.Ship_to_Pin__c).Region__c : null;
            }
        }

        for (Asset asset : assets) {
            if(asset.Ship_to_Pin__c != null) {
                String oldPinCode = pincodeMap.containsKey(asset.Pin_Code_Master__c) ? pincodeMap.get(asset.Pin_Code_Master__c).Name : null;
                if(asset.Pin_Code_Master__c == null) {
                    if(pincodeMap.containsKey(asset.Ship_to_Pin__c)) {
                        asset.Pin_Code_Master__c = pincodeMap.get(asset.Ship_to_Pin__c).Id;
                    }
                }
                else if(asset.Ship_to_Pin__c != oldPinCode) {
                    if(pincodeMap.containsKey(asset.Ship_to_Pin__c)) {
                        asset.Pin_Code_Master__c = pincodeMap.get(asset.Ship_to_Pin__c).Id;
                    }
                    else {
                        // asset.Ship_to_Pin__c.addError('Pincode is not present in Pincode Master');
                    }
                }
            }
            else {
                asset.Pin_Code_Master__c = null;
            }
        }
    }


    public static void handleAssetSharing(List<Asset> newRecords, Map<Id, Asset> oldMap) {
        Map<Id, Service_Resource__c> serviceResourceMap = new Map<Id, Service_Resource__c>();
        for(Service_Resource__c sr : [SELECT Id, User__c FROM Service_Resource__c]) {
            serviceResourceMap.put(sr.Id, sr);
        }

        Map<Id, Id> assetToServiceEngineerMap = new Map<Id, Id>();
        List<AssetShare> assetShareToInsert = new List<AssetShare>();
        for (Asset asset : newRecords) {
            Asset oldAsset = oldMap.get(asset.Id);

            if(asset.Service_Engineer_Pincode_based__c != oldAsset.Service_Engineer_Pincode_based__c) {
                if(oldAsset.Service_Engineer_Pincode_based__c != null) {
                    assetToServiceEngineerMap.put(asset.Id, serviceResourceMap.get(oldAsset.Service_Engineer_Pincode_based__c).User__c);
                }
                if(asset.Service_Engineer_Pincode_based__c != null) {
                    AssetShare assetShare = new AssetShare();
                    assetShare.AssetId = asset.Id;
                    assetShare.UserOrGroupId = serviceResourceMap.get(asset.Service_Engineer_Pincode_based__c).User__c;
                    assetShare.AssetAccessLevel = 'Read';
                    assetShare.RowCause = 'Manual';
                    assetShareToInsert.add(assetShare);
                }
            }

            if(asset.RSM_Pincode_based__c != oldAsset.RSM_Pincode_based__c) {
                if(oldAsset.RSM_Pincode_based__c != null) {
                    assetToServiceEngineerMap.put(asset.Id, serviceResourceMap.get(oldAsset.RSM_Pincode_based__c).User__c);
                }
                if(asset.RSM_Pincode_based__c != null) {
                    AssetShare assetShare = new AssetShare();
                    assetShare.AssetId = asset.Id;
                    assetShare.UserOrGroupId = serviceResourceMap.get(asset.RSM_Pincode_based__c).User__c;
                    assetShare.AssetAccessLevel = 'Read';
                    assetShare.RowCause = 'Manual';
                    assetShareToInsert.add(assetShare);
                }
            }

            if(asset.Coordinator_Pincode_based__c != oldAsset.Coordinator_Pincode_based__c) {
                if(oldAsset.Coordinator_Pincode_based__c != null) {
                    assetToServiceEngineerMap.put(asset.Id, serviceResourceMap.get(oldAsset.Coordinator_Pincode_based__c).User__c);
                }
                if(asset.Coordinator_Pincode_based__c != null) {
                    AssetShare assetShare = new AssetShare();
                    assetShare.AssetId = asset.Id;
                    assetShare.UserOrGroupId = serviceResourceMap.get(asset.Coordinator_Pincode_based__c).User__c;
                    assetShare.AssetAccessLevel = 'Read';
                    assetShare.RowCause = 'Manual';
                    assetShareToInsert.add(assetShare);
                }
            }
        }

        if(!assetToServiceEngineerMap.isEmpty()) {
            List<AssetShare> assetShareToDelete = new List<AssetShare>();
            for(AssetShare assetShare : [
                SELECT Id, AssetId, UserOrGroupId
                FROM AssetShare
                WHERE AssetId IN :assetToServiceEngineerMap.keySet() AND RowCause = 'Manual' AND UserOrGroupId IN :assetToServiceEngineerMap.values()
            ]) {
                if(assetToServiceEngineerMap.containsKey(assetShare.AssetId) && assetShare.UserOrGroupId == assetToServiceEngineerMap.get(assetShare.AssetId)) {
                    assetShareToDelete.add(assetShare);
                }
            }

            if(!assetShareToDelete.isEmpty()) {
                DELETE assetShareToDelete;
            }
        }

        // for(AssetShare a : [SELECT Id, Asset.Owner.Name, UserOrGroupId, UserOrGroup.Name, AssetAccessLevel, RowCause FROM AssetShare WHERE AssetId IN :newRecords]) {
        //     System.debug('before ' + a.UserOrGroupId + ' ' + a.UserOrGroup.Name + ' ' + a.AssetAccessLevel + ' ' + a.RowCause + ' ' + a.Asset.Owner.Name + ' ' + a.Id);
        // }

        // for(AssetShare a : assetShareToInsert) {
        //     System.debug('insert ' + a.UserOrGroupId + ' ' + a.AssetAccessLevel + ' ' + a.RowCause);
        // }

        if(!assetShareToInsert.isEmpty()) {
            Database.insert(assetShareToInsert, false);
        }

        // for(AssetShare a : [SELECT Id, Asset.Owner.Name, UserOrGroupId, UserOrGroup.Name, AssetAccessLevel, RowCause FROM AssetShare WHERE AssetId IN :newRecords]) {
        //     System.debug('after ' + a.UserOrGroupId + ' ' + a.UserOrGroup.Name + ' ' + a.AssetAccessLevel + ' ' + a.RowCause + ' ' + a.Asset.Owner.Name + ' ' + a.Id);
        // }
    }


    public static void updatePincodeFieldsBasedOnOwner(List<Asset> assets, Map<Id, Asset> oldMap) {
        Set<Id> ownerIds = new Set<Id>();
        for(Asset a : assets) {
            if(a.OwnerId != oldMap.get(a.Id).OwnerId) {
                ownerIds.add(a.OwnerId);
            }
        }

        if(ownerIds.isEmpty()) {
            return;
        }


        Map<Id, Service_Resource__c> userIdToServiceResource = new Map<Id, Service_Resource__c>();
        for(Service_Resource__c sr : [SELECT Id, User__c, Role__c, Coordinator__c, RSM__c FROM Service_Resource__c WHERE User__r.isActive = true]) {
            userIdToServiceResource.put(sr.User__c, sr);
        }

        for (Asset a : assets) {
            if (a.OwnerId != oldMap.get(a.Id).OwnerId) {
                a.Service_Engineer_Pincode_based__c = null;
                a.RSM_Pincode_based__c = null;
                a.Coordinator_Pincode_based__c = null;

                if(userIdToServiceResource.containsKey(a.OwnerId)) {
                    Service_Resource__c sr = userIdToServiceResource.get(a.OwnerId);

                    if (sr.Role__c == 'Service Engineer') {
                        a.Service_Engineer_Pincode_based__c = sr.Id;

                        if (String.isNotBlank(sr.RSM__c) && userIdToServiceResource.containsKey(sr.RSM__c)) {
                            a.RSM_Pincode_based__c = userIdToServiceResource.get(sr.RSM__c).Id;
                        }
                        if (String.isNotBlank(sr.Coordinator__c) && userIdToServiceResource.containsKey(sr.Coordinator__c)) {
                            a.Coordinator_Pincode_based__c = userIdToServiceResource.get(sr.Coordinator__c).Id;
                        }
                    }
                    else if (sr.Role__c == 'RSM') {
                        a.RSM_Pincode_based__c = sr.Id;

                        if (String.isNotBlank(sr.Coordinator__c) && userIdToServiceResource.containsKey(sr.Coordinator__c)) {
                            a.Coordinator_Pincode_based__c = userIdToServiceResource.get(sr.Coordinator__c).Id;
                        }
                    }
                    else if (sr.Role__c == 'Coordinator') {
                        a.Coordinator_Pincode_based__c = sr.Id;
                    }
                }
            }

            System.debug(a.Service_Engineer_Pincode_based__c + ' ' + a.RSM_Pincode_based__c + ' ' + a.Coordinator_Pincode_based__c);
        }
    }


    public static void updateAssetType(List<Asset> assets) {
        updateAssetType(assets, null);
    }

    public static void updateAssetType(List<Asset> assets, Map<Id, Asset> oldMap) {

        Set<Id> acctIds = new Set<Id>();
        for (Asset a : assets) {
            if (a.AccountId != null) {
                if (oldMap == null || a.AccountId != oldMap.get(a.Id).AccountId) {
                    acctIds.add(a.AccountId);
                }
            }
        }
        if (acctIds.isEmpty()) return;

        Map<Id, Account> acctMap = new Map<Id, Account>(
            [
                SELECT Id, Type 
                FROM Account 
                WHERE Id IN :acctIds
            ]
        );

        for (Asset a : assets) {
            if (a.AccountId == null) continue;

            Account acc = acctMap.get(a.AccountId);
            if (acc == null) continue;

            String ctype = acc.Type;  

            if (ctype == null) continue;

            ctype = ctype.trim().toLowerCase();

            if (ctype == 'oem') {
                a.Asset_Type__c = 'OEM Asset';

            } else if (ctype == 'dealer') {
                a.Asset_Type__c = 'Regular Asset';

            } else if (ctype == 'customer') {
                a.Asset_Type__c = 'Regular Asset';
            }
        }
    }


    // After Insert Trigger Logic for manual asset creation notification
    // Method to filter assets created by non-Integration users
    public static List<Asset> getAssetsCreatedByNonIntegration(List<Asset> newAssets) {
        try {
            // Get all creator user IDs
            Set<Id> createdByIds = new Set<Id>();
            for (Asset asset : newAssets) {
                createdByIds.add(asset.CreatedById);
            }
            
            // Get Integration users
            Map<Id, User> integrationUsersMap = new Map<Id, User>([
                SELECT Id, Name 
                FROM User 
                WHERE Id IN :createdByIds
                AND Name = 'Integration'
            ]);
            
            // Filter assets created by non-Integration users
            List<Asset> nonIntegrationAssets = new List<Asset>();
            for (Asset asset : newAssets) {
                if (!integrationUsersMap.containsKey(asset.CreatedById)) {
                    nonIntegrationAssets.add(asset);
                }
            }
            
            return nonIntegrationAssets;
            
        } catch (Exception e) {
            System.debug('Error in getAssetsCreatedByNonIntegration: ' + e.getMessage());
            return new List<Asset>();
        }
    }
    
    // Method to notify Service Head when assets are created by non-Integration users
    public static void notifyServiceHead(List<Asset> newAssets) {
        try {
            // Filter to get only assets created by non-Integration users
            List<Asset> nonIntegrationAssets = getAssetsCreatedByNonIntegration(newAssets);
            
            if (nonIntegrationAssets.isEmpty()) {
                System.debug('All assets created by Integration user - No notification sent');
                return;
            }
            
            // Query for Service Head Printer users
            List<User> serviceHeads = [
                SELECT Id, Name, Email, UserRole.Name, Business_Unit__c
                FROM User 
                WHERE UserRole.Name like 'Service Head%'
                AND Email != null
            ];

            Map<String, List<User>> bvToServiceHeads = new Map<String, List<User>>();
            for (User sh : serviceHeads) {
                if (!bvToServiceHeads.containsKey(sh.Business_Unit__c)) {
                    bvToServiceHeads.put(sh.Business_Unit__c, new List<User>());
                }
                bvToServiceHeads.get(sh.Business_Unit__c).add(sh);
            }
            
            if (serviceHeads.isEmpty()) {
                System.debug('No Service Head Printer users found');
                return;
            }
            
            // Prepare email addresses
            List<String> toAddresses = new List<String>();
            for (User serviceHead : serviceHeads) {
                toAddresses.add(serviceHead.Email);
            }
            
            // Build email content
            String emailSubject = 'New Assets Created Manually (Non-Integration)';
            String emailBody = buildEmailBody(nonIntegrationAssets, serviceHeads, newAssets.size() - nonIntegrationAssets.size());
            
            // Send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(emailSubject);
            mail.setHtmlBody(emailBody);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            
            System.debug('Notification sent to Service Head for ' + nonIntegrationAssets.size() + ' non-integration created assets (Filtered from ' + newAssets.size() + ' total assets)');
            
        } catch (Exception e) {
            System.debug('Error in notifyServiceHead: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    // Method to build email body
    private static String buildEmailBody(List<Asset> nonIntegrationAssets, List<User> serviceHeads, Integer integrationAssetsCount) {
        String htmlBody = '';
        
        htmlBody += '<h3>New Assets Created Manually</h3>';
        
        if (integrationAssetsCount > 0) {
            htmlBody += '<p><strong>Note:</strong> ' + integrationAssetsCount + ' asset(s) were created by Integration user and are excluded from this notification.</p>';
        }
        
        htmlBody += '<p>The following assets were created manually (not by Integration user) and require your attention:</p>';
        
        htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse; width:100%;">';
        htmlBody += '<tr style="background-color:#f2f2f2;">';
        htmlBody += '<th>Asset Name</th>';
        htmlBody += '<th>Account</th>';
        htmlBody += '<th>Serial Number</th>';
        htmlBody += '<th>Installation Date</th>';
        htmlBody += '<th>Created By User</th>';
        htmlBody += '</tr>';
        
        // Get creator user information for non-integration assets
        Set<Id> createdByIds = new Set<Id>();
        for (Asset asset : nonIntegrationAssets) {
            createdByIds.add(asset.CreatedById);
        }
        
        Map<Id, User> createdByUsers = new Map<Id, User>([
            SELECT Id, Name, Email 
            FROM User 
            WHERE Id IN :createdByIds
        ]);
        
        for (Asset asset : nonIntegrationAssets) {
            User createdBy = createdByUsers.get(asset.CreatedById);
            String creatorName = createdBy != null ? createdBy.Name : 'Unknown';
            
            htmlBody += '<tr>';
            htmlBody += '<td>' + (asset.Name != null ? asset.Name : 'N/A') + '</td>';
            htmlBody += '<td>' + (asset.AccountId != null ? 'Account Reference' : 'N/A') + '</td>';
            htmlBody += '<td>' + (asset.SerialNumber != null ? asset.SerialNumber : 'N/A') + '</td>';
            htmlBody += '<td>' + (asset.InstallDate != null ? String.valueOf(asset.InstallDate) : 'N/A') + '</td>';
            htmlBody += '<td>' + creatorName + '</td>';
            htmlBody += '</tr>';
        }
        
        htmlBody += '</table>';
        
        htmlBody += '<br/><p><strong>Notification Sent To Service Head Team:</strong></p>';
        htmlBody += '<ul>';
        for (User serviceHead : serviceHeads) {
            htmlBody += '<li>' + serviceHead.Name + ' (' + serviceHead.UserRole.Name + ')</li>';
        }
        htmlBody += '</ul>';
        
        /*htmlBody += '<br/><p><strong>Summary:</strong></p>';
        htmlBody += '<ul>';
        htmlBody += '<li>Total assets processed: ' + (nonIntegrationAssets.size() + integrationAssetsCount) + '</li>';
        htmlBody += '<li>Assets created by Integration user: ' + integrationAssetsCount + ' (excluded)</li>';
        htmlBody += '<li>Assets created by regular users: ' + nonIntegrationAssets.size() + ' (included in this notification)</li>';
        htmlBody += '</ul>';*/
        
        htmlBody += '<p>Best regards,<br/>Salesforce System</p>';
        
        return htmlBody;
    }



    
    // Method to notify Service Head when critical fields are changed    
    public static void notifyServiceHeadOnFieldChange(List<Asset> newAssets, Map<Id, Asset> oldAssetsMap) {
        try {
            List<Asset> changedAssets = getAssetsWithCriticalFieldChanges(newAssets, oldAssetsMap);
            
            if (changedAssets.isEmpty()) {
                System.debug('No critical field changes detected - No notification sent');
                return;
            }
            
            // Get Business Unit to Service Heads mapping
            Map<String, List<User>> bvToServiceHeads = getServiceHeadsByBusinessUnit();
            
            if (bvToServiceHeads.isEmpty()) {
                System.debug('No Service Head users found');
                return;
            }
            
            // Group assets by Business Vertical
            Map<String, List<Asset>> bvToAssets = groupAssetsByBusinessVertical(changedAssets);
            
            // Send notifications for each Business Unit
            sendNotificationsByBusinessUnit(bvToAssets, bvToServiceHeads, oldAssetsMap);
            
            System.debug('Field change notification sent for ' + changedAssets.size() + ' assets');
            
        } catch (Exception e) {
            System.debug('Error in notifyServiceHeadOnFieldChange: ' + e.getMessage() + ' at line ' + e.getLineNumber());
        }
    }
    
    // Method to get Service Heads grouped by Business Unit
    private static Map<String, List<User>> getServiceHeadsByBusinessUnit() {
        List<User> serviceHeads = [
            SELECT Id, Name, Email, UserRole.Name, Business_Unit__c
            FROM User 
            WHERE UserRole.Name like 'Service Head %'
            AND Email != null
        ];

        Map<String, List<User>> bvToServiceHeads = new Map<String, List<User>>();
        for (User sh : serviceHeads) {
            String businessUnit = sh.Business_Unit__c != null ? sh.Business_Unit__c : 'Other';
            
            if (!bvToServiceHeads.containsKey(businessUnit)) {
                bvToServiceHeads.put(businessUnit, new List<User>());
            }
            bvToServiceHeads.get(businessUnit).add(sh);
        }
        
        return bvToServiceHeads;
    }
    
    // Method to group assets by Business Vertical
    private static Map<String, List<Asset>> groupAssetsByBusinessVertical(List<Asset> assets) {
        Map<String, List<Asset>> bvToAssets = new Map<String, List<Asset>>();
        
        for (Asset asset : assets) {
            String businessVertical = asset.Business_Vertical__c;
            if (businessVertical == null) {
                businessVertical = 'Other';
            }
            
            if (!bvToAssets.containsKey(businessVertical)) {
                bvToAssets.put(businessVertical, new List<Asset>());
            }
            bvToAssets.get(businessVertical).add(asset);
        }
        
        return bvToAssets;
    }
    
    // Method to send notifications by Business Unit
    private static void sendNotificationsByBusinessUnit(Map<String, List<Asset>> bvToAssets, Map<String, List<User>> bvToServiceHeads, Map<Id, Asset> oldAssetsMap) {
        for (String businessVertical : bvToAssets.keySet()) {
            List<Asset> assetsForBV = bvToAssets.get(businessVertical);
            List<User> serviceHeadsForBV = bvToServiceHeads.get(businessVertical);
            
            if (serviceHeadsForBV != null && !serviceHeadsForBV.isEmpty()) {
                // Prepare email addresses for this Business Unit
                List<String> toAddresses = new List<String>();
                for (User serviceHead : serviceHeadsForBV) {
                    toAddresses.add(serviceHead.Email);
                }
                
                // Build email content specific to this Business Unit
                String emailSubject = 'Asset Critical Fields Updated - ' + businessVertical + ' Business Unit';
                String emailBody = buildFieldChangeEmailBody(assetsForBV, serviceHeadsForBV, oldAssetsMap, businessVertical);
                
                // Send email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAddresses);
                mail.setSubject(emailSubject);
                mail.setHtmlBody(emailBody);
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                
                System.debug('Notification sent for ' + assetsForBV.size() + ' assets in Business Unit: ' + businessVertical);
            } else {
                System.debug('No Service Head found for Business Unit: ' + businessVertical);
            }
        }
    }
    
    // Method to get assets with critical field changes
    private static List<Asset> getAssetsWithCriticalFieldChanges(List<Asset> newAssets, Map<Id, Asset> oldAssetsMap) {
        List<Asset> changedAssets = new List<Asset>();
        
        for (Asset newAsset : newAssets) {
            Asset oldAsset = oldAssetsMap.get(newAsset.Id);
            
            if (oldAsset != null) {
                // Check if any critical field has changed
                Boolean isAccountChanged = newAsset.AccountId != oldAsset.AccountId;
                Boolean isEndCustomerChanged = newAsset.End_Customer__c != oldAsset.End_Customer__c;
                Boolean isContactChanged = newAsset.ContactId != oldAsset.ContactId;
                
                if (isAccountChanged || isEndCustomerChanged || isContactChanged) {
                    changedAssets.add(newAsset);
                }
            }
        }
        
        return changedAssets;
    }
    
    // Method to build email body for field changes
    private static String buildFieldChangeEmailBody(List<Asset> changedAssets, List<User> serviceHeads, Map<Id, Asset> oldAssetsMap, String businessVertical) {
        String htmlBody = '';
        
        htmlBody += '<h3>Asset Critical Fields Updated - ' + businessVertical + ' Business Unit</h3>';
        htmlBody += '<p>The following assets had critical field changes and require your attention:</p>';
        
        htmlBody += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse; width:100%;">';
        htmlBody += '<tr style="background-color:#f2f2f2;">';
        htmlBody += '<th>Asset Name</th>';
        htmlBody += '<th>Field Changed</th>';
        htmlBody += '<th>Old Value</th>';
        htmlBody += '<th>New Value</th>';
        htmlBody += '<th>Modified By</th>';
        htmlBody += '</tr>';
        
        // Get modified by user information
        Set<Id> lastModifiedByIds = new Set<Id>();
        for (Asset asset : changedAssets) {
            lastModifiedByIds.add(asset.LastModifiedById);
        }
        
        Map<Id, User> modifiedByUsers = new Map<Id, User>([
            SELECT Id, Name, Email 
            FROM User 
            WHERE Id IN :lastModifiedByIds
        ]);
        
        for (Asset asset : changedAssets) {
            Asset oldAsset = oldAssetsMap.get(asset.Id);
            User modifiedBy = modifiedByUsers.get(asset.LastModifiedById);
            String modifierName = modifiedBy != null ? modifiedBy.Name : 'Unknown';
            
            // Check each field and create rows for changes
            if (asset.AccountId != oldAsset.AccountId) {
                htmlBody += '<tr>';
                htmlBody += '<td>' + (asset.Name != null ? asset.Name : 'N/A') + '</td>';
                htmlBody += '<td>Account</td>';
                htmlBody += '<td>' + (oldAsset.AccountId != null ? 'Account Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + (asset.AccountId != null ? 'Account Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + modifierName + '</td>';
                htmlBody += '</tr>';
            }
            
            if (asset.End_Customer__c != oldAsset.End_Customer__c) {
                htmlBody += '<tr>';
                htmlBody += '<td>' + (asset.Name != null ? asset.Name : 'N/A') + '</td>';
                htmlBody += '<td>End Customer</td>';
                htmlBody += '<td>' + (oldAsset.End_Customer__c != null ? 'End Customer Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + (asset.End_Customer__c != null ? 'End Customer Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + modifierName + '</td>';
                htmlBody += '</tr>';
            }
            
            if (asset.ContactId != oldAsset.ContactId) {
                htmlBody += '<tr>';
                htmlBody += '<td>' + (asset.Name != null ? asset.Name : 'N/A') + '</td>';
                htmlBody += '<td>Contact</td>';
                htmlBody += '<td>' + (oldAsset.ContactId != null ? 'Contact Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + (asset.ContactId != null ? 'Contact Reference' : 'Empty') + '</td>';
                htmlBody += '<td>' + modifierName + '</td>';
                htmlBody += '</tr>';
            }
        }
        
        htmlBody += '</table>';
        
        htmlBody += '<br/><p><strong>Notification Sent To Service Head Team (' + businessVertical + '):</strong></p>';
        htmlBody += '<ul>';
        for (User serviceHead : serviceHeads) {
            htmlBody += '<li>' + serviceHead.Name + ' (' + serviceHead.UserRole.Name + ' - ' + serviceHead.Business_Unit__c + ')</li>';
        }
        htmlBody += '</ul>';
        
        // htmlBody += '<br/><p><strong>Summary:</strong></p>';
        // htmlBody += '<ul>';
        // htmlBody += '<li>Business Unit: ' + businessVertical + '</li>';
        // htmlBody += '<li>Total assets with field changes: ' + changedAssets.size() + '</li>';
        // htmlBody += '<li>Fields monitored: Account, End Customer, Contact</li>';
        // htmlBody += '</ul>';
        
        htmlBody += '<p>Best regards,<br/>Salesforce System</p>';
        
        return htmlBody;
    }

}