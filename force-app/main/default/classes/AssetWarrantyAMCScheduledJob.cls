global class AssetWarrantyAMCScheduledJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        runUpdateLogic();
    }

    public static void runUpdateLogic() {
        WarrantyExpiryUpdateBatch warrantyBatch = new WarrantyExpiryUpdateBatch(); //update warranty status
        Database.executeBatch(warrantyBatch);

        AmcExprityUpdateBatch amcBatch = new AmcExprityUpdateBatch();
        Database.executeBatch(amcBatch);  // update amc status
    }


    //updateWarrantyStatus();
        //updateAMCStatus();
       // updateAssetType();

    /*private static void updateWarrantyStatus() {
        List<Asset_Warranty__c> warrantiesToUpdate = [
            SELECT Id, Warranty_End_Date__c, Asset_Warranty_PO_Status__c
            FROM Asset_Warranty__c
            WHERE Warranty_End_Date__c != NULL AND Asset__c != NULL
        ];

        Date today = Date.today();
        List<Asset_Warranty__c> updateList = new List<Asset_Warranty__c>();

        for (Asset_Warranty__c warranty : warrantiesToUpdate) {
            String newStatus = (warranty.Warranty_End_Date__c >= today) ? 'Active' : 'Expired';

            if (warranty.Asset_Warranty_PO_Status__c != newStatus) {
                warranty.Asset_Warranty_PO_Status__c = newStatus;
                updateList.add(warranty);
            }
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
    }


    private static void updateAMCStatus() {
        List<Asset_AMC__c> amcRecordsToUpdate = [
            SELECT Id, AMC_End_Date__c, Asset_AMC_PO_Status__c
            FROM Asset_AMC__c
            WHERE AMC_End_Date__c != NULL
        ];

        Date today = Date.today();
        List<Asset_AMC__c> updateList = new List<Asset_AMC__c>();

        for (Asset_AMC__c amc : amcRecordsToUpdate) {
            String newStatus = (amc.AMC_End_Date__c >= today) ? 'Active' : 'Expired';

            if (amc.Asset_AMC_PO_Status__c != newStatus) {
                amc.Asset_AMC_PO_Status__c = newStatus;
                updateList.add(amc);
            }
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
    }


    private static void updateAssetType() {

        List<Asset_Warranty__c> warranties = [
            SELECT Id, Asset_Warranty_PO_Status__c, Asset__c
            FROM Asset_Warranty__c
            WHERE Asset__c != NULL
        ];


        Set<Id> assetIds = new Set<Id>();
        for (Asset_Warranty__c warranty : warranties) {
            assetIds.add(warranty.Asset__c);
        }
        Map<Id, Boolean> assetHasAMC = new Map<Id, Boolean>();
        for (Asset_AMC__c amc : [
            SELECT Id, Asset__c FROM Asset_AMC__c WHERE Asset__c IN :assetIds
        ]) {
            assetHasAMC.put(amc.Asset__c, true);
        }
        List<Asset> assetsToUpdate = [SELECT Id, Type__c FROM Asset WHERE Id IN :assetIds];
        List<Asset> updateList = new List<Asset>();
        for (Asset asset : assetsToUpdate) {
            for (Asset_Warranty__c warranty : warranties) {
                if (warranty.Asset__c != null && warranty.Asset__c.equals(asset.Id)) { // Use equals() for Id comparison
                    String newType;

                    if (warranty.Asset_Warranty_PO_Status__c == 'Active') {
                        newType = 'Within Warranty';
                    } else if (warranty.Asset_Warranty_PO_Status__c == 'Expired' && assetHasAMC.containsKey(asset.Id)) {
                        newType = 'Within AMC';
                    } else {
                        newType = 'Non AMC';
                    }

                    if (asset.Type__c != newType) {
                        asset.Type__c = newType;
                        updateList.add(asset);
                    }
                }
            }
        }

        // Perform update if list is not empty
        if (!updateList.isEmpty()) {
            update updateList;
        }

    }*/
}