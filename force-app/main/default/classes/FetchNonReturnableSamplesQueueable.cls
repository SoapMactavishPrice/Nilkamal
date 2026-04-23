public class FetchNonReturnableSamplesQueueable implements Queueable, Database.AllowsCallouts {
    
    Integer offset;
    public FetchNonReturnableSamplesQueueable(Integer offset) {
        this.offset = offset;
    }
    
    public void execute(QueueableContext context) {
        API_log__c apiLog=new API_log__c();
        apiLog.Log_Name__c ='NonReturnableSampleAPI';
        // Instantiate the web service class
        //ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS service = new ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS();
        
        // Call the API method
        //ReturnableSample.ZcrmReturnableSamplesResponse_element response = service.ZcrmReturnableSamples('X');
        
        //ReturnableSample.ZcrmRsamplesOutput sampledata=response.EmReturnableSamples;
        // Total items count (assuming it's a field in the response)
        try{
        HttpUtils.APIparamter util=HttpUtils.getWSDLAPIdetails('ReturnableSample');
        	String endpoint = util.Endpoint;
            
            SAPAuthSecret__mdt auth = SAPAuthSecret__mdt.getInstance('AuthDetails');

        	String us = auth.Username__c;
        	String ps = auth.Password__c;

        	String authString = us + ':' + ps;
        	String base64Auth = EncodingUtil.base64Encode(Blob.valueOf(authString));
            String requestBody = '<ZcrmReturnableSamples>'
    						  +'<Foc>X</Foc>'+
							  +'</ZcrmReturnableSamples>';
        
        	HttpRequest req = new HttpRequest();
       		 req.setEndpoint(endpoint);
        	req.setMethod('POST');
        	req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            req.setHeader('Authorization', 'Basic ' + base64Auth);
        	req.setBody(requestBody);
        	req.setTimeout(120000);
        
         Http http = new Http();
         HttpResponse res = http.send(req);
        
         if(res.getStatusCode()==201){
            Dom.Document doc = new Dom.Document();
            doc.load(res.getBody());
            Dom.XMLNode root = doc.getRootElement();
            Dom.XMLNode emRtrnSample = root.getChildElement('EmReturnableSamples', null);
            String responseTotal=root.getChildElement('EmAddnData', null).getText();
             String responseXml = res.getBody();
        Integer total = 0;
        if(responseTotal != null && responseTotal!='')
        {
            System.debug('EmAddnData ==> '+responseTotal);
            total = responseTotal != null ? Integer.valueOf(responseTotal.trim()) : 0;
        }
        
        // Process records (assuming a list of items is returned in response.EmReturnableSamples)
        List<Sample_Returnable_Order__c> samplesToInsert = new List<Sample_Returnable_Order__c>();
        
        if (emRtrnSample != null && emRtrnSample.getChildElements() != null) {
            Set<String> custids=new Set<String>();
            Set<String> productCodes = new Set<String>();
            Set<String> saleOrgIds = new Set<String>();
            Set<String> slorgList = new Set<String>();
            Set<String> disChlList = new Set<String>();
            Set<String> divList = new Set<String>();
            Set<String> pCodeList = new Set<String>();
            Set<String> mfgParts = new Set<String>();
            Set<String> bUomCodeList = new Set<String>();
            for (Dom.XMLNode item : emRtrnSample.getChildElements()) {
               String customer=item.getChildElement('Kunnr', null)?.getText();
                if( customer!=null && customer!=''){
                    custids.add(customer);
                }
                String Matnr=item.getChildElement('Matnr', null)?.getText();
                if(Matnr!=null && Matnr!=''){
                    productCodes.add(Matnr);
                }
                String Vkorg=item.getChildElement('Vkorg', null)?.getText();
                if(Vkorg!=null && Vkorg!=''){
                    slorgList.add(Vkorg);
                }
                String Vtweg=item.getChildElement('Vtweg', null)?.getText();
                if(Vtweg!=null && Vtweg!=''){
                    disChlList.add(Vtweg);
                }
                String Spart=item.getChildElement('Spart', null)?.getText();
                if(Spart!=null && Spart!=''){
                    divList.add(Spart);
                }
                
                String Werks=item.getChildElement('Werks', null)?.getText();
                if(Werks!=null && Werks!=''){
                    pCodeList.add(Werks);
            }
                 String Mfrpn=item.getChildElement('Mfrpn', null)?.getText();
                if(Mfrpn != null && Mfrpn!=''){
                    mfgParts.add(Mfrpn);
                }
                String Zieme=item.getChildElement('Zieme', null)?.getText();
                if(Zieme!=null && Zieme!=''){
                    bUomCodeList.add(Zieme);
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
            
           /* Set<String> orderNoSet=new Set<String>();
            for (ReturnableSample.ZcrmCustomerSampleOutStr item : sampledata.item) {
                if(item.Auart=='ZSOA'){
                    System.debug('====> '+item.Auart);
                    orderNoSet.add(item.Vbeln);
                }
            }
            List<Quote> quoteList =new List<Quote>();
            quoteList= [SELECT Id,Name,Returnable_Received__c,SAP_Order_No__c,Total_Quantity__c FROM Quote WHERE SAP_Order_No__c IN :orderNoSet AND Billing_Type__c='FOC and Returnable'];
            Map<String, Quote> mpQuote =new Map<String, Quote>();
            for(Quote quote :quoteList){
                mpQuote.put(quote.SAP_Order_No__c,quote);
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
            
            Map<Id, QuoteLineItem> quoteLineItemsToUpdate = new Map<Id, QuoteLineItem>();*/
            
            Map<String,Double> mpNewQty=new Map<String,Double>();
            for (Dom.XMLNode item : emRtrnSample.getChildElements()) {
                //System.debug('====> '+item.Auart);
                Sample_Returnable_Order__c sample = new Sample_Returnable_Order__c();
                sample.Document_Type__c = item.getChildElement('Auart', null)?.getText();
                if(item.getChildElement('Audat', null)?.getText() != '0000-00-00'){
                    sample.Document_Date__c = item.getChildElement('Audat', null)?.getText() != null ? Date.valueOf(item.getChildElement('Audat', null)?.getText()) : null;
                }
                sample.Name = item.getChildElement('Vbeln', null)?.getText();
                sample.Sales_Organizations__c =soMap.get(item.getChildElement('Vkorg', null)?.getText())!=null?soMap.get(item.getChildElement('Vkorg', null)?.getText()).Id:null;
                sample.Distribution_Channel__c = dcMap.get(item.getChildElement('Vtweg', null)?.getText())!=null?dcMap.get(item.getChildElement('Vtweg', null)?.getText()).Id:null;   //item.VTWEG;
                sample.Division__c = diMap.get(item.getChildElement('Spart', null)?.getText())!=null?diMap.get(item.getChildElement('Spart', null)?.getText()).Id:null;
                sample.Customer_Code__c=item.getChildElement('Kunnr', null)?.getText();
                sample.Customer_Name__c= accMap.get(item.getChildElement('Kunnr', null)?.getText())!=null?accMap.get(item.getChildElement('Kunnr', null)?.getText()).Id:null;
                sample.Customer_Name_Desc__c = item.getChildElement('Name1', null)?.getText();
                sample.Plant_Master__c =pltMap.get(item.getChildElement('Werks', null)?.getText())!=null?pltMap.get(item.getChildElement('Werks', null)?.getText()).Id:null;
                sample.Item__c=item.getChildElement('Posnr', null)?.getText();
                sample.Material__c =productMap.get(item.getChildElement('Matnr', null)?.getText())!=null?productMap.get(item.getChildElement('Matnr', null)?.getText()).Id:null;
                sample.Order_Quantity__c =item.getChildElement('Kwmeng', null)?.getText()!=''&& item.getChildElement('Kwmeng', null)?.getText()!=null?Decimal.valueOf(item.getChildElement('Kwmeng', null)?.getText()):0;
                sample.Billed_Quantity__c =item.getChildElement('Fkimg', null)?.getText()!=''&& item.getChildElement('Fkimg', null)?.getText()!=null?Decimal.valueOf(item.getChildElement('Fkimg', null)?.getText()):0;
                //sample.Invoice_Quantity__c=item.Fkimg;
                sample.Base_UOM__c =  baseUomMap.get(item.getChildElement('Zieme', null)?.getText())!=null?baseUomMap.get(item.getChildElement('Zieme', null)?.getText()).Id:null ;
                sample.Moving_Average_Price__c = item.getChildElement('Verpr', null)?.getText() != null ? Decimal.valueOf(item.getChildElement('Verpr', null)?.getText()) : null;
                sample.Delivery__c = item.getChildElement('Vbeln1', null)?.getText();
                sample.Predecessr__c=item.getChildElement('Pgno', null)?.getText();
                sample.Sale_Document_Challen_No__c=item.getChildElement('Aubel', null)?.getText();
                sample.Sales_Document__c=item.getChildElement('Kdmat', null)?.getText();
                sample.Return_Delay_Days__c =String.valueOf(item.getChildElement('ZDAYS', null)?.getText());
                sample.Description__c = item.getChildElement('Maktx', null)?.getText();
                sample.Manufacturer_Part_Number__c =mfgMap.get(item.getChildElement('Mfrpn', null)?.getText())!=null?mfgMap.get(item.getChildElement('Mfrpn', null)?.getText()).Id:null;
                sample.Sales_Group__c = item.getChildElement('Vkgrp', null)?.getText();
                sample.Sales_Group_Description__c = item.getChildElement('SgrpDesc', null)?.getText() != null ? String.valueOf(item.getChildElement('SgrpDesc', null)?.getText()) : null;
                sample.Sales_Office__c = item.getChildElement('SoffDesc', null)?.getText();
                sample.Sales_Employee__c = item.getChildElement('Salesman', null)?.getText();
                sample.Sales_Employee_Code__c =item.getChildElement('Snam', null)?.getText();
                if(item.getChildElement('Snam', null)?.getText()!=null && item.getChildElement('Snam', null)?.getText()!=''){
                    String uid=item.getChildElement('Snam', null)?.getText();
                    if(uMap.containsKey(uid)){
                        sample.OwnerId=uMap.get(uid);
                    }
                }
                sample.Is_Non_Returnable__c=true;
                /*if(mpQuote.get(item.Kdmat)!=null){
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
                    if(item.Auart == 'ZDIR') {
                        qli.ZIDR_Date__c = sample.Document_Date__c;
                        quoteLineItemsToUpdate.put(qli.Id, qli);
                    }
                }
                
                if(mpNewQty.containsKey(item.Kdmat)){
                    Double qty = mpNewQty.get(item.Kdmat);
                    mpNewQty.put(item.Kdmat,qty+Decimal.valueOf(item.Fkimg));
                }else{
                    mpNewQty.put(item.Kdmat,Decimal.valueOf(item.Fkimg));
                }*/
                samplesToInsert.add(sample);
            }
            
            // Insert into Salesforce
            if (!samplesToInsert.isEmpty()) {
                insert samplesToInsert;
            }
            
        }
        
        // Enqueue next if needed
        System.debug('total '+total+' offset '+offset);
        if (total > offset) {
            System.enqueueJob(new FetchNonReturnableSamplesQueueable(offset + 1));
        }
         
         apiLog.Response__c=responseXml;
         apiLog.Status__c='Success';
         }
        }catch (Exception e) {
            System.debug('Error Parsing SOAP Response: ' + e.getMessage() + e.getLineNumber());
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
        }
        Insert apiLog;
    }
        
}