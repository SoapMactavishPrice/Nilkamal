public with sharing class QuoteLineItemTriggerHandler {
    
    public static void overrideGrandPriceTotal(List<Id> quoteIds) {
        List<QuoteLineItem> qlis = [SELECT Id, QuoteId, Advanced_Received__c, Discount_In__c, GST_Percentage__c, Amount__c FROM QuoteLineItem WHERE QuoteId IN :quoteIds];
        Map<Id, List<QuoteLineItem>> qliMap = new Map<Id, List<QuoteLineItem>>();
        for (QuoteLineItem qli : qlis) {
            if (qli.QuoteId != null) {
                if (!qliMap.containsKey(qli.QuoteId)) {
                    qliMap.put(qli.QuoteId, new List<QuoteLineItem>());
                }
                qliMap.get(qli.QuoteId).add(qli);
            }
        }
        List<Quote> toBeUpdatedQuotes = new List<Quote>();
        for (Id quoteId : qliMap.keySet()) {
            Decimal totalGst = 0, totalDiscount = 0, totalAmount = 0, totalAdvanceReceived = 0;
            List<QuoteLineItem> lineItems = qliMap.get(quoteId);
            for (QuoteLineItem qli : lineItems) {
                if (qli.Amount__c != null) {
                    totalAmount += qli.Amount__c;
                }
                if (qli.Discount_In__c != null) {
                    totalDiscount += qli.Discount_In__c;
                }
                if (qli.GST_Percentage__c != null) {
                    totalGst += qli.GST_Percentage__c;
                }
                if (qli.Advanced_Received__c != null) {
                    totalAdvanceReceived += qli.Advanced_Received__c;
                }
            }
            Decimal avgGst = totalGst/lineItems.size();
            Decimal avgDiscount = totalDiscount/lineItems.size();
            Decimal grandPrice = (((avgGst+100)/100)*totalAmount) - ((avgDiscount/100)*totalAmount) - totalAdvanceReceived;
            Quote updateQuote = new Quote();
            updateQuote.Id = quoteId;
            updateQuote.Grand_Total_Price__c = grandPrice;
            toBeUpdatedQuotes.add(updateQuote);
        }
        
        UPDATE toBeUpdatedQuotes;
    }
    
    public static void UpdatePrice(List<QuoteLineItem> qliList, Map<Id, QuoteLineItem> oldMap)
    {
        
        Set<Id> pIds=new Set<Id>();
        for(QuoteLineItem qli:qliList)
        {
            pIds.add(qli.PricebookEntryId);
        }
        Map<Id, PricebookEntry> pbeMap = new Map<Id, PricebookEntry>([SELECT Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Id IN :pIds]);
        for (QuoteLineItem qli : qliList) {
            if (qli.PricebookEntryId != null && qli.Billing_Type__c=='Chargeable' && (oldMap.get(qli.Id).Billing_Type__c =='FOC and Returnable'|| oldMap.get(qli.Id).Billing_Type__c =='FOC and Non-Returnable')) {
                if (pbeMap.containsKey(qli.PricebookEntryId)) {
                    qli.UnitPrice = pbeMap.get(qli.PricebookEntryId).UnitPrice;
                }
            }
            if(qli.NT_Price__c!=oldMap.get(qli.Id).NT_Price__c){
                if(qli.NT_Price__c){
                    qli.Original_Unit_Price__c=qli.UnitPrice;
                    qli.UnitPrice=qli.UnitPrice + (qli.UnitPrice * 0.15); // if NT is applicable then apply increase the margin by 15%
                }else if(!qli.NT_Price__c){
                    qli.UnitPrice=qli.Original_Unit_Price__c; // if NT is not applicable
                }
            }
        }
    }
    
    public static void UpdateHSNCodeGST(List<QuoteLineItem> qliList, Map<Id, QuoteLineItem> oldMap)
    {
        
        Set<Id> proId=new Set<Id>();
        Map<Id,Product2> proMap=new Map<Id,Product2>();
        for(QuoteLineItem qli:qliList)
        {
            proId.add(qli.Product2Id);
        }
        Set<Id> hsnId=new Set<Id>();
        for(Product2 pro:[Select Id,Name,HSN_Code__c,Lead_Time__c from Product2 where id in:proId])
        {
            hsnId.add(pro.HSN_Code__c);
            proMap.put(pro.Id,pro);
        }
        Map<Id,HSN_Master__c> hsnMap=new Map<Id,HSN_Master__c>([SELECT Id, name, CGST__c,IGST__c,SGST__c FROM HSN_Master__c WHERE Id IN :hsnId]);
        for(QuoteLineItem qli:qliList)
        {
            System.debug(qli.Product2Id + ' ' + proMap.keySet());
            qli.HSN_Code__c=proMap.get(qli.Product2Id).HSN_Code__c;
            qli.Delivery_Time__c=proMap.get(qli.Product2Id).Lead_Time__c;
            System.debug('hsnMap.get(qli.Product2.HSN_Code__c)'+hsnMap.get(qli.HSN_Code__c));
            System.debug('hsnMap.get(qli.Product2.HSN_Code__c)'+hsnMap.get(qli.HSN_Code__c).CGST__c);
            System.debug('hsnMap.get(qli.Product2.HSN_Code__c)'+hsnMap.get(qli.HSN_Code__c).IGST__c);
            System.debug('hsnMap.get(qli.Product2.HSN_Code__c)'+hsnMap.get(qli.HSN_Code__c).SGST__c);
            
            qli.GST_Percentage__c=(hsnMap.get(qli.HSN_Code__c).CGST__c!=null?hsnMap.get(qli.HSN_Code__c).CGST__c:0)+
                (hsnMap.get(qli.HSN_Code__c).SGST__c!=null?hsnMap.get(qli.HSN_Code__c).SGST__c:0); //(hsnMap.get(qli.HSN_Code__c).IGST__c!=null?hsnMap.get(qli.HSN_Code__c).IGST__c:0)+
        }
    }
    
    public Static void UpdateDiscountValue(List<QuoteLineItem> qslLine,Map<Id,QuoteLineItem> oldMap)
    {
        for(QuoteLineItem qsl:qslLine)
        {
            if(oldMap.get(qsl.Id).Discount_In__c != qsl.Discount_In__c){
                if(qsl.Discount_In__c > 0){
                    qsl.Discount_In_Value_New__c  = (qsl.UnitPrice * qsl.Discount_In__c)/100;
                }
                else {
                    if(qsl.Discount_In_Value_New__c > 0){
                        decimal m = ((qsl.Discount_In_Value_New__c / qsl.UnitPrice) *100).setScale(2);
                        if(m > 100){
                            qsl.addError('The discount should be between 0 and 100%');
                        }
                        else {
                            qsl.Discount_In__c  = m;
                        }
                    }
                }
                
            }
            if(oldMap.get(qsl.Id).Discount_In_Value_New__c != qsl.Discount_In_Value_New__c){
                if(qsl.Discount_In_Value_New__c > 0){
                    qsl.Discount_In__c  = ((qsl.Discount_In_Value_New__c / qsl.UnitPrice) *100).setScale(2) ;
                    decimal m = ((qsl.Discount_In_Value_New__c / qsl.UnitPrice) *100).setScale(2) ;
                    if(m > 100) {
                        qsl.addError('The discount should be between 0 and 100%');
                    }
                    else {
                        qsl.Discount_In__c  = m;
                    }
                }
                else {
                    if(qsl.Discount_In__c > 0){
                        qsl.Discount_In_Value_New__c  = (qsl.UnitPrice * qsl.Discount_In__c)/100;
                    }
                }
            }
            
        }
    }
    
    
    public static void unlinkSpareRequests(List<QuoteLineItem> qliList) {
        List<Spare_Request__c> spareRequests = [
            SELECT Id, Name, Opportunity__c, Opportunity_Product__c, Quote__c, Quote_Line_item__c
            FROM Spare_Request__c
            WHERE Quote_Line_item__c IN :qliList
        ];
        for(Spare_Request__c spareRequest : spareRequests) {
            spareRequest.Opportunity__c = null;
            spareRequest.Opportunity_Product__c = null;
            spareRequest.Quote__c = null;
            spareRequest.Quote_Line_item__c = null;
        }
        if(spareRequests.size() > 0) {
            update spareRequests;
        }
    }
    
}