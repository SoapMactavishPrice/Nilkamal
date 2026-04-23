public class QuoteServiceLineItemTriggerHandler {

    public static void updateQuoteSummary(List<Quote_Service_Line_Item__c> newRecords, List<Quote_Service_Line_Item__c> oldRecords) {
        Set<Id> quoteIds = new Set<Id>();
        if (newRecords != null) {
            for (Quote_Service_Line_Item__c record : newRecords) {
                if (record.Quote__c != null) {
                    quoteIds.add(record.Quote__c);
                }
            }
        }
        if (oldRecords != null) {
            for (Quote_Service_Line_Item__c record : oldRecords) {
                if (record.Quote__c != null) {
                    quoteIds.add(record.Quote__c);
                }
            }
        }
        if (quoteIds.isEmpty()) {
            return;
        }

        Map<Id, AggregateResult> aggMap = new Map<Id, AggregateResult>();
        for (AggregateResult ar : [
            SELECT Quote__c, SUM(Service_Gross_Totals__c) totalSubTotal, SUM(Service_Grand_Total__c) totalGrandTotal,
            SUM(GST_Value__c) totalGSTValue, SUM(Service_Amount__c) totalServiceAmount
            FROM Quote_Service_Line_Item__c
            WHERE Quote__c IN :quoteIds
            GROUP BY Quote__c
        ]) {
            aggMap.put((Id)ar.get('Quote__c'), ar);
        }

        List<Quote> quotesToUpdate = new List<Quote>();
        for (Id qId : quoteIds) {
            Quote quote = new Quote();
            quote.Id = qId;

            if (aggMap.containsKey(qId)) {
                AggregateResult ar = aggMap.get(qId);
                quote.Service_Total_Amount__c = (Decimal) ar.get('totalSubTotal');
                quote.Service_Grand_Total__c = (Decimal) ar.get('totalGrandTotal');
                quote.Service_GST_Value__c = (Decimal) ar.get('totalGSTValue');
                quote.Quote_Service_Total_Price__c = (Decimal) ar.get('totalServiceAmount');
            } else {
                // Case: No line items left → reset to 0
                quote.Service_Total_Amount__c = 0;
                quote.Service_Grand_Total__c = 0;
                quote.Service_GST_Value__c = 0;
                quote.Quote_Service_Total_Price__c = 0;
            }
            quotesToUpdate.add(quote);
        }

        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
        }
    }


    public Static void UpdateGST(List<Quote_Service_Line_Item__c> qslLine) {
        Set<Id>sId=new Set<Id>();
        for(Quote_Service_Line_Item__c qsl : qslLine) {
            if(qsl.Service_GST__c == null || qsl.Service_GST__c == 0) {
                sId.add(qsl.Item_Master__c);
            }
        }

        if(sId.size() > 0) {
            Map<Id,Product2> itemMap=new Map<Id,Product2>([SELECT Id,HSN_Code__c,HSN_Code__r.CGST__c,HSN_Code__r.IGST__c,HSN_Code__r.SGST__c FROM Product2 WHERE Id IN :sId]);
            for(Quote_Service_Line_Item__c qsl : qslLine) {
                if(qsl.Service_GST__c == null || qsl.Service_GST__c == 0) {
                    qsl.Service_GST__c = (itemMap.get(qsl.Item_Master__c).HSN_Code__r.CGST__c!=null?itemMap.get(qsl.Item_Master__c).HSN_Code__r.CGST__c:0)+
                                        (itemMap.get(qsl.Item_Master__c).HSN_Code__r.SGST__c!=null?itemMap.get(qsl.Item_Master__c).HSN_Code__r.SGST__c:0); //(itemMap.get(qsl.Item_Master__c).HSN_Code__r.IGST__c!=null?itemMap.get(qsl.Item_Master__c).HSN_Code__r.IGST__c:0)+
                }
            }
        }
    }

    public Static void UpdateDiscountValue(List<Quote_Service_Line_Item__c> qslLine,Map<Id,Quote_Service_Line_Item__c> oldMap) {
        for(Quote_Service_Line_Item__c qsl:qslLine) {
            if(oldMap.get(qsl.Id).Discount_In__c != qsl.Discount_In__c) {
                if(qsl.Discount_In__c > 0) {
                    qsl.Discount_In_Value_New__c  = (qsl.Service_Amount__c * qsl.Discount_In__c)/100;
                }
                else {
                    if(qsl.Discount_In_Value_New__c > 0) {
                        qsl.Discount_In__c  = ((qsl.Discount_In_Value_New__c / qsl.Service_Amount__c) *100).setScale(2);
                    }
                }
            }
            if(oldMap.get(qsl.Id).Discount_In_Value_New__c != qsl.Discount_In_Value_New__c) {
                if(qsl.Discount_In_Value_New__c > 0) {
                    qsl.Discount_In__c  = ((qsl.Discount_In_Value_New__c / qsl.Service_Amount__c) *100).setScale(2);
                }else{
                    if(qsl.Discount_In__c > 0) {
                        qsl.Discount_In_Value_New__c  = (qsl.Service_Amount__c * qsl.Discount_In__c)/100;
                    }
                }
            }
        }
    }
        // added by keshav

    public static void unlinkServiceRequests(List<Quote_Service_Line_Item__c> qliList) {
        List<Id> quoteIds = new List<Id>();
        for(Quote_Service_Line_Item__c qli : qliList) {
            quoteIds.add(qli.Id);

        }
        List<Service_Request__c> serviceRequests = [
            SELECT Id, Name, Opportunity__c, Enquiry_Service_Line_Item__c, Quote__c, Quote_Service_Line_Item__c
            FROM Service_Request__c
            WHERE Quote_Service_Line_Item__c IN :quoteIds
        ];
        for(Service_Request__c serviceRequest : serviceRequests) {
            serviceRequest.Opportunity__c = null;
            serviceRequest.Enquiry_Service_Line_Item__c = null;
            serviceRequest.Quote__c = null;
            serviceRequest.Quote_Service_Line_Item__c = null;
        }
        if(serviceRequests.size() > 0) {
            update serviceRequests;
        }
    }

}