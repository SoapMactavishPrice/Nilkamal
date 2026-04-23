public with sharing class fieldServiceRequest {

    @AuraEnabled
    public static List<Work_Order__c> getWorkOrderData(String woid) {
        return [
            SELECT Id, Case__c, Case__r.Type, Case__r.AssetId, Case__r.CaseNumber, Case__r.Account.Name, Case__r.Account.Pricelist__c, Case__r.CreatedDate,
            Case__r.Asset.SerialNumber, Case__r.Asset.ProductCode, Case__r.Asset.Product2Id, Case__r.Asset.Product2.Material_Group_6__c,
            Case__r.Asset.InstallDate, Case__r.Asset.Type__c, Case__r.Asset.Invoice__r.Name,Case__r.Division__c
            FROM Work_Order__c
            WHERE Case__c != null AND Case__r.AssetId != null AND Id =: woid
        ];
    }


    @AuraEnabled
    public static List<Map<String, Object>> getProductsByPartNo(String woid) {
        Work_Order__c wo = [
            SELECT Case__r.Account.Pricelist__c,Case__r.Asset.Product2.Material_Group_6__c, CurrencyIsoCode,
            Case__r.Division__c, Case__r.Type, Case__r.Case_Sub_Type__c,Case__r.AssetId,Case__r.Asset.Product2Id
            FROM Work_Order__c
            WHERE Id = :woid
            LIMIT 1
        ];

        if (wo.Case__r.Account.Pricelist__c == null) {
            throw new AuraHandledException('No Pricebook assigned to the Account.');
        }

        Id accountPricebookId = wo.Case__r.Account.Pricelist__c;

        String query = 'SELECT Id, ProductCode, Warranty__c, Name, Description, Category__c, HSN_Code__r.Name, Material_Group_6__c ' +
                    'FROM Product2 WHERE Category__c = \'SERVICE\' AND Business_Vertical__c = \'' + wo.Case__r.Division__c + '\' AND IsActive = true ';
        if(wo.Case__r.Division__c == 'MHE') {
            if(wo.Case__r.Type == 'Installation') {
                if(wo.Case__r.Case_Sub_Type__c == 'Installation & Commissioning') {
                    query += 'AND ProductCode = \'MHEINSTALNSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Preventive Maintenance') {
                if(wo.Case__r.Case_Sub_Type__c == 'AMC PM') {
                    query += 'AND ProductCode = \'MHEAMCSER\'';
                }
                else if(wo.Case__r.Case_Sub_Type__c == 'CAMC PM') {
                    query += 'AND ProductCode = \'MHECAMCSER\'';
                }
                else if(wo.Case__r.Case_Sub_Type__c == 'Health Checkup') {
                    query += 'AND ProductCode = \'MHEOWSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Courtesy') {
                if(wo.Case__r.Case_Sub_Type__c == 'Quote Negotiation' || wo.Case__r.Case_Sub_Type__c == 'AMC Business') {
                    query += 'AND ProductCode = \'MHEAMCSER\'';
                }
                else if (wo.Case__r.Case_Sub_Type__c == 'DEMO') {
                    query += ' AND ProductCode IN (\'MHEOWSER\', \'MHEAMCSER\', \'MHETRAINING\', \'MHECAMCSER\') ';
                }
            }
            else if(wo.Case__r.Type == 'Breakdown') {
                if(wo.Case__r.Case_Sub_Type__c == 'Chargeable Service') {
                    query += 'AND ProductCode = \'MHEOWSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Re-Installation') {
                if(wo.Case__r.Case_Sub_Type__c == 'Re-installation') {
                    query += 'AND ProductCode = \'MHEREINSTALNSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Training') {
                if(wo.Case__r.Case_Sub_Type__c == 'Training') {
                    query += 'AND ProductCode = \'MHETRAINING\'';
                }
            }
            else {
                query += 'AND Id = null';
            }
        }

        if(wo.Case__r.Division__c == 'Printer') {
            if(wo.Case__r.Type == 'Installation') {
                if(wo.Case__r.Case_Sub_Type__c == 'Installation & Commissioning') {
                    query += 'AND ProductCode = \'NCOWSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Preventive Maintenance') {
                if(wo.Case__r.Case_Sub_Type__c == 'AMC PM') {
                    query += 'AND ProductCode = \'NCAMCSER\'';
                }
                else if(wo.Case__r.Case_Sub_Type__c == 'Warranty PM') {
                    query += 'AND ProductCode = \'NCAMCSER\'';
                }
                else if(wo.Case__r.Case_Sub_Type__c == 'Health Checkup') {
                    query += 'AND ProductCode = \'NCOWSER\'';
                }
                else if (wo.Case__r.Case_Sub_Type__c == 'CAMC PM') {
                    query += 'AND Id = null';
                }
            }
            // else if(wo.Case__r.Type == 'Courtesy') {
            //     if(wo.Case__r.Case_Sub_Type__c == 'Quote Negotiation' || wo.Case__r.Case_Sub_Type__c == 'AMC Business') {
            //         query += 'AND ProductCode = \'MHEAMCSER\'';
            //     }
            // }
            else if(wo.Case__r.Type == 'Breakdown') {
                if(wo.Case__r.Case_Sub_Type__c == 'Chargeable Service') {
                    query += 'AND ProductCode = \'NCOWSER\'';
                }
                else if(wo.Case__r.Case_Sub_Type__c == 'Warranty Breakdown' || wo.Case__r.Case_Sub_Type__c == 'AMC Breakdown' || wo.Case__r.Case_Sub_Type__c == 'CAMC Breakdown') {
                    query += 'AND Id = null';
                }

            }
            else if(wo.Case__r.Type == 'Re-Installation') {
                if(wo.Case__r.Case_Sub_Type__c == 'Re-installation') {
                    query += 'AND ProductCode = \'NCOWSER\'';
                }
            }
            else if(wo.Case__r.Type == 'Training') {
                if(wo.Case__r.Case_Sub_Type__c == 'Training') {
                    query += 'AND ProductCode = \'NCOWSER\'';
                } else if(wo.Case__r.Case_Sub_Type__c == 'Service engineer Training') {
                    query += 'AND Id = null';
                }
            }
            else {
                query += 'AND Id = null';
            }
        }

        

        System.debug('Query: ' + query);
        List<Product2> prodList = Database.query(query);

        Set<Id> productIds = new Set<Id>();
        Set<String> productIdsSet = new Set<String>();
        for (Product2 p : prodList) {
            productIds.add(p.Id);
            productIdsSet.add(p.ProductCode+'-'+(String.isNotBlank(wo.Case__r.Asset.Product2.Material_Group_6__c) ? wo.Case__r.Asset.Product2.Material_Group_6__c : ''));
            System.debug(p.ProductCode+'-'+wo.Case__r.Asset.Product2.Material_Group_6__c);
        }

        Map<Id,Double> proToAMCPrice =  new Map<Id,Double>();
        Map<Id,Datetime> amcToDate =  new Map<Id,Datetime>();
        List<Asset_AMC__c> assetAMC=[SELECT Id,Asset__c,Asset__r.Product2Id,AMC_PO_Value__c,Asset_AMC_PO_Status__c,CreatedDate FROM Asset_AMC__c 
                                     WHERE Asset_AMC_PO_Status__c='Active' AND Asset__r.Product2Id IN:productIds];

        for(Asset_AMC__c astAMC:assetAMC){
             if(proToAMCPrice.containsKey(astAMC.Asset__r.Product2Id)){
                if(astAMC.CreatedDate>amcToDate.get(astAMC.Asset__r.Product2Id))
                    proToAMCPrice.put(astAMC.Asset__r.Product2Id,(Double)astAMC.AMC_PO_Value__c); 
                    amcToDate.put(astAMC.Asset__r.Product2Id,astAMC.CreatedDate);                                         
                }
            else{
                proToAMCPrice.put(astAMC.Asset__r.Product2Id,(Double)astAMC.AMC_PO_Value__c);
                 amcToDate.put(astAMC.Asset__r.Product2Id,astAMC.CreatedDate);    
            }               
        }

        System.debug('Product list: ' + prodList);
        System.debug('productIdsSet: ' + productIdsSet);
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Product2Id, UnitPrice, CurrencyIsoCode
            FROM PricebookEntry
            WHERE Pricebook2Id = :accountPricebookId
            AND Product2Id IN :productIds
            AND IsActive = true

        ]) {
            pricebookEntryMap.put(pbe.Product2Id, pbe);
        }


        List<Map<String, Object>> mpList = new List<Map<String, Object>>();

        List<Service_Request__c>  spareList=new List<Service_Request__c>();
        spareList = [
            SELECT Id,Original_Price__c,Price__c, Is_Cloned__c,Clone_Id__c,Number_of_Breakdown_Visit__c,Number_of_PM_Visit__c,Warranty_Period__c,Name,
            Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c, Pricebook_Entry_Id__c, Quantity__c
            FROM Service_Request__c
            WHERE Work_Order__c = :woid
            ORDER BY CreatedDate DESC
        ];
        Map<Id, List<Service_Request__c>> productToServiceRequests = new Map<Id, List<Service_Request__c>>();
        for (Service_Request__c sr : sparelist) {
            if (sr.Item_Master__c != null) {
                if (!productToServiceRequests.containsKey(sr.Item_Master__c)) {
                    productToServiceRequests.put(sr.Item_Master__c, new List<Service_Request__c>());
                }
                productToServiceRequests.get(sr.Item_Master__c).add(sr);
            }
        }

        List<Service_Pricing__c> servicepriceList=new List<Service_Pricing__c>();
        servicepriceList=[SELECT Id,Material_Group_6__c,Service_Material_Code__c,Service_Material_Code__r.ProductCode,Price__c,Unique__c FROM Service_Pricing__c WHERE Unique__c IN :productIdsSet];
        Map<String,Decimal> mpPrice =new Map<String,Decimal>();
        for(Service_Pricing__c sp:servicepriceList){
            if(sp.Price__c!=null){
                mpPrice.put(sp.Service_Material_Code__r.ProductCode, sp.Price__c);
            }
            //    }
        }

        // Iterate over the product list and populate mpList
        for (Product2 spare : prodlist) {
            List<Service_Request__c> relatedRequests = productToServiceRequests.get(spare.Id);

            if (relatedRequests != null && !relatedRequests.isEmpty()) {
                for (Service_Request__c sr : relatedRequests) {
                    Map<String, Object> params = new Map<String, Object>();
                    params.put('Id', sr.Id);
                    params.put('Item_Master__c', sr.Item_Master__c);
                    params.put('modelName', spare.Name);
                    params.put('modelDesc', spare.Description);
                    params.put('hsncode', spare.HSN_Code__r != null ? spare.HSN_Code__r.Name : '');

                    if (mpPrice.containsKey(spare.ProductCode)) {
                        params.put('price', sr.Price__c);
                    } else {
                        params.put('price', '');
                    }
                    if(proToAMCPrice.containsKey(spare.Id)){
                        params.put('AMCprice', proToAMCPrice.get(spare.Id));
                    }
                    else {
                        params.put('AMCprice', '');
                    }
                    params.put('newprice', sr.Original_Price__c);
                    params.put('currency', wo.CurrencyIsoCode);
                    params.put('quantity', sr.Quantity__c != null ? sr.Quantity__c : 1);
                    params.put('warranty', 'Y');
                    params.put('warrantyperiod', sr.Warranty_Period__c);
                    params.put('noofpmvisit', sr.Number_of_PM_Visit__c);
                    params.put('noofbreakdownvisit', sr.Number_of_Breakdown_Visit__c);
                    params.put('isClone', sr.Is_Cloned__c);
                    params.put('cloneId', sr.Clone_Id__c);
                    params.put('materialGroup6',spare.Material_Group_6__c);
                    mpList.add(params);
                }
            } else if (pricebookEntryMap.containsKey(spare.Id)) {
                // Handle products that don't have a matching Service_Request__c
                Map<String, Object> params = new Map<String, Object>();
                params.put('Id', spare.Id);
                params.put('Item_Master__c', spare.Id);
                params.put('modelName', spare.Name);
                params.put('modelDesc', spare.Description);
                params.put('hsncode', spare.HSN_Code__r != null ? spare.HSN_Code__r.Name : '');
                params.put('price', mpPrice.containsKey(spare.ProductCode) ? String.valueOf(mpPrice.get(spare.ProductCode)) : '');
                if(proToAMCPrice.containsKey(spare.Id)){
                    params.put('AMCprice', proToAMCPrice.get(spare.Id));
                }
                else {
                    params.put('AMCprice', '');
                }
                params.put('newprice', '');
                params.put('currency', wo.CurrencyIsoCode);
                params.put('quantity', 1);
                params.put('warranty', 'Y');
                params.put('warrantyperiod', null);
                params.put('noofpmvisit', null);
                params.put('noofbreakdownvisit', null);
                params.put('isClone', false);
                params.put('cloneId', '');
                params.put('materialGroup6',spare.Material_Group_6__c);
                mpList.add(params);
            }
        }

        // Return the list of maps with the data
        return mpList;
    }


    @AuraEnabled
    public static void createServiceRequest(List<Map<String, Object>> spareParts, String woid, String serviceAppointmentId) {
        System.debug('WOID received: ' + woid);
        System.debug('spareParts received: ' + JSON.serialize(spareParts));
        if (spareParts.isEmpty() || String.isEmpty(woid)) {
            throw new AuraHandledException('Invalid input data');
        }

        //Fetch Work Order to get related Case ID
        Work_Order__c wo = [SELECT Id, Case__c,Case__r.AssetId,Case__r.Account.Pricelist__c FROM Work_Order__c WHERE Id = :woid LIMIT 1];

        if (wo == null || wo.Case__c == null) {
            throw new AuraHandledException('No related Case found for the given Work Order.');
        }


        List<Service_Request__c>  sparelist=new List<Service_Request__c>();
        sparelist=[SELECT Id,Is_Cloned__c,Clone_Id__c, Name, Item_Master__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c,
                                Pricebook_Entry_Id__c
                                FROM Service_Request__c
                                WHERE Work_Order__c=:woid
                                Order By CreatedDate DESC];
        Map<String,String> mpIds=new Map<String,String>();
        Map<String,String> mpClonedIds=new Map<String,String>();
        for(Service_Request__c  sp:sparelist) {
            if(sp.Is_Cloned__c) {
                if(sp.Clone_Id__c!=null) {
                    mpClonedIds.put(sp.Clone_Id__c,sp.Id);
                }
            } else {
                if(!mpIds.containsKey(sp.Id)) {
                    mpIds.put(sp.Id, sp.Id);
                }
            }
        }

        List<Service_Request__c> spareRequests = new List<Service_Request__c>();
        for (Map<String, Object> spare : spareParts) {
            if ((Boolean) spare.get('checkbox') && spare.get('quantity') != null) {
                Object priceValue = spare.get('price');
                Decimal unitPrice = (priceValue instanceof Decimal) ? (Decimal) priceValue : Decimal.valueOf(String.valueOf(priceValue));

                Object newPriceValue = spare.get('newprice');
                Decimal newPrice = (newPriceValue instanceof Decimal) ? (Decimal) newPriceValue : Decimal.valueOf(String.valueOf(newPriceValue));

                Object amcPriceValue = spare.get('amcprice');
                Decimal amcPrice = (amcPriceValue instanceof Decimal) ? (Decimal) amcPriceValue : Decimal.valueOf(String.valueOf(amcPriceValue));

                String spareReqId='';

                if((Boolean) spare.get('isClone') ){
                    if(mpClonedIds.containsKey(String.valueOf(spare.get('cloneId')))){
                        spareReqId=mpClonedIds.get(String.valueOf(spare.get('cloneId')));
                    }
                }else{
                    if(mpIds.get(String.valueOf(spare.get('Id')))!=null){
                        spareReqId=mpIds.get(String.valueOf(spare.get('Id')));
                    }
                }

                //modify the 155 to 166 15-3-25
                    Service_Request__c sr=new Service_Request__c();
                    sr.Work_Order__c = woid;
                    sr.Case__c = wo.Case__c;// Assign Case ID from Work Orde;
                    sr.Asset__c = wo.Case__r.AssetId; // Assign Asset from Cas;
                    sr.Quantity__c = (Decimal) spare.get('quantity');
                    sr.Name = (String) spare.get('modelName');
                    sr.Item_Description__c = (String) spare.get('modelDesc');
                    sr.Price__c = unitPrice;
                    sr.Original_Price__c =newPrice;
                    sr.Last_AMC_Price__c=amcPrice;
                    if (sr.Name.contains('AMC')) {
                        sr.Warranty_Period__c=(String) spare.get('warrantyperiod');
                        if(spare.get('noofpmvisit')!=null && spare.get('noofpmvisit')!=''){
                            sr.Number_of_PM_Visit__c=(String) spare.get('noofpmvisit');
                        }

                        if(spare.get('noofbreakdownvisit')!=null && spare.get('noofbreakdownvisit')!=''){
                            sr.Number_of_Breakdown_Visit__c=(String) spare.get('noofbreakdownvisit');
                        }
                    }
                    sr.Service_Appointment__c = serviceAppointmentId;
                    sr.Is_Cloned__c=(Boolean) spare.get('isClone');
                    sr.Clone_Id__c=(String) spare.get('cloneId');
                    // Assign spareReqId only if it is not blank
                    if (String.isNotBlank(spareReqId)) {
                        sr.Id = spareReqId;
                    } else {
                        sr.Item_Master__c = (String) spare.get('Item_Master__c');
                        /*
                        String itemMasterId=(String) spare.get('Id');
                        System.debug('itemMasterId - ' + itemMasterId);
                        if(itemMasterId.contains('-')) {
                            itemMasterId=(String)itemMasterId.substringBefore('-');
                            sr.Item_Master__c =itemMasterId;
                        } else {
                            sr.Item_Master__c = itemMasterId;
                        }
                        */
                    }
                    spareRequests.add(sr);
            }
        }

        if (!spareRequests.isEmpty()) {
            UPSERT spareRequests;
        }
    }


    @AuraEnabled
    public static Object getAssetDetails(String serialNo) {
        try {
            Asset_AMC__c assetAMC = new Asset_AMC__c();
            assetAMC = [SELECT Id,AMC_Start_Date__c,AMC_End_Date__c,AMC_PO_Value__c
                        FROM Asset_AMC__c
                        WHERE Asset__r.Name = :serialNo AND Asset_AMC_PO_Status__c IN ('Active', 'Expired')
                        ORDER BY CreatedDate DESC
                        LIMIT 1];
            return assetAMC;
        }
        catch(Exception e) {
            Asset_Warranty__c assetWarranty = new Asset_Warranty__c();
            assetWarranty = [SELECT Id,Warranty_Start_Date__c,Warranty_End_Date__c
                            FROM Asset_Warranty__c
                            WHERE Asset__r.Name = :serialNo
                            ORDER BY CreatedDate DESC
                            LIMIT 1];
            return assetWarranty;
        }
    }

}