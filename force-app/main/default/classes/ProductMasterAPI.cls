/*******************************************************************************************
* ProductMasterAPI.class

* Author    :   Shashank
* Purpose   :   Item master API
* Date      :  25/11/2024
--------------------------------------------------------------------------------------------
Version     Date            Author          Remarks
v1          25/11/2024      Shashank
=======     ===========     ========        ======================
*******************************************************************************************/
@RestResource(urlMapping = '/productMaster/*')
global  class ProductMasterAPI {


    @HttpPost
    global static void doPost() {
        RestResponse response;
        RestRequest request;
        API_log__c apiLog=new API_log__c();
        apiLog.Log_Name__c ='Product_Master';
        //Savepoint sp = Database.setSavepoint();
        String resmessage='Created Successfully';
        try {


            request = RestContext.request;
            response = RestContext.response;
            Integer blobSize = request.requestBody.size();
            System.debug('Request Blob size (bytes): ' + blobSize);
            
            // You can adjust this limit as per your comfort margin
            Integer safeStringLimit = 5500000; // ~5.5 MB

            if (blobSize <= safeStringLimit) {

            
                    String jSONRequestBody = request.requestBody.toString().trim();
                    System.debug('IjSONRequestBody=' + jSONRequestBody);
                    //apiLog.Request__c=jSONRequestBody;
                    List<IntegrationRequestBuilder.ProductMasterJson> jData = IntegrationRequestBuilder.itemMasterParse(jSONRequestBody);
                    System.debug('Json--' + jData);

                    apiLog.Request__c='Total Size ='+jData.size();



                    map<String,Product2> productList = new map<String,Product2>();
                    List<String> itemCode = new List<String>();
                    List<String> slorgList = new List<String>();
                    List<String> disChlList = new List<String>();
                    List<String> divList = new List<String>();
                    List<String> bUomCodeList = new List<String>();
                    List<String> pCodeList = new List<String>();
                    List<String> hsnCodeList = new List<String>();
                    List<String> itmGrpCodeList = new List<String>();

                    Pricebook2 pbk1 =[ SELECT IsActive ,Description, IsStandard, Id, Name, SystemModstamp FROM Pricebook2 WHERE IsActive=True and Name='Nilkamal Pricebook' ];
                    Pricebook2 standardPriceBook = [ SELECT Id  FROM Pricebook2 WHERE isStandard = true  LIMIT 1];

                    //added by shashank
                    Set<String> plantExtensionIds=new Set<String>();
                    Set<String> salesareanIds=new Set<String>();
                    Set<String> itemNumberIds=new Set<String>();
                    for (IntegrationRequestBuilder.ProductMasterJson jd : jData) {
                        itemNumberIds.add(jd.ITEM_NUMBER);
                        itmGrpCodeList.add(jd.ITEM_GROUP);
                        hsnCodeList.add(jd.HSN_CODE);
                        pCodeList.add(jd.PLANT_CODE);
                        bUomCodeList.add(jd.SALES_UOM);
                        slorgList.add(jd.SALES_ORGANISATION);
                        disChlList.add(jd.DISTRIBUTION_CHANNEL);
                        divList.add(jd.DIVISION);
                        if(jd.PRODUCT_IMAGE_BASE64==''){
                            apiLog.Request__c=jSONRequestBody;
                        }
                    }
                    //added by shashank
                    Map<String,String> mpproductIds=new Map<String,String>();
                    List<Product2> prodList=new List<Product2>();
                    prodList=[SELECT Id,ProductCode FROM Product2 WHERE ProductCode IN : itemNumberIds];
                    for(Product2 pex:prodList){
                        mpproductIds.put(pex.ProductCode , pex.Id);
                    }

                    List<Item_Group_Master__c> itmGrpList= new List<Item_Group_Master__c>();
                    itmGrpList = [SELECT ID,Item_Group_Code__c FROM Item_Group_Master__c WHERE Item_Group_Code__c IN : itmGrpCodeList];

                    Map<String,Item_Group_Master__c> itmGrpMap = new  Map<String,Item_Group_Master__c>();
                    for (Item_Group_Master__c va : itmGrpList) {
                        itmGrpMap.put(va.Item_Group_Code__c,va);
                    }

                    List<UOM_Master__c> baseList= new List<UOM_Master__c>();
                    baseList = [SELECT ID,Code__c FROM UOM_Master__c WHERE Code__c IN : bUomCodeList];

                    Map<String,UOM_Master__c> baseUomMap = new  Map<String,UOM_Master__c>();


                    for (UOM_Master__c va : baseList) {
                        baseUomMap.put(va.Code__c,va);
                    }



                    List<Sales_Organizations__c> soList= new List<Sales_Organizations__c>();
                    soList = [SELECT ID,Name FROM Sales_Organizations__c WHERE Name IN : slorgList];

                    Map<String,Sales_Organizations__c> soMap = new  Map<String,Sales_Organizations__c>();
                    for (Sales_Organizations__c va : soList) {

                        soMap.put(va.Name,va);
                    }

                    List<Distribution_Channel__c> dcList= new List<Distribution_Channel__c>();
                    dcList = [SELECT ID,Distribution_Code__c  FROM Distribution_Channel__c WHERE Distribution_Code__c IN : disChlList];

                    Map<String,Distribution_Channel__c> dcMap = new  Map<String,Distribution_Channel__c>();
                    for (Distribution_Channel__c va : dcList) {

                        dcMap.put(va.Distribution_Code__c,va);
                    }


                    List<Division__c> diList= new List<Division__c>();
                    diList = [SELECT ID,Division_Code__c FROM Division__c WHERE Division_Code__c IN : divList];

                    Map<String,Division__c> diMap = new  Map<String,Division__c>();
                    for (Division__c va : diList) {

                        diMap.put(va.Division_Code__c,va);
                    }

                    List<HSN_Master__c> hsnList= new List<HSN_Master__c>();
                    hsnList = [SELECT ID,Code__c,Name FROM HSN_Master__c WHERE Name IN : hsnCodeList];

                    Map<String,HSN_Master__c> hsnMap = new  Map<String,HSN_Master__c>();
                    for (HSN_Master__c va : hsnList) {

                        hsnMap.put(va.Name,va);
                    }
                    Map<String,Manufacturing_Part_No__c> mnpMap = new  Map<String,Manufacturing_Part_No__c>();
                    for (Manufacturing_Part_No__c va : [select id,name,Business_Vertical__c,Category__c from Manufacturing_Part_No__c]) {

                        mnpMap.put(va.Name,va);
                    }


                    List<Plant_Master__c> pltList= new List<Plant_Master__c>();
                    pltList = [SELECT ID,Name, Plant_Code__c FROM Plant_Master__c WHERE Plant_Code__c IN : pCodeList];

                    Map<String,Plant_Master__c> pltMap = new  Map<String,Plant_Master__c>();
                    for (Plant_Master__c va : pltList) {
                        pltMap.put(va.Plant_Code__c,va);
                    }


                    String sfdc_id='';
                    for (IntegrationRequestBuilder.ProductMasterJson jd : jData) {
                        Product2 pr=new Product2();
                        if(mpproductIds.get(jd.ITEM_NUMBER)!=null){
                            pr.Id = mpproductIds.get(jd.ITEM_NUMBER);
                            sfdc_id = mpproductIds.get(jd.ITEM_NUMBER);
                            resmessage = 'Updated successfully';
                        }

                        pr.Name=jd.ITEM_NUMBER;
                        pr.ProductCode=jd.ITEM_NUMBER;
                        pr.Description=jd.ITEM_DESCRIPTION;
                        pr.IsActive=true;

                        if (itmGrpMap.containsKey(jd.ITEM_GROUP)) {
                            pr.Item_Group__c = itmGrpMap.get(jd.ITEM_GROUP).id;
                        }
                        pr.Item_Group_Text__c = jd.ITEM_GROUP;

                        if (String.isNotBlank(jd.ITEM_TYPE)) {
                            pr.Item_Type__c=jd.ITEM_TYPE; //Pick
                        }

                        if (String.isNotBlank(jd.OLD_MATERIAL_CODE)) {
                            pr.Old_Material_Code__c=jd.OLD_MATERIAL_CODE;
                        }


                        if (soMap.containsKey(jd.SALES_ORGANISATION)) {
                            pr.Sales_Organizations__c=soMap.get(jd.SALES_ORGANISATION).id;
                        }
                        if (dcMap.containsKey(jd.DISTRIBUTION_CHANNEL)) {
                            pr.Distribution_Channel__c=dcMap.get(jd.DISTRIBUTION_CHANNEL).id;
                        }
                        if (diMap.containsKey(jd.DIVISION)) {
                            pr.Division__c=diMap.get(jd.DIVISION).id;
                        }

                        if (String.isNotBlank(jd.SALES_UOM)) {
                            if (baseUomMap.containsKey(jd.SALES_UOM)) {
                                System.debug('BaseUom='+jd.SALES_UOM);
                                pr.Sales_UOM__c=baseUomMap.get(jd.SALES_UOM).id;
                            }
                        }

                        if (pltMap.containsKey(jd.PLANT_CODE)) {
                            pr.Plant_Master__c=pltMap.get(jd.PLANT_CODE).id;
                        }

                        // pr.GenItemCatGroup__c=jd.GENITEMCATGROUP;

                        if (String.isNotBlank(jd.GENITEMCATGROUP)) {
                            //pr.Item_Category__c=jd.GENITEMCATGROUP;
                        }


                        pr.Size_Dimensions__c=jd.SIZE_DIMENSIONS;
                        pr.Material_Group_2__c=jd.MATERIAL_GROUP_2;
                        pr.Material_Group_3__c=jd.MATERIAL_GROUP_3;
                        pr.Material_Group_4__c=jd.MATERIAL_GROUP_4;
                        pr.Material_Group_5__c=jd.MATERIAL_GROUP_5;
                        pr.Material_Group_6__c=jd.MATERIAL_GROUP_6;
                        if (String.isNotBlank(jd.Warranty)) {
                            pr.Warranty__c=jd.Warranty;
                        }

                        if (String.isNotBlank(jd.LeadTime)) {
                            pr.Lead_Time__c=jd.LeadTime;
                        }

                        if (String.isNotBlank(jd.LIST_PRICE_MRP_PRICE)) {
                            pr.List_Price_MRP_Price__c=Decimal.valueOf(jd.LIST_PRICE_MRP_PRICE);
                        }


                        if (hsnMap.containsKey(jd.HSN_CODE)) {
                            pr.HSN_Code__c=hsnMap.get(jd.HSN_CODE).id;
                        }

                        if(mnpMap.containskey(jd.MPN)) {
                            if(jd.MPN!='SERVICE'){
                            pr.Manufacturing_Part_No1__c=mnpMap.get(jd.MPN).Id;
                            pr.Business_Vertical__c=mnpMap.get(jd.MPN).Business_Vertical__c;
                            pr.Category__c=mnpMap.get(jd.MPN).Category__c;
                            }
                            else {
                                pr.Manufacturing_Part_No1__c=mnpMap.get(jd.MPN).Id;
                                pr.Category__c=mnpMap.get(jd.MPN).Category__c;
                                if(jd.MATERIAL_GROUP_2=='M H E') {
                                    pr.Business_Vertical__c='MHE';
                                }
                                if(jd.MATERIAL_GROUP_2=='HANEL') {
                                    pr.Business_Vertical__c='Hanel';
                                }
                                if(jd.MATERIAL_GROUP_2=='HOSPITALITY') {
                                    pr.Business_Vertical__c='CNPL';
                                }
                                if(jd.MATERIAL_GROUP_2=='CODING & MARKING') {
                                    pr.Business_Vertical__c='Printer';
                                }
                            }
                        }
                        pr.MPN__c = jd.MPN;

                        if(jd.PRODUCT_STATUS =='Active') {
                            pr.IsActive=True;
                        }if(jd.PRODUCT_STATUS =='Inactive') {
                            pr.IsActive=False;
                        }

                        productList.put(jd.ITEM_NUMBER, pr);
                    }

                    if (productList.values().size()>0) {
                        upsert productList.values();

                        List<PricebookEntry>  priceEntry = new List<PricebookEntry>();
                        List<PricebookEntry>  priceEntry1 = new List<PricebookEntry>();
                        Map<String,String> mpIds=new Map<String,String>();
                        if(sfdc_id == '') {
                            for (Product2 pr : productList.values()) {
                                mpIds.put(pr.ProductCode,pr.Id);
                                PricebookEntry p1 = new PricebookEntry();
                                p1.UnitPrice=pr.List_Price_MRP_Price__c;
                                p1.Pricebook2Id=pbk1.Id;
                                p1.isActive=true;
                                p1.Product2Id=pr.id;
                                p1.CurrencyIsoCode='INR';
                                priceEntry.add(p1);

                                PricebookEntry p3 = new PricebookEntry();
                                p3.UnitPrice=pr.List_Price_MRP_Price__c;
                                p3.Pricebook2Id=standardPriceBook.Id;
                                p3.isActive=true;
                                p3.Product2Id=pr.id;
                                p3.CurrencyIsoCode='INR';
                                priceEntry1.add(p3);
                            }
                        }



                        upsert priceEntry1;
                        upsert priceEntry;
                        for (IntegrationRequestBuilder.ProductMasterJson jd : jData) {
                            if (!String.isBlank(jd.PRODUCT_IMAGE_BASE64) && jd.PRODUCT_IMAGE_BASE64!=null) {
                            // Decode the Base64 string
                            Blob fileBlob = EncodingUtil.base64Decode(jd.PRODUCT_IMAGE_BASE64);

                            // Create a ContentVersion record
                            ContentVersion contentVersion = new ContentVersion();
                            contentVersion.Title = jd.PRODUCT_IMAGE_NAME;
                            contentVersion.PathOnClient = jd.PRODUCT_IMAGE_NAME;
                            contentVersion.VersionData = fileBlob;

                            // Insert the ContentVersion record
                            insert contentVersion;

                            // If a parentId is provided, create a ContentDocumentLink to associate the file
                            if (mpIds.get(jd.ITEM_NUMBER)!= null) {
                                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                                contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                                contentDocumentLink.LinkedEntityId = mpIds.get(jd.ITEM_NUMBER);
                                contentDocumentLink.ShareType = 'V'; // Viewer permissions
                                insert contentDocumentLink;
                            }
                        }
                        }


                    }
                    Map<String,Object> mpResponse=new Map<String,Object>();
                    mpResponse.put('Status','success');
                    mpResponse.put('msg',resmessage);
                // mpResponse.put('data',jData);
                    response.statusCode=200;
                    response.responseBody=Blob.valueOf(JSON.serialize(mpResponse));
                    apiLog.Status__c='Success';
                    apiLog.Item_Master__c=productList.values()[0].Id;
                }else{
                    // Save the full requestBody into ContentVersion
                    ContentVersion cv = new ContentVersion();
                    cv.Title = 'ProductMasterPayload_' + Datetime.now().getTime();
                    cv.PathOnClient = 'ProductMasterPayload.json';
                    cv.VersionData = request.requestBody;
                    insert cv;

                    // Start Queueable to process
                    System.enqueueJob(new ProductMasterProcessor(cv.Id));

                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf('{"msg":"Payload received and processing started","Status":"Success"}');
                }


            }catch(Exception e){
                //Database.RollBack(sp);
                apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
                response.statusCode=500;
                response.responseBody=Blob.valueOf('{"msg":"'+apiLog.Exception_Description__c+'","Status":"Failed"}');
                apiLog.Status__c='Failed';

            }
            finally{
                INSERT apiLog;
            }
    }




}