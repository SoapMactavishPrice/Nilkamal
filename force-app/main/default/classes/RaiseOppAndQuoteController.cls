public with sharing class RaiseOppAndQuoteController {

    @AuraEnabled
    public static Object raiseOppAndQuote(String recordId, String serviceAppointmentId, String type) {
        try {
            if(String.isBlank(recordId)) {
                // throw new CustomException('Something went wrong, please get in touch with your administrator. recordId');
            }
            if(String.isBlank(serviceAppointmentId)) {
                // throw new CustomException('Something went wrong, please get in touch with your administrator. serviceAppointmentId');
            }
            if(String.isBlank(type)) {
                // throw new CustomException('Something went wrong, please get in touch with your administrator. type');
            }


            Work_Order__c workOrder = [
                SELECT Name, CurrencyIsoCode,
                Case__r.OwnerId, TYPEOF Case__r.Owner WHEN User THEN Sales_Group__c END,
                Case__r.AccountId, Case__r.Account.Name, Case__r.Account.Sales_Organizations__c,
                Case__r.Account.Distribution_Channel__c, Case__r.Account.Division__c, Case__r.Account.Inco_Term_1__c, Case__r.Account.ShippingAddress,
                Case__c, Case__r.Account.Pricelist__c,
                Case__r.ContactId, Case__r.Contact.Name, Case__r.Contact.Email, Case__r.Contact.Phone,
                Case__r.Case_Notified_By__c, Case__r.Case_Notified_By__r.Name, Case__r.Case_Notified_By__r.Email, Case__r.Case_Notified_By__r.Phone,
                Case__r.Division__c,
                Case__r.AssetId, Case__r.Asset.Name, Case__r.Account.Terms_of_Payment__c, Case__r.Account.Inco_Term_2_Description__c,
                Case__r.Asset.AccountId, Case__r.Asset.End_Customer__c, Case__r.Asset.End_Customer__r.Sales_office__c,
                Case__r.Asset.Invoice__r.Sold_To_Party_1__c, Case__r.Asset.Invoice__r.Ship_To_Party_1__c,
                Case__r.Asset.Invoice__r.Distribution_Channel_1__c, Case__r.Asset.Invoice__r.Sales_Organizations__c, Case__r.Asset.Invoice__r.Division_1__c
                FROM Work_Order__c WHERE Id =: recordId LIMIT 1
            ];

            if(String.isBlank(workOrder.Case__r.AssetId)) {
                throw new CustomException('Please make sure Asset is tagged on the Case and try again.');
            }
            if(String.isBlank(workOrder.Case__r.AccountId)) {
                throw new CustomException('Please make sure Account is tagged on the Case and try again.');
            }
            if(String.isBlank(workOrder.Case__r.Account.Pricelist__c)) {
                throw new CustomException('Please make sure Pricelist is tagged on the Account and try again.');
            }

            if(type == 'spare') {
                Division__c div;
                try {
                    div = [SELECT Id FROM Division__c WHERE Division_Code__c = '01' LIMIT 1];
                } catch(Exception e) {
                    throw new CustomException('Division 01 does not exist, please get in touch with your administrator.');
                }
                List<Spare_Material_Request__c> spList=[SELECT Id, Name,Case__c, Status__c FROM Spare_Material_Request__c WHERE case__c=:workOrder.case__c and Status__c!='Completed'];
                if(spList.size()>0){
                    throw new CustomException('Cannot Create/update the quote as there are open requests for SAP Material Code Creation.');
                }
                return handleSpareRequestLogic(workOrder, serviceAppointmentId, div.Id);
            }
            else if(type == 'service') {
                Division__c div;
                Boolean batchQuote = 'frombatch' == serviceAppointmentId;
                system.debug('batchQuote boo-->'+batchQuote);
                if(serviceAppointmentId == 'frombatch'){
                    serviceAppointmentId = null;
                }
                try {
                    div = [SELECT Id FROM Division__c WHERE Division_Code__c = '03' LIMIT 1];
                } catch(Exception e) {
                    System.debug(e.getLineNumber() + ' ' + e.getMessage());
                    throw new CustomException('Division 03 does not exist, please get in touch with your administrator.');
                }
                return handleServiceRequestLogic(workOrder, serviceAppointmentId, div.Id, 'Chargeable Service',batchQuote);
            }
            return null;
        }
        catch(AuraHandledException e) {
            System.debug('System.isBatch() ' + System.isBatch() + ' System.isFuture() ' + System.isFuture() + ' System.isQueueable() ' + System.isQueueable() + ' Trigger.isExecuting ' + Trigger.isExecuting);
            if(System.isBatch() || System.isFuture() || System.isQueueable() || Trigger.isExecuting) {
                throw new CustomException(e.getMessage());
            }
            else {
                throw new AuraHandledException(e.getMessage());
            }
        }
        catch(Exception e) {
            System.debug('System.isBatch() ' + System.isBatch() + ' System.isFuture() ' + System.isFuture() + ' System.isQueueable() ' + System.isQueueable() + ' Trigger.isExecuting ' + Trigger.isExecuting);
            if(System.isBatch() || System.isFuture() || System.isQueueable() || Trigger.isExecuting) {
                throw new CustomException(e.getMessage());
            }
            else {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }


    private static List<Id> handleSpareRequestLogic(Work_Order__c workOrder, Id serviceAppointmentId, Id divisionId) {
        List<Spare_Request__c> spareRequests = [
            SELECT Id, Name, Item_Master__c,Category__c, CurrencyIsoCode, Opportunity__c, Opportunity_Product__c, Item_Description__c, OEM_Material_Code__c, Total_Stock__c,
            Pricebook_Entry_Id__c, Quantity_Required__c, Billed_Value__c, Billing_Type__c, Quote__c, Quote_Line_item__c, Opp_Raised__c, Quote_Raised__c,
            Warranty_Period__c, Number_of_PM_Visit__c, Number_of_Breakdown_Visit__c,Quote_Line_Item__r.Id
            FROM Spare_Request__c
            WHERE Work_Order__c =: workOrder.Id
        ];

         List<Spare_Request__c> checkSpareRequest = new List<Spare_Request__c>();
     	for(Spare_Request__c sr : spareRequests) {
      	   if(sr.Billed_Value__c == null && sr.Billed_Value__c == 0) {
             checkSpareRequest.add(sr);
         }
     }
    
     if(!checkSpareRequest.isEmpty()) {
         throw new CustomException('No valid Spare Requests found. All Spare Requests must have a positive Billed Value.');
     }

        if(!spareRequests.isEmpty()) {
            Boolean isSpareRequestAvailableForQuoteCreation = false;
            for(Spare_Request__c spareRequest : spareRequests) {
                if(spareRequest.Opportunity_Product__c == null && spareRequest.Quote_Line_item__c == null) {
                    isSpareRequestAvailableForQuoteCreation = true;
                    break;
                }
            }
            if(isSpareRequestAvailableForQuoteCreation == false) {
                throw new CustomException('There are no open Spare Requests, please raise a Spare Request and try again.');
            }
        }

        Set<String> billingTypesAvailable = new Set<String>();
        map<String, List<Spare_Request__c>> billingTypeWiseSpareRequests = new map<String, List<Spare_Request__c>>();
        for(Spare_Request__c spareRequest : spareRequests) {
            if( spareRequest.Billing_Type__c != null) {
                if(spareRequest.Opportunity__c == null) {
                    billingTypesAvailable.add(spareRequest.Billing_Type__c);
                }

                if(!billingTypeWiseSpareRequests.containsKey(spareRequest.Billing_Type__c)) {
                    billingTypeWiseSpareRequests.put(spareRequest.Billing_Type__c, new List<Spare_Request__c>());
                }
                billingTypeWiseSpareRequests.get(spareRequest.Billing_Type__c).add(spareRequest);
            }
        }

        List<Id> quoteIds = new List<Id>();
        if(!billingTypesAvailable.isEmpty()) {
            AggregateResult result = [SELECT MAX(Current_Sequence_No__c) maxDoc FROM Sequence_Master__c WHERE Current_Sequence_No__c != null];
            Sequence_Master__c cur=[SELECT Id,format__c,Starting_Number__c,Current_Sequence_No__c FROM Sequence_Master__c LIMIT 1];
            Integer maxNumber = 0;
            if (result != null && result.get('maxDoc') != null) {
                maxNumber = Integer.valueOf(result.get('maxDoc'));
            } else {
                maxNumber = integer.valueOf(cur.Starting_Number__c);
            }
            String curLng = cur.format__c;

            if(billingTypesAvailable.contains('FOC and Returnable')) {
                if(billingTypeWiseSpareRequests.containsKey('FOC and Returnable')) {
                    maxNumber++;
                    quoteIds.add(handleCreateEnquiryAndQuote(workOrder, serviceAppointmentId, 'FOC and Returnable', billingTypeWiseSpareRequests.get('FOC and Returnable'), divisionId, 'Spares', maxNumber, curLng));
                }
            }
            if(billingTypesAvailable.contains('FOC and Non-Returnable')) {
                if(billingTypeWiseSpareRequests.containsKey('FOC and Non-Returnable')) {
                    maxNumber++;
                    quoteIds.add(handleCreateEnquiryAndQuote(workOrder, serviceAppointmentId, 'FOC and Non-Returnable', billingTypeWiseSpareRequests.get('FOC and Non-Returnable'), divisionId, 'Spares', maxNumber, curLng));
                }
            }
            if(billingTypesAvailable.contains('Chargeable')) {
                if(billingTypeWiseSpareRequests.containsKey('Chargeable')) {
                    maxNumber++;
                    quoteIds.add(handleCreateEnquiryAndQuote(workOrder, serviceAppointmentId, 'Chargeable', billingTypeWiseSpareRequests.get('Chargeable'), divisionId, 'Spares', maxNumber, curLng));
                }
            }

            cur.Current_Sequence_No__c = maxNumber;
            update cur;

        }
        return quoteIds;
    }


    private static Id handleCreateEnquiryAndQuote(Work_Order__c workOrder, Id serviceAppointmentId, String billingType, List<Spare_Request__c> spareRequests, Id divisionId, String quoteDocType, Integer maxNumber, String curLng) {
        Distribution_Channel__c defaultDistr = [SELECT Id,Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c = '10' LIMIT 1];
        Sales_Organizations__c defaultSalesOrg = [SELECT Id,Sales_Org_Code__c FROM Sales_Organizations__c WHERE Sales_Org_Code__c = '1000' LIMIT 1];

        Set<Id> oppIds = new Set<Id>();
        for(Spare_Request__c spareRequest : spareRequests) {
            if(spareRequest.Opportunity__c != null) {
                oppIds.add(spareRequest.Opportunity__c);
            }
        }

        List<Opportunity> existingOpps = [SELECT Id, Name, Billing_Type__c,
                                        (SELECT Id, Name, Status FROM Quotes
                                        WHERE Status = 'Draft' OR Status != 'In Review' OR Status = 'Approved' OR Status = 'Rejected' OR Status = 'Presented' OR Status = 'Negotiation' OR Status = 'Denied'
                                        ORDER BY CreatedDate ASC LIMIT 1)
                                        FROM Opportunity
                                        WHERE Id IN :oppIds AND Billing_Type__c = :billingType
                                        ORDER BY CreatedDate DESC];

        Id oppId;
        Id quoteId;
        Opportunity opportunity;
        Quote quote;
        Boolean isPresentedStage = false;

        for(Opportunity existingOpp : existingOpps) {
            if (!existingOpp.Quotes.isEmpty()) {
                Quote existingQuote = existingOpp.Quotes[0];
                if(existingQuote.Status == 'Draft' || existingQuote.Status == 'In Review' || existingQuote.Status == 'Approved' || existingQuote.Status == 'Rejected') {
                    oppId = existingOpp.Id;
                    quoteId = existingQuote.Id;
                    isPresentedStage = false;
                    break;
                }
                else if(existingQuote.Status == 'Presented' || existingQuote.Status == 'Negotiation' || existingQuote.Status == 'Denied') {
                    oppId = existingOpp.Id;
                    quoteId = existingQuote.Id;
                    isPresentedStage = true;
                    break;
                }
            }
        }

        // for(Opportunity existingOpp : existingOpps) {
        //     if (!existingOpp.Quotes.isEmpty() &&
        //         (existingOpp.Quotes[0].Status == 'Draft' || existingOpp.Quotes[0].Status == 'Rejected' || existingOpp.Quotes[0].Status == 'Denied')) {
        //             oppId = existingOpp.Id;
        //             break;
        //     }
        // }

        if(String.isNotBlank(oppId)) {
            opportunity = [SELECT Id, Name, CurrencyIsoCode, Division__c, Distribution_Channel__c, Sales_Organizations__c, Sales_office__c, Sales_Group__c, Quote_Count__c, Billing_Type__c
                        FROM Opportunity
                        WHERE Id =: oppId];

            quote = [SELECT Id, Name, Pricebook2Id
                    FROM Quote
                    WHERE Id =: quoteId AND (Status = 'Draft' OR Status != 'In Review' OR Status = 'Approved' OR Status = 'Rejected' OR Status = 'Presented' OR Status = 'Negotiation' OR Status = 'Denied')];

            if(isPresentedStage == true) {
                createVersionController.createQuoteAndRelated(quoteId);
            }
        }
        else {
            String month = System.today().month() < 10 ? '0' + System.today().month() : String.valueOf(System.today().month());

            String quoteNumber = QuoteTriggerHandler.padWithZeros(maxNumber, curLng.length());

            opportunity = new Opportunity();
            opportunity.Name = quoteNumber + ' ' + workOrder.Case__r.Account.Name + ' ' + workOrder.Case__r.Asset.Name + ' ' + billingType + ' ' + System.today().year() + '/' + month;
            opportunity.StageName = 'Prospecting';
            opportunity.CloseDate = Date.today().addDays(30);
            opportunity.AccountId = workOrder.Case__r.AccountId;
            opportunity.Customer_Contact__c = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__c : workOrder.Case__r.ContactId;
            opportunity.Case__c = workOrder.Case__c;
            opportunity.Opportunity_Received_Date__c = System.today();
            opportunity.CurrencyIsoCode = workOrder.CurrencyIsoCode;
            opportunity.Pricebook2Id = workOrder.Case__r.Account.Pricelist__c;
            opportunity.serial_number__c = workOrder.Case__r.AssetId;
            opportunity.Distribution_Channel__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c) ? workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c : defaultDistr.Id;
            opportunity.Sales_Organizations__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c) ? workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c : defaultSalesOrg.Id;
            opportunity.Division__c = divisionId;
            opportunity.Sales_office__c = workOrder.Case__r.Asset.End_Customer__r.Sales_office__c;
            if(workOrder.Case__r.Owner instanceof User) {
                User owner = (User) workOrder.Case__r.Owner;
                opportunity.Sales_Group__c = owner.Sales_Group__c;
            }
            opportunity.Payment_Terms__c =workOrder.Case__r.Account.Terms_of_Payment__c;
            opportunity.Inco_Terms__c = workOrder.Case__r.Account.Inco_Term_1__c;
            opportunity.Inco_Remark__c = workOrder.Case__r.Account.Inco_Term_2_Description__c;
            opportunity.Sold_to_Party__c = workOrder.Case__r.Asset.AccountId;
            opportunity.Ship_to_Party__c = workOrder.Case__r.Asset.End_Customer__c;
            opportunity.Billing_Type__c = billingType;
            Database.insert(opportunity, true, AccessLevel.SYSTEM_MODE);

            Integer quoteCount = opportunity.Quote_Count__c != null ? Integer.valueOf(opportunity.Quote_Count__c) : 0;

            quote = new Quote();
            quote.Name = quoteNumber + ' V0 ' + workOrder.Case__r.Account.Name + ' ' + workOrder.Case__r.Asset.Name + ' ' + billingType + ' ' + System.today().year() + '/' + month;
            quote.Document_No_1__c = quoteNumber;
            quote.OpportunityId = opportunity.Id;
            quote.Case__c = workOrder.Case__c;
            quote.Work_Order__c = workOrder.Id;
            quote.Service_Appointment__c = serviceAppointmentId;
            quote.CurrencyIsoCode = opportunity.CurrencyIsoCode;
            quote.Pricebook2Id = workOrder.Case__r.Account.Pricelist__c;
            quote.ContactId = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__c : workOrder.Case__r.ContactId;
            quote.Email = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__r.Email : workOrder.Case__r.Contact.Email;
            quote.Phone = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__r.Phone : workOrder.Case__r.Contact.Phone;
            quote.Asset_Serial_Number__c = workOrder.Case__r.AssetId;
            quote.Quote_Start_Date__c = System.today();
            quote.Quote_Due_Date__c = System.today().addDays(3);
            quote.Business_Vertical__c = workOrder.Case__r.Division__c;
            quote.Distribution_Channel__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c) ? workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c : defaultDistr.Id;
            quote.Sales_Organizations__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c) ? workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c : defaultSalesOrg.Id;
            quote.Division__c = opportunity.Division__c;
            quote.Sales_office__c = opportunity.Sales_office__c;
            quote.Sales_Group__c = opportunity.Sales_Group__c;
            quote.Bill_to_Party__c = workOrder.Case__r.Asset.AccountId;
            quote.Ship_to_Party__c = workOrder.Case__r.Asset.End_Customer__c;
            quote.Quote_Document_Type__c = quoteDocType;
            quote.Billing_Type__c = opportunity.Billing_Type__c;
            quote.Quote_Number_in_Number__c = String.isNotBlank(quote.Document_No_1__c)? Integer.valueOf(quote.Document_No_1__c): null;
            Database.insert(quote, true, AccessLevel.SYSTEM_MODE);
        }


        List<Id> priceBookEntryIds = new List<Id>();
        for (Spare_Request__c spareRequest: spareRequests) {
            priceBookEntryIds.add(spareRequest.Pricebook_Entry_Id__c);
        }

        List<PricebookEntry> pricebookEntries = [SELECT Pricebook2Id FROM PricebookEntry WHERE Id IN :priceBookEntryIds AND Pricebook2Id != :quote.Pricebook2Id];
        if (!pricebookEntries.isEmpty()) {
            throw new CustomException('Some of the PricebookEntry does not match the parent pricebook2Id, please get in touch with your administrator.');
        }


        List<OpportunityLineItem> oppProductsToBeInserted = new List<OpportunityLineItem>();
        List<QuoteLineItem> quoteLineItemsToBeInserted = new List<QuoteLineItem>();

        for (Spare_Request__c spareRequest : spareRequests) {
            if(spareRequest.Opportunity_Product__c == null && spareRequest.Quote_Line_item__c == null) {
                OpportunityLineItem oppProduct = new OpportunityLineItem();
                if(spareRequest.Opportunity_Product__c != null) {
                    oppProduct.Id = spareRequest.Opportunity_Product__c;
                } else {
                    oppProduct.OpportunityId = opportunity.Id;
                    oppProduct.Product2Id = spareRequest.Item_Master__c ;
                    oppProduct.PricebookEntryId = spareRequest.Pricebook_Entry_Id__c;
                    oppProduct.UnitPrice = spareRequest.Billed_Value__c;
                    oppProduct.Billing_Type__c = spareRequest.Billing_Type__c;
                }
                oppProduct.Quantity = spareRequest.Quantity_Required__c;
                oppProductsToBeInserted.add(oppProduct);

                QuoteLineItem quoteLineItem = new QuoteLineItem();
                if(spareRequest.Quote_Line_item__c != null) {
                    quoteLineItem.Id = spareRequest.Quote_Line_item__c;
                } else {
                    quoteLineItem.QuoteId = quote.Id;
                    quoteLineItem.Product2Id = spareRequest.Item_Master__c;
                    quoteLineItem.pricebookEntryId = spareRequest.Pricebook_Entry_Id__c;
                    quoteLineItem.UnitPrice = spareRequest.Billed_Value__c;
                    quoteLineItem.Billing_Type__c = spareRequest.Billing_Type__c;
                    quoteLineItem.OEM_Material_Code__c = spareRequest.OEM_Material_Code__c;
                    quoteLineItem.Description = spareRequest.Item_Description__c;
                    quoteLineItem.Stock__c = spareRequest.Total_Stock__c;
                    quoteLineItem.Category__c = spareRequest.Category__c;
                    try { quoteLineItem.Warranty_Months__c = Decimal.valueOf(spareRequest.Warranty_Period__c); } catch (Exception e) { }
                    try { quoteLineItem.Number_of_PM_visits_in_12_Months__c = Decimal.valueOf(spareRequest.Number_of_PM_Visit__c); } catch (Exception e) { }
                    try { quoteLineItem.Number_of_Other_Visit_in_12_Months__c = Decimal.valueOf(spareRequest.Number_of_Breakdown_Visit__c); } catch (Exception e) { }
                }
                quoteLineItem.Quantity = spareRequest.Quantity_Required__c;
                quoteLineItemsToBeInserted.add(quoteLineItem);

                spareRequest.Opportunity_Product__r = oppProduct;
                spareRequest.Quote_Line_item__r = quoteLineItem;
            }
        }

        // UPSERT oppProductsToBeInserted;
        // UPSERT quoteLineItemsToBeInserted;

        Database.upsert(oppProductsToBeInserted, true, AccessLevel.SYSTEM_MODE);
        Database.upsert(quoteLineItemsToBeInserted, true, AccessLevel.SYSTEM_MODE);

        for (Spare_Request__c spareRequest : spareRequests) {
            if(spareRequest.Opportunity_Product__c == null) {
                spareRequest.Opportunity__c = opportunity.Id;
                spareRequest.Opportunity_Product__c = spareRequest.Opportunity_Product__r.Id;
                spareRequest.Opp_Raised__c = true;
            }
            if(spareRequest.Quote_Line_item__c == null) {
                spareRequest.Quote__c = quote.Id;
                spareRequest.Quote_Line_item__c = spareRequest.Quote_Line_item__r.Id;
                spareRequest.Quote_Raised__c = true;
            }
        }

        UPDATE spareRequests;

        return quote.Id;
    }


    private static Id handleServiceRequestLogic(Work_Order__c workOrder, Id serviceAppointmentId, Id divisionId, String quoteDocType, Boolean isBatch) {
        Distribution_Channel__c defaultServiceDistr = [SELECT Id,Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c = '10' LIMIT 1];
        Sales_Organizations__c defaultServiceSalesOrg = [SELECT Id,Sales_Org_Code__c FROM Sales_Organizations__c WHERE Sales_Org_Code__c = '1000' LIMIT 1];

        List<Service_Request__c> serviceRequests = [SELECT Id, Name, Price__c, Quantity__c, Opportunity__c, Enquiry_Service_Line_Item__c, Pricebook_Entry_Id__c, Item_Master__c, CurrencyIsoCode,
                                                    Quote__c, Quote_Service_Line_Item__c, Item_Master__r.Name, Item_Description__c, Original_Price__c,
                                                    Warranty_Period__c, Number_of_PM_Visit__c, Number_of_Breakdown_Visit__c,Quote_Service_Line_Item__r.Quote__c,Last_AMC_Price__c,Case__r.Division__c
                                                    FROM Service_Request__c
                                                    WHERE Work_Order__c =: workOrder.Id];

        Decimal totalPrice=0;
        Set<Id> srIds = new Set<Id>();
        for(Service_Request__c srqs:serviceRequests){
            totalPrice+=srqs.Price__c;
            if(srqs.Last_AMC_Price__c>srqs.Price__c){
                srIds.add(srqs.Id);
            }
        }

        if(totalPrice==0 && isBatch){
            Case cs=[Select Id,OwnerId,CaseNumber,Asset.Name,Is_Quote_Restricted__c FROM Case WHERE Id=:workOrder.Case__c];
             cs.Is_Quote_Restricted__c=true;
             update cs;
            return null;
        }
        else{
        if(!serviceRequests.isEmpty()) {
            if(serviceRequests.size() == 1) {
                if(String.isNotBlank(serviceRequests[0].Item_Master__r.Name)) {
                    if(serviceRequests[0].Item_Master__r.Name.toLowerCase().contains('amc')) {
                        quoteDocType = 'AMC';
                    }
                }
            }
        }

        if(!serviceRequests.isEmpty()) {
            Boolean isServiceRequestAvailableForQuoteCreation = false;
            for(Service_Request__c serviceRequest : serviceRequests) {
                if(serviceRequest.Enquiry_Service_Line_Item__c == null || serviceRequest.Quote_Service_Line_Item__c == null) {
                    isServiceRequestAvailableForQuoteCreation = true;
                    break;
                }
            }
            if(isServiceRequestAvailableForQuoteCreation == false) {
                throw new CustomException('There are no open Service Requests, please raise a Service Request and try again.');
            }
        }

        Set<Id> oppIds = new Set<Id>();
        for(Service_Request__c serviceRequest : serviceRequests) {
            if(serviceRequest.Opportunity__c != null) {
                oppIds.add(serviceRequest.Opportunity__c);
            }
        }

        List<Opportunity> existingOpps = [SELECT Id, Name, Billing_Type__c,
                                        (SELECT Id, Name, Status FROM Quotes
                                        WHERE Status = 'Draft' OR Status != 'In Review' OR Status = 'Approved' OR Status = 'Rejected' OR Status = 'Presented' OR Status = 'Negotiation' OR Status = 'Denied'
                                        ORDER BY CreatedDate ASC LIMIT 1)
                                        FROM Opportunity
                                        WHERE Id IN :oppIds];

        Id oppId;
        Id quoteId;
        Opportunity opportunity;
        Quote quote;
        Boolean isPresentedStage = false;

        for(Opportunity existingOpp : existingOpps) {
            if(!existingOpp.Quotes.isEmpty()) {
                Quote existingQuote = existingOpp.Quotes[0];
                if(existingQuote.Status == 'Draft' || existingQuote.Status == 'Rejected' || existingQuote.Status == 'Denied') {
                    oppId = existingOpp.Id;
                    quoteId = existingQuote.Id;
                    isPresentedStage = false;
                    break;
                }
                else if(existingQuote.Status == 'Presented' || existingQuote.Status == 'Negotiation' || existingQuote.Status == 'Denied') {
                    oppId = existingOpp.Id;
                    quoteId = existingQuote.Id;
                    isPresentedStage = true;
                    break;
                }
            }
        }


        if(String.isNotBlank(oppId)) {
            opportunity = [SELECT Id, Name, CurrencyIsoCode, Division__c, Distribution_Channel__c, Sales_Organizations__c, Sales_office__c, Sales_Group__c, Quote_Count__c, Billing_Type__c
                        FROM Opportunity
                        WHERE Id =: oppId];

            quote = [SELECT Id, Name, Pricebook2Id
                    FROM Quote
                    WHERE Id =: quoteId AND (Status = 'Draft' OR Status != 'In Review' OR Status = 'Approved' OR Status = 'Rejected' OR Status = 'Presented' OR Status = 'Negotiation' OR Status = 'Denied')];

            if(isPresentedStage == true) {
                createVersionController.createQuoteAndRelated(quoteId);
            }
        }
        else {
            String month = System.today().month() < 10 ? '0' + System.today().month() : String.valueOf(System.today().month());

            AggregateResult result = [SELECT MAX(Current_Sequence_No__c) maxDoc FROM Sequence_Master__c WHERE Current_Sequence_No__c != null];
            Sequence_Master__c cur = [SELECT Id,format__c,Starting_Number__c,Current_Sequence_No__c FROM Sequence_Master__c LIMIT 1];
            Integer maxNumber = 0;
            if (result != null && result.get('maxDoc') != null) {
                maxNumber = Integer.valueOf(result.get('maxDoc'));
            } else {
                maxNumber = integer.valueOf(cur.Starting_Number__c);
            }
            String curLng = cur.format__c;
            maxNumber++;

            String quoteNumber = QuoteTriggerHandler.padWithZeros(maxNumber, curLng.length());

            cur.Current_Sequence_No__c = maxNumber;
            update cur;

            opportunity = new Opportunity();
            opportunity.OwnerId=workOrder.Case__r.OwnerId;
            opportunity.Name = quoteNumber + ' ' + workOrder.Case__r.Account.Name + ' ' + workOrder.Case__r.Asset.Name + ' ' + System.today().year() + '/' + month;
            opportunity.StageName = 'Prospecting';
            opportunity.CloseDate = Date.today().addDays(30);
            opportunity.AccountId = workOrder.Case__r.AccountId;
            opportunity.Customer_Contact__c = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__c : workOrder.Case__r.ContactId;
            opportunity.Case__c = workOrder.Case__c;
            opportunity.Opportunity_Received_Date__c = System.today();
            opportunity.CurrencyIsoCode = workOrder.CurrencyIsoCode;
            opportunity.Pricebook2Id = workOrder.Case__r.Account.Pricelist__c;
            opportunity.serial_number__c = workOrder.Case__r.AssetId;
            opportunity.Distribution_Channel__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c) ? workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c : defaultServiceDistr.Id;
            opportunity.Sales_Organizations__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c) ? workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c : defaultServiceSalesOrg.Id;
            opportunity.Division__c = divisionId;
            opportunity.Sales_office__c = workOrder.Case__r.Asset.End_Customer__r.Sales_office__c;
            if(workOrder.Case__r.Owner instanceof User) {
                User owner = (User) workOrder.Case__r.Owner;
                opportunity.Sales_Group__c = owner.Sales_Group__c;
            }
            opportunity.Payment_Terms__c =workOrder.Case__r.Account.Terms_of_Payment__c;
            opportunity.Inco_Terms__c = workOrder.Case__r.Account.Inco_Term_1__c;
            opportunity.Inco_Remark__c = workOrder.Case__r.Account.Inco_Term_2_Description__c;
            opportunity.Sold_to_Party__c = workOrder.Case__r.Asset.AccountId;
            opportunity.Ship_to_Party__c = workOrder.Case__r.Asset.End_Customer__c;
            opportunity.Billing_Type__c = 'Chargeable';
            Database.insert(opportunity, true, AccessLevel.SYSTEM_MODE);

            Integer quoteCount = opportunity.Quote_Count__c != null ? Integer.valueOf(opportunity.Quote_Count__c) : 0;

            quote = new Quote();
            quote.OwnerId=workOrder.Case__r.OwnerId;
            quote.Name = quoteNumber + ' V0 ' + workOrder.Case__r.Account.Name + ' ' + workOrder.Case__r.Asset.Name + ' ' + System.today().year() + '/' + month;
            quote.Document_No_1__c = quoteNumber;
            quote.OpportunityId = opportunity.Id;
            quote.Case__c = workOrder.Case__c;
            quote.Work_Order__c = workOrder.Id;
            quote.Service_Appointment__c = serviceAppointmentId;
            quote.CurrencyIsoCode = opportunity.CurrencyIsoCode;
            quote.Pricebook2Id = workOrder.Case__r.Account.Pricelist__c;
            quote.ContactId = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__c : workOrder.Case__r.ContactId;
            quote.Email = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__r.Email : workOrder.Case__r.Contact.Email;
            quote.Phone = workOrder.Case__r.Case_Notified_By__c != null ? workOrder.Case__r.Case_Notified_By__r.Phone : workOrder.Case__r.Contact.Phone;
            quote.Asset_Serial_Number__c = workOrder.Case__r.AssetId;
            quote.Quote_Start_Date__c = System.today();
            quote.Quote_Due_Date__c = System.today().addDays(3);
            quote.Business_Vertical__c = workOrder.Case__r.Division__c;
            quote.Distribution_Channel__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c) ? workOrder.Case__r.Asset.Invoice__r.Distribution_Channel_1__c : defaultServiceDistr.Id;
            quote.Sales_Organizations__c = String.isNotBlank(workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c) ? workOrder.Case__r.Asset.Invoice__r.Sales_Organizations__c : defaultServiceSalesOrg.Id;
            quote.Division__c = opportunity.Division__c;
            quote.Sales_office__c = opportunity.Sales_office__c;
            quote.Sales_Group__c = opportunity.Sales_Group__c;
            quote.Bill_to_Party__c = workOrder.Case__r.Asset.AccountId;
            quote.Ship_to_Party__c = workOrder.Case__r.Asset.End_Customer__c;
            quote.Quote_Document_Type__c = quoteDocType;
            quote.Billing_Type__c = 'Chargeable';
            quote.Quote_Number_in_Number__c = String.isNotBlank(quote.Document_No_1__c)? Integer.valueOf(quote.Document_No_1__c): null;
            Database.insert(quote, true, AccessLevel.SYSTEM_MODE);
        }


        List<Id> pricebookEntryIds = new List<Id>();
        for(Service_Request__c serviceRequest : serviceRequests) {
            pricebookEntryIds.add(serviceRequest.Item_Master__c);
        }

        List<PricebookEntry> pricebookEntries = [SELECT Pricebook2Id FROM PricebookEntry WHERE Id IN :pricebookEntryIds AND Pricebook2Id != :quote.Pricebook2Id];
        if (!pricebookEntries.isEmpty()) {
            throw new CustomException('Some of the PricebookEntry does not match the parent pricebook2Id, please get in touch with your administrator.');
        }


        List<Opportunity_Service_Line_Item__c> oppServiceLineItemsToBeInserted = new List<Opportunity_Service_Line_Item__c>();
        List<Quote_Service_Line_Item__c> quoteServiceLineItemsToBeInserted = new List<Quote_Service_Line_Item__c>();

        for (Service_Request__c serviceRequest : serviceRequests) {
            if(serviceRequest.Enquiry_Service_Line_Item__c == null) {
                Opportunity_Service_Line_Item__c oppService = new Opportunity_Service_Line_Item__c();
                if(serviceRequest.Enquiry_Service_Line_Item__c != null) {
                    oppService.Id = serviceRequest.Enquiry_Service_Line_Item__c;
                } else {
                    oppService.product__c = serviceRequest.Item_Master__c;
                    oppService.Enquiry__c = opportunity.Id;
                    oppService.Service_Amount__c = serviceRequest.Price__c;
                }
                oppService.Quentity__c = serviceRequest.Quantity__c;
                oppServiceLineItemsToBeInserted.add(oppService);

                Quote_Service_Line_Item__c quoteService = new Quote_Service_Line_Item__c();
                if(serviceRequest.Quote_Service_Line_Item__c != null) {
                    quoteService.Id = serviceRequest.Quote_Service_Line_Item__c;
                } else {
                    quoteService.Item_Master__c = serviceRequest.Item_Master__c;
                    quoteService.Description__c = serviceRequest.Item_Description__c;
                    quoteService.Quote__c = quote.Id;
                    quoteService.Service_Amount__c = serviceRequest.Price__c;
                    quoteService.Original_Price__c = serviceRequest.Original_Price__c;
                    quoteService.Quantity__c = serviceRequest.Quantity__c;
                    quoteService.Last_AMC_Price__c = serviceRequest.Last_AMC_Price__c;
                    try { quoteService.AMC_Period_In_Months__c = Decimal.valueOf(serviceRequest.Warranty_Period__c); } catch (Exception e) { }
                    try { quoteService.Number_of_PM_visits_in_12_Months__c = Decimal.valueOf(serviceRequest.Number_of_PM_Visit__c); } catch (Exception e) { }
                    try { quoteService.Number_of_Breakdown_visits_in_12_Months__c = Decimal.valueOf(serviceRequest.Number_of_Breakdown_Visit__c); } catch (Exception e) { }
                }
                quoteServiceLineItemsToBeInserted.add(quoteService);


                serviceRequest.Enquiry_Service_Line_Item__r = oppService;
                serviceRequest.Quote_Service_Line_Item__r = quoteService;
            }
        }

        // UPSERT oppServiceLineItemsToBeInserted;
        // UPSERT quoteServiceLineItemsToBeInserted;

        Database.insert(oppServiceLineItemsToBeInserted, true, AccessLevel.SYSTEM_MODE);
        Database.insert(quoteServiceLineItemsToBeInserted, true, AccessLevel.SYSTEM_MODE);

        for(Service_Request__c serviceRequest : serviceRequests) {
            if(serviceRequest.Enquiry_Service_Line_Item__c == null) {
                serviceRequest.Opportunity__c = opportunity.Id;
                serviceRequest.Enquiry_Service_Line_Item__c = serviceRequest.Enquiry_Service_Line_Item__r.Id;
                serviceRequest.Opp_Raised__c = true;
            }
            if(serviceRequest.Quote_Service_Line_Item__c == null) {
                serviceRequest.Quote__c = quote.Id;
                serviceRequest.Quote_Service_Line_Item__c = serviceRequest.Quote_Service_Line_Item__r.Id;
                serviceRequest.Quote_Raised__c = true;
            }
        }

        UPDATE serviceRequests;

        List<Quote> quoteToUpdate = new List<Quote>();
        for(Service_Request__c serviceRqst : serviceRequests) {
            if(srIds.contains(serviceRqst.Id)){
                Quote quoteRec=new Quote();
                quoteRec.Id=serviceRqst.Quote__c;
                quoteRec.Send_for_Approval__c=true;
                quoteToUpdate.add(quoteRec);
            }
        }

        Update quoteToUpdate;

        return quote.Id;
    }
    }

}