public class FetchReturnableSamplesQueueable implements Queueable, Database.AllowsCallouts {
    
    Integer offset;
    public FetchReturnableSamplesQueueable(Integer offset) {
        this.offset = offset;
    }
    
    public void execute(QueueableContext context) {
        API_log__c apiLog=new API_log__c();
        apiLog.Log_Name__c ='ReturnableSampleAPI';
        try{
            // Instantiate the web service class
            ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS service = new ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS();
            apiLog.Request__c='Request -'+'';
            // Call the API method
            ReturnableSample.ZcrmReturnableSamplesResponse_element response = service.ZcrmReturnableSamples('');
            
            ReturnableSample.ZcrmRsamplesOutput sampledata=response.EmReturnableSamples;
            // Total items count (assuming it's a field in the response)
            Integer total = 0;
            if(response.EmAddnData != null && response.EmAddnData!='')
            {
                System.debug('EmAddnData ==> '+response.EmAddnData);
                total = response.EmAddnData != null ? Integer.valueOf(response.EmAddnData.trim()) : 0;
            }
            
            // Process records (assuming a list of items is returned in response.EmReturnableSamples)
            List<Sample_Returnable_Order__c> samplesToInsert = new List<Sample_Returnable_Order__c>();
            
            if (sampledata != null && sampledata.item != null) {
                Set<String> custids=new Set<String>();
                Set<String> productCodes = new Set<String>();
                Set<String> saleOrgIds = new Set<String>();
                Set<String> slorgList = new Set<String>();
                Set<String> disChlList = new Set<String>();
                Set<String> divList = new Set<String>();
                Set<String> pCodeList = new Set<String>();
                Set<String> mfgParts = new Set<String>();
                Set<String> bUomCodeList = new Set<String>();
                apiLog.Response__c=String.valueOf(sampledata);
                apiLog.Status__c='Success';
                for (ReturnableSample.ZcrmCustomerSampleOutStr item : sampledata.item) {
                    if( item.KUNNR!=null && item.KUNNR!=''){
                        custids.add(item.KUNNR);
                    }
                    if(item.MATNR!=null && item.MATNR!=''){
                        productCodes.add(item.MATNR);
                    }
                    if(item.VKORG!=null && item.VKORG!=''){
                        slorgList.add(item.VKORG);
                    }
                    if(item.VTWEG!=null && item.VTWEG!=''){
                        disChlList.add(item.VTWEG);
                    }
                    if(item.SPART!=null && item.SPART!=''){
                        divList.add(item.SPART);
                    }
                    
                    if(item.WERKS!=null && item.WERKS!=''){
                        pCodeList.add(item.WERKS);
                    }
                    
                    if(item.MFRPN != null && item.MFRPN!=''){
                        mfgParts.add(item.MFRPN);
                    }
                    if(item.Zieme!=null && item.Zieme!=''){
                        bUomCodeList.add(item.Zieme);
                    }
                }
                Map<String, Account> accMap=new Map<String, Account>();
                for(Account ac:[Select id,Name,SAP_Customer_code__c from Account where SAP_Customer_code__c IN :custids]){
                    accMap.put(ac.SAP_Customer_code__c,ac);
                }
                
                // Product2 Map
                Map<String, Product2> productMap = new Map<String, Product2>();
                for (Product2 product : [
                SELECT Id, ProductCode, Category__c, Business_Vertical__c
                FROM Product2
                WHERE ProductCode IN :productCodes
            ]) {
                    productMap.put(product.ProductCode, product);
                }
                
                // Plant_Master__c Map
                Map<String, Plant_Master__c> plantMap = new Map<String, Plant_Master__c>();
                for (Plant_Master__c plant : [
                SELECT Id, Plant_Code__c
                FROM Plant_Master__c
                WHERE Plant_Code__c IN :pCodeList
            ]) {
                    plantMap.put(plant.Plant_Code__c, plant);
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
                
                
                List<Plant_Master__c> pltList= new List<Plant_Master__c>();
                pltList = [SELECT ID,Plant_Code__c,Name FROM Plant_Master__c WHERE Plant_Code__c IN : pCodeList];
                
                Map<String,Plant_Master__c> pltMap = new  Map<String,Plant_Master__c>();
                for (Plant_Master__c va : pltList) {
                    
                    pltMap.put(va.Plant_Code__c,va);
                }
                
                // Manufacturing_Part_No__c Map
                Map<String, Manufacturing_Part_No__c> mfgMap = new Map<String, Manufacturing_Part_No__c>();
                for (Manufacturing_Part_No__c mfg : [
                SELECT Id, Name
                FROM Manufacturing_Part_No__c
                WHERE Name IN :mfgParts
            ]) {
                    mfgMap.put(mfg.Name, mfg);
                }
                
                //UOM
                List<UOM_Master__c> baseList= new List<UOM_Master__c>();
                baseList = [SELECT ID,Code__c FROM UOM_Master__c WHERE Code__c IN : bUomCodeList];
                
                Map<String,UOM_Master__c> baseUomMap = new  Map<String,UOM_Master__c>();
                
                
                for (UOM_Master__c va : baseList) {
                    baseUomMap.put(va.Code__c,va);
                }
                
                List<User> ulist= new List<User>();
                ulist = [SELECT Id,UID__c from User];
                
                Map<String,String> uMap = new  Map<String,String>();
                for (User va : ulist) {
                    
                    uMap.put(va.UID__c,va.Id);
                }
                
                Set<String> orderNoSet=new Set<String>();
                Set<String> orderZDIRSet=new Set<String>();
                for (ReturnableSample.ZcrmCustomerSampleOutStr item : sampledata.item) {
                    if(item.Auart=='ZSOA'){
                        System.debug('====> '+item.Auart);
                        orderNoSet.add(item.Vbeln);
                    }
                    else if(item.Auart == 'ZIDR'){
                        orderZDIRSet.add(item.Kdmat);
                    }
                }
                System.debug('orderNoSet '+orderNoSet);
                System.debug('orderZDIRSet '+orderZDIRSet);
                List<Quote> quoteList =new List<Quote>();
                quoteList= [SELECT Id,Name,Returnable_Received__c,SAP_Order_No__c,Total_Quantity__c FROM Quote WHERE SAP_Order_No__c IN :orderNoSet AND Billing_Type__c='FOC and Returnable'];
                Map<String, Quote> mpQuote =new Map<String, Quote>();
                for(Quote quote :quoteList){
                    mpQuote.put(quote.SAP_Order_No__c,quote);
                }
                
                Map<String,Decimal> quoteSRmap = new Map<String,Decimal>();
                for(AggregateResult quotes:[Select Quote__r.SAP_Order_No__c, SUM(Order_Quantity__c) ordQty FROM Sample_Returnable_Order__c Where Quote__r.SAP_Order_No__c IN: orderZDIRSet AND Quote__r.Billing_Type__c='FOC and Returnable' AND Document_Type__c ='ZIDR' GROUP BY Quote__r.SAP_Order_No__c]){
                    quoteSRmap.put((String)quotes.get('Quote__r.SAP_Order_No__c'),(Decimal)quotes.get('ordQty'));
                }
                
                List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
                quoteLineItems = [
                SELECT Id, Quote.SAP_Order_No__c, Product2.ProductCode, ZSOA_Date__c, ZIDR_Date__c
                FROM QuoteLineItem
                WHERE Quote.SAP_Order_No__c IN :orderNoSet AND Quote.Billing_Type__c='FOC and Returnable'
            ];
                Map<String, QuoteLineItem> mpQuoteLineItem = new Map<String, QuoteLineItem>();
                for (QuoteLineItem quoteLineItem : quoteLineItems) {
                    mpQuoteLineItem.put(quoteLineItem.Quote.SAP_Order_No__c + '-' + quoteLineItem.Product2.ProductCode, quoteLineItem);
                }
                
                //             AND Quote.Billing_Type__c='FOC and Returnable'
                //  quoteLineItems = [SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, GST_Tax__c, Product2.Base_UOM__r.Name,Delivery_Time_Remark__c,Stock__c,
            //             HSN_Code__r.Name, Description, SAP_Code__c, Unit__c, GST_Percentage__c, Amount__c, Advanced_Received__c, Discount_In__c,Delivery_Time__c,Discount_In_Value__c,Grand_Price__c,Warranty_Months__c,OEM_Material_Code__c,Category__c
            //             FROM QuoteLineItem
            //             WHERE Quote.SAP_Order_No__c IN :orderNoSet
            //             AND Quote.Billing_Type__c='FOC and Returnable'];
                
                Map<Id, QuoteLineItem> quoteLineItemsToUpdate = new Map<Id, QuoteLineItem>();
                
                Map<String,Double> mpNewQty=new Map<String,Double>();
                for (ReturnableSample.ZcrmCustomerSampleOutStr item : sampledata.item) {
                    //System.debug('====> '+item.Auart);
                    Sample_Returnable_Order__c sample = new Sample_Returnable_Order__c();
                    sample.Document_Type__c = item.Auart;
                    if(item.Audat != '0000-00-00'){
                        sample.Document_Date__c = item.Audat != null ? Date.valueOf(item.Audat) : null;
                    }
                    sample.Name = item.Vbeln;
                    sample.Sales_Organizations__c =soMap.get(item.Vkorg)!=null?soMap.get(item.Vkorg).Id:null;
                    sample.Distribution_Channel__c = dcMap.get(item.Vtweg)!=null?dcMap.get(item.Vtweg).Id:null;   //item.VTWEG;
                    sample.Division__c = diMap.get(item.Spart)!=null?diMap.get(item.Spart).Id:null;
                    sample.Customer_Code__c=item.Kunnr;
                    sample.Customer_Name__c= accMap.get(item.Kunnr)!=null?accMap.get(item.Kunnr).Id:null;
                    sample.Customer_Name_Desc__c = item.Name1;
                    sample.Plant_Master__c =pltMap.get(item.Werks)!=null?pltMap.get(item.Werks).Id:null;
                    sample.Item__c=item.Posnr;
                    sample.Material__c =productMap.get(item.Matnr)!=null?productMap.get(item.Matnr).Id:null;
                    sample.Order_Quantity__c =item.Kwmeng!=''&& item.Kwmeng!=null?Decimal.valueOf(item.Kwmeng):0;
                    sample.Billed_Quantity__c =item.Fkimg!=''&& item.Fkimg!=null?Decimal.valueOf(item.Fkimg):0;
                    //sample.Invoice_Quantity__c=item.Fkimg;
                    sample.Base_UOM__c = baseUomMap.get(item.Zieme)!=null?baseUomMap.get(item.Zieme).Id:null ;
                    sample.Moving_Average_Price__c = item.Verpr != null ? Decimal.valueOf(item.Verpr) : null;
                    sample.Delivery__c = item.Vbeln1;
                    sample.Predecessr__c=item.Pgno;
                    sample.Sale_Document_Challen_No__c=item.Aubel;
                    sample.Sales_Document__c=item.Kdmat;
                    sample.Return_Delay_Days__c =String.valueOf(item.ZDAYS);
                    sample.Description__c = item.Maktx;
                    sample.Manufacturer_Part_Number__c =mfgMap.get( item.Mfrpn)!=null?mfgMap.get( item.Mfrpn).Id:null;
                    sample.Sales_Group__c = item.Vkgrp;
                    sample.Sales_Group_Description__c = item.SgrpDesc != null ? String.valueOf(item.SgrpDesc) : null;
                    sample.Sales_Office__c = item.SoffDesc;
                    sample.Sales_Employee__c = item.Salesman;
                    sample.Sales_Employee_Code__c = item.Snam;
                    if(item.Snam!=null && item.Snam!=''){
                        String uid=item.Snam;
                        if(uMap.containsKey(uid)){
                            sample.OwnerId=uMap.get(uid);
                        }
                    }
                    sample.IsReturnable__c=true;
                    if(mpQuote.get(item.Kdmat)!=null){
                        sample.Quote__c=mpQuote.get(item.Kdmat).Id;
                    }
                    if(mpQuoteLineItem.containsKey(item.Kdmat+'-'+item.Matnr)){
                        QuotelineItem qli = mpQuoteLineItem.get(item.Kdmat+'-'+item.Matnr);
                        sample.Quote_Line_Item__c = qli.Id;
                        if(item.Auart == 'ZSOA') {
                            if(qli.ZSOA_Date__c == null) {
                                qli.ZSOA_Date__c = sample.Document_Date__c;
                                quoteLineItemsToUpdate.put(qli.Id, qli);
                            }
                        }
                        if(item.Auart == 'ZIDR') {
                            qli.ZIDR_Date__c = sample.Document_Date__c;
                            quoteLineItemsToUpdate.put(qli.Id, qli);
                        }
                    }
                    if(item.Auart == 'ZIDR'){ // 24-11
                        if(quoteSRmap.containsKey(item.Kdmat)){
                            Double qty = quoteSRmap.get(item.Kdmat);
                            quoteSRmap.put(item.Kdmat,qty+Decimal.valueOf(item.Fkimg));
                        }else{
                            quoteSRmap.put(item.Kdmat,Decimal.valueOf(item.Fkimg));
                        }
                    } // 24-11
                    samplesToInsert.add(sample);
                }
                
                // Insert into Salesforce
                if (!samplesToInsert.isEmpty()) {
                    //insert samplesToInsert;
                    
                    // ✅ FIX: partial insert
                    Database.SaveResult[] srList = Database.insert(samplesToInsert, false);
                    
                    // ✅ Error handling per record
                    for (Integer i = 0; i < srList.size(); i++) {
                        if (!srList[i].isSuccess()) {
                            for (Database.Error err :
                            srList[i].getErrors()) {
                                System.debug(
                                    '❌ Insert failed | Index: ' + i +
                                    ' | OwnerId: ' +
                                    samplesToInsert[i].OwnerId +
                                    ' | Error: ' + err.getMessage()
                                    );
                            }
                        }
                    }
                }
                
                if(!quoteLineItemsToUpdate.isEmpty()){
                    //update quoteLineItemsToUpdate.values();
                    
                    Database.update(quoteLineItemsToUpdate.values(), false);
                }
                
                List<Quote> nQuotelst=new List<Quote>();
                for(Quote quote :quoteList){
                    if(quoteSRmap.containsKey(quote.SAP_Order_No__c)){
                        Double returnableQty= quoteSRmap.get(quote.SAP_Order_No__c)*-1;
                        System.debug('returnableQty '+returnableQty);
                        System.debug('returnableQty '+quote.Total_Quantity__c);
                        if(quote.Total_Quantity__c == returnableQty) {
                            quote.Returnable_Received__c = true;
                            quote.ReturnableReceivedMarkedFromBackend__c = true;
                            nQuotelst.add(quote);
                        }
                    }
                    
                }
                if(!nQuotelst.isEmpty()){
                    //update nQuotelst;
                    Database.update(nQuotelst, false);
                }
            }
            
            // Enqueue next if needed
            System.debug('total '+total+' offset '+offset);
            if (total > offset) {
                System.enqueueJob(new FetchReturnableSamplesQueueable(offset + 1));
            }
        }catch (Exception e) {
            System.debug('Error Parsing SOAP Response: ' + e.getMessage() + e.getLineNumber());
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
        }
        Insert apiLog;
    }
}