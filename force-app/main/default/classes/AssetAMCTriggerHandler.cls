public without sharing class AssetAMCTriggerHandler {

    public static void updateExternalId(List<Asset_AMC__c> assetAMC) {
       // added by keshav
    Set<Id> assetIds = new Set<Id>();
    for (Asset_AMC__c amc : assetAMC) {
        if (amc.Asset__c != null) {
            assetIds.add(amc.Asset__c);
        }
    }

    Map<Id, Asset> assetMap = new Map<Id, Asset>();
    if (!assetIds.isEmpty()) {
        assetMap = new Map<Id, Asset>(
            [SELECT Id, OwnerId FROM Asset WHERE Id IN :assetIds]
        );
    }

    for (Asset_AMC__c amc : assetAMC) {
        amc.External_Id__c = amc.Asset_Serial_Number_Formula__c 
                             + ' - ' + amc.AMC_Start_Date__c.year() 
                             + ' - ' + amc.AMC_Start_Date__c.month() 
                             + ' - ' + amc.AMC_Start_Date__c.day();

        if (amc.Asset__c != null && assetMap.containsKey(amc.Asset__c)) {
            amc.OwnerId = assetMap.get(amc.Asset__c).OwnerId;
        }
    }
    }

    public static void updateAMCEndDates(List<Asset_AMC__c> assetAMC) {
        for (Asset_AMC__c amc : assetAMC) {
            if (amc.AMC_Start_Date__c != null && amc.AMC_Period_In_Months__c != null) {
                Integer amcPeriod = amc.AMC_Period_In_Months__c.intValue();
                Date tempDate = amc.AMC_Start_Date__c.addDays(-1).addMonths(amcPeriod);
                Integer lastDay = Date.daysInMonth(tempDate.year(), tempDate.month());
                Date calculatedEndDate = Date.newInstance(tempDate.year(), tempDate.month(), lastDay);
                amc.AMC_End_Date__c = calculatedEndDate;

                Date today = System.today();
                if(today < amc.AMC_Start_Date__c) {
                    amc.Asset_AMC_PO_Status__c = 'Planned';
                }
                else if(amc.AMC_Start_Date__c <= today && today <= amc.AMC_End_Date__c) {
                    amc.Asset_AMC_PO_Status__c = 'Active';
                }
                else {
                    amc.Asset_AMC_PO_Status__c = 'Expired';
                }
            }
        }
    }

    public static void updateAMCStatusAndAssetType(List<Asset_AMC__c> assetAMC) {
        List<Id> assetId=new List<Id>();
        List<Asset> updateAssetList = new List<Asset>();
        for(Asset_AMC__c amc:assetAMC) {
            assetId.add(amc.Asset__c);
        }
        List<Asset> assetList = [
            SELECT Id, Type__c,
            (
                SELECT Id, Name, Product_Category_Type__c
                FROM Asset_AMCs__r
                WHERE AMC_End_Date__c >= TODAY
            )
            FROM Asset
            WHERE Id IN :assetId
        ];
        for(Asset asset:assetList) {
            String newStatus;

            if(asset.Asset_AMCs__r.size() > 0) {
                if(asset.Asset_AMCs__r[0].Product_Category_Type__c=='CAMC') {
                    newStatus='Within CAMC';
                }
                else {
                    newStatus='Within AMC';
                }
            }
            else {
                newStatus='Expired';
            }
            asset.Type__c = newStatus;
            updateAssetList.add(asset);
        }
        if(updateAssetList.size() > 0) {
            update updateAssetList;
        }
    }

    public static void createAssetVisit(List<Asset_AMC__c> assetAMC) {
        List<Asset_Visits__c> assetVisits = new List<Asset_Visits__c>();
        for(Asset_AMC__c amc:assetAMC) {
            if (amc != null && amc.AMC_Period_In_Months__c != null) {
                Integer noOfDays=(Integer)amc.AMC_Period_In_Months__c*30;
                Integer noOfDaysAfter=Integer.valueOF(noOfDays/amc.PM_Visit_Allowed__c);
                for(Integer i=1;i<=amc.PM_Visit_Allowed__c;i++) {
                    Asset_Visits__c assetVisit = new Asset_Visits__c();
                    assetVisit.name='AMC PM Visit '+i;
                    assetVisit.Asset_AMC__c=amc.Id;
                    assetVisit.Asset_Serial_No__c=amc.Asset__c;
                    if(i==amc.PM_Visit_Allowed__c) {
                        System.debug('noOfDaysAfter'+amc.AMC_Start_Date__c.addDays((i*noOfDaysAfter)-15));
                        assetVisit.Planned_Visit_Date__c=amc.AMC_Start_Date__c.addDays((i*noOfDaysAfter)-15);
                    }
                    else {
                        System.debug('noOfDaysAfter'+amc.AMC_Start_Date__c.addDays((i*noOfDaysAfter)));
                        assetVisit.Planned_Visit_Date__c=(amc.AMC_Start_Date__c.addDays((i*noOfDaysAfter)));
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

    public static void updateAMCDetailsOnAsset(List<Asset_AMC__c> newRecords, Map<Id, Asset_AMC__c> oldMap) {
        Set<Id> assetIds = new Set<Id>();
        for(Asset_AMC__c amc : newRecords) {
            if(Trigger.isInsert) {
                if(amc.Asset__c != null) {
                    assetIds.add(amc.Asset__c);
                }
            }
            else if(Trigger.isDelete) {
                if(amc.Asset__c != null) {
                    assetIds.add(amc.Asset__c);
                }
            }
            else {
                if(amc.Asset__c != null && amc.Asset__c != oldMap.get(amc.Id).Asset__c ||
                    amc.AMC_Start_Date__c != oldMap.get(amc.Id).AMC_Start_Date__c ||
                    amc.AMC_End_Date__c != oldMap.get(amc.Id).AMC_End_Date__c ||
                    amc.AMC_Period_In_Months__c != oldMap.get(amc.Id).AMC_Period_In_Months__c ||
                    amc.AMC_PO_Value__c != oldMap.get(amc.Id).AMC_PO_Value__c ||
                    amc.SE_Name__c != oldMap.get(amc.Id).SE_Name__c
                ) {
                    assetIds.add(amc.Asset__c);
                }
            }
        }

        Map<Id, List<Asset_AMC__c>> assetAmcMapByAssetId = new Map<Id, List<Asset_AMC__c>>();
        for(Id assetId : assetIds) {
            assetAmcMapByAssetId.put(assetId, new List<Asset_AMC__c>());
        }
        for(Asset_AMC__c amc : [SELECT Id, AMC_Start_Date__c, AMC_End_Date__c, AMC_Period_In_Months__c, AMC_PO_Value__c, Asset__c, SE_Name__c
                                FROM Asset_AMC__c
                                WHERE Asset__c IN :assetIds AND Asset_AMC_PO_Status__c != 'Planned'
                                ORDER BY AMC_End_Date__c DESC]
        ) {
            if (!assetAmcMapByAssetId.containsKey(amc.Asset__c)) {
                assetAmcMapByAssetId.put(amc.Asset__c, new List<Asset_AMC__c>());
            }
            assetAmcMapByAssetId.get(amc.Asset__c).add(amc);
        }

        List<Asset> assetsToUpdate = new List<Asset>();


        for(Id assetId : assetAmcMapByAssetId.keySet()) {
            if(assetAmcMapByAssetId.get(assetId).size() == 1) {
                Asset asset = new Asset();
                asset.Id = assetId;
                asset.AMC_Number__c = 1;

                asset.AMC_Start_Date__c = assetAmcMapByAssetId.get(assetId)[0].AMC_Start_Date__c;
                asset.AMC_End_Date__c = assetAmcMapByAssetId.get(assetId)[0].AMC_End_Date__c;
                asset.AMC_Period_Months__c = assetAmcMapByAssetId.get(assetId)[0].AMC_Period_In_Months__c;
                asset.AMC_PO_Value__c = assetAmcMapByAssetId.get(assetId)[0].AMC_PO_Value__c;
                asset.AMC_SE_Name__c = assetAmcMapByAssetId.get(assetId)[0].SE_Name__c;

                asset.First_AMC_Start_Date__c = assetAmcMapByAssetId.get(assetId)[0].AMC_Start_Date__c;
                asset.First_AMC_End_Date__c = assetAmcMapByAssetId.get(assetId)[0].AMC_End_Date__c;
                asset.First_AMC_Period_Months__c = assetAmcMapByAssetId.get(assetId)[0].AMC_Period_In_Months__c;
                asset.First_AMC_PO_Value__c = assetAmcMapByAssetId.get(assetId)[0].AMC_PO_Value__c;

                assetsToUpdate.add(asset);
            }
            else if(assetAmcMapByAssetId.get(assetId).size() > 1) {
                Asset_AMC__c currentAMC = assetAmcMapByAssetId.get(assetId)[0];
                Asset_AMC__c previousAMC = assetAmcMapByAssetId.get(assetId)[1];
                Asset_AMC__c firstAMC = assetAmcMapByAssetId.get(assetId)[assetAmcMapByAssetId.get(assetId).size() - 1];

                Asset asset = new Asset();
                asset.Id = assetId;
                asset.AMC_Number__c = assetAmcMapByAssetId.get(assetId).size();

                asset.AMC_Start_Date__c = currentAMC.AMC_Start_Date__c;
                asset.AMC_End_Date__c = currentAMC.AMC_End_Date__c;
                asset.AMC_Period_Months__c = currentAMC.AMC_Period_In_Months__c;
                asset.AMC_PO_Value__c = currentAMC.AMC_PO_Value__c;
                asset.AMC_SE_Name__c = currentAMC.SE_Name__c;

                asset.Previous_AMC_Start_Date__c = previousAMC.AMC_Start_Date__c;
                asset.Previous_AMC_End_Date__c = previousAMC.AMC_End_Date__c;
                asset.Previous_AMC_Period_Months__c = previousAMC.AMC_Period_In_Months__c;
                asset.Previous_AMC_PO_Value__c = previousAMC.AMC_PO_Value__c;
                asset.Previous_AMC_SE_Name__c = previousAMC.SE_Name__c;

                asset.First_AMC_Start_Date__c = firstAMC.AMC_Start_Date__c;
                asset.First_AMC_End_Date__c = firstAMC.AMC_End_Date__c;
                asset.First_AMC_Period_Months__c = firstAMC.AMC_Period_In_Months__c;
                asset.First_AMC_PO_Value__c = firstAMC.AMC_PO_Value__c;

                assetsToUpdate.add(asset);
            }
            else {
                Asset asset = new Asset();
                asset.Id = assetId;
                asset.AMC_Number__c = 0;

                asset.AMC_Start_Date__c = null;
                asset.AMC_End_Date__c = null;
                asset.AMC_Period_Months__c = null;
                asset.AMC_PO_Value__c = null;
                asset.AMC_SE_Name__c = null;

                asset.Previous_AMC_Start_Date__c = null;
                asset.Previous_AMC_End_Date__c = null;
                asset.Previous_AMC_Period_Months__c = null;
                asset.Previous_AMC_PO_Value__c = null;
                asset.Previous_AMC_SE_Name__c = null;

                asset.First_AMC_Start_Date__c = null;
                asset.First_AMC_End_Date__c = null;
                asset.First_AMC_Period_Months__c = null;
                asset.First_AMC_PO_Value__c = null;



                assetsToUpdate.add(asset);
            }
        }

        if(!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
    }


    public static void markLatestAMC(List<Asset_AMC__c> newAMCs, Map<Id, Asset_AMC__c> oldMap) {
        
        Set<Id> assetIds = new Set<Id>();
        
        // Collect Asset IDs
        if(newAMCs != null) {
            for(Asset_AMC__c amc : newAMCs) {
                if(amc.Asset__c != null) assetIds.add(amc.Asset__c);
            }
        }
        
        if(oldMap != null) {
            for(Asset_AMC__c oldAmc : oldMap.values()) {
                if(oldAmc.Asset__c != null) assetIds.add(oldAmc.Asset__c);
            }
        }
        
        if(assetIds.isEmpty()) return;
        
        // SINGLE QUERY: Get max end date per asset using Aggregate
        Map<Id, Date> maxEndDateByAsset = new Map<Id, Date>();
        for(AggregateResult ar : [
            SELECT Asset__c assetId, MAX(AMC_End_Date__c) maxEndDate
            FROM Asset_AMC__c 
            WHERE Asset__c IN :assetIds
            AND AMC_End_Date__c != null
            GROUP BY Asset__c
        ]) {
            maxEndDateByAsset.put((Id)ar.get('assetId'), (Date)ar.get('maxEndDate'));
        }
        
        // SINGLE QUERY: Get all AMCs for these assets
        List<Asset_AMC__c> allAMCs = [
            SELECT Id, Asset__c, AMC_End_Date__c, Is_Latest_AMC__c
            FROM Asset_AMC__c 
            WHERE Asset__c IN :assetIds
        ];
        
        // Prepare updates
        List<Asset_AMC__c> amcsToUpdate = new List<Asset_AMC__c>();
        
        for(Asset_AMC__c amc : allAMCs) {
            Boolean shouldBeLatest = false;
            
            if(amc.AMC_End_Date__c != null && maxEndDateByAsset.containsKey(amc.Asset__c)) {
                if(amc.AMC_End_Date__c == maxEndDateByAsset.get(amc.Asset__c)) {
                    shouldBeLatest = true;
                }
            }
            
            if(amc.Is_Latest_AMC__c != shouldBeLatest) {
                amc.Is_Latest_AMC__c = shouldBeLatest;
                amcsToUpdate.add(amc);
            }
        }
        
        // SINGLE DML
        if(!amcsToUpdate.isEmpty()) {
            update amcsToUpdate;
        }
    }

}