public without sharing class FieldsServiceSpareRequest {
    
    @AuraEnabled
    public static Quote getQuoteRecordDetails(String quoteId) {
        try {
            return [SELECT Id, Work_Order__c, Case__c, Asset_Serial_Number__c FROM Quote WHERE Id =: quoteId];
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Work_Order__c> getWorkOrderData(String woId) {
        return [SELECT Id, Case__r.Type, Case__r.CaseNumber, Case__r.Account.Name, Case__r.Account.Pricelist__c, Case__r.CreatedDate, Case__r.Asset.SerialNumber,
                Case__r.Asset.ProductCode,Case__r.Asset.Invoice_Number__c, Case__r.Asset.Product2Id, Case__r.Asset.Name, Case__r.Asset.InstallDate, Case__r.Asset.Type__c,case__r.Division__c
                FROM Work_Order__c
                WHERE Id =: woId];
    }
    
    
    @AuraEnabled
    public static Work_Order__c getWorkOrderData1(String woId) {
        return [SELECT Id, Case__r.Type, Case__r.CaseNumber, Case__r.Account.Name, Case__r.Account.Pricelist__c, Case__r.CreatedDate, Case__r.Asset.SerialNumber,
                Case__r.Asset.ProductCode,Case__r.Asset.Invoice_Number__c, Case__r.Asset.Product2Id,Case__r.Asset.Name,Case__r.Division__c
                FROM Work_Order__c
                WHERE Id =: woId];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Object getAssetDetails(String woId) {
        try {
            Work_Order__c wo = [SELECT Id, Case__r.AssetId FROM Work_Order__c WHERE Id =: woId];
            Asset asset = [SELECT Id, Name, SerialNumber,
                        (
                            SELECT Id, Warranty_Start_Date__c, Warranty_End_Date__c
                            FROM Asset_Warranty__r
                        ),
                        (
                            SELECT Id, AMC_Start_Date__c, AMC_End_Date__c
                            FROM Asset_AMCs__r
                        )
                        FROM Asset
                        WHERE Id =: wo.Case__r.AssetId];
            return asset;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    
    @AuraEnabled
    public static String getSparePartsByName(String productId, String woId,Boolean showAll) {
        if (String.isEmpty(productId)) {
            throw new AuraHandledException('Product ID cannot be empty');
        }
        
        Work_Order__c workOrder = [SELECT Id, Case__r.Division__c FROM Work_Order__c WHERE Id = :woId];
        
        List<Equipment_Spare_Master__c> eqList=new List<Equipment_Spare_Master__c>();
        if(!showAll){
            eqList = [SELECT SAP_Material_Code_Spare__r.HSN_Code__c,SAP_Material_Code_Spare__r.HSN_Code__r.Name,Vendor_Material_Code_part_code__c,SAP_Material_Code_Spare__r.Name,SAP_Material_Code_Spare__r.Warranty__c, SAP_Material_code_Spare_Description__c, SAP_Material_Code_Spare__c,
                                                Returnable_NonReturnable__c,Chargeable_NonChargeable__c,SAP_Nilkamal_Model_Code_Equipment__r.Name,
                                                SAP_Nilkamal_Model_Code_Equipment__r.Description,
                                                SAP_Nilkamal_Model_Code_Equipment__c,SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
                                                FROM Equipment_Spare_Master__c
                                                WHERE SAP_Nilkamal_Model_Code_Equipment__c =: productId];
        }else{
            eqList = [SELECT SAP_Material_Code_Spare__r.HSN_Code__c,SAP_Material_Code_Spare__r.HSN_Code__r.Name,Vendor_Material_Code_part_code__c,SAP_Material_Code_Spare__r.Name,SAP_Material_Code_Spare__r.Warranty__c,SAP_Material_code_Spare_Description__c, SAP_Material_Code_Spare__c,
                                                Returnable_NonReturnable__c,Chargeable_NonChargeable__c,SAP_Nilkamal_Model_Code_Equipment__r.Name,
                                                SAP_Nilkamal_Model_Code_Equipment__r.Description,
                                                SAP_Nilkamal_Model_Code_Equipment__c,SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
                                                FROM Equipment_Spare_Master__c
                                                WHERE SAP_Material_Code_Spare__r.Business_Vertical__c = : workOrder.Case__r.Division__c
                                                ];
        }
        
        
        String priceListValue = null;
        workOrder = getWorkOrderData1(woId);
        priceListValue = workOrder.Case__r.Account.Pricelist__c;
        
        Set<String> setName = new Set<String>();
        for (Equipment_Spare_Master__c eq : eqList) {
            setName.add(eq.SAP_Material_Code_Spare__c);
        }
        
        List<Inventory__c> inventoryList=new List<Inventory__c>();
        Map<String,Decimal> mpInv=new Map<String,Decimal>();
        inventoryList=[SELECT Id,Material__c,Quantity__c,Plant_Master__r.Plant_Code__c FROM Inventory__c WHERE Material__c IN :setName];
        for(Inventory__c inv:inventoryList){
            mpInv.put(inv.Material__c+'_'+inv.Plant_Master__r.Plant_Code__c,inv.Quantity__c);
        }
        
        
        Map<String, Map<String, Object>> mapName = new Map<String, Map<String, Object>>();
        if (!setName.isEmpty()) {
            List<PricebookEntry> listName = [SELECT Id, Name, UnitPrice, Product2Id,CurrencyIsoCode, Product2.Name, Pricebook2Id, Pricebook2.Name,
                                            Product2.Description, Product2.Base_UOM__r.Name
                                            FROM PricebookEntry
                                            WHERE Product2Id IN :setName AND Pricebook2Id = :priceListValue AND IsActive = true AND Product2.IsActive = true];
            
            for (PricebookEntry pbe : listName) {
                Map<String, Object> pricebookDetails = new Map<String, Object>();
                pricebookDetails.put('unitPrice', pbe.UnitPrice);
                pricebookDetails.put('pricebookEntryId', pbe.Id);
                pricebookDetails.put('CurrencyIsoCode', pbe.CurrencyIsoCode);
                mapName.put(pbe.Product2Id, pricebookDetails);
            }
        } else {
            System.debug('setName is empty, skipping PricebookEntry query');
        }
        
        Map<String, List<String>> productImageMap = new Map<String, List<String>>();
        if (!setName.isEmpty()) {
            List<ContentDocumentLink> contentLinks = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId IN :setName AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
                                                    ORDER BY ContentDocument.LatestPublishedVersion.FileType];
            
            for (ContentDocumentLink link : contentLinks) {
                if (!productImageMap.containsKey(link.LinkedEntityId)) {
                    productImageMap.put(link.LinkedEntityId, new List<String>());
                }
                productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
            }
        } else {
            System.debug('setName is empty, skipping ContentDocumentLink query');
        }
        
        List<Spare_Request__c>  sparelist=new List<Spare_Request__c>();
        sparelist=[SELECT Id,Number_of_Breakdown_Visit__c,Number_of_PM_Visit__c,Warranty_Period__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
                                FROM Spare_Request__c
                                WHERE Work_Order__c=:woId
                                AND Quote__c=null
                                AND Quote_Line_Item__c = null
                                Order By CreatedDate DESC];
        Map<String,Integer> mpIds=new Map<String,Integer>();
        Map<String,Spare_Request__c> mpSpareRequest=new Map<String,Spare_Request__c>();
        Map<String,Spare_Request__c> mpWarrentyPe=new Map<String,Spare_Request__c>();
        for(Spare_Request__c sp:sparelist){
            if(!mpIds.containsKey(sp.Item_Master__c)){
                mpIds.put(sp.Item_Master__c, (Integer)sp.Quantity_Required__c);
                mpSpareRequest.put(sp.Item_Master__c, sp);
                if(sp.Warranty_Period__c!=null){
                    mpWarrentyPe.put(sp.Item_Master__c, sp);
                }
            }
        }
        
        List<Asset> assetList=new List<Asset>();
        assetList=[SELECT Id,AccountId,Product2Id,Type__c FROM Asset WHERE ParentId = :workOrder.Case__r.AssetId AND Product2Id IN:setName];
        Map<String,String> mpIds2=new Map<String,String>();
        for(Asset sp:assetList){
            if(sp.Type__c =='Within Warranty'){
                mpIds2.put(sp.Product2Id, sp.Id);
            }
            
        }
        
        List<Map<String, Object>> mpList = new List<Map<String, Object>>();
        Set<String> uniqueSpares=new Set<String>();
        for (Equipment_Spare_Master__c eq : eqList) {
            
            if(!uniqueSpares.contains(eq.SAP_Material_Code_Spare__c)){
                Map<String, Object> params = new Map<String, Object>();
                params.put('prodName', eq.SAP_Material_Code_Spare__r.Name);
                params.put('prodId', eq.SAP_Material_Code_Spare__c);
                params.put('modelName', eq.Vendor_Material_Code_part_code__c);
                params.put('modelDesc', eq.SAP_Material_code_Spare_Description__c);
                params.put('hsncode', eq.SAP_Material_Code_Spare__r.HSN_Code__r.Name);
                params.put('returnableNonReturnable', eq.Returnable_NonReturnable__c);
                params.put('chargeableNonChargeable', eq.Chargeable_NonChargeable__c);
                params.put('materialCode', eq.SAP_Nilkamal_Model_Code_Equipment__r.ProductCode);
                params.put('plantName', eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c);
                
                if (mapName.containsKey(eq.SAP_Material_Code_Spare__c)) {
                    Map<String, Object> pricebookDetails = mapName.get(eq.SAP_Material_Code_Spare__c);
                    params.put('price', String.valueOf(pricebookDetails.get('unitPrice')));
                    if(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c)!=null){
                        params.put('calculatedPrice', String.valueOf(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c).Billed_Value__c));
                    }else{
                        params.put('calculatedPrice', '');
                    }
                    params.put('pricebookEntryId', String.valueOf(pricebookDetails.get('pricebookEntryId')));
                    params.put('currencyCode', String.valueOf(pricebookDetails.get('CurrencyIsoCode')));
                } else {
                    params.put('price', '');
                    params.put('calculatedPrice', '');
                    continue;
                }
                
                params.put('Id', eq.Id);
                
                if (productImageMap.containsKey(eq.SAP_Material_Code_Spare__c)) {
                    params.put('imageUrls', productImageMap.get(eq.SAP_Material_Code_Spare__c));
                }
                //added by shashank
                if(mpIds.containsKey(eq.SAP_Material_Code_Spare__c)){
                    params.put('quantity',mpIds.get(eq.SAP_Material_Code_Spare__c));
                }else{
                    params.put('quantity',0);
                }
                
                if(mpIds2.get(eq.SAP_Material_Code_Spare__c) != null){
                    params.put('withinWarenty',true);
                }else{
                    params.put('withinWarenty',false);
                }
                
                if(eq.SAP_Material_Code_Spare__r.Warranty__c!=null){
                    params.put('warranty',eq.SAP_Material_Code_Spare__r.Warranty__c);
                }else{
                    params.put('warranty','N');
                }
                
                if(mpWarrentyPe.get(eq.SAP_Material_Code_Spare__c)!=null){
                    params.put('warrantyperiod',mpWarrentyPe.get(eq.SAP_Material_Code_Spare__c).Warranty_Period__c);
                    params.put('noofpmvisit',mpWarrentyPe.get(eq.SAP_Material_Code_Spare__c).Number_of_PM_Visit__c);
                    params.put('noofbreakdownvisit',mpWarrentyPe.get(eq.SAP_Material_Code_Spare__c).Number_of_Breakdown_Visit__c);
                }else{
                    params.put('warrantyperiod',null);
                    params.put('noofpmvisit',null);
                    params.put('noofbreakdownvisit',null);
                }
                
                if(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c)!=null){
                    params.put('billingType',mpSpareRequest.get(eq.SAP_Material_Code_Spare__c).Billing_Type__c);
                }else{
                    params.put('billingType','');
                }
                
                if(mpInv.get(eq.SAP_Material_Code_Spare__c+'_'+eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c)!=null){
                    params.put('totalStock',String.valueOf(mpInv.get(eq.SAP_Material_Code_Spare__c+'_'+eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c)));
                }else{
                    params.put('totalStock',0);
                }
                
                
                
                mpList.add(params);
                uniqueSpares.add(eq.SAP_Material_Code_Spare__c);
            }
            
        }
        
        return JSON.serialize(mpList);
    }
    
    @AuraEnabled
    public static List<PricebookEntry> getAllSpares(String productId, String woId ,Boolean isMobile, String searchKey) {
        if (String.isEmpty(productId)) {
            throw new AuraHandledException('Product ID cannot be empty');
        }
        // Work_Order__c workOrderd = getWorkOrderData1(woId);
        // String priceListValue = workOrderd.Case__r.Account.Pricelist__c;
        // // Step 2: Load PricebookEntry
        //     List<PricebookEntry> listName = [
        //         SELECT Id, Name, Product2.Plant_Master__r.Plant_Code__c, Product2.ProductCode, Product2.Warranty__c,
        //             Product2.Name, Product2.Category__c, Product2.HSN_Code__r.Name, Product2.Material_Group_6__c,
        //             UnitPrice, Product2Id, CurrencyIsoCode, Pricebook2Id, Pricebook2.Name, Product2.Description,
        //             Product2.Base_UOM__r.Name
        //         FROM PricebookEntry
        //         WHERE Product2.Category__c = 'Spare'
        //             AND Product2.Business_Vertical__c =:workOrderd.Case__r.Division__c
        //             AND Pricebook2Id = :priceListValue
        //             AND IsActive = true
        //     ];
        //     return listName;
        Work_Order__c workOrderd = getWorkOrderData1(woId);
        String priceListValue = workOrderd.Case__r.Account.Pricelist__c;
        String businessVertical = workOrderd.Case__r.Division__c;
        
        // Base query
        String query = 'SELECT Id, Name, Product2.Plant_Master__r.Plant_Code__c, Product2.ProductCode, ' +
            'Product2.Warranty__c, Product2.Name, Product2.Category__c, Product2.HSN_Code__r.Name, ' +
            'Product2.Material_Group_6__c, UnitPrice, Product2Id, CurrencyIsoCode, Pricebook2Id, ' +
            'Pricebook2.Name, Product2.Description, Product2.Base_UOM__r.Name ' +
            'FROM PricebookEntry ' +
            'WHERE Product2.Category__c = \'Spare\' ' +
            'AND Product2.Business_Vertical__c = :businessVertical ' +
            'AND Pricebook2Id = :priceListValue ' +
            'AND Product2.IsActive = true ' +
            'AND IsActive = true ';
        
        // Mobile → apply search and limit
        if (isMobile) {
            if (String.isNotBlank(searchKey)) {
                String likeSearch = '%' + searchKey + '%';
                query += 'AND (Product2.Name LIKE :likeSearch OR Product2.Description LIKE :likeSearch) ';
            }
            query += 'ORDER BY Product2.Name LIMIT 50';
        }
        system.debug('Final Query: ' + query);
        return Database.query(query);
    }
    
    @AuraEnabled
    public static Map<String, Object> getAllSparesDetails(String productId, String woId, String setNamelstJson, List<String> setName) {
        if (String.isEmpty(productId)) {
            throw new AuraHandledException('Product ID cannot be empty');
        }
        
        if(setName != null && setName.size() > 0) {
            
        }
        else {
            setName = (List<String>) JSON.deserialize(setNamelstJson, List<String>.class);
        }
        
        Work_Order__c workOrderd = getWorkOrderData1(woId);
        
        List<Equipment_Spare_Master__c> eqList = [
            SELECT SAP_Material_Code_Spare__r.HSN_Code__c, SAP_Material_Code_Spare__r.HSN_Code__r.Name,
                Vendor_Material_Code_part_code__c, SAP_Material_Code_Spare__r.Name,
                SAP_Material_Code_Spare__r.Warranty__c, SAP_Material_code_Spare_Description__c,
                SAP_Material_Code_Spare__c, Returnable_NonReturnable__c, Chargeable_NonChargeable__c,
                SAP_Nilkamal_Model_Code_Equipment__r.Name, SAP_Nilkamal_Model_Code_Equipment__r.Description,
                SAP_Nilkamal_Model_Code_Equipment__c, SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,
                SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
            FROM Equipment_Spare_Master__c
            WHERE SAP_Material_Code_Spare__r.Business_Vertical__c = :workOrderd.Case__r.Division__c
        ];
        
        List<Inventory__c> inventoryList = [
            SELECT Id, Material__c, Quantity__c, Plant_Master__r.Plant_Code__c
            FROM Inventory__c
            WHERE Material__c IN :setName
        ];
        
        List<ContentDocumentLink> contentLinks =new List<ContentDocumentLink>();
        if(setName.size()>0){
            contentLinks=[
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :setName
                AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
            ];
        }
        
        List<Spare_Request__c> spareList = [
            SELECT Id, Number_of_Breakdown_Visit__c, Number_of_PM_Visit__c, Warranty_Period__c, Name,
                Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
            FROM Spare_Request__c

            WHERE Work_Order__c = :woId AND Quote__c = null
                    AND Quote_Line_Item__c = null AND Item_Master__c IN :setName
        ];
        
        List<Asset> assetList = [
            SELECT Id, AccountId, Product2Id, Type__c
            FROM Asset
            WHERE ParentId = :workOrderd.Case__r.AssetId AND Product2Id IN :setName
        ];
        
        Map<String, Object> result = new Map<String, Object>();
        result.put('eqList', eqList);
        result.put('inventory', inventoryList);
        result.put('contentLinks', contentLinks);
        result.put('spareList', spareList);
        result.put('assetList', assetList);
        
        return result;
    }
    
    @AuraEnabled
    public static String getAssetCategory(String productId, String woId,String Category) {
        
        List<Equipment_Spare_Master__c> eqList=new List<Equipment_Spare_Master__c>();
        eqList = [SELECT SAP_Material_Code_Spare__r.HSN_Code__c,SAP_Material_Code_Spare__r.HSN_Code__r.Name,Vendor_Material_Code_part_code__c,SAP_Material_Code_Spare__r.Name,SAP_Material_Code_Spare__r.Warranty__c, SAP_Material_code_Spare_Description__c, SAP_Material_Code_Spare__c,
                                                Returnable_NonReturnable__c,Chargeable_NonChargeable__c,SAP_Nilkamal_Model_Code_Equipment__r.Name,
                                                SAP_Nilkamal_Model_Code_Equipment__r.Description,
                                                SAP_Nilkamal_Model_Code_Equipment__c,SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
                                                FROM Equipment_Spare_Master__c
                                                WHERE SAP_Nilkamal_Model_Code_Equipment__c =: productId];
        
        
        
        String priceListValue = null;
        Work_Order__c workOrder = getWorkOrderData1(woId);
        priceListValue = workOrder.Case__r.Account.Pricelist__c;
        
        Set<String> setName = new Set<String>();
        for (Equipment_Spare_Master__c eq : eqList) {
            setName.add(eq.SAP_Material_Code_Spare__c);
        }
        
        List<Inventory__c> inventoryList=new List<Inventory__c>();
        Map<String,Decimal> mpInv=new Map<String,Decimal>();
        inventoryList=[SELECT Id,Material__c,Quantity__c,Plant_Master__r.Plant_Code__c FROM Inventory__c WHERE Material__c IN :setName];
        for(Inventory__c inv:inventoryList){
            mpInv.put(inv.Material__c+'_'+inv.Plant_Master__r.Plant_Code__c,inv.Quantity__c);
        }
        
        
        Map<String, Map<String, Object>> mapName = new Map<String, Map<String, Object>>();
        if (!setName.isEmpty()) {
            List<PricebookEntry> listName = [SELECT Id, Name, UnitPrice, Product2Id,CurrencyIsoCode, Product2.Name, Pricebook2Id, Pricebook2.Name,
                                            Product2.Description, Product2.Base_UOM__r.Name
                                            FROM PricebookEntry
                                            WHERE Product2Id IN :setName AND Pricebook2Id = :priceListValue AND IsActive = true];
            
            for (PricebookEntry pbe : listName) {
                Map<String, Object> pricebookDetails = new Map<String, Object>();
                pricebookDetails.put('unitPrice', pbe.UnitPrice);
                pricebookDetails.put('pricebookEntryId', pbe.Id);
                pricebookDetails.put('CurrencyIsoCode', pbe.CurrencyIsoCode);
                mapName.put(pbe.Product2Id, pricebookDetails);
            }
        } else {
            System.debug('setName is empty, skipping PricebookEntry query');
        }
        
        Map<String, List<String>> productImageMap = new Map<String, List<String>>();
        if (!setName.isEmpty()) {
            List<ContentDocumentLink> contentLinks = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId IN :setName AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
                                                    ORDER BY ContentDocument.LatestPublishedVersion.FileType];
            
            for (ContentDocumentLink link : contentLinks) {
                if (!productImageMap.containsKey(link.LinkedEntityId)) {
                    productImageMap.put(link.LinkedEntityId, new List<String>());
                }
                productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
            }
        } else {
            System.debug('setName is empty, skipping ContentDocumentLink query');
        }
        
        
        List<Spare_Request__c>  sparelist=new List<Spare_Request__c>();
        sparelist=[SELECT Id,Number_of_Breakdown_Visit__c,Number_of_PM_Visit__c,Warranty_Period__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
                                FROM Spare_Request__c
                                WHERE Work_Order__c=:woId
                                Order By CreatedDate DESC];
        Map<String,Integer> mpSpareIds=new Map<String,Integer>();
        Map<String,Spare_Request__c> mpSpareRequest=new Map<String,Spare_Request__c>();
        for(Spare_Request__c sp:sparelist){
            mpSpareRequest.put(sp.Item_Master__c, sp);
            if(!mpSpareIds.containsKey(sp.Item_Master__c)){
                mpSpareIds.put(sp.Item_Master__c, (Integer)sp.Quantity_Required__c);
                
            }
        }
        
        List<Asset_Spare_Category__c> asseSPareCateo=new List<Asset_Spare_Category__c>();
        asseSPareCateo=[SELECT Id,Spare_Material_Code__c,Quantity__c
                                FROM Asset_Spare_Category__c
                                WHERE Spare_Material_Code__c IN :setName
                                AND Category__c=:Category
                                Order By CreatedDate DESC];
        Map<String,Integer> mpIds=new Map<String,Integer>();
        for(Asset_Spare_Category__c sp:asseSPareCateo){
            if(!mpIds.containsKey(sp.Spare_Material_Code__c)){
                mpIds.put(sp.Spare_Material_Code__c, (Integer)sp.Quantity__c);
            }
        }
        
        
        
        List<Asset> assetList=new List<Asset>();
        assetList=[SELECT Id,AccountId,Product2Id,Type__c FROM Asset WHERE Id=:workOrder.Case__r.AssetId AND Product2Id IN:setName];
        Map<String,String> mpIds2=new Map<String,String>();
        for(Asset sp:assetList){
            if(sp.Type__c =='Within Warranty'){
                mpIds2.put(sp.Product2Id, sp.Id);
            }
            
        }
        
        List<Map<String, Object>> mpList = new List<Map<String, Object>>();
        Set<String> uniqueSpares=new Set<String>();
        for (Equipment_Spare_Master__c eq : eqList) {
            
            if(!uniqueSpares.contains(eq.SAP_Material_Code_Spare__c)){
                Map<String, Object> params = new Map<String, Object>();
                params.put('prodName', eq.SAP_Material_Code_Spare__r.Name);
                params.put('prodId', eq.SAP_Material_Code_Spare__c);
                params.put('modelName', eq.Vendor_Material_Code_part_code__c);
                params.put('modelDesc', eq.SAP_Material_code_Spare_Description__c);
                params.put('hsncode', eq.SAP_Material_Code_Spare__r.HSN_Code__r.Name);
                params.put('returnableNonReturnable', eq.Returnable_NonReturnable__c);
                params.put('chargeableNonChargeable', eq.Chargeable_NonChargeable__c);
                params.put('materialCode', eq.SAP_Nilkamal_Model_Code_Equipment__r.ProductCode);
                params.put('plantName', eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c);
                
                if (mapName.containsKey(eq.SAP_Material_Code_Spare__c)) {
                    Map<String, Object> pricebookDetails = mapName.get(eq.SAP_Material_Code_Spare__c);
                    params.put('price', String.valueOf(pricebookDetails.get('unitPrice')));
                    if(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c)!=null){
                        params.put('calculatedPrice', String.valueOf(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c).Billed_Value__c));
                    }else{
                        params.put('calculatedPrice', '');
                    }
                    params.put('pricebookEntryId', String.valueOf(pricebookDetails.get('pricebookEntryId')));
                    params.put('currencyCode', String.valueOf(pricebookDetails.get('CurrencyIsoCode')));
                } else {
                    params.put('price', '');
                    params.put('calculatedPrice', '');
                    continue;
                }
                
                params.put('Id', eq.Id);
                
                if (productImageMap.containsKey(eq.SAP_Material_Code_Spare__c)) {
                    params.put('imageUrls', productImageMap.get(eq.SAP_Material_Code_Spare__c));
                }
                //added by shashank
                if(mpSpareIds.containsKey(eq.SAP_Material_Code_Spare__c)){
                    params.put('quantity',mpSpareIds.get(eq.SAP_Material_Code_Spare__c));
                }
                else if(mpIds.containsKey(eq.SAP_Material_Code_Spare__c)){
                    params.put('quantity',mpIds.get(eq.SAP_Material_Code_Spare__c));
                }else{
                    params.put('quantity',0);
                }
                
                if(mpIds2.get(eq.SAP_Material_Code_Spare__c) != null){
                    params.put('withinWarenty',true);
                }else{
                    params.put('withinWarenty',false);
                }
                
                if(eq.SAP_Material_Code_Spare__r.Warranty__c!=null){
                    params.put('warranty',eq.SAP_Material_Code_Spare__r.Warranty__c);
                }else{
                    params.put('warranty','N');
                }
                
                params.put('warrantyperiod','');
                params.put('noofpmvisit','');
                params.put('noofbreakdownvisit','');
                
                if(mpSpareRequest.get(eq.SAP_Material_Code_Spare__c)!=null){
                    params.put('billingType',mpSpareRequest.get(eq.SAP_Material_Code_Spare__c).Billing_Type__c);
                }else{
                    params.put('billingType','');
                }
                
                if(mpInv.get(eq.SAP_Material_Code_Spare__c+'_'+eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c)!=null){
                    params.put('totalStock',String.valueOf(mpInv.get(eq.SAP_Material_Code_Spare__c+'_'+eq.SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c)));
                }else{
                    params.put('totalStock',null);
                }
                mpList.add(params);
                uniqueSpares.add(eq.SAP_Material_Code_Spare__c);
            }
            
        }
        
        return JSON.serialize(mpList);
    }
    
    
    @AuraEnabled
    public static String getAssetCategory_v1(String productId, String woId,Boolean fastMoving, Boolean critical, Boolean consumables,Boolean mappedSpares) {
        
        List<Map<String, Object>> mpList = new List<Map<String, Object>>();
        Set<String> selectedCategories = new Set<String>();
        if (mappedSpares) {
            System.debug('inside the Mapped Spare');
            return getMappedSpares(productId, woId);
        }
        if (fastMoving) selectedCategories.add('Fast Moving');
        if (critical) selectedCategories.add('Critical');
        if (consumables) selectedCategories.add('Consumables');
        // Build category filter set
        if(selectedCategories.size()>0){
            Map<String,Equipment_Spare_Master__c> mpEquipIds=new Map<String,Equipment_Spare_Master__c>();
            List<Equipment_Spare_Master__c> eqList=new List<Equipment_Spare_Master__c>();
            System.debug('productId '+productId);
            eqList = [SELECT SAP_Material_Code_Spare__r.HSN_Code__c,SAP_Material_Code_Spare__r.HSN_Code__r.Name,Vendor_Material_Code_part_code__c,SAP_Material_Code_Spare__r.Name,SAP_Material_Code_Spare__r.Warranty__c, SAP_Material_code_Spare_Description__c, SAP_Material_Code_Spare__c,
                                                    Returnable_NonReturnable__c,Chargeable_NonChargeable__c,SAP_Nilkamal_Model_Code_Equipment__r.Name,
                                                    SAP_Nilkamal_Model_Code_Equipment__r.Description,
                                                    SAP_Nilkamal_Model_Code_Equipment__c,SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
                                                    FROM Equipment_Spare_Master__c
                                                    WHERE SAP_Nilkamal_Model_Code_Equipment__c =: productId];
            
            for(Equipment_Spare_Master__c eq: eqList){
                mpEquipIds.put(eq.SAP_Material_Code_Spare__c,eq);
            }
            
            Work_Order__c workOrder = getWorkOrderData1(woId);
            
            List<Asset_Spare_Category__c> asseSPareCateo=new List<Asset_Spare_Category__c>();
            asseSPareCateo=[SELECT Id,Spare_Material_Code__c,Quantity__c,Category__c,Asset_Serial_No__r.Product2Id
                                    FROM Asset_Spare_Category__c
                                    WHERE
                                    //Spare_Material_Code__c IN :setName AND
                                    Spare_Material_Code__r.Category__c='Spare'
                                    AND Asset_Serial_No__r.Product2Id=:productId
                                    AND Category__c IN :selectedCategories
                                    AND Asset_Serial_No__c=:workOrder.Case__r.AssetId
                                    Order By CreatedDate DESC];
            Map<String,Integer> mpIds=new Map<String,Integer>();
            Map<String,String> mpCat=new Map<String,String>();
            Set<String> asssetName = new Set<String>();
            for(Asset_Spare_Category__c sp:asseSPareCateo){
                if(!mpIds.containsKey(sp.Spare_Material_Code__c)){
                    asssetName.add(sp.Spare_Material_Code__c);
                    mpIds.put(sp.Spare_Material_Code__c, (Integer)sp.Quantity__c);
                    mpCat.put(sp.Spare_Material_Code__c, sp.Category__c);
                }
            }
            
            String query = 'SELECT Id,Plant_Master__r.Plant_Code__c, ProductCode, Warranty__c, Name, Description, Category__c, HSN_Code__r.Name, Material_Group_6__c ' +
                'FROM Product2 WHERE Category__c = \'Spare\' AND Business_Vertical__c = \'' + workOrder.Case__r.Division__c + '\' AND IsActive = true AND Id IN: asssetName';
            List<Product2> pdList = Database.query(query);
            
            String priceListValue = null;
            priceListValue = workOrder.Case__r.Account.Pricelist__c;
            
            Set<String> setName = new Set<String>();
            for (Product2 eq : pdList) {
                setName.add(eq.Id);
            }
            
            List<Inventory__c> inventoryList=new List<Inventory__c>();
            Map<String,Decimal> mpInv=new Map<String,Decimal>();
            inventoryList=[SELECT Id,Material__c,Quantity__c,Plant_Master__r.Plant_Code__c FROM Inventory__c WHERE Material__c IN :setName];
            for(Inventory__c inv:inventoryList){
                mpInv.put(inv.Material__c+'_'+inv.Plant_Master__r.Plant_Code__c,inv.Quantity__c);
            }
            
            
            Map<String, Map<String, Object>> mapName = new Map<String, Map<String, Object>>();
            if (!setName.isEmpty()) {
                List<PricebookEntry> listName = [SELECT Id, Name, UnitPrice, Product2Id,CurrencyIsoCode, Product2.Name, Pricebook2Id, Pricebook2.Name,
                                                Product2.Description, Product2.Base_UOM__r.Name
                                                FROM PricebookEntry
                                                WHERE Product2Id IN :setName AND Pricebook2Id = :priceListValue AND IsActive = true AND Product2.IsActive = true];
                
                for (PricebookEntry pbe : listName) {
                    Map<String, Object> pricebookDetails = new Map<String, Object>();
                    pricebookDetails.put('unitPrice', pbe.UnitPrice);
                    pricebookDetails.put('pricebookEntryId', pbe.Id);
                    pricebookDetails.put('CurrencyIsoCode', pbe.CurrencyIsoCode);
                    mapName.put(pbe.Product2Id, pricebookDetails);
                }
            } else {
                System.debug('setName is empty, skipping PricebookEntry query');
            }
            
            Map<String, List<String>> productImageMap = new Map<String, List<String>>();
            if (!setName.isEmpty()) {
                List<ContentDocumentLink> contentLinks = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityId IN :setName AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
                                                        ORDER BY ContentDocument.LatestPublishedVersion.FileType];
                
                for (ContentDocumentLink link : contentLinks) {
                    if (!productImageMap.containsKey(link.LinkedEntityId)) {
                        productImageMap.put(link.LinkedEntityId, new List<String>());
                    }
                    productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
                }
            } else {
                System.debug('setName is empty, skipping ContentDocumentLink query');
            }
            
            
            List<Spare_Request__c>  sparelist=new List<Spare_Request__c>();
            sparelist=[SELECT Id,Number_of_Breakdown_Visit__c,Number_of_PM_Visit__c,Warranty_Period__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                    Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
                                    FROM Spare_Request__c
                                    WHERE Work_Order__c=:woId
                                    Order By CreatedDate DESC];
            Map<String,Integer> mpSpareIds=new Map<String,Integer>();
            Map<String,Spare_Request__c> mpSpareRequest=new Map<String,Spare_Request__c>();
            for(Spare_Request__c sp:sparelist){
                mpSpareRequest.put(sp.Item_Master__c, sp);
                if(!mpSpareIds.containsKey(sp.Item_Master__c)){
                    mpSpareIds.put(sp.Item_Master__c, (Integer)sp.Quantity_Required__c);
                    
                }
            }
            
            List<Asset> assetList=new List<Asset>();
            assetList=[SELECT Id,AccountId,Product2Id,Type__c FROM Asset WHERE Id=:workOrder.Case__r.AssetId AND Product2Id IN:setName];
            Map<String,String> mpIds2=new Map<String,String>();
            for(Asset sp:assetList){
                if(sp.Type__c =='Within Warranty'){
                    mpIds2.put(sp.Product2Id, sp.Id);
                }
                
            }
            
            
            
            
            Set<String> uniqueSpares=new Set<String>();
            System.debug('selectedCategories '+selectedCategories.size());
            
            for (Product2 eq : pdList) {
                if(mpIds.get(eq.Id)!=null){
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('Id', eq.Id);
                    params.put('prodName', eq.Name);
                    params.put('prodId', eq.Id);
                    if(mpEquipIds.get(eq.Id)!=null){
                        params.put('modelName', mpEquipIds.get(eq.Id).Vendor_Material_Code_part_code__c);
                    }else{
                        params.put('modelName', '');
                    }
                    params.put('modelDesc', eq.Description);
                    params.put('hsncode', eq.HSN_Code__r.Name);
                    if(mpEquipIds.get(eq.Id)!=null){
                        params.put('returnableNonReturnable', mpEquipIds.get(eq.Id).Returnable_NonReturnable__c);
                    }else{
                        params.put('returnableNonReturnable', 'false');
                    }
                    
                    if(mpEquipIds.get(eq.Id)!=null){
                        params.put('chargeableNonChargeable', mpEquipIds.get(eq.Id).Chargeable_NonChargeable__c);
                    }else{
                        params.put('chargeableNonChargeable', 'false');
                    }
                    params.put('materialCode', eq.ProductCode);
                    params.put('plantName', eq.Plant_Master__r.Plant_Code__c);
                    
                    if (mapName.containsKey(eq.Id)) {
                        Map<String, Object> pricebookDetails = mapName.get(eq.Id);
                        params.put('price', String.valueOf(pricebookDetails.get('unitPrice')));
                        if(mpSpareRequest.get(eq.Id)!=null){
                            params.put('calculatedPrice', String.valueOf(mpSpareRequest.get(eq.Id).Billed_Value__c));
                        }else{
                            params.put('calculatedPrice', '');
                        }
                        params.put('pricebookEntryId', String.valueOf(pricebookDetails.get('pricebookEntryId')));
                        params.put('currencyCode', String.valueOf(pricebookDetails.get('CurrencyIsoCode')));
                    } else {
                        params.put('price', '');
                        params.put('calculatedPrice', '');
                        continue;
                    }
                    if (productImageMap.containsKey(eq.Id)) {
                        params.put('imageUrls', productImageMap.get(eq.Id));
                    }
                    //added by shashank
                    if(mpSpareIds.containsKey(eq.Id)){
                        params.put('quantity',mpSpareIds.get(eq.Id));
                    }
                    else if(mpIds.containsKey(eq.Id)){
                        params.put('quantity',mpIds.get(eq.Id));
                    }else{
                        params.put('quantity',0);
                    }
                    
                    if(mpIds2.get(eq.Id) != null){
                        params.put('withinWarenty',true);
                    }else{
                        params.put('withinWarenty',false);
                    }
                    
                    if(eq.Warranty__c!=null){
                        params.put('warranty',eq.Warranty__c);
                    }else{
                        params.put('warranty','N');
                    }
                    
                    params.put('warrantyperiod','');
                    params.put('noofpmvisit','');
                    params.put('noofbreakdownvisit','');
                    
                    if(mpSpareRequest.get(eq.Id)!=null){
                        params.put('billingType',mpSpareRequest.get(eq.Id).Billing_Type__c);
                    }else{
                        params.put('billingType','');
                    }
                    
                    if(mpInv.get(eq.Id+'_'+eq.Plant_Master__r.Plant_Code__c)!=null){
                        params.put('totalStock',String.valueOf(mpInv.get(eq.Id+'_'+eq.Plant_Master__r.Plant_Code__c)));
                    }else{
                        params.put('totalStock',null);
                    }
                    
                    if(mpCat.get(eq.Id)!=null){
                        if(mpCat.get(eq.Id) =='Fast Moving'){
                            params.put('category','F');
                        }
                        
                        if(mpCat.get(eq.Id) =='Critical'){
                            params.put('category','CR');
                        }
                        
                        if(mpCat.get(eq.Id) =='Consumables'){
                            params.put('category','C');
                        }
                    }else{
                        params.put('category','');
                    }
                    mpList.add(params);
                }
            }
        }
        else{
            String returnres=getSparePartsByName(productId, woId, false);
            return returnres;
        }
        
        return JSON.serialize(mpList);
    }
    
    
    private static String getMappedSpares(String productId, String woId) {
        List<Map<String, Object>> mpList = new List<Map<String, Object>>();
        System.debug('=== getMappedSpares START ===');
        System.debug('productId: ' + productId);
        System.debug('woId: ' + woId);
        // Get Equipment mappings
        Map<String, Equipment_Spare_Master__c> mpEquipIds = new Map<String, Equipment_Spare_Master__c>();
        List<Equipment_Spare_Master__c> eqList = [
        SELECT SAP_Material_Code_Spare__r.HSN_Code__c,
               SAP_Material_Code_Spare__r.HSN_Code__r.Name,
               Vendor_Material_Code_part_code__c,
               SAP_Material_Code_Spare__r.Name,
               SAP_Material_Code_Spare__r.Warranty__c,
               SAP_Material_code_Spare_Description__c,
               SAP_Material_Code_Spare__c,
               Returnable_NonReturnable__c,
               Chargeable_NonChargeable__c,
               SAP_Nilkamal_Model_Code_Equipment__r.Name,
               SAP_Nilkamal_Model_Code_Equipment__r.Description,
               SAP_Nilkamal_Model_Code_Equipment__c,
               SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,
               SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
        FROM Equipment_Spare_Master__c
        WHERE SAP_Nilkamal_Model_Code_Equipment__c = :productId
    ];
        
        for(Equipment_Spare_Master__c eq: eqList) {
            mpEquipIds.put(eq.SAP_Material_Code_Spare__c, eq);
        }
        System.debug('Mapped Equipment IDs: ' + mpEquipIds.keySet());
        Work_Order__c workOrder = getWorkOrderData1(woId);
        Set<String> allMappedSpareIds = mpEquipIds.keySet();
        
        // Get Product details for all mapped spares
        String query = 'SELECT Id, Plant_Master__r.Plant_Code__c, Warranty__c, Name, Description, Category__c, HSN_Code__r.Name, Material_Group_6__c, ProductCode ' +
            'FROM Product2 WHERE Category__c = \'Spare\' AND Business_Vertical__c = \'' + workOrder.Case__r.Division__c + '\' AND IsActive = true AND Id IN: allMappedSpareIds';
        List<Product2> pdList = Database.query(query);
        System.debug('pdList size: ' + pdList.size());
        Set<String> setName = new Set<String>();
        for (Product2 eq : pdList) {
            setName.add(eq.Id);
        }
        
        // Get Pricebook Entries
        String priceListValue = workOrder.Case__r.Account.Pricelist__c;
        Map<String, Map<String, Object>> mapName = new Map<String, Map<String, Object>>();
        if (!setName.isEmpty()) {
            List<PricebookEntry> listName = [
            SELECT Id, Name, UnitPrice, Product2Id, CurrencyIsoCode, Product2.Name, Pricebook2Id, Pricebook2.Name,
                   Product2.Description, Product2.Base_UOM__r.Name
            FROM PricebookEntry
            WHERE Product2Id IN :setName AND Pricebook2Id = :priceListValue AND IsActive = true AND Product2.IsActive = true
        ];
            
            for (PricebookEntry pbe : listName) {
                Map<String, Object> pricebookDetails = new Map<String, Object>();
                pricebookDetails.put('unitPrice', pbe.UnitPrice);
                pricebookDetails.put('pricebookEntryId', pbe.Id);
                pricebookDetails.put('CurrencyIsoCode', pbe.CurrencyIsoCode);
                mapName.put(pbe.Product2Id, pricebookDetails);
            }
        }
        
        // Get Images
        Map<String, List<String>> productImageMap = new Map<String, List<String>>();
        if (!setName.isEmpty()) {
            List<ContentDocumentLink> contentLinks = [
            SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :setName AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
            ORDER BY ContentDocument.LatestPublishedVersion.FileType
        ];
            
            for (ContentDocumentLink link : contentLinks) {
                if (!productImageMap.containsKey(link.LinkedEntityId)) {
                    productImageMap.put(link.LinkedEntityId, new List<String>());
                }
                productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
            }
        }
        
        // Get Inventory
        Map<String, Decimal> mpInv = new Map<String, Decimal>();
        List<Inventory__c> inventoryList = [
        SELECT Id, Material__c, Quantity__c, Plant_Master__r.Plant_Code__c 
        FROM Inventory__c 
        WHERE Material__c IN :setName
    ];
        for(Inventory__c inv: inventoryList) {
            mpInv.put(inv.Material__c + '_' + inv.Plant_Master__r.Plant_Code__c, inv.Quantity__c);
        }
        
        // Get Spare Requests
        Map<String, Spare_Request__c> mpSpareRequest = new Map<String, Spare_Request__c>();
        List<Spare_Request__c> sparelist = [
        SELECT Id, Number_of_Breakdown_Visit__c, Number_of_PM_Visit__c, Warranty_Period__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, 
               Opportunity_Product__c, Item_Description__c, Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
        FROM Spare_Request__c
        WHERE Work_Order__c = :woId
        Order By CreatedDate DESC
    ];
        for(Spare_Request__c sp: sparelist) {
            mpSpareRequest.put(sp.Item_Master__c, sp);
        }
        
        // Build response for each mapped spare
        for (Product2 eq : pdList) {
            Map<String, Object> params = new Map<String, Object>();
            params.put('Id', eq.Id);
            params.put('prodName', eq.Name);
            params.put('prodId', eq.Id);
            
            if(mpEquipIds.get(eq.Id) != null) {
                params.put('modelName', mpEquipIds.get(eq.Id).Vendor_Material_Code_part_code__c);
                params.put('returnableNonReturnable', mpEquipIds.get(eq.Id).Returnable_NonReturnable__c);
                params.put('chargeableNonChargeable', mpEquipIds.get(eq.Id).Chargeable_NonChargeable__c);
            } else {
                params.put('modelName', '');
                params.put('returnableNonReturnable', 'false');
                params.put('chargeableNonChargeable', 'false');
            }
            
            params.put('modelDesc', eq.Description);
            params.put('hsncode', eq.HSN_Code__r.Name);
            params.put('materialCode', eq.ProductCode);
            params.put('plantName', eq.Plant_Master__r.Plant_Code__c);
            params.put('category', '');  // No category for mapped spares
            
            // Pricing
            if (mapName.containsKey(eq.Id)) {
                Map<String, Object> pricebookDetails = mapName.get(eq.Id);
                params.put('price', String.valueOf(pricebookDetails.get('unitPrice')));
                params.put('pricebookEntryId', String.valueOf(pricebookDetails.get('pricebookEntryId')));
                params.put('currencyCode', String.valueOf(pricebookDetails.get('CurrencyIsoCode')));
                
                if(mpSpareRequest.get(eq.Id) != null) {
                    params.put('calculatedPrice', String.valueOf(mpSpareRequest.get(eq.Id).Billed_Value__c));
                } else {
                    params.put('calculatedPrice', '');
                }
            } else {
                params.put('price', '');
                params.put('pricebookEntryId', '');
                params.put('currencyCode', '');
                params.put('calculatedPrice', '');
            }
            
            // Images
            if (productImageMap.containsKey(eq.Id)) {
                params.put('imageUrls', productImageMap.get(eq.Id));
            }
            
            // Other fields
            params.put('quantity', 0);  // No specific quantity for mapped spares
            params.put('withinWarenty', false);
            params.put('warranty', eq.Warranty__c != null ? eq.Warranty__c : 'N');
            params.put('warrantyperiod', '');
            params.put('noofpmvisit', '');
            params.put('noofbreakdownvisit', '');
            params.put('billingType', '');
            
            // Inventory
            if(mpInv.get(eq.Id + '_' + eq.Plant_Master__r.Plant_Code__c) != null) {
                params.put('totalStock', String.valueOf(mpInv.get(eq.Id + '_' + eq.Plant_Master__r.Plant_Code__c)));
            } else {
                params.put('totalStock', null);
            }
            
            mpList.add(params);
        }
        
        return JSON.serialize(mpList);
    }
    
    
    @AuraEnabled
    public static String getMappedSparesData(String productId, String woId) {
        List<Map<String, Object>> mpList = new List<Map<String, Object>>();
        
        // Get Equipment mappings
        Map<String, Equipment_Spare_Master__c> mpEquipIds = new Map<String, Equipment_Spare_Master__c>();
        List<Equipment_Spare_Master__c> eqList = [
            SELECT SAP_Material_Code_Spare__r.HSN_Code__c,
                SAP_Material_Code_Spare__r.HSN_Code__r.Name,
                Vendor_Material_Code_part_code__c,
                SAP_Material_Code_Spare__r.Name,
                SAP_Material_Code_Spare__r.Warranty__c,
                SAP_Material_code_Spare_Description__c,
                SAP_Material_Code_Spare__c,
                Returnable_NonReturnable__c,
                Chargeable_NonChargeable__c,
                SAP_Nilkamal_Model_Code_Equipment__r.Name,
                SAP_Nilkamal_Model_Code_Equipment__r.Description,
                SAP_Nilkamal_Model_Code_Equipment__c,
                SAP_Material_Code_Spare__r.Plant_Master__r.Plant_Code__c,
                SAP_Nilkamal_Model_Code_Equipment__r.ProductCode
            FROM Equipment_Spare_Master__c
            WHERE SAP_Nilkamal_Model_Code_Equipment__c = :productId
        ];
        
        for(Equipment_Spare_Master__c eq: eqList) {
            mpEquipIds.put(eq.SAP_Material_Code_Spare__c, eq);
        }
        
        Work_Order__c workOrder = getWorkOrderData1(woId);
        Set<String> allMappedSpareIds = mpEquipIds.keySet();
        
        if (allMappedSpareIds.isEmpty()) {
            return JSON.serialize(mpList);
        }
        
        // Get Product details for all mapped spares
        String query = 'SELECT Id, Plant_Master__r.Plant_Code__c, Warranty__c, Name, Description, Category__c, HSN_Code__r.Name, Material_Group_6__c, ProductCode ' +
            'FROM Product2 WHERE Category__c = \'Spare\' AND Business_Vertical__c = \'' + workOrder.Case__r.Division__c + '\' AND IsActive = true AND Id IN: allMappedSpareIds';
        List<Product2> pdList = Database.query(query);
        System.debug('Fetched Products for Mapped Spares: ' + pdList.size());
        Set<String> setName = new Set<String>();
        for (Product2 eq : pdList) {
            setName.add(eq.Id);
        }
        
        // Get Pricebook Entries
        String priceListValue = workOrder.Case__r.Account.Pricelist__c;
        Map<String, Map<String, Object>> mapName = new Map<String, Map<String, Object>>();
        if (!setName.isEmpty()) {
            List<PricebookEntry> listName = [
                SELECT Id, Name, UnitPrice, Product2Id, CurrencyIsoCode, Product2.Name, Pricebook2Id, Pricebook2.Name,
                    Product2.Description, Product2.Base_UOM__r.Name
                FROM PricebookEntry
                WHERE Product2Id IN :setName AND Pricebook2Id = :priceListValue AND IsActive = true AND Product2.IsActive = true
            ];
            
            for (PricebookEntry pbe : listName) {
                Map<String, Object> pricebookDetails = new Map<String, Object>();
                pricebookDetails.put('unitPrice', pbe.UnitPrice);
                pricebookDetails.put('pricebookEntryId', pbe.Id);
                pricebookDetails.put('CurrencyIsoCode', pbe.CurrencyIsoCode);
                mapName.put(pbe.Product2Id, pricebookDetails);
            }
        }
        System.debug('Mapped Spares - Pricebook Entries: ' + mapName);
        
        // Get Images
        Map<String, List<String>> productImageMap = new Map<String, List<String>>();
        if (!setName.isEmpty()) {
            List<ContentDocumentLink> contentLinks = [
                SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.VersionDataUrl
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :setName AND ContentDocument.LatestPublishedVersion.FileType IN ('JPG', 'PNG', 'WEBP')
                ORDER BY ContentDocument.LatestPublishedVersion.FileType
            ];
            
            for (ContentDocumentLink link : contentLinks) {
                if (!productImageMap.containsKey(link.LinkedEntityId)) {
                    productImageMap.put(link.LinkedEntityId, new List<String>());
                }
                productImageMap.get(link.LinkedEntityId).add(link.ContentDocument.LatestPublishedVersion.VersionDataUrl);
            }
        }
        
        // Get Inventory
        Map<String, Decimal> mpInv = new Map<String, Decimal>();
        List<Inventory__c> inventoryList = [
            SELECT Id, Material__c, Quantity__c, Plant_Master__r.Plant_Code__c 
            FROM Inventory__c 
            WHERE Material__c IN :setName
        ];
        for(Inventory__c inv: inventoryList) {
            mpInv.put(inv.Material__c + '_' + inv.Plant_Master__r.Plant_Code__c, inv.Quantity__c);
        }
        
        // Get Spare Requests
        Map<String, Spare_Request__c> mpSpareRequest = new Map<String, Spare_Request__c>();
        List<Spare_Request__c> sparelist = [
            SELECT Id, Number_of_Breakdown_Visit__c, Number_of_PM_Visit__c, Warranty_Period__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, 
                Opportunity_Product__c, Item_Description__c, Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
            FROM Spare_Request__c
            WHERE Work_Order__c = :woId
            Order By CreatedDate DESC
        ];
        for(Spare_Request__c sp: sparelist) {
            mpSpareRequest.put(sp.Item_Master__c, sp);
        }
        
        // Build response for each mapped spare
        for (Product2 eq : pdList) {
            Map<String, Object> params = new Map<String, Object>();
            params.put('Id', eq.Id);
            params.put('prodName', eq.Name);
            params.put('prodId', eq.Id);
            
            if(mpEquipIds.get(eq.Id) != null) {
                params.put('modelName', mpEquipIds.get(eq.Id).Vendor_Material_Code_part_code__c);
                params.put('returnableNonReturnable', mpEquipIds.get(eq.Id).Returnable_NonReturnable__c);
                params.put('chargeableNonChargeable', mpEquipIds.get(eq.Id).Chargeable_NonChargeable__c);
            } else {
                params.put('modelName', '');
                params.put('returnableNonReturnable', 'false');
                params.put('chargeableNonChargeable', 'false');
            }
            
            params.put('modelDesc', eq.Description);
            params.put('hsncode', eq.HSN_Code__r.Name);
            params.put('materialCode', eq.ProductCode);
            params.put('plantName', eq.Plant_Master__r.Plant_Code__c);
            params.put('category', '');
            
            if (mapName.containsKey(eq.Id)) {
                Map<String, Object> pricebookDetails = mapName.get(eq.Id);
                params.put('price', String.valueOf(pricebookDetails.get('unitPrice')));
                params.put('pricebookEntryId', String.valueOf(pricebookDetails.get('pricebookEntryId')));
                params.put('currencyCode', String.valueOf(pricebookDetails.get('CurrencyIsoCode')));
                
                if(mpSpareRequest.get(eq.Id) != null) {
                    params.put('calculatedPrice', String.valueOf(mpSpareRequest.get(eq.Id).Billed_Value__c));
                } else {
                    params.put('calculatedPrice', '');
                }
            } else {
                params.put('price', '');
                params.put('pricebookEntryId', '');
                params.put('currencyCode', '');
                params.put('calculatedPrice', '');
            }
            
            if (productImageMap.containsKey(eq.Id)) {
                params.put('imageUrls', productImageMap.get(eq.Id));
            }
            
            params.put('quantity', 0);
            params.put('withinWarenty', false);
            params.put('warranty', eq.Warranty__c != null ? eq.Warranty__c : 'N');
            params.put('warrantyperiod', '');
            params.put('noofpmvisit', '');
            params.put('noofbreakdownvisit', '');
            params.put('billingType', '');
            
            if(mpInv.get(eq.Id + '_' + eq.Plant_Master__r.Plant_Code__c) != null) {
                params.put('totalStock', String.valueOf(mpInv.get(eq.Id + '_' + eq.Plant_Master__r.Plant_Code__c)));
            } else {
                params.put('totalStock', null);
            }
            
            mpList.add(params);
            System.debug('Mapped Spare: ' + mpList);
        }
        
        return JSON.serialize(mpList);
    }
    
    
    @AuraEnabled
    public static void createSpareRequests(String workOrderId, String quoteId, List<Map<String, Object>> spareParts, string serviceAppointmentId) {
        if (String.isEmpty(workOrderId) || spareParts.isEmpty()) {
            throw new AuraHandledException('Invalid input data');
        }
        
        // Retrieve Case ID from Work Order
        Work_Order__c workOrder = [SELECT Id, Case__c,Case__r.AssetId FROM Work_Order__c WHERE Id = :workOrderId LIMIT 1];
        
        if (workOrder == null || workOrder.Case__c == null) {
            throw new AuraHandledException('No related Case found for the Work Order.');
        }
        Id assetId = workOrder.Case__r.AssetId; // Fetch the asset linked to the case
        System.debug('spareParts == >'+spareParts);
        
        List<Spare_Request__c> spareRequests = new List<Spare_Request__c>();
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
        
        List<Spare_Request__c>  sparelist=new List<Spare_Request__c>();
        sparelist=[SELECT Id, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
                                FROM Spare_Request__c
                                WHERE Work_Order__c=:workOrderId
                                // AND Service_Appointment__c=: serviceAppointmentId
                                Order By CreatedDate DESC];
        Map<String,String> mpIds=new Map<String,String>();
        for(Spare_Request__c sp:sparelist){
            
            if(!mpIds.containsKey(sp.Item_Master__c)){
                mpIds.put(sp.Item_Master__c, sp.Id);
            }
        }
        
        for (Map<String, Object> spare : spareParts) {
            System.debug('spare: ' + spare + ' ' + JSON.serialize(spare));
            if ((Boolean) spare.get('checkbox') && spare.get('quantity') != null) {
                // Id modelId = modelNameToIdMap.get((String) spare.get('modelName'));
                String spareReqId='';
                if(mpIds.get(String.valueOf(spare.get('prodId')))!=null){
                    spareReqId=mpIds.get(String.valueOf(spare.get('prodId')));
                }
                System.debug('===> '+String.valueOf(spare.get('prodId')));
                System.debug('===> '+mpIds.get(String.valueOf(spare.get('prodId'))));
                Spare_Request__c spareRequest = new Spare_Request__c(
                    Work_Order__c = workOrderId,
                Case__c = workOrder.Case__c, // Assign Case ID from Work Order
                Asset__c = assetId, // Assign Asset from Case
                Quantity_Required__c = (Decimal) spare.get('quantity'),
                Name = (String) spare.get('prodName'),
                Item_Master__c = String.valueOf(spare.get('prodId')),
                Item_Description__c = (String) spare.get('modelDesc'),
                Billed_Value__c = Decimal.valueOf(String.valueOf(spare.get('price'))),
                Pricebook_Entry_Id__c = (String) spare.get('pricebookEntryId'),
                CurrencyIsoCode = (String) spare.get('currencyCode'),
                //Returnable_NonReturnable__c = (Boolean) spare.get('returnableNonReturnable'),
                //Chargeable_NonChargeable__c = (Boolean) spare.get('chargeableNonChargeable'),
                Billing_Type__c = (String) spare.get('billingType'),
                Warranty_Period__c=(String) spare.get('warrantyperiod'),
                Number_of_PM_Visit__c=(String) spare.get('noofpmvisit'),
                Number_of_Breakdown_Visit__c=(String) spare.get('noofbreakdownvisit'),
                OEM_Material_Code__c=(String) spare.get('modelName'),
                Total_Stock__c =Decimal.valueOf(String.valueOf(spare.get('totalStock'))),
                Service_Appointment__c = serviceAppointmentId,
                Category__c=(String) spare.get('category')
                    );
                
                // Assign spareReqId only if it is not blank
                if (String.isNotBlank(spareReqId)) {
                    spareRequest.Id = spareReqId;
                }
                
                spareRequests.add(spareRequest);
            }
        }
        
        if (!spareRequests.isEmpty()) {
            UPSERT spareRequests;
            
            
            if(String.isNotBlank(quoteId)) {
                RaiseOppAndQuoteController.raiseOppAndQuote(workOrderId, serviceAppointmentId, 'spare');
                /*
                Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE Id =: quoteId];
                Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Id =: quote.OpportunityId];
                
                spareRequests = [SELECT Id, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c
                                FROM Spare_Request__c
                                WHERE Id IN: spareRequests];
                
                List<OpportunityLineItem> oppProductsToBeInserted = new List<OpportunityLineItem>();
                List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();
                
                for(Spare_Request__c spareRequest : spareRequests) {
                    OpportunityLineItem oppProduct = new OpportunityLineItem();
                    oppProduct.Product2Id = spareRequest.Item_Master__c ;
                    oppProduct.OpportunityId = opportunity.Id;
                    oppProduct.UnitPrice = spareRequest.Billed_Value__c;
                    oppProduct.Quantity = spareRequest.Quantity_Required__c;
                    oppProduct.Billing_Type__c = spareRequest.Billing_Type__c;
                    oppProduct.PricebookEntryId = spareRequest.Pricebook_Entry_Id__c;
                    oppProductsToBeInserted.add(oppProduct);
                    
                    spareRequest.Opportunity_Product__r = oppProduct;
                    
                    QuoteLineItem quoteLineItem = new QuoteLineItem();
                    quoteLineItem.pricebookEntryId = spareRequest.Pricebook_Entry_Id__c;
                    quoteLineItem.Product2Id = spareRequest.Item_Master__c;
                    quoteLineItem.Description = spareRequest.Item_Description__c;
                    quoteLineItem.QuoteId = quote.Id;
                    quoteLineItem.UnitPrice = spareRequest.Billed_Value__c;
                    quoteLineItem.Billing_Type__c = spareRequest.Billing_Type__c;
                    quoteLineItem.Quantity = spareRequest.Quantity_Required__c;
                    quoteLineItemsToBeInserted.add(quoteLineItem);
                }
                
                INSERT oppProductsToBeInserted;
                INSERT quoteLineItemsToBeInserted;
                
                for (Integer i = 0; i < spareRequests.size(); i++) {
                    Spare_Request__c spareRequest = spareRequests[i];
                    if(spareRequest.Opportunity_Product__c == null) {
                        spareRequest.Opportunity__c = opportunity.Id;
                        spareRequest.Opportunity_Product__c = spareRequest.Opportunity_Product__r.Id;
                    }
                }
                
                UPDATE spareRequests;
                 */
            }
        }
    }
    
    
    
    
    
    
    @AuraEnabled
    public static List<InventoryWrapper> fetchInventory(String material, String plant) {
        inventoryFunctionsMcS.ZBAPI_ORDERSTOCK1 api = new inventoryFunctionsMcS.ZBAPI_ORDERSTOCK1();
        inventoryFunctionsMcS.TableOfZbapiOrdstk output = new inventoryFunctionsMcS.TableOfZbapiOrdstk();
        
        // Call the API method
        inventoryFunctionsMcS.TableOfZbapiOrdstk response = api.ZbapiOrderstock(material, output, plant);
        List<InventoryWrapper> wrapperList = new List<InventoryWrapper>();
        System.debug('Response is ' + JSON.serialize(response));
        if (response != null && response.item != null) {
            System.debug('Response is ' + response.item);
            System.debug('Response is ' + response.item.size());
            System.debug('Response is ' + JSON.serialize(response.item));
            for(inventoryFunctionsMcS.ZbapiOrdstk item : response.item){
                InventoryWrapper wrapper = new InventoryWrapper();
                wrapper.Material = item.Material;
                wrapper.Plant = item.Plant;
                wrapper.PlantName = item.PlantName;
                wrapper.UnrestrictedStock = item.UnrestrictedStock;
                wrapper.TotalStock = item.TotalStock;
                wrapper.StockInTransit = item.StockInTransit;
                wrapper.ManufacturingPartNo = item.ManufacturingPartNo;
                
                wrapperList.add(wrapper);
            }
            return wrapperList;
        }
        return null;
    }
    
    
    
    
    public class InventoryWrapper {
        @AuraEnabled public String Material;
        @AuraEnabled public String Plant;
        @AuraEnabled public String PlantName;
        @AuraEnabled public String UnrestrictedStock;
        @AuraEnabled public String TotalStock;
        @AuraEnabled public String StockInTransit;
        @AuraEnabled public String ManufacturingPartNo;
    }
    
    
}