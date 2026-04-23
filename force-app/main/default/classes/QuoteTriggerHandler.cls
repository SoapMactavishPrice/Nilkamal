public without sharing class QuoteTriggerHandler {
    
    public static void setExternalId(List<Quote> quoteList) {
        for(Quote q : quoteList) {
            q.External_Id__c = q.Document_No_1__c + ' - ' + (q.Document_Version__c ?? '');
        }
    }
    
    
    public static void setRSMApprover(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        for(Quote q : quoteList) {
            // Check if RSM_Approver__c is being set or updated
            if(q.RSM_Approver__c != null && (oldMap == null || oldMap.get(q.Id) == null || q.RSM_Approver__c != oldMap.get(q.Id).RSM_Approver__c)) {
                q.RSM_Approver__c = Label.MHERSMApprover;
            }
        }
    }
    
    
    public static void updateOwnerToEnquiry(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        Map<Id, Opportunity> enqMap = new Map<Id, Opportunity>();
        for(Quote q : quoteList) {
            if(q.OpportunityId != null && q.OwnerId != oldMap.get(q.Id).OwnerId) {
                enqMap.put(q.OpportunityId, new Opportunity(Id = q.OpportunityId, OwnerId = q.OwnerId));
            }
        }
        
        if(enqMap.size() > 0) {
            update enqMap.values();
        }
    }
    
    
    public static void checkApprovalRequired(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        // Handle null oldMap for insert operations
        if(oldMap == null) {
            oldMap = new Map<Id, Quote>();
        }
        
        Map<Id, List<QuoteLineItem>> quoteLineItemMap = new Map<Id, List<QuoteLineItem>>();
        Map<Id, List<Quote_Service_Line_Item__c>> quoteServiceLineItemMap = new Map<Id, List<Quote_Service_Line_Item__c>>();
        
        // Only query if we have IDs to query (i.e., for updates)
        List<Quote> qList = new List<Quote>();
        if(oldMap.keySet().size() > 0) {
            qList = [SELECT Id, Name, Business_Vertical__c, Quote_Document_Type__c,
                                (SELECT Id, Product2Id, Product2.Name, Discount_In__c, Warranty_Months__c FROM QuoteLineItems ORDER BY Discount_In__c DESC, Warranty_Months__c DESC),
                                (SELECT Id, Item_Master__c, Item_Master__r.Name, Discount_In__c, Margin_Percentage__c FROM Quote_Service_Line_Items__r ORDER BY Margin_Percentage__c DESC, Discount_In__c DESC)
                                FROM Quote
                                WHERE Id IN :oldMap.keySet()];
        }
        
        for(Quote q : qList) {
            quoteLineItemMap.put(q.Id, q.QuoteLineItems);
            quoteServiceLineItemMap.put(q.Id, q.Quote_Service_Line_Items__r);
        }
        
        //Map<Id, User> userMap = DataCls.getUsersById();
        Map<Id, User> userMap = DataCls.getUsersById();
        if(userMap == null) {
            userMap = new Map<Id, User>();
        }
        System.debug('User Map: ' + userMap);
        
        for(Quote quote : quoteList) {
            System.debug('Quote=>' + quote);
            
            User u = userMap.get(quote.OwnerId);
            
            String approverId;
            String rsmApproverId;
            Boolean isApprovalRequired = false;
            List<String> approvalReasons = new List<String>();
            
            Boolean isSpares = quote.Quote_Document_Type__c == 'Spares';
            Boolean isAMC = quote.Quote_Document_Type__c == 'AMC';
            Boolean isChargeableService = quote.Quote_Document_Type__c == 'Chargeable Service';
            Boolean isAMCOrChargeable = isAMC || isChargeableService;
            
            Boolean isFOCReturnableSpare = quote.Billing_Type__c == 'FOC and Returnable';
            Boolean isFOCNonReturnableSpare = quote.Billing_Type__c == 'FOC and Non-Returnable';
            Boolean isFOCSpare = isFOCReturnableSpare || isFOCNonReturnableSpare;
            Boolean isChargeableSpare = quote.Billing_Type__c == 'Chargeable';
            
            // For insert operations, there's no line item data available in before insert trigger
            // So only process approval logic for quotes that have been saved before (updates)
            if(quoteLineItemMap.containsKey(quote.Id) || quoteServiceLineItemMap.containsKey(quote.Id)) {
                
                if(quote.Business_Vertical__c == 'MHE') {
                    if (isSpares) {
                        if(isFOCSpare) {
                            approverId = label.MHEFOCApprover;
                            rsmApproverId = label.MHERSMApprover;
                            isApprovalRequired = true;
                            approvalReasons.add('Quote Billing Type is FOC so need approval from ' + userMap.get(label.MHEFOCApprover).Name + ' or higher authority');
                        }
                        else {
                            List<QuoteLineItem> qli = quoteLineItemMap.get(quote.Id);
                            for(QuoteLineItem ql : qli) {
                                System.debug('QL=>' + ql.Product2.Name + ' ' + ql.Discount_In__c + ' ' + ql.Warranty_Months__c);
                                if(ql.Warranty_Months__c > 3) {
                                    if(approverId == null || approverId == u.ManagerId) {
                                        approverId = label.MHEFOCApprover;
                                    }
                                    if(rsmApproverId == null) {
                                        rsmApproverId = label.MHERSMApprover;
                                    }
                                    isApprovalRequired = true;
                                    approvalReasons.add(ql.Product2.Name + ' has ' + ql.Warranty_Months__c + ' months of warranty so need approval from ' + userMap.get(label.MHEFOCApprover).Name + ' or higher authority');
                                }
                                if(ql.Discount_In__c > 10) {
                                    if(approverId == null) {
                                        approverId = u.ManagerId;
                                    }
                                    if(rsmApproverId == null) {
                                        rsmApproverId = label.MHERSMApprover;
                                    }
                                    isApprovalRequired = true;
                                    if(!Test.isRunningTest()) {
                                        approvalReasons.add(ql.Product2.Name + ' has discount of ' + ql.Discount_In__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                                    }
                                    
                                }
                            }
                        }
                    }
                    else if(isAMCOrChargeable) {
                        List<Quote_Service_Line_Item__c> qsl = quoteServiceLineItemMap.get(quote.Id);
                        for(Quote_Service_Line_Item__c ql : qsl) {
                            if(ql.Margin_Percentage__c > 10 || ql.Margin_Percentage__c < -10) {
                                if(approverId == null) {
                                    approverId = u.ManagerId;
                                }
                                if(rsmApproverId == null) {
                                    rsmApproverId = label.MHERSMApprover;
                                }
                                isApprovalRequired = true;
                                if(!Test.isRunningTest()) {
                                    approvalReasons.add(ql.Item_Master__r.Name + ' has margin of ' + ql.Margin_Percentage__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                                }
                            }
                            if(ql.Discount_In__c > 10) {
                                if(approverId == null) {
                                    approverId = u.ManagerId;
                                }
                                if(rsmApproverId == null) {
                                    rsmApproverId = label.MHERSMApprover;
                                }
                                isApprovalRequired = true;
                                approvalReasons.add(ql.Item_Master__r.Name + ' has discount of ' + ql.Discount_In__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                            }
                        }
                    }
                    
                    if(quote.L_D_Applicable__c != 'Yes') {
                        quote.LD_Terms__c = null;
                    }
                    if(quote.Performance_Bank_Guarantee__c != 'Yes') {
                        quote.Performance_Bank_Guarantee_Terms__c = null;
                    }
                    if(quote.Additional_Bank_Guarantee__c != 'Yes') {
                        quote.ABG_Terms__c = null;
                    }
                    
                    if(quote.L_D_Applicable__c == 'Yes' || quote.Performance_Bank_Guarantee__c == 'Yes' || quote.Additional_Bank_Guarantee__c == 'Yes') {
                        if(approverId == null) {
                            approverId = u.ManagerId;
                        }
                        if(rsmApproverId == null) {
                            rsmApproverId = label.MHERSMApprover;
                        }
                        isApprovalRequired = true;
                        
                        if(quote.L_D_Applicable__c == 'Yes') {
                            approvalReasons.add('Quote has "LD" so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                        } else {
                            quote.LD_Terms__c = null;
                        }
                        
                        if(quote.Performance_Bank_Guarantee__c == 'Yes') {
                            approvalReasons.add('Quote has "Performance Bank Guarantee" so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                        } else {
                            quote.Performance_Bank_Guarantee_Terms__c = null;
                        }
                        
                        if(quote.Additional_Bank_Guarantee__c == 'Yes') {
                            approvalReasons.add('Quote has "Additional Bank Guarantee" so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                        } else {
                            quote.ABG_Terms__c = null;
                        }
                    }
                    system.debug('approver__c--'+quote.approver__c);
                    system.debug('Send_for_Approval__c--'+quote.Send_for_Approval__c);
                    if(quote.Send_for_Approval__c==true){
                        approvalReasons.add('For certain Quote service line item(s), the Basic Unit Price is lower than the Basic Unit Price of last AMC for the same service.');
                        if(quote.approver__c == null) {
                            approverId=u.ManagerId;
                        }
                        if(rsmApproverId == null) {
                            rsmApproverId = label.MHERSMApprover;
                        }
                    }
                }
                
                if(quote.Business_Vertical__c=='Printer') {
                    if (isSpares) {
                        if(isFOCSpare) {
                            if(isFOCReturnableSpare) {
                                if(approverId == null) {
                                    approverId = u.ManagerId;
                                }
                                isApprovalRequired = true;
                                approvalReasons.add('Quote Billing Type is "FOC and Returnable" so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                            }
                            else if(isFOCNonReturnableSpare) {
                                if(approverId == null || approverId == u.ManagerId) {
                                    approverId = label.PrinterApprover;
                                }
                                isApprovalRequired = true;
                                approvalReasons.add('Quote Billing Type is "FOC and Non-Returnable" so need approval from ' + userMap.get(label.PrinterApprover).Name + ' or higher authority');
                            }
                        }
                        else {
                            List<QuoteLineItem> qli = quoteLineItemMap.get(quote.Id);
                            for(QuoteLineItem ql : qli) {
                                System.debug('QLI=>' + ql.Product2.Name + ' ' + ql.Warranty_Months__c + ' ' + ql.Discount_In__c);
                                if(ql.Warranty_Months__c > 3) {
                                    if(approverId == null || approverId == u.ManagerId) {
                                        // approverId = label.PrinterApprover;
                                        approverId = u.ManagerId;
                                        
                                    }
                                    isApprovalRequired = true;
                                    approvalReasons.add(ql.Product2.Name + ' has ' + ql.Warranty_Months__c + ' months of warranty so need approval from ' + userMap.get(label.PrinterApprover).Name + ' or higher authority');
                                }
                                if(ql.Discount_In__c > 0) {
                                    if(approverId == null) {
                                        approverId = u.ManagerId;
                                    }
                                    isApprovalRequired = true;
                                    approvalReasons.add(ql.Product2.Name + ' has discount of ' + ql.Discount_In__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                                }
                            }
                        }
                    }
                    if(isAMCOrChargeable) {
                        List<Quote_Service_Line_Item__c> qsl = quoteServiceLineItemMap.get(quote.Id);
                        for(Quote_Service_Line_Item__c ql : qsl) {
                            if(ql.Margin_Percentage__c > 10 || ql.Margin_Percentage__c < -10) {
                                if(approverId == null) {
                                    approverId = u.ManagerId;
                                }
                                isApprovalRequired = true;
                                approvalReasons.add(ql.Item_Master__r.Name + ' has margin of ' + ql.Margin_Percentage__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                            }
                            if(ql.Discount_In__c > 0) {
                                if(approverId == null) {
                                    approverId = u.ManagerId;
                                }
                                isApprovalRequired = true;
                                approvalReasons.add(ql.Item_Master__r.Name + ' has discount of ' + ql.Discount_In__c + '% so need approval from ' + userMap.get(u.ManagerId).Name + ' or higher authority');
                            }
                        }
                    }
                }
                
                System.debug('quote.Required_Approval__c ' + quote.Required_Approval__c + ' New value ' + isApprovalRequired);
                System.debug('quote.approver__c ' + quote.approver__c + ' New value ' + approverId);
                System.debug('quote.RSM_Approver__c ' + quote.RSM_Approver__c + ' New value ' + rsmApproverId);
                
                if(quote.approver__c != approverId || quote.Required_Approval__c != isApprovalRequired || quote.RSM_Approver__c != rsmApproverId) {
                    quote.Required_Approval__c = isApprovalRequired;
                    quote.approver__c = approverId;
                    quote.RSM_Approver__c = rsmApproverId;
                }
                
                if(approvalReasons.size() > 0) {
                    String approvalReasonsString = '';
                    for(Integer i = 0; i < approvalReasons.size(); i++) {
                        approvalReasonsString += (i + 1) + '. ' + approvalReasons[i] + '\n';
                    }
                    if(approvalReasonsString.endsWith('\n')) {
                        approvalReasonsString = approvalReasonsString.substring(0, approvalReasonsString.length() - 1);
                    }
                    
                    System.debug('approvalReasonsString isEqual ' + (quote.Approval_Reason__c == approvalReasonsString) + ' ' + quote.Approval_Status__c);
                    
                    if(quote.Approval_Reason__c != approvalReasonsString) {
                        quote.Approval_Reason__c = approvalReasonsString;
                        if(quote.Approval_Status__c == 'Approved') {
                            quote.Approval_Status__c = '';
                            if(quote.Status == 'In Review' || quote.Status == 'Approved' || quote.Status == 'Rejected' || quote.Status == 'Presented' || quote.Status == 'Negotiation' || quote.Status == 'PO Received') {
                                quote.Status = 'Draft';
                            }
                        }
                    }
                    
                    System.debug('approvalReasonsString isEqual ' + quote.Approval_Status__c);
                }
                else {
                    if(quote.Approval_Reason__c != null) {
                        quote.Approval_Reason__c = '';
                    }
                }
            }  // Close the if condition for quoteLineItemMap/quoteServiceLineItemMap
        }
    }
    
    
    public static void validateSalesGroup(List<Quote> quoteList) {
        for(Quote qt : quoteList) {
            if(DataCls.getUserById(qt.OwnerId)!=null){
                user u=DataCls.getUserById(qt.OwnerId);
                if(u.Sales_Group__c != qt.Sales_Group__c) {
                    qt.Sales_Group__c = u.Sales_Group__c;
                }
            }
        }
    }
    
    
    // public static void updateAssetAMC(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        //     Set<Id> quoteIds = new Set<Id>();
        //     List<Asset_AMC__c> assetAMCsToCreate=new List<Asset_AMC__c>();
        //     Map<Id, Quote> quoteListMap = new Map<Id, Quote>();
        //     for(Quote q : quoteList) {
            //         quoteListMap.put(q.Id, q);
            //         if(q.SAP_Order_No__c != null && q.SAP_Order_No__c != oldMap.get(q.Id).SAP_Order_No__c) {
                //             quoteIds.add(q.Id);
            //         }
        //     }
        //     if(quoteIds.size()>0)
        //     {
            //         List<Quote_Service_Line_Item__c> qLine=[Select id,name,toLabel(Item_Master__r.Material_Group_5__c),Item_Master__c,AMC_Period_In_Months__c,AMC_Start_Date__c,Service_Grand_Total__c, Quote__r.Service_Grand_Total__c,Number_of_Breakdown_visits_in_12_Months__c,Number_of_PM_visits_in_12_Months__c,Quote__c, Quote__r.Grand_Total_Value__c,Quote__r.Asset_Serial_Number__c,Quote__r.Asset_Serial_Number__r.Name,Quote__r.Customer_PO_Date__c, Quote__r.Customer_PO_Number__c,Quote__r.OwnerId from Quote_Service_Line_Item__c where Quote__c in:quoteIds];
            //         for(Quote_Service_Line_Item__c q:qLine)
            //         {
                //             System.debug('q.Material_Group5__c'+q.Item_Master__r.Material_Group_5__c);
                //             if(q.Item_Master__r.Material_Group_5__c!=null && q.Item_Master__r.Material_Group_5__c.contains('AMC'))
                //             {
                    //             if(q.AMC_Start_Date__c == null || q.AMC_Period_In_Months__c == null) {
                        //                 String msg = 'Cannot add SAP Order No. Quote Service Line Item "'
                        //                             + q.Name + '" is missing AMC Start Date or AMC Period.';
                        //                 quoteListMap.get(q.Quote__c).SAP_Order_No__c.addError(msg);
                        //                 continue;
                    //             }
                    
                    //                 System.debug('in Asset');
                    //                 Asset_AMC__c assetAMC = new Asset_AMC__c();
                    //                 assetAMC.Name = q.Quote__r.Asset_Serial_Number__r.Name;
                    //                 assetAMC.Asset__c = q.Quote__r.Asset_Serial_Number__c;
                    //                 if (q.AMC_Period_In_Months__c != null) {
                        //                     assetAMC.AMC_Period_In_Months__c = Integer.valueOf(q.AMC_Period_In_Months__c);
                    //                 }
                    //                 assetAMC.AMC_Start_Date__c = q.AMC_Start_Date__c;
                    //                 assetAMC.Breakdown_Visits_Allowed__c = q.Number_of_Breakdown_visits_in_12_Months__c;
                    //                 assetAMC.PM_Visit_Allowed__c = q.Number_of_PM_visits_in_12_Months__c;
                    //                 assetAMC.Asset_AMC_PO_Status__c='Active';
                    //                 assetAMC.Asset_AMC_PO_Date__c=q.Quote__r.Customer_PO_Date__c;
                    //                 assetAMC.Asset_AMC_PO__c=q.Quote__r.Customer_PO_Number__c;
                    //                 assetAMC.AMC_PO_Value__c= q.Quote__r.Service_Grand_Total__c;
                    //                 assetAMC.SE_Name__c = q.Quote__r.OwnerId;
                    //                 if(q.Item_Master__r.Material_Group_5__c.contains('CAMC'))
                    //                 {
                        //                 assetAMC.Product_Category_Type__c='CAMC';
                    //                 }
                    //                 else {
                        //                 assetAMC.Product_Category_Type__c='AMC';
                    //                 }
                    
                    //                 assetAMCsToCreate.add(assetAMC);
                //                 }
            //         }
            //         if(assetAMCsToCreate.size()>0)
            //         {
                //             insert assetAMCsToCreate;
            //         }
        //     }
    // }
    
    public static void updateAssetAMC(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        List<Asset_AMC__c> assetAMCsToInsert = new List<Asset_AMC__c>();
        List<Asset_AMC__c> assetAMCsToUpdate = new List<Asset_AMC__c>();
        Map<Id, Quote> quoteListMap = new Map<Id, Quote>();
        // Collect quotes that have SAP Order No changed
        for(Quote q : quoteList) {
            quoteListMap.put(q.Id, q);
            if(q.SAP_Order_No__c != null && q.SAP_Order_No__c != oldMap.get(q.Id).SAP_Order_No__c) {
                quoteIds.add(q.Id);
            }
        }
        // Only proceed if there are quotes with changed SAP Order No
        if(quoteIds.size() > 0) {
            // Query all Quote Service Line Items for the affected quotes
            List<Quote_Service_Line_Item__c> qLine = [
            SELECT Id, Name, 
                   toLabel(Item_Master__r.Material_Group_5__c),
                   Item_Master__c,
                   AMC_Period_In_Months__c,
                   AMC_Start_Date__c,
                   Service_Grand_Total__c, 
                   Quote__r.Service_Grand_Total__c,
                   Number_of_Breakdown_visits_in_12_Months__c,
                   Number_of_PM_visits_in_12_Months__c,
                   Quote__c, 
                   Quote__r.Grand_Total_Value__c,
                   Quote__r.Asset_Serial_Number__c,
                   Quote__r.Asset_Serial_Number__r.Name,
                   Quote__r.Customer_PO_Date__c, 
                   Quote__r.Customer_PO_Number__c,
                   Quote__r.OwnerId 
            FROM Quote_Service_Line_Item__c 
            WHERE Quote__c IN :quoteIds
        ];
            // Create sets for querying existing Asset AMC records
            Set<Id> assetIds = new Set<Id>();
            Set<Date> amcStartDates = new Set<Date>();
            // Collect Asset IDs and AMC Start Dates for AMC-related line items
            for(Quote_Service_Line_Item__c q : qLine) {
                if(q.Item_Master__r.Material_Group_5__c != null &&
                    q.Item_Master__r.Material_Group_5__c.contains('AMC') &&
                    q.Quote__r.Asset_Serial_Number__c != null &&
                q.AMC_Start_Date__c != null) {
                    assetIds.add(q.Quote__r.Asset_Serial_Number__c);
                    amcStartDates.add(q.AMC_Start_Date__c);
                }
            }
            // Query existing Asset AMC records that match our criteria
            Map<String, Asset_AMC__c> existingAssetAMCMap = new Map<String, Asset_AMC__c>();
            if(!assetIds.isEmpty() && !amcStartDates.isEmpty()) {
                for(Asset_AMC__c existingAMC : [
                SELECT Id, Asset__c, AMC_Start_Date__c, Name,
                       AMC_Period_In_Months__c, Breakdown_Visits_Allowed__c,
                       PM_Visit_Allowed__c, Asset_AMC_PO_Status__c,
                       Asset_AMC_PO_Date__c, Asset_AMC_PO__c,
                       AMC_PO_Value__c, SE_Name__c, Product_Category_Type__c
                FROM Asset_AMC__c 
                WHERE Asset__c IN :assetIds 
                AND AMC_Start_Date__c IN :amcStartDates
            ]) {
                    // CRITICAL: Create unique key using Asset ID + AMC Start Date
                    // This allows us to quickly find matching records
                    String key = existingAMC.Asset__c + '_' + existingAMC.AMC_Start_Date__c;
                    existingAssetAMCMap.put(key, existingAMC);
                }
            }
            // Process each quote service line item
            for(Quote_Service_Line_Item__c q : qLine) {
                System.debug('q.Material_Group5__c'+q.Item_Master__r.Material_Group_5__c);
                if(q.Item_Master__r.Material_Group_5__c == null ||
                !q.Item_Master__r.Material_Group_5__c.contains('AMC')) {
                    continue;
                }
                // Validate required fields
                if(q.AMC_Start_Date__c == null || q.AMC_Period_In_Months__c == null) {
                    String msg = 'Cannot add SAP Order No. Quote Service Line Item "'
                        + q.Name + '" is missing AMC Start Date or AMC Period.';
                    quoteListMap.get(q.Quote__c).SAP_Order_No__c.addError(msg);
                    continue;
                }
                // Skip if Asset is null
                if(q.Quote__r.Asset_Serial_Number__c == null) {
                    continue;
                }
                String assetAMCKey = q.Quote__r.Asset_Serial_Number__c + '_' + q.AMC_Start_Date__c;
                if(existingAssetAMCMap.containsKey(assetAMCKey)) {
                    // UPDATE CASE: Found existing record - update it
                    Asset_AMC__c existingAssetAMC = existingAssetAMCMap.get(assetAMCKey);
                    // Update all fields from the quote line item
                    existingAssetAMC.Name = q.Quote__r.Asset_Serial_Number__r.Name;
                    existingAssetAMC.Asset__c = q.Quote__r.Asset_Serial_Number__c;
                    existingAssetAMC.AMC_Start_Date__c = q.AMC_Start_Date__c;
                    if (q.AMC_Period_In_Months__c != null) {
                        existingAssetAMC.AMC_Period_In_Months__c = Integer.valueOf(q.AMC_Period_In_Months__c);
                    }
                    existingAssetAMC.Breakdown_Visits_Allowed__c = q.Number_of_Breakdown_visits_in_12_Months__c;
                    existingAssetAMC.PM_Visit_Allowed__c = q.Number_of_PM_visits_in_12_Months__c;
                    existingAssetAMC.Asset_AMC_PO_Status__c = 'Active';
                    existingAssetAMC.Asset_AMC_PO_Date__c = q.Quote__r.Customer_PO_Date__c;
                    existingAssetAMC.Asset_AMC_PO__c = q.Quote__r.Customer_PO_Number__c;
                    existingAssetAMC.AMC_PO_Value__c = q.Quote__r.Service_Grand_Total__c;
                    existingAssetAMC.SE_Name__c = q.Quote__r.OwnerId;
                    // Set product category type
                    if(q.Item_Master__r.Material_Group_5__c.contains('CAMC')) {
                        existingAssetAMC.Product_Category_Type__c = 'CAMC';
                    } else {
                        existingAssetAMC.Product_Category_Type__c = 'AMC';
                    }
                    assetAMCsToUpdate.add(existingAssetAMC);
                } else {
                    // INSERT CASE: No matching record found - create new one
                    Asset_AMC__c newAssetAMC = new Asset_AMC__c();
                    // Set all required fields
                    newAssetAMC.Name = q.Quote__r.Asset_Serial_Number__r.Name;
                    newAssetAMC.Asset__c = q.Quote__r.Asset_Serial_Number__c;
                    newAssetAMC.AMC_Start_Date__c = q.AMC_Start_Date__c;
                    if (q.AMC_Period_In_Months__c != null) {
                        newAssetAMC.AMC_Period_In_Months__c = Integer.valueOf(q.AMC_Period_In_Months__c);
                    }
                    newAssetAMC.Breakdown_Visits_Allowed__c = q.Number_of_Breakdown_visits_in_12_Months__c;
                    newAssetAMC.PM_Visit_Allowed__c = q.Number_of_PM_visits_in_12_Months__c;
                    newAssetAMC.Asset_AMC_PO_Status__c = 'Active';
                    newAssetAMC.Asset_AMC_PO_Date__c = q.Quote__r.Customer_PO_Date__c;
                    newAssetAMC.Asset_AMC_PO__c = q.Quote__r.Customer_PO_Number__c;
                    newAssetAMC.AMC_PO_Value__c = q.Quote__r.Service_Grand_Total__c;
                    newAssetAMC.SE_Name__c = q.Quote__r.OwnerId;
                    if(q.Item_Master__r.Material_Group_5__c.contains('CAMC')) {
                        newAssetAMC.Product_Category_Type__c = 'CAMC';
                    } else {
                        newAssetAMC.Product_Category_Type__c = 'AMC';
                    }
                    assetAMCsToInsert.add(newAssetAMC);
                }
            }
            try {
                if(assetAMCsToInsert.size() > 0) {
                    insert assetAMCsToInsert;
                }
                if(assetAMCsToUpdate.size() > 0) {
                    update assetAMCsToUpdate;
                }
            } catch(Exception e) {
                System.debug('Error processing Asset AMC records: ' + e.getMessage());
            }
        }
    }
    
    
    public static void updateContactDetailsByContactId(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        Map<Id, List<Quote>> contactQuoteMap = new Map<Id, List<Quote>>();
        for (Quote quote : quoteList) {
            if (quote.ContactId != null && quote.ContactId != oldMap.get(quote.Id).ContactId) {
                if (!contactQuoteMap.containsKey(quote.ContactId)) {
                    contactQuoteMap.put(quote.ContactId, new List<Quote>());
                }
                contactQuoteMap.get(quote.ContactId).add(quote);
            }
        }
        List<Contact> contacts = [SELECT Id, Name, Email, Phone, MobilePhone, Fax FROM Contact WHERE Id IN :contactQuoteMap.keySet()];
        for (Contact contact : contacts) {
            List<Quote> updateQuotes = contactQuoteMap.get(contact.Id);
            for (Quote each : updateQuotes) {
                each.Email = contact.Email;
                each.Phone = contact.MobilePhone;
                each.Fax = contact.Fax;
            }
        }
    }
    
    
    public static void updateOrderType(List<Quote> qList) {
        Set<Id> plantId=new Set<Id>();
        for(Quote quote:qList)
        {
            plantId.add(quote.Delivery_Plant__c);
        }
        Map<Id,Plant_Master__c> plantMap=new Map<Id,Plant_Master__c>([Select id,Name,Plant_Code__c,Plant_Depot_Type__c  from Plant_Master__c where id in:plantId]);
        for(Quote Quote:qList)
        {
            if(Quote.Quote_Document_Type__c=='AMC' || Quote.Quote_Document_Type__c=='Chargeable Service')
            {
                Quote.Order_Type__c='ZSEI';
            }
            
            if(Quote.Quote_Document_Type__c=='Spares' && plantMap.containsKey(Quote.Delivery_Plant__c)&& plantMap.get(Quote.Delivery_Plant__c).Plant_Depot_Type__c=='DEPOT')
            {
                quote.Order_Type__c='ZDOR';
            }
            
            if(Quote.Quote_Document_Type__c=='Spares' && plantMap.containsKey(Quote.Delivery_Plant__c)&& plantMap.get(Quote.Delivery_Plant__c).Plant_Depot_Type__c=='MFG PLANT')
            {
                quote.Order_Type__c='ZFOR';
            }
            if(Quote.Billing_Type__c=='FOC and Returnable')
            {
                quote.Order_Type__c='ZSOA';
            }
            if(Quote.Billing_Type__c=='FOC and Non-Returnable')
            {
                quote.Order_Type__c='ZEFO';
            }
        }
    }
    
    
    public static void UpdateEnquiry(List<Quote> quoteList) {
        Set<Id> enqIds = new Set<Id>();
        Map<Id,Quote> quoteMap=new Map<Id,Quote>();
        for(Quote quo:quoteList) {
            enqIds.add(quo.OpportunityId);
            quoteMap.put(quo.OpportunityId,quo);
        }
        List<Opportunity> enqList=[Select id,Name,StageName,Opportunity_Due_Date__c from Opportunity where Id in:enqIds];
        for(Opportunity enq:enqList) {
            Quote quote=quoteMap.get(enq.Id);
            if(quote.Status=='Draft') {
                enq.StageName='New';
            }
            if(quote.Status=='Accepted' || quote.Status=='PO Received' || quote.Status=='Order Created' || quote.Status=='Error in Order') {
                enq.StageName='Qualified';
            }
            else if(quote.Status=='Denied') {
                enq.StageName='Disqualified';
            }
            If(quote.Status=='Negotiation') {
                enq.StageName='Under Discussion';
            }
            if(quote.Status=='Amended') {
                enq.StageName='Negotiation';
            }
            if (quote.Quote_Due_Date__c != null) {
                enq.Opportunity_Due_Date__c = quote.Quote_Due_Date__c;
            }
            
        }
        update enqList;
    }
    
    
    public static void UpdateDiscount(List<Quote> quoteList, Map<Id, Quote> oldMap) {
        map<Id,Quote> quoMap = new map<Id,Quote>();
        map<Id,Quote> quoMapNTPriceEnable = new map<Id,Quote>();
        map<Id,Quote> quoMapNTPriceDisable = new map<Id,Quote>();
        List<string> docType = new List<string>();
        boolean bCheckDocType = false;
        for(Quote qt : quoteList){
            if(string.isNotBlank(qt.Quote_Document_Type__c)) {
                docType.add(qt.Quote_Document_Type__c);
                if(qt.Discount_Type__c != oldMap.get(qt.Id).Discount_Type__c) {
                    quoMap.put(qt.Id, qt);
                }
                if(qt.Discount_Value__c != oldMap.get(qt.Id).Discount_Value__c) {
                    quoMap.put(qt.Id , qt);
                }
                if(qt.NT_Price__c != oldMap.get(qt.Id).NT_Price__c) {
                    if(qt.NT_Price__c){
                        quoMapNTPriceEnable.put(qt.Id , qt);
                    }else{
                        quoMapNTPriceDisable.put(qt.Id , qt);
                    }
                }
            }
        }
        
        if(quoMap.size() > 0){
            if(docType.contains('Spares')){
                List<QuoteLineItem> qtline = [select Id ,Discount_In_Value_new__c,QuoteId,UnitPrice, Discount_In__c from QuoteLineItem where QuoteId IN : quoMap.keyset()];
                map<Id,QuoteLineItem> quoLineMap = new map<Id,QuoteLineItem>();
                for(QuoteLineItem qt : qtline){
                    if(quoMap.containsKey(qt.QuoteId)){
                        string bType = quoMap.get(qt.QuoteId).Discount_Type__c;
                        if(bType =='Value'){
                            decimal DiscountValue = quoMap.get(qt.QuoteId).Discount_Value__c ?? 0;
                            decimal totalValue = quoMap.get(qt.QuoteId).Subtotal;
                            decimal propotionPercent = (qt.UnitPrice  / totalValue)*100 ;
                            qt.Discount_In_Value_New__c = ((propotionPercent * DiscountValue)/100).setScale(2);
                            qt.Discount_Type__c = bType;
                            quoLineMap.put(qt.Id,qt);
                        }
                        else if(bType =='Percent'){
                            qt.Discount_In_Value_New__c  = (qt.UnitPrice * (quoMap.get(qt.QuoteId).Discount_Value__c ?? 0))/100;
                            qt.Discount_In__c = quoMap.get(qt.QuoteId).Discount_Value__c ?? 0;
                            qt.Discount_Type__c = bType;
                            quoLineMap.put(qt.Id,qt);
                        }
                        
                    }
                }
                
                if(quoLineMap.size() > 0){
                    update quoLineMap.values();
                }
                
            }else if(docType.contains('Chargeable Service') || docType.contains('AMC')){
                List<Quote_Service_Line_Item__c> qsline = [select Id ,Discount_In_Value_New__c,Service_Amount__c, Discount_In__c,Quote__c from Quote_Service_Line_Item__c where Quote__c IN : quoMap.keyset()];
                map<Id,Quote_Service_Line_Item__c> quoLineMap = new map<Id,Quote_Service_Line_Item__c>();
                for(Quote_Service_Line_Item__c qt : qsline){
                    if(quoMap.containsKey(qt.Quote__c)){
                        string bType = quoMap.get(qt.Quote__c).Discount_Type__c;
                        if(bType =='Value'){
                            
                            
                            decimal DiscountValue = quoMap.get(qt.Quote__c).Discount_Value__c ?? 0;
                            decimal totalValue = quoMap.get(qt.Quote__c).Quote_Service_Total_Price__c;
                            decimal propotionPercent = (qt.Service_Amount__c  / totalValue)*100 ;
                            //qt.Discount_In__c  = ((quoMap.get(qt.Quote__c).Discount_Value__c / qt.Service_Amount__c) *100).setScale(2) ;
                            qt.Discount_In_Value_New__c = ((propotionPercent * DiscountValue)/100).setScale(2);
                            quoLineMap.put(qt.Id,qt);
                        }else if(bType =='Percent'){
                            qt.Discount_In_Value_New__c  = (qt.Service_Amount__c * (quoMap.get(qt.Quote__c).Discount_Value__c ?? 0))/100;
                            qt.Discount_In__c = quoMap.get(qt.Quote__c).Discount_Value__c ?? 0;
                            quoLineMap.put(qt.Id,qt);
                        }
                        
                    }
                }
                if(quoLineMap.size() > 0){
                    update quoLineMap.values();
                }
                
            }
        }
        // System.debug('quoMapNTPriceEnable '+quoMapNTPriceEnable);
        // System.debug('quoMapNTPriceDisable '+quoMapNTPriceDisable);
        if(quoMapNTPriceEnable.size()>0){
            List<QuoteLineItem> qtline = [select Id ,NT_Price__c,Original_Unit_Price__c,Discount_In_Value_new__c,QuoteId,UnitPrice, Discount_In__c from QuoteLineItem where QuoteId IN : quoMapNTPriceEnable.keyset()];
            map<Id,QuoteLineItem> quoLineMap = new map<Id,QuoteLineItem>();
            for(QuoteLineItem qt : qtline){
                qt.NT_Price__c=true;
                // qt.Original_Unit_Price__c=qt.UnitPrice;
                // qt.UnitPrice=qt.UnitPrice + (qt.UnitPrice * 0.15); // if NT is applicable then apply increase the margin by 15%
                quoLineMap.put(qt.Id,qt);
            }
            if(quoLineMap.size() > 0){
                update quoLineMap.values();
            }
        }
        if(quoMapNTPriceDisable.size()>0){
            List<QuoteLineItem> qtline = [select Id ,NT_Price__c,Original_Unit_Price__c,Discount_In_Value_new__c,QuoteId,UnitPrice, Discount_In__c from QuoteLineItem where QuoteId IN : quoMapNTPriceDisable.keyset()];
            map<Id,QuoteLineItem> quoLineMap = new map<Id,QuoteLineItem>();
            for(QuoteLineItem qt : qtline){
                qt.NT_Price__c=false;
                // qt.UnitPrice=qt.Original_Unit_Price__c; // if NT is not applicable
                quoLineMap.put(qt.Id,qt);
            }
            if(quoLineMap.size() > 0){
                update quoLineMap.values();
            }
        }
    }
    
    
    public static void assignDocumentNumber(List<Quote> newQuotes) {
        Boolean isDocumentNumberToBeGenerated = false;
        for (Quote q : newQuotes) {
            if(String.isBlank(q.Document_No_1__c)){
                isDocumentNumberToBeGenerated = true;
                break;
            }
        }
        if (!isDocumentNumberToBeGenerated) {
            return;
        }
        
        AggregateResult result = [SELECT MAX(Current_Sequence_No__c) maxDoc FROM Sequence_Master__c WHERE Current_Sequence_No__c != null];
        Sequence_Master__c cur=[SELECT Id,format__c,Starting_Number__c,Current_Sequence_No__c FROM Sequence_Master__c LIMIT 1];
        Integer maxNumber = 0;
        if (result != null && result.get('maxDoc') != null) {
            maxNumber = Integer.valueOf(result.get('maxDoc'));
        }else{
            maxNumber = integer.valueof(cur.Starting_Number__c);
        }
        String curLng=cur.format__c;
        for (Quote q : newQuotes) {
            maxNumber++;
            q.Document_No_1__c = padWithZeros(maxNumber,curLng.length());
            q.Quote_Number_in_Number__c = String.isNotBlank(q.Document_No_1__c) ? Integer.valueOf(q.Document_No_1__c.replaceFirst('^0+', '')) : null;
        }
        cur.Current_Sequence_No__c = maxNumber;
        UPDATE cur;
    }
    
    
    public static String padWithZeros(Integer sNumber, Integer length) { // getting called from RaiseOppAndQuoteController also
        String numStr = String.valueOf(sNumber);
        while (numStr.length() < length) {
            numStr = '0' + numStr; // Add leading zeros
        }
        return numStr;
    }
    
    
    public static void lockQuoteFields(List<Quote> newList, Map<Id, Quote> oldMap) {
        for (Quote newQuote : newList) {
            Quote oldQuote = oldMap.get(newQuote.Id);
            
            if (oldQuote != null && oldQuote.Status == 'Order Created') {
                Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Quote.fields.getMap();
                for (String fieldName : fieldsMap.keySet()) {
                    if (
                        fieldName == 'Id' ||
                        fieldName == 'SAP_Order_No__c' ||
                        fieldName == 'SAP_Response_Date__c' ||
                        fieldName == 'Expected_Close_Date__c' ||
                        fieldName == 'SAP_Response_Message__c' ||
                        fieldName == 'Number_of_invoices__c' ||
                        fieldName == 'Total_Invoice_Amount__c' ||
                        fieldName == 'Returnable_Received__c' ||
                        fieldName == 'Battery_Buyback_received__c' ||
                        fieldName == 'Battery_Buyback_required__c' ||
                        fieldName ==  'ReturnableReceivedMarkedFromBackend__c' ||
                        fieldName == 'PI_Date__c' ||
                        fieldName == 'external_id__c'
                    ) {
                        continue;
                    }
                    
                    Object oldVal = oldQuote.get(fieldName);
                    Object newVal = newQuote.get(fieldName);
                    
                    if (oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
                        newQuote.addError('Quote is already pushed to SAP. You cannot modify the quote.');
                        break;
                    }
                }
            }
        }
    }
    
    
    public static void lockQuoteLineItems(List<QuoteLineItem> newItems, Map<Id, QuoteLineItem> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        for (QuoteLineItem qli : newItems) {
            quoteIds.add(qli.QuoteId);
        }
        
        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id,PI_Date__c,  Status FROM Quote WHERE Id IN :quoteIds]
            );
        
        for (QuoteLineItem qli : newItems) {
            QuoteLineItem oldQli = oldMap.get(qli.Id);
            
            if (quoteMap.containsKey(qli.QuoteId) && quoteMap.get(qli.QuoteId).Status == 'Order Created') {
                Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.QuoteLineItem.fields.getMap();
                for(String fieldName : fieldsMap.keySet()) {
                    if(
                        fieldName == 'AMC_Start_Date__c' ||
                        fieldName == 'ZSOA_Date__c' ||
                        fieldName == 'ZIDR_Date__c' ||
                        fieldName == 'PI_Date__c' ||
                        fieldName == 'Discount_Type__c'
                    ) {
                        continue;
                    }
                    
                    Object oldVal = oldQli.get(fieldName);
                    Object newVal = qli.get(fieldName);
                    
                    if(oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
                        qli.addError('Quote is already pushed to SAP. You cannot modify the quote or its line items.');
                        break;
                    }
                }
            }
        }
    }
    
    
    public static void lockQuoteServiceLineItems(List<Quote_Service_Line_Item__c> newItems, Map<Id, Quote_Service_Line_Item__c> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        for (Quote_Service_Line_Item__c item : newItems) {
            quoteIds.add(item.Quote__c); // Adjust if your lookup field is different
        }
        
        Map<Id, Quote> quoteMap = new Map<Id, Quote>(
            [SELECT Id,PI_Date__c, Status FROM Quote WHERE Id IN :quoteIds]
            );
        
        for (Quote_Service_Line_Item__c item : newItems) {
            Quote_Service_Line_Item__c oldItem = oldMap.get(item.Id);
            
            if (quoteMap.containsKey(item.Quote__c) && quoteMap.get(item.Quote__c).Status == 'Order Created') {
                Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Quote_Service_Line_Item__c.fields.getMap();
                for(String fieldName : fieldsMap.keySet()) {
                    if(
                        fieldName == 'AMC_Start_Date__c' ||
                        fieldName == 'PI_Date__c' ||
                        fieldName == 'Discount_Type__c'
                    ) {
                        continue;
                    }
                    
                    Object oldVal = oldItem.get(fieldName);
                    Object newVal = item.get(fieldName);
                    
                    if(oldVal != newVal && (oldVal == null || !oldVal.equals(newVal))) {
                        item.addError('Quote is already pushed to SAP. You cannot modify the quote or its service line items.');
                        break;
                    }
                }
            }
        }
    }
    
    
    public static void setCoordinatorFromServiceResource(List<Quote> quoteList) {
        Set<Id> userIds = new Set<Id>();
        
        for (Quote q : quoteList) {
            if (q.OwnerId != null) {
                userIds.add(q.OwnerId);
            }
        }
        
        if (userIds.isEmpty()) return;
        
        Map<Id, Service_Resource__c> userIdToServiceResourceMap = new Map<Id, Service_Resource__c>();
        List<Service_Resource__c> srList = [
            SELECT Id, User__c, Coordinator__c
            FROM Service_Resource__c
            WHERE User__c IN :userIds
        ];
        
        for (Service_Resource__c sr : srList) {
            if (sr.User__c != null && sr.Coordinator__c != null) {
                userIdToServiceResourceMap.put(sr.User__c, sr);
            }
        }
        
        for (Quote q : quoteList) {
            if (q.OwnerId != null && userIdToServiceResourceMap.containsKey(q.OwnerId)) {
                Service_Resource__c matchedSR = userIdToServiceResourceMap.get(q.OwnerId);
                q.Coordinator_Name__c = matchedSR.Coordinator__c;
            }
        }
    }
    
    
    public static void updateActivityDateToAsset(List<Quote> newRecords) {
        Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
        for (Quote q : newRecords) {
            
            if(q.Asset_Serial_Number__c != null && (q.Status != 'Denied' || q.Status != 'Amended')) {
                assetsToUpdate.put(q.Asset_Serial_Number__c, new Asset(Id = q.Asset_Serial_Number__c, Last_Quotation_Activity_Date__c = System.today()));
            }
        }
        
        if(!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate.values(), true, AccessLevel.SYSTEM_MODE);
        }
    }
    
    
    public static void notifyCoordinatorForFailedOrders(List<Quote> newRecords, Map<Id, Quote> oldMap) {
        Set<Id> quoteIds = new Set<Id>();
        for (Quote q : newRecords) {
            if (q.Status == 'Error in Order' && oldMap.containsKey(q.Id) && oldMap.get(q.Id).Status != 'Error in Order') {
                quoteIds.add(q.Id);
            }
        }
        
        if(quoteIds.isEmpty()) return;
        
        List<Quote> quotes = [
            SELECT Id, Name, AccountId, Account.Name, Document_No_1__c, OpportunityId, Opportunity.OwnerId, Opportunity.Owner.Name, Opportunity.Owner.Email,Quote_Number_in_Number__c
            FROM Quote
            WHERE Id IN :quoteIds
        ];
        
        Set<Id> ownerIds = new Set<Id>();
        for (Quote q : quotes) {
            ownerIds.add(q.Opportunity.OwnerId);
        }
        
        List<Service_Resource__c> serviceResources = [
            SELECT Id, User__c, User__r.Name, RSM__c, RSM__r.Name, RSM__r.Email, Coordinator__c, Coordinator__r.Name, Coordinator__r.Email
            FROM Service_Resource__c
            WHERE User__c IN :ownerIds
        ];
        
        Map<Id, Service_Resource__c> ownerToServiceResourceMap = new Map<Id, Service_Resource__c>();
        for (Service_Resource__c sr : serviceResources) {
            ownerToServiceResourceMap.put(sr.User__c, sr);
        }
        
        List<CustomNotificationType> notificationTypes = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Failed_Order'
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(Quote qt : quotes) {
            if(ownerToServiceResourceMap.containsKey(qt.Opportunity.OwnerId)) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                List<String> toAddresses = new List<String>();
                if(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__c != null) {
                    toAddresses.add(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__r.Email);
                }
                email.setToAddresses(toAddresses);
                
                List<String> ccAddresses = new List<String>();
                if(qt.Opportunity.Owner.Email != null) {
                    ccAddresses.add(qt.Opportunity.Owner.Email);
                }
                if(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).RSM__c != null) {
                    ccAddresses.add(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).RSM__r.Email);
                }
                email.setCCAddresses(ccAddresses);
                
                // email.setToAddresses(new List<String> {ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__r.Email});
                // email.setCCAddresses(new List<String> {qt.Opportunity.Owner.Email, ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).RSM__r.Email});
                
                email.setSubject('Failed Order Notification');
                email.setHtmlBody('<p>Hi ' + ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__r.Name + ',</p>' +
                    '<br/>' +
                    '<p>Following Order has failed: ' + qt.Document_No_1__c + '</p>' +
                    '<p>Account: ' + qt.Account.Name + '</p>' +
                    '<p>Quote: ' + qt.Name + '</p>' +
                    '<p>Click here to view the order: ' + URL.getOrgDomainURL().toExternalForm() + '/' + qt.Id + '</p>' +
                    '<br/>' +
                    '<p>Regards,<br/>' +
                    ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).User__r.Name + '</p>');
                emails.add(email);
                
                if(notificationTypes.size() > 0) {
                    CustomNotificationType notificationType = notificationTypes[0];
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setBody('Following Order has failed: ' + qt.Document_No_1__c);
                    notification.setTitle('Failed Order Notification');
                    notification.setSenderId(UserInfo.getUserId());
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(qt.Id);
                    if(ownerToServiceResourceMap.containsKey(qt.Opportunity.OwnerId)) {
                        if(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__c != null) {
                            notification.send(new Set<String> {ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).Coordinator__c});
                        }
                        if(ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).RSM__c != null) {
                            notification.send(new Set<String> {ownerToServiceResourceMap.get(qt.Opportunity.OwnerId).RSM__c});
                        }
                    }
                }
            }
        }
        
        if(!emails.isEmpty() && Label.Internal_Email_Disabled != 'True') {
            Messaging.sendEmail(emails);
        }
    }
    
    
    public static void updateCaseStatus(List<Quote> newRecords, Map<Id, Quote> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Case> caseMapToUpdate = new Map<Id, Case>();
        for (Quote qt : newRecords) {
            if(String.isNotBlank(qt.Case__c) && qt.Status != oldMap.get(qt.Id).Status) {
                caseIds.add(qt.Case__c);
                
                Case cs = new Case();
                cs.Id = qt.Case__c;
                
                switch on qt.Status {
                    when 'Presented', 'Negotiation' {
                        cs.Status = 'PO Awaited';
                    }
                    when 'PO Received' {
                        cs.Status = 'Dispatch Awaited';
                    }
                    when 'Order Created' {
                        if (qt.Billing_Type__c == 'FOC and Returnable') {
                            cs.Status = qt.Returnable_Received__c ? 'Return to Depot' : 'Return Pending';
                        } else {
                            cs.Status = 'Pending for Close';
                        }
                    }
                    when else {
                        continue;
                    }
                }
                caseMapToUpdate.put(cs.Id, cs);
            }
        }
        
        List<Case> casesToUpdate = new List<Case>();
        
        Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, Status FROM Case WHERE Id IN :caseIds AND IsClosed = false]);
        for(Case cs : caseMapToUpdate.values()) {
            if(cases.containsKey(cs.Id)) {
                if(cases.get(cs.Id).Status != cs.Status) {
                    casesToUpdate.add(cs);
                }
            }
        }
        
        if(!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
    
    
    public static void validateReturnableReceived(List<Quote> newList, Map<Id, Quote> oldMap) {
        Boolean isMarkedReturnableReceivedFromUI = false;
        Set<Id> quoteIds = new Set<Id>();
        for(Quote qt : newList) {
            Quote oldQt = oldMap.get(qt.Id);
            if(qt.Returnable_Received__c && qt.Returnable_Received__c != oldQt.Returnable_Received__c && qt.ReturnableReceivedMarkedFromBackend__c == false) {
                isMarkedReturnableReceivedFromUI = true;
                quoteIds.add(qt.Id);
            }
        }
        
        if(isMarkedReturnableReceivedFromUI) {
            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT Id, LinkedEntityId, ContentDocument.Title, ContentDocument.CreatedDate
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :quoteIds
            ];
            Map<Id, List<ContentDocumentLink>> contentDocumentLinkMap = new Map<Id, List<ContentDocumentLink>>();
            for(ContentDocumentLink cdl : contentDocumentLinks) {
                if(!contentDocumentLinkMap.containsKey(cdl.LinkedEntityId)) {
                    contentDocumentLinkMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>());
                }
                contentDocumentLinkMap.get(cdl.LinkedEntityId).add(cdl);
            }
            
            for(Quote qt : newList) {
                if(quoteIds.contains(qt.Id)) {
                    Boolean isFileUploaded = false;
                    DateTime sapOrderDate = qt.SAP_Response_Date__c ?? System.now();
                    if(contentDocumentLinkMap.get(qt.Id)!=null){
                        for(ContentDocumentLink cdl : contentDocumentLinkMap.get(qt.Id)) {
                            if(cdl.ContentDocument.CreatedDate > sapOrderDate) {
                                isFileUploaded = true;
                                break;
                            }
                        }
                    }
                    
                    if(!isFileUploaded) {
                        qt.addError('Please upload a file for Returnable Received.');
                    }
                }
            }
            
        }
    }
    
    
    public static void sendReturnableReceivedNotification(List<Quote> newList, Map<Id, Quote> oldMap) {
        try {
            // 1. GET NOTIFICATION TYPE
            CustomNotificationType notifType = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = 'Returnable_Received'
                LIMIT 1
            ];
            
            // 2. GET CURRENT USER CONTEXT
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            Boolean isCoordinator = currentUser.Profile.Name.contains('Coordinator');
            
            // 4. GET ORGANIZATION DOMAIN URL
            String orgDomainUrl = URL.getOrgDomainUrl().toExternalForm();
            
            // 5. PREPARE DATA STRUCTURES
            Set<Id> ownerIds = new Set<Id>();
            Map<Id, Id> quoteToOwnerMap = new Map<Id, Id>();
            Map<Id, Messaging.CustomNotification> quoteNotificationMap = new Map<Id, Messaging.CustomNotification>();
            Map<Id, String> quoteNotificationTitles = new Map<Id, String>();
            Map<Id, String> quoteNotificationBodies = new Map<Id, String>();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            
            // 6. COLLECT OWNER IDs AND CREATE NOTIFICATIONS
            for (Quote q : newList) {
                Quote oldQ = oldMap.get(q.Id);
                if (q.Returnable_Received__c == true && (oldQ == null || oldQ.Returnable_Received__c != true)) {
                    if (q.OwnerId != null) {
                        ownerIds.add(q.OwnerId);
                        quoteToOwnerMap.put(q.Id, q.OwnerId);
                    }
                    
                    String quoteNumber = q.Document_No_1__c != null ? q.Document_No_1__c : 'N/A';
                    
                    // CREATE NOTIFICATION
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    String notifTitle = isCoordinator
                        ? 'Coordinator Marked Returnable Received'
                        : 'System Marked Returnable Received';
                    
                    String notifBody = isCoordinator
                        ? 'Coordinator has marked Returnable Received for quote: ' + quoteNumber
                        : 'System processed Returnable Received for quote: ' + quoteNumber;
                    
                    notification.setTitle(notifTitle);
                    notification.setBody(notifBody);
                    notification.setNotificationTypeId(notifType.Id);
                    notification.setTargetId(q.Id);
                    
                    // Store notification and its components
                    quoteNotificationMap.put(q.Id, notification);
                    quoteNotificationTitles.put(q.Id, notifTitle);
                    quoteNotificationBodies.put(q.Id, notifBody);
                }
            }
            
            // 7. GET OWNER DETAILS FOR EMAILS
            Map<Id, User> owners = new Map<Id, User>([
                SELECT Id, Email, Name
                FROM User
                WHERE Id IN :ownerIds AND Email != null
            ]);
            
            // 8. PREPARE EMAILS
            for (Quote q : newList) {
                if (quoteNotificationMap.containsKey(q.Id) && owners.containsKey(q.OwnerId)) {
                    String quoteNumber = q.Document_No_1__c != null ? q.Document_No_1__c : 'N/A';
                    String notifTitle = quoteNotificationTitles.get(q.Id);
                    String notifBody = quoteNotificationBodies.get(q.Id);
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new List<String>{owners.get(q.OwnerId).Email});
                    mail.setSubject(notifTitle);
                    
                    // PLAIN TEXT VERSION
                    String emailBody = 'Hello ' + owners.get(q.OwnerId).Name + ',\n\n';
                    emailBody += notifBody + '\n\n';
                    emailBody += 'Quote Details:\n';
                    emailBody += '- Number: ' + quoteNumber + '\n';
                    emailBody += '- Link: ' + orgDomainUrl + '/lightning/r/Quote/' + q.Id + '/view\n\n';
                    emailBody += 'Thank you,\nSales Operations Team';
                    mail.setPlainTextBody(emailBody);
                    
                    // HTML VERSION
                    String htmlBody = '<html><body>';
                    htmlBody += '<p>Hello ' + owners.get(q.OwnerId).Name + ',</p>';
                    htmlBody += '<p>' + notifBody + '</p>';
                    htmlBody += '<p><strong>Quote Details:</strong></p><ul>';
                    htmlBody += '<li><strong>Number:</strong> ' + quoteNumber + '</li>';
                    htmlBody += '<li><strong>Link:</strong> <a href="' + orgDomainUrl + '/lightning/r/Quote/' + q.Id + '/view">View Quote</a></li>';
                    htmlBody += '</ul><p>Thank you,<br/><strong>Sales Operations Team</strong></p>';
                    htmlBody += '</body></html>';
                    mail.setHtmlBody(htmlBody);
                    
                    emails.add(mail);
                }
            }
            
            // 9. SEND NOTIFICATIONS
            for (Id quoteId : quoteNotificationMap.keySet()) {
                try {
                    Id ownerId = quoteToOwnerMap.get(quoteId);
                    if (ownerId != null) {
                        quoteNotificationMap.get(quoteId).send(new Set<String>{ String.valueOf(ownerId) });
                    }
                } catch(Exception e) {
                    System.debug('Notification send failed for quote ' + quoteId + ': ' + e.getMessage());
                }
            }
            
            // 10. SEND EMAILS
            if (!emails.isEmpty()) {
                try {
                    Messaging.sendEmail(emails);
                } catch(Exception e) {
                    System.debug('Email send failed: ' + e.getMessage());
                }
            }
            
        } catch(Exception e) {
            System.debug('Error in notification processing: ' + e.getMessage() +
                '\nLine: ' + e.getLineNumber() +
                '\nStack Trace: ' + e.getStackTraceString());
        }
    }
    
    
}