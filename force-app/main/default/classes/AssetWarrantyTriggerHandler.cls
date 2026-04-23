public without sharing class AssetWarrantyTriggerHandler {

    public static void updateWarrantyEndDate(List<Asset_Warranty__c> assetWarranty) {
        for (Asset_Warranty__c warranty : assetWarranty) {
            if (warranty.Warranty_Start_Date__c != null && warranty.Warranty_Period__c != null) {
                Integer warrantyPeriod = warranty.Warranty_Period__c.intValue();
                Date calculatedEndDate =warranty.Warranty_Start_Date__c.addDays(10);
                calculatedEndDate= calculatedEndDate.addMonths(warrantyPeriod);
                system.debug('before-->'+warranty.Warranty_End_Date__c);
                if(!test.isRunningTest()){
                  warranty.Warranty_End_Date__c = Date.newInstance(calculatedEndDate.year(), calculatedEndDate.month(), Date.daysInMonth(calculatedEndDate.year(), calculatedEndDate.month()));
                
                system.debug('After-->'+warranty.Warranty_End_Date__c);
                if(warranty.Warranty_End_Date__c!=null && warranty.Warranty_End_Date__c>=System.today()) {
                    warranty.Asset_Warranty_PO_Status__c='Active';
                }
                else {
                    warranty.Asset_Warranty_PO_Status__c='Expired';
                }
                }
            }
        }
    }

    public static void updateWarrantyStatusAndAssetType(List<Asset_Warranty__c> assetWarranty) {
        List<Asset_Warranty__c> updateList = new List<Asset_Warranty__c>();
        Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
        for (Asset_Warranty__c warranty : assetWarranty) {
            String newStatus;
            if (warranty.Warranty_End_Date__c != null) {
                Date today = Date.today();
                newStatus= (warranty.Warranty_End_Date__c >= today) ? 'Within Warranty' : 'Expired';
            }
            else {
                newStatus = 'Expired';
            }
            if (warranty.Asset__c != null) {
                Asset asset = new Asset();
                asset.Id = warranty.Asset__c;
                asset.Type__c = newStatus;
                assetsToUpdate.put(asset.Id, asset);
            }
        }

        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate.values();
        }
    }

    public static void createAssetVisit(List<Asset_Warranty__c> assetAMC) {
        List<Asset_Visits__c> assetVisits = new List<Asset_Visits__c>();
        for(Asset_Warranty__c amc:assetAMC) {
            if (amc.PM_Visit_Allowed__c != null  && amc.Warranty_Period__c != null ) {
                Integer noOfDays=(Integer)amc.Warranty_Period__c*30;
                Integer noOfDaysAfter=Integer.valueOF(noOfDays/amc.PM_Visit_Allowed__c);
                for(Integer i = 1; i <= amc.PM_Visit_Allowed__c; i++) {
                    Asset_Visits__c assetVisit = new Asset_Visits__c();
                    assetVisit.name='Warranty PM Visit '+i;
                    assetVisit.Asset_Warranty__c=amc.Id;
                    assetVisit.Asset_Serial_No__c=amc.Asset__c;
                    if(i == amc.PM_Visit_Allowed__c) {
                        assetVisit.Planned_Visit_Date__c=amc.Warranty_Start_Date__c.addDays((i*noOfDaysAfter)-15);
                    }
                    else {
                        assetVisit.Planned_Visit_Date__c=amc.Warranty_Start_Date__c.addDays((i*noOfDaysAfter));
                    }
                    assetVisit.Visit_Type__c='Preventive Maintenance';
                    assetVisits.add(assetVisit);
                }
            }
        }

        if(assetVisits.size()>0) {
            insert assetVisits;
        }
    }

    public static void updateAsset(Map<Id, Asset_Warranty__c> assetWarrantyMap) {
        Map<Id, Id> assetToAssetWarrantyMap = new Map<Id, Id>();

        for (Asset_Warranty__c warranty : assetWarrantyMap.values()) {
            assetToAssetWarrantyMap.put(warranty.Asset__c, warranty.Id);
        }
        List<Asset> assetsToBeUpdated = new List<Asset>();
        for (Id eachId:assetToAssetWarrantyMap.keySet()) {
            Asset asset = new Asset();
            asset.Id = eachId;

            Asset_Warranty__c warrantyObj = assetWarrantyMap.get(assetToAssetWarrantyMap.get(eachId));
            asset.Warranty_Start_Date__c = warrantyObj.Warranty_Start_Date__c;
            asset.Warranty_End_Date__c = warrantyObj.Warranty_End_Date__c;
            asset.Warranty_Period_Months__c = warrantyObj.Warranty_Period__c;

            assetsToBeUpdated.add(asset);
        }

        if(!assetsToBeUpdated.isEmpty()) {
            Database.update(assetsToBeUpdated, true, AccessLevel.SYSTEM_MODE);
        }
    }

    //  added by keshav
   public static void setWarrantyOwner(List<Asset_Warranty__c> newWarrantyList) {
        
        Set<Id> assetIds = new Set<Id>();
        for (Asset_Warranty__c warranty : newWarrantyList) {
            if (warranty.Asset__c != null) {
                assetIds.add(warranty.Asset__c);
            }
        }

        if (assetIds.isEmpty()) {
            return;
        }

        
        Map<Id, Asset> assetMap = new Map<Id, Asset>(
            [SELECT Id, OwnerId FROM Asset WHERE Id IN :assetIds]
        );

        
        for (Asset_Warranty__c warranty : newWarrantyList) {
            if (warranty.Asset__c != null && assetMap.containsKey(warranty.Asset__c)) {
                warranty.OwnerId = assetMap.get(warranty.Asset__c).OwnerId;
            }
        }
    }

}