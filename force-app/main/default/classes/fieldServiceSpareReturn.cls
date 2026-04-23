public with sharing class fieldServiceSpareReturn {
    @AuraEnabled
    public static List<Work_Order__c> getWorkOrderData(String woid) {
        return [SELECT Id, Case__r.Type, Case__r.CaseNumber, Case__r.Account.Name, Case__r.Account.Pricelist__c, Case__r.CreatedDate, Case__r.Asset.SerialNumber,
                Case__r.Asset.ProductCode, Case__r.Asset.Product2Id
                FROM Work_Order__c
                WHERE Case__c != null AND Case__r.AssetId != null AND Id =: woid];
    }


    @AuraEnabled
    public static Object getSpareRequests(String workOrderId) {
        // List<Map<String, Object>> mpList = new List<Map<String, Object>>();

        // List<Spare_Request__c> spareList = [SELECT Id, Name, Quantity_Required__c, CurrencyIsoCode,Pricebook_Entry_Id__c, Billed_Value__c, Item_Master__c, Item_Description__c, Item_Master__r.Name
        //                                     FROM Spare_Request__c
        //                                     WHERE Work_Order__c = :workOrderId
        //                                     ];
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();

        // Query Spare Requests
        List<Spare_Request__c> spareList = [
            SELECT Id,Item_Master__c, Name, Quantity_Required__c, CurrencyIsoCode, Pricebook_Entry_Id__c, Billed_Value__c, 
                 Item_Description__c, Item_Master__r.Name
            FROM Spare_Request__c
            WHERE Work_Order__c = :workOrderId
        ];
        System.debug('spareList' + spareList);

        // Set<String> setName = new Set<String>();
        // for (Spare_Request__c spare : spareList) {
        //     if (spare.Item_Master__c != null) {
        //         setName.add(spare.Item_Master__c);
        //     }
        // }

        Set<Id> itemMasterIds = new Set<Id>();
        for (Spare_Request__c spare : spareList) {
            if (spare.Item_Master__c != null) {
                itemMasterIds.add(spare.Item_Master__c);
            }
        }
        System.debug('itemMasterIds'+ itemMasterIds);

        // Map<String, List<String>> productImageMap = new Map<String, List<String>>();
        // if (!setName.isEmpty()) {
        //     List<ContentDocumentLink> contentLinks = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
        //                                             FROM ContentDocumentLink
        //                                             WHERE LinkedEntityId IN :setName];

        //     for (ContentDocumentLink link : contentLinks) {
        //         if (!productImageMap.containsKey(link.LinkedEntityId)) {
        //             productImageMap.put(link.LinkedEntityId, new List<String>());
        //         }
        //         productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
        //     }
        // } else {
        //     System.debug('setName is empty, skipping ContentDocumentLink query');
        // }

        // for (Spare_Request__c spare : spareList) {
        //     Map<String, Object> params = new Map<String, Object>();
        //     params.put('Id', spare.Id);
        //     params.put('prodName', spare.Name);
        //     params.put('modelName', spare.Item_Master__r.Name);
        //     params.put('modelDesc', spare.Item_Description__c);
        //     params.put('quantityReq', spare.Quantity_Required__c != null ? String.valueOf(spare.Quantity_Required__c) : '0');
        //     params.put('price', spare.Billed_Value__c != null ? String.valueOf(spare.Billed_Value__c) : '0');
        //     params.put('currency', spare.CurrencyIsoCode);
        //     params.put('pricebookEntryId', spare.Pricebook_Entry_Id__c);
        //     if (productImageMap.containsKey(spare.Item_Master__c)) {
        //         params.put('imageUrls', productImageMap.get(spare.Item_Master__c));
        //     }
        //     mpList.add(params);
        // }

        // return mpList;
        Map<Id, List<String>> productImageMap = new Map<Id, List<String>>();
    if (!itemMasterIds.isEmpty()) {
        List<ContentDocumentLink> contentLinks = [
            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :itemMasterIds
        ];

        for (ContentDocumentLink link : contentLinks) {
            if (!productImageMap.containsKey(link.LinkedEntityId)) {
                productImageMap.put(link.LinkedEntityId, new List<String>());
            }
            productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
        }
    } else {
        System.debug('No Item_Master__c IDs found, skipping ContentDocumentLink query.');
    }

    // Prepare the result list
    for (Spare_Request__c spare : spareList) {
        Map<String, Object> spareMap = new Map<String, Object>();
        spareMap.put('Id', spare.Id);
        spareMap.put('prodName', spare.Name);
        spareMap.put('modelName', spare.Item_Master__r != null ? spare.Item_Master__r.Name : '');
        spareMap.put('modelDesc', spare.Item_Description__c);
        spareMap.put('quantityReq', spare.Quantity_Required__c != null ? String.valueOf(spare.Quantity_Required__c) : '0');
        spareMap.put('price', spare.Billed_Value__c != null ? String.valueOf(spare.Billed_Value__c) : '0');
        spareMap.put('currency', spare.CurrencyIsoCode);
        spareMap.put('pricebookEntryId', spare.Pricebook_Entry_Id__c);

        // Add image URLs if available
        if (spare.Item_Master__c != null && productImageMap.containsKey(spare.Item_Master__c)) {
            spareMap.put('imageUrls', productImageMap.get(spare.Item_Master__c));
        } else {
            spareMap.put('imageUrls', new List<String>()); // Default to empty list if no images
        }

        resultList.add(spareMap);
    }

    return resultList;
    }


    @AuraEnabled
    public static void createSpareReturns(String workOrderId, List<Map<String, Object>> spareParts) {
        if (String.isEmpty(workOrderId) || spareParts.isEmpty()) {
            throw new AuraHandledException('Invalid input data');
        }

        
        // Retrieve Case ID from Work Order
    Work_Order__c workOrder = [SELECT Id, Case__c,Case__r.AssetId FROM Work_Order__c WHERE Id = :workOrderId LIMIT 1];

    if (workOrder == null || workOrder.Case__c == null) {
        throw new AuraHandledException('No related Case found for the Work Order.');
    }
    Id assetId = workOrder.Case__r.AssetId; // Fetch the asset linked to the case

        List<Spare_Return__c> spareRequests = new List<Spare_Return__c>();
        Set<String> modelNames = new Set<String>();

        for (Map<String, Object> spare : spareParts) {
            if ((Boolean) spare.get('checkbox') && spare.get('quantity') != null) {
                modelNames.add((String) spare.get('modelName'));
            }
        }

        Map<String, Id> modelNameToIdMap = new Map<String, Id>();
        for (Product2 model : [SELECT Id, Name FROM Product2  WHERE Name IN :modelNames]) {
            modelNameToIdMap.put(model.Name, model.Id);
        }

        for (Map<String, Object> spare : spareParts) {
            if ((Boolean) spare.get('checkbox') && spare.get('quantity') != null) {
            Id modelId = modelNameToIdMap.get((String) spare.get('modelName'));
                spareRequests.add(new Spare_Return__c(
                    Work_Order__c = workOrderId,
                    Case__c = workOrder.Case__c, // Assign Case ID from Work Order
                    Asset__c = assetId, // Assign Asset from Case
                    //Spare_Part__c = (String) spare.get('Id'),
                    Return_Quantity__c = (Decimal) spare.get('quantity'),
                    Name = (String) spare.get('prodName'),
                    Item_Master__c = modelId,
                    // Item_Master__c = (String) spare.get('modelName'),
                    Item_Description__c = (String) spare.get('modelDesc'),
                    Price__c = decimal.valueOf((String) spare.get('price')),
                    Pricebook_Entry_Id__c = (String) spare.get('pricebookEntryId'),
                    Quantity__c = Decimal.valueOf((String) spare.get('quantityReq'))

                ));
            }
        }

        if (!spareRequests.isEmpty()) {
            insert spareRequests;
        }
    }

}