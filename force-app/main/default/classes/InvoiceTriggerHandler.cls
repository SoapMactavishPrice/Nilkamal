public with sharing class InvoiceTriggerHandler {
    
    public static void updateExternalId(List<Invoice__c> invoiceList) {
        for(Invoice__c invoice : invoiceList) {
            invoice.External_Id__c = invoice.Name + ' - ' + invoice.Line_Item__c + ' - ' + invoice.Serial_No__c;
        }
    }
    
    
    public static void updateInvoiceCountToQuote(List<Invoice__c> invoiceList) {
        Set<Id> quoteIds = new Set<Id>();
        for (Invoice__c invoice : invoiceList) {
            quoteIds.add(invoice.Quote__c);
        }
        
        Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Total_Number_of_invoices__c, Total_Invoice_Amount__c, Total_Quantity_from_Invoices__c FROM Quote WHERE Id IN :quoteIds]);
        
        List<Quote> quotesToUpdate = new List<Quote>();
        for(AggregateResult ar : [
            SELECT Quote__c, COUNT(Id) numberOfInvoices, SUM(Total_document_amount__c) totalAmount, SUM(Billing_Qty__c) totalQuantity
            FROM Invoice__c
            WHERE Quote__c IN :quoteIds
            GROUP BY Quote__c]
        ) {
            Decimal numberOfInvoices = (Decimal) ar.get('numberOfInvoices');
            Decimal totalAmount = (Decimal) ar.get('totalAmount');
            Decimal totalQuantity = (Decimal) ar.get('totalQuantity');
            
            if(quoteMap.containsKey((Id) ar.get('Quote__c'))) {
                Quote qtFromDB = quoteMap.get((Id) ar.get('Quote__c'));
                if(qtFromDB.Total_Number_of_invoices__c != numberOfInvoices || qtFromDB.Total_Invoice_Amount__c != totalAmount || qtFromDB.Total_Quantity_from_Invoices__c != totalQuantity) {
                    qtFromDB.Total_Number_of_invoices__c = numberOfInvoices;
                    qtFromDB.Total_Invoice_Amount__c = totalAmount;
                    qtFromDB.Total_Quantity_from_Invoices__c = totalQuantity;
                    quotesToUpdate.add(qtFromDB);
                }
            }
        }
        
        if(quotesToUpdate.size() > 0) {
            update quotesToUpdate;
        }
    }
    
    
    public static void createSpareInstallationCases(List<Invoice__c> invoiceList) {
        Set<Id> invoiceIds = new Set<Id>();
        Set<String> serialNumbers = new Set<String>();
        for (Invoice__c invoice : invoiceList) {
            if (invoice.Id != null) {
                invoiceIds.add(invoice.Id);
            }
            if (String.isNotBlank(invoice.Serial_No__c)) {
                serialNumbers.add(invoice.Serial_No__c);
            }
        }
        
        if (invoiceIds.isEmpty()) {
            return;
        }
        
        // Query for Assets by serial number
        Map<String, Id> assetMap = new Map<String, Id>();
        for (Asset asset : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN :serialNumbers]) {
            assetMap.put(asset.SerialNumber, asset.Id);
        }
        
        List<Invoice__c> invoices = [
            SELECT Id, Name, Quote__c, Billing_Date__c, SAPOrderNo__c, Material__c, Billing_Qty__c, Serial_No__c,
                   Sold_To_Party_1__c, Ship_To_Party_1__c, Contact__c, Business_Vertical__c, OwnerId,
                   Item_Master__r.Category__c, Item_Master__r.ProductCode, Item_Master__r.Business_Vertical__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds
        ];
        
        Id openQueueId;
        Map<String, Group> groupsByName = DataCls.getGroupsByName();
        if (groupsByName != null && groupsByName.containsKey('Open Queue')) {
            openQueueId = groupsByName.get('Open Queue').Id;
        }
        
        // Query for existing invoices to check for duplicates with same Billing_Date and SAPOrderNo
        Map<String, Id> existingBillingMap = new Map<String, Id>();
        Map<String, Id> existingBillingCaseMap = new Map<String, Id>();
        for (Invoice__c existingInvoice : [
            SELECT Id, Billing_Date__c, SAPOrderNo__c, Case__c
            FROM Invoice__c
            WHERE Id NOT IN :invoiceIds
        ]) {
            if (existingInvoice.Billing_Date__c != null && String.isNotBlank(existingInvoice.SAPOrderNo__c)) {
                String key = String.valueOf(existingInvoice.Billing_Date__c) + '-' + existingInvoice.SAPOrderNo__c;
                existingBillingMap.put(key, existingInvoice.Id);
                if (existingInvoice.Case__c != null) {
                    existingBillingCaseMap.put(key, existingInvoice.Case__c);
                }
            }
        }
        
        List<Case> casesToInsert = new List<Case>();
        Map<Integer, Id> caseIndexToInvoiceIdMap = new Map<Integer, Id>();
        List<Invoice__c> invoicesToUpdateWithExistingCase = new List<Invoice__c>();
        Integer caseIndex = 0;
        
        for (Invoice__c invoice : invoices) {
            System.debug('Processing invoice: ' + invoice.Name + ', Billing_Date: ' + invoice.Billing_Date__c + ', SAPOrderNo: ' + invoice.SAPOrderNo__c);
            
            // Check if same Billing_Date and SAPOrderNo combination already exists
            if (invoice.Billing_Date__c != null && String.isNotBlank(invoice.SAPOrderNo__c)) {
                String key = String.valueOf(invoice.Billing_Date__c) + '-' + invoice.SAPOrderNo__c;
                if (existingBillingMap.containsKey(key)) {
                    System.debug('Duplicate found with key: ' + key);
                    // If an existing case is found, map it to this invoice
                    if (existingBillingCaseMap.containsKey(key)) {
                        Invoice__c invoiceToUpdate = new Invoice__c();
                        invoiceToUpdate.Id = invoice.Id;
                        invoiceToUpdate.Case__c = existingBillingCaseMap.get(key);
                        invoicesToUpdateWithExistingCase.add(invoiceToUpdate);
                        System.debug('Mapping existing case: ' + existingBillingCaseMap.get(key) + ' to invoice: ' + invoice.Id);
                    }
                    continue;
                }
            }
            
            Case courtesyCase = new Case();
            courtesyCase.Subject = 'Spare installation for invoice ' + invoice.Name;
            courtesyCase.Status = 'New';
            courtesyCase.Priority = 'Medium';
            courtesyCase.Origin = 'Web';
            courtesyCase.Type = 'Courtesy';
            courtesyCase.Case_Sub_Type__c = 'Spare Installation';
            
            if (String.isNotBlank(invoice.Serial_No__c) && assetMap.containsKey(invoice.Serial_No__c)) {
                courtesyCase.AssetId = assetMap.get(invoice.Serial_No__c);
            }
            courtesyCase.AccountId = invoice.Sold_To_Party_1__c != null ? invoice.Sold_To_Party_1__c : invoice.Ship_To_Party_1__c;
            courtesyCase.ContactId = invoice.Contact__c;
            courtesyCase.Division__c = String.isNotBlank(invoice.Business_Vertical__c) ? invoice.Business_Vertical__c : invoice.Item_Master__r.Business_Vertical__c;
            courtesyCase.Description = buildSpareInstallationRemark(invoice);
            String remark = buildSpareInstallationRemark(invoice);
            System.debug('Remark being set: ' + remark);
            courtesyCase.Comments = remark;
            System.debug('After setting - Comments value: ' + courtesyCase.Comments);
            
            if (openQueueId != null) {
                courtesyCase.OwnerId = openQueueId;
            } else if (invoice.OwnerId != null) {
                courtesyCase.OwnerId = invoice.OwnerId;
            } else {
                courtesyCase.OwnerId = UserInfo.getUserId();
            }
            
            casesToInsert.add(courtesyCase);
            caseIndexToInvoiceIdMap.put(caseIndex, invoice.Id);
            caseIndex++;
        }
        
        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
            
            // Update invoices with the created case IDs
            List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();
            for (Integer i = 0; i < casesToInsert.size(); i++) {
                Invoice__c invoiceToUpdate = new Invoice__c();
                invoiceToUpdate.Id = caseIndexToInvoiceIdMap.get(i);
                invoiceToUpdate.Case__c = casesToInsert.get(i).Id;
                invoicesToUpdate.add(invoiceToUpdate);
            }
            
            // Add invoices that need to be mapped with existing cases
            invoicesToUpdate.addAll(invoicesToUpdateWithExistingCase);
            
            if (!invoicesToUpdate.isEmpty()) {
                update invoicesToUpdate;
            }
        } else if (!invoicesToUpdateWithExistingCase.isEmpty()) {
            // If no new cases were created but existing cases need to be mapped
            update invoicesToUpdateWithExistingCase;
        }
    }
    
    
    private static String buildSpareInstallationRemark(Invoice__c invoice) {
        String materialCode = String.isNotBlank(invoice.Material__c) ? invoice.Material__c : null;
        if (String.isBlank(materialCode) && invoice.Item_Master__r != null) {
            materialCode = invoice.Item_Master__r.ProductCode;
        }
        if (String.isBlank(materialCode)) {
            materialCode = invoice.Name;
        }
        
        String quantity = invoice.Billing_Qty__c != null ? String.valueOf(invoice.Billing_Qty__c) : '0';
        return 'Spare material code: ' + materialCode + ', Quantity supplied: ' + quantity + ' against invoice ' + invoice.Name;
    }
    
    
    public static void createAssets(List<Invoice__c> invoiceList) {
        Map<Integer, Warranty_Mapping__mdt> warrantyConfigMap = new Map<Integer, Warranty_Mapping__mdt>();
        for (Warranty_Mapping__mdt month : [
            SELECT Warranty_Period__c, Preventive_Visits__c, Breakdown_Visits__c
            FROM Warranty_Mapping__mdt
        ]) {
            // warrantyConfigMap.put(month.Warranty_Period__c, month);
            warrantyConfigMap.put(Integer.valueOf(month.Warranty_Period__c), month);
        }
        Set<String> pinCodes = new Set<String>();
        Set<Id> itemMasterIds = new Set<Id>();
        Set<String> ordMap=new Set<String>();
        Map<String,String> assetOrdMap=new map<String,String>();
        for(Invoice__c invoice : invoiceList) {
            pinCodes.add(invoice.Ship_to_Pin__c);
            itemMasterIds.add(invoice.Item_Master__c);
            ordMap.add(invoice.SAPOrderNo__c);
        }
        for(Quote quote:[Select id,name,Asset_Serial_Number__c, SAP_Order_No__c from Quote where SAP_Order_No__c in: ordMap AND SAP_Order_No__c != null]) {
            assetOrdMap.put(quote.SAP_Order_No__c,quote.Asset_Serial_Number__c);
        }
        
        Map<String, Pin_Code_Master__c> pinCodeMap = new Map<String, Pin_Code_Master__c>();
        for(Pin_Code_Master__c pincode : [
            SELECT Id, Name,
            (
                SELECT Id, Name, Territory_Master__c, Pin_Code_Master__c, Territory_Master__r.Name, Territory_Master__r.Division__c, Pin_Code_Master__r.Name
                FROM Territory_Pincode_Mappings__r
            )
            FROM Pin_Code_Master__c
            WHERE Name IN :pinCodes
        ]) {
            pinCodeMap.put(pincode.Name, pincode);
        }
        
        
        Map<Id, Product2> productMap = new Map<Id, Product2>();
        for(Product2 product : [
            SELECT Id, Name, Description, Business_Vertical__c, Category__c, Manufacturing_Part_No1__r.Name
            FROM Product2
            WHERE Id IN :itemMasterIds
        ]) {
            productMap.put(product.Id, product);
        }
        
        
        List<Asset> assetsToInsert = new List<Asset>();
        List<Asset_Warranty__c> warrantiesToInsert = new List<Asset_Warranty__c>();
        for (Invoice__c invoice : invoiceList) {
            if (!productMap.containsKey(invoice.Item_Master__c)) continue;
            system.debug('Billing_Type__c'+ invoice.Billing_Type__c);
            if(invoice.Billing_Type__c != 'F2') continue;
            
            Product2 product = productMap.get(invoice.Item_Master__c);
            System.debug('product' + invoice.Item_Master__c + ' ' + product + ' ' + product.Manufacturing_Part_No1__r);
            Boolean isAssetToBeCreated = product.Manufacturing_Part_No1__r.Name == 'MHE COMPLEX' || product.Manufacturing_Part_No1__r.Name == 'MHE SEMI COMPLEX' || product.Manufacturing_Part_No1__r.Name == 'MHE SIMPLE' || product.Manufacturing_Part_No1__r.Name == 'CODING & MARKING';
            if (!isAssetToBeCreated) continue;
            
            for (Integer i = 1; i <= invoice.Billing_Qty__c; i++) {
                Asset asset = new Asset();
                asset.Asset_Category__c = 'Direct Sale';
                asset.Type__c = 'Expired';
                asset.Invoice_Number__c = invoice.Name;
                asset.Invoice__c = invoice.Id;
                asset.ContactId = invoice.Contact__c;
                
                asset.AccountId = invoice.Sold_To_Party_1__c;
                asset.Bill_to_Address__c = invoice.Sold_to_Address__c;
                asset.Bill_to_City__c = invoice.Sold_to_City__c;
                asset.Bill_to_Pin__c = invoice.Sold_to_Pin__c;
                asset.Bill_to_Region__c = invoice.Sold_to_Region__c;
                asset.Bill_to_Country__c = invoice.Sold_to_Country__c;
                asset.Bill_to_Customer_Code__c = invoice.Sold_To_Party_Number__c;
                
                asset.End_Customer__c = invoice.Ship_To_Party_1__c;
                asset.Ship_to_Address__c = invoice.Ship_to_Address__c;
                asset.Ship_to_City__c = invoice.Ship_to_City__c;
                asset.Ship_to_Region__c = invoice.Ship_to_Region__c;
                asset.Ship_to_Country__c = invoice.Ship_to_Country__c;
                asset.Ship_to_Pin__c = invoice.Ship_to_Pin__c;
                asset.Ship_to_Customer_Code__c = invoice.Ship_To_Party_Number__c;
                
                asset.PO_Number__c = invoice.PO_Number__c;
                asset.PurchaseDate = invoice.Billing_Date__c;
                asset.Price = invoice.Net_Value_per_Piece__c;
                
                if (product.Category__c == 'Spare' && assetOrdMap.containsKey(invoice.SAPOrderNo__c)) {
                    asset.ParentId = assetOrdMap.get(invoice.SAPOrderNo__c);
                }
                
                asset.Business_Vertical__c = product.Business_Vertical__c;
                asset.Product2Id = invoice.Item_Master__c;
                asset.Description = product.Description;
                
                if (invoice.Billing_Qty__c > 1 || invoice.Serial_No__c == null) {
                    asset.Name = 'Temp-' + invoice.Name + '-' + invoice.Line_Item__c + '-' + i;
                    asset.SerialNumber = 'Temp-' + invoice.Name + '-' + invoice.Line_Item__c + '-' + i;
                    asset.Is_Temp_Serial_Number__c = true;
                } else {
                    asset.Name = invoice.Serial_No__c;
                    asset.SerialNumber = invoice.Serial_No__c;
                }
                
                if (pinCodeMap.containsKey(invoice.Ship_to_Pin__c)) {
                    Pin_Code_Master__c pinCode = pinCodeMap.get(invoice.Ship_to_Pin__c);
                    asset.Pin_Code_Master__c = pinCode.Id;
                    if (pinCode.Territory_Pincode_Mappings__r != null && pinCode.Territory_Pincode_Mappings__r.size() > 0) {
                        for (Territory_Pincode_Mapping__c mapping : pinCode.Territory_Pincode_Mappings__r) {
                            if (mapping.Territory_Master__r.Division__c == product.Business_Vertical__c) {
                                asset.Territory_Master__c = mapping.Territory_Master__c;
                                break;
                            }
                        }
                    }
                }
                
                assetsToInsert.add(asset);
                
                if (invoice.Warrenty_Periods__c != null && Integer.valueOf(invoice.Warrenty_Periods__c) > 0) {
                    Asset_Warranty__c warranty = new Asset_Warranty__c();
                    warranty.Name = asset.Name + ' Warranty';
                    warranty.Asset__r = asset;
                    warranty.Invoice_No__c = invoice.id;
                    warranty.Warranty_Start_Date__c = invoice.Billing_Date__c;
                    warranty.Asset_Warranty_PO_Date__c = invoice.PO_Date__c;
                    warranty.Asset_Warranty_PO__c = invoice.PO_Number__c;
                    String warrantyPeriod = invoice.Warrenty_Periods__c != null ? String.valueOf(invoice.Warrenty_Periods__c) : '0';
                    
                    Warranty_Mapping__mdt month = warrantyConfigMap.get(Integer.valueOf(warrantyPeriod));
                    if (month != null) {
                        warranty.PM_Visit_Allowed__c = month.Preventive_Visits__c;
                        warranty.Breakdown_Visits_Allowed__c = month.Breakdown_Visits__c;
                    } else {
                        warranty.PM_Visit_Allowed__c = 0;
                        warranty.Breakdown_Visits_Allowed__c = 0;
                    }
                    warranty.Asset_Warranty_PO_Status__c = 'Active';
                    warranty.Warranty_Period__c = Double.valueOf(invoice.Warrenty_Periods__c);
                    
                    warrantiesToInsert.add(warranty);
                }
            }
        }
        
        if (!assetsToInsert.isEmpty()) {
            insert assetsToInsert;
            
            for(Asset_Warranty__c warranty : warrantiesToInsert) {
                warranty.Asset__c = warranty.Asset__r.Id;
            }
            insert warrantiesToInsert;
            
            // Call future method to map resource to asset
            Set<Id> assetIds = new Set<Id>();
            for (Asset asset : assetsToInsert) {
                assetIds.add(asset.Id);
            }
            MapResourceToAssetByPinCode.mapResourcesToAssets(assetIds);
        }
        else {
            System.debug('Im out');
        }
    }
    
    
    /*
    public static void insertUndeleteFlowToUpdateSalesAchieved(List<Invoice__c> newRecords, Boolean isInsert) {
        Map<String, List<Invoice__c>> invoicePersonnelMap = new Map<String, List<Invoice__c>>();
        Set<Id> prodIds = new Set<Id>();
        for (Invoice__c invoice : newRecords) {
            System.debug('invoice.Sales_Employee_code__c: ' + invoice.Sales_Employee_code__c);
            String uid = invoice.Sales_Employee_code__c;
            if(String.isBlank(uid)) {
                continue;
            }
            
            if (!invoicePersonnelMap.containsKey(uid)) {
                invoicePersonnelMap.put(uid, new List<Invoice__c>());
            }
            invoicePersonnelMap.get(uid).add(invoice);
            
            if(String.isNotBlank(invoice.Item_Master__c)) {
                prodIds.add(invoice.Item_Master__c);
            }
        }
        
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Category__c FROM Product2 WHERE Id IN :prodIds]);
        
        List<Service_Goal__c> serviceGoals = [
            SELECT Service_Resource__r.User__r.UID__c, Sales_Achievement__c, Financial_Year__c, Service_Achievement__c
            FROM Service_Goal__c
            WHERE Service_Resource__r.User__r.UID__c IN :invoicePersonnelMap.keySet()
        ];
        List<Service_Goal__c> serviceGoalsToBeUpdated = new List<Service_Goal__c>();
        for (Service_Goal__c serviceGoal: serviceGoals) {
            List<Invoice__c> invoiceList = invoicePersonnelMap.get(serviceGoal.Service_Resource__r.User__r.UID__c);
            for (Invoice__c invoice : invoiceList) {
                String financialYear = getFinancialYearFormat(invoice.Billing_Date__c);
                if (invoice.Billing_Date__c != null && financialYear != null) {
                    if (serviceGoal.Financial_Year__c == financialYear) {
                        if(isInsert) {
                            invoice.Service_Goal__c = serviceGoal.Id;
                        }
                        if (productMap.get(invoice.Item_Master__c).Category__c == 'Spare') {
                            if (serviceGoal.Sales_Achievement__c == null) {
                                serviceGoal.Sales_Achievement__c = 0;
                            }
                            serviceGoal.Sales_Achievement__c += invoice.Line_Item_Net_Value__c;
                        }
                        else if (productMap.get(invoice.Item_Master__c).Category__c == 'Service') {
                            if (serviceGoal.Service_Achievement__c == null) {
                                serviceGoal.Service_Achievement__c = 0;
                            }
                            serviceGoal.Service_Achievement__c += invoice.Line_Item_Net_Value__c;
                        }
                    }
                }
            }
            serviceGoalsToBeUpdated.add(serviceGoal);
        }
        
        Database.update(serviceGoalsToBeUpdated, true, AccessLevel.SYSTEM_MODE);
    }
    
    
    public static void updateFlowToUpdateSalesAchieved(List<Invoice__c> newRecords, Map<Id, Invoice__c> oldMap) {
        Map<String, List<Invoice__c>> invoicePersonnelMap = new Map<String, List<Invoice__c>>();
        Set<Id> prodIds = new Set<Id>();
        for (Invoice__c invoice : newRecords) {
            if (invoice.Line_Item_Net_Value__c != oldMap.get(invoice.Id).Line_Item_Net_Value__c) {
                String uid = invoice.Sales_Employee_code__c;
                if(String.isBlank(uid)) {
                    continue;
                }
                
                if (uid != null) {
                    if (!invoicePersonnelMap.containsKey(uid)) {
                        invoicePersonnelMap.put(uid, new List<Invoice__c>());
                    }
                    invoicePersonnelMap.get(uid).add(invoice);
                }
                if(String.isNotBlank(invoice.Item_Master__c)) {
                    prodIds.add(invoice.Item_Master__c);
                }
            }
        }
        
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Category__c FROM Product2 WHERE Id IN :prodIds]);
        
        List<Service_Goal__c> serviceGoals = [
            SELECT Service_Resource__r.User__r.UID__c, Sales_Achievement__c, Financial_Year__c, Service_Achievement__c
            FROM Service_Goal__c
            WHERE Service_Resource__r.User__r.UID__c IN :invoicePersonnelMap.keySet()
        ];
        
        List<Service_Goal__c> serviceGoalsToBeUpdated = new List<Service_Goal__c>();
        for (Service_Goal__c serviceGoal: serviceGoals) {
            List<Invoice__c> invoiceList = invoicePersonnelMap.get(serviceGoal.Service_Resource__r.User__r.UID__c);
            for (Invoice__c invoice : invoiceList) {
                String financialYear = getFinancialYearFormat(invoice.Billing_Date__c);
                if (invoice.Billing_Date__c != null && financialYear != null) {
                    if (serviceGoal.Financial_Year__c == financialYear) {
                        invoice.Service_Goal__c = serviceGoal.Id;
                        if (productMap.get(invoice.Item_Master__c).Category__c == 'Spare') {
                            if (serviceGoal.Sales_Achievement__c == null) {
                                serviceGoal.Sales_Achievement__c = 0;
                            }
                            serviceGoal.Sales_Achievement__c += (invoice.Line_Item_Net_Value__c - oldMap.get(invoice.Id).Line_Item_Net_Value__c);
                        }
                        else if (productMap.get(invoice.Item_Master__c).Category__c == 'Service') {
                            if (serviceGoal.Service_Achievement__c == null) {
                                serviceGoal.Service_Achievement__c = 0;
                            }
                            serviceGoal.Service_Achievement__c += (invoice.Line_Item_Net_Value__c - oldMap.get(invoice.Id).Line_Item_Net_Value__c);
                        }
                    }
                }
            }
            serviceGoalsToBeUpdated.add(serviceGoal);
        }
        
        Database.update(serviceGoalsToBeUpdated, true, AccessLevel.SYSTEM_MODE);
    }
    
    
    public static void deleteFlowToUpdateSalesAchieved(Map<Id, Invoice__c> invoiceMap) {
        Map<String, List<Invoice__c>> invoicePersonnelMap = new Map<String, List<Invoice__c>>();
        Set<Id> prodIds = new Set<Id>();
        for (Invoice__c invoice : invoiceMap.values()) {
            String uid = invoice.Sales_Employee_code__c;
            if(String.isBlank(uid)) {
                continue;
            }
            
            if (!invoicePersonnelMap.containsKey(uid)) {
                invoicePersonnelMap.put(uid, new List<Invoice__c>());
            }
            invoicePersonnelMap.get(uid).add(invoice);
            
            prodIds.add(invoice.Item_Master__c);
        }
        
        Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT Id, Category__c FROM Product2 WHERE Id IN :prodIds]);
        
        List<Service_Goal__c> serviceGoals = [
            SELECT Service_Resource__r.User__r.UID__c, Sales_Achievement__c, Financial_Year__c, Service_Achievement__c
            FROM Service_Goal__c
            WHERE Service_Resource__r.User__r.UID__c IN :invoicePersonnelMap.keySet()
        ];
        List<Service_Goal__c> serviceGoalsToBeUpdated = new List<Service_Goal__c>();
        for (Service_Goal__c serviceGoal: serviceGoals) {
            List<Invoice__c> invoiceList = invoicePersonnelMap.get(serviceGoal.Service_Resource__r.User__r.UID__c);
            for (Invoice__c invoice : invoiceList) {
                String financialYear = getFinancialYearFormat(invoice.Billing_Date__c);
                if (invoice.Billing_Date__c != null && financialYear != null) {
                    if (serviceGoal.Financial_Year__c == financialYear) {
                        if (productMap.get(invoice.Item_Master__c).Category__c == 'Spare') {
                            if (serviceGoal.Sales_Achievement__c == null) {
                                serviceGoal.Sales_Achievement__c = 0;
                            }
                            serviceGoal.Sales_Achievement__c -= invoice.Line_Item_Net_Value__c;
                            if (serviceGoal.Sales_Achievement__c < 0) {
                                serviceGoal.Sales_Achievement__c = 0;
                            }
                        }
                        else if (productMap.get(invoice.Item_Master__c).Category__c == 'Service') {
                            if (serviceGoal.Service_Achievement__c == null) {
                                serviceGoal.Service_Achievement__c = 0;
                            }
                            serviceGoal.Service_Achievement__c -= invoice.Line_Item_Net_Value__c;
                            if (serviceGoal.Service_Achievement__c < 0) {
                                serviceGoal.Service_Achievement__c = 0;
                            }
                        }
                    }
                }
            }
            serviceGoalsToBeUpdated.add(serviceGoal);
        }
        
        Database.update(serviceGoalsToBeUpdated, true, AccessLevel.SYSTEM_MODE);
    }
    
    
    public static String getFinancialYearFormat(Date billed_date) {
        if (billed_date == null) {
            return null;
        }
        
        Integer year = billed_date.year();
        Integer month = billed_date.month();
        Integer fyStartYear;
        Integer fyEndYear;
        
        if (month >= 4) {
            // April to December
            fyStartYear = year;
            fyEndYear = year + 1;
        } else {
            // January to March
            fyStartYear = year - 1;
            fyEndYear = year;
        }
        
        return 'FY ' + fyStartYear + '-' + fyEndYear.toString().substring(2);
    }
     */
    
}