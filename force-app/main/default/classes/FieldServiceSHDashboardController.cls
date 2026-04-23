public with sharing class FieldServiceSHDashboardController {

    @AuraEnabled(cacheable=true) // 1 - List of Warranty TO Out of Warranty Assets in coming 60 days (RSM Wise)
    public static Object getWarrantyToOutOfWarranty() {
        try {
            return FieldServiceSCDashboardController.getWarrantyToOutOfWarrantyRSMWise();
        }
        catch (Exception e) {
            System.debug('❌ Error in getWarrantyToOutOfWarranty: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 2 - AMC Renewal due in coming 60 days (RSM Wise)
    public static Object getAMCRenewalDueIn60DaysRSMWise() {
        try {
            return FieldServiceSCDashboardController.getAMCRenewalRSMWiseInNext60Days();
        }
        catch (Exception e) {
            System.debug('❌ Error in getAMCRenewalDueIn60DaysRSMWise: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 3 - AMC not renewed in Last 90 days (RSM Wise)
    public static Object getAMCNotRenewedInLast90DaysRSMWise() {
        try {
            Date todayMinus90Days = System.today().addDays(-90);

            Map<Id, User> userMap = DataCls.getUsersById();
            Map<Id, Set<Id>> rsmWisePincodeIds = UtilityCls.getRSMWisePincodeList();
            Set<Id> pincodeAssignedToMe = new Set<Id>();
            Map<Id, Id> pincodeWiseRSM = new Map<Id, Id>();
            for(Id rsmId : rsmWisePincodeIds.keySet()) {
                pincodeAssignedToMe.addAll(rsmWisePincodeIds.get(rsmId));
                for(Id pincodeId : rsmWisePincodeIds.get(rsmId)) {
                    pincodeWiseRSM.put(pincodeId, rsmId);
                }
            }

            Map<Id, Asset_AMC__c> assetWiseExpiredAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> expiredAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND AMC_End_Date__c <= TODAY AND AMC_End_Date__c >= :todayMinus90Days
            ]) {
                expiredAssetIds.add(amc.Asset__c);
                assetWiseExpiredAMC.put(amc.Asset__c, amc);
            }

            Map<Id, Asset_AMC__c> assetWiseRenewedAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> renewedAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND Asset__c IN :expiredAssetIds AND AMC_Start_Date__c >= :todayMinus90Days
            ]) {
                renewedAssetIds.add(amc.Asset__c);
                assetWiseRenewedAMC.put(amc.Asset__c, amc);
            }

            Map<Id, Map<String, Object>> rsmDetails = new Map<Id, Map<String, Object>>();
            Map<Id, List<Map<String, Object>>> rsmWiseAssetDetails = new Map<Id, List<Map<String, Object>>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name
                FROM Asset
                WHERE Id NOT IN :renewedAssetIds AND Id IN :expiredAssetIds
            ]) {
                Id rsmId = pincodeWiseRSM.get(a.Pin_Code_Master__c);
                if(rsmDetails.containsKey(rsmId) == false) {
                    Map<String, Object> rsm = new Map<String, Object>();
                    rsm.put('id', rsmId);
                    rsm.put('name', userMap.get(rsmId).Name);
                    rsmDetails.put(rsmId, rsm);
                }

                Asset_AMC__c amc = assetWiseExpiredAMC.get(a.Id);
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('pinCode', a.Pin_Code_Master__c);
                asset.put('pinCodeName', a.Pin_Code_Master__r.Name);

                if(assetWiseExpiredAMC.containsKey(a.Id)) {
                    asset.put('amcId', amc.Id);
                    asset.put('amcStartDate', amc.AMC_Start_Date__c);
                    asset.put('amcEndDate', amc.AMC_End_Date__c);
                }

                if(rsmWiseAssetDetails.containsKey(rsmId) == false) {
                    rsmWiseAssetDetails.put(rsmId, new List<Map<String, Object>>());
                }
                rsmWiseAssetDetails.get(rsmId).add(asset);
            }

            List<Object> result = new List<Object>();
            for(String key : rsmDetails.keySet()) {
                Map<String, Object> rsm = rsmDetails.get(key);
                result.add(new Map<String, Object> {
                    'rsmId' => rsm.get('id'),
                    'rsmName' => rsm.get('name'),
                    'assets' => rsmWiseAssetDetails.get(key)
                });
            }

            return result;

        }
        catch (Exception e) {
            System.debug('❌ Error in getAMCNotRenewedInLast90DaysRSMWise: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 4 - OPEN Sale Order (Pending Dispatches) (RSM Wise) // TODO: Not implemented yet
    public static Object getOpenSaleOrder() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getOpenSaleOrder: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 5 - Quote Vs PO Conversion (RSM Wise) // TODO: Not implemented yet
    public static Object getQuoteVsPOConversion() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getQuoteVsPOConversion: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 6 - NON Conversion of Warranty TO AMC in last 90 days (RSM Wise)
    public static Object getNonConversionOfWarrantyToAMC() {
        try {
            Date todayMinus90Days = System.today().addDays(-90);

            Map<Id, User> userMap = DataCls.getUsersById();
            Map<Id, Set<Id>> rsmWisePincodeIds = UtilityCls.getRSMWisePincodeList();
            Set<Id> pincodeAssignedToMe = new Set<Id>();
            Map<Id, Id> pincodeWiseRSM = new Map<Id, Id>();
            for(Id rsmId : rsmWisePincodeIds.keySet()) {
                pincodeAssignedToMe.addAll(rsmWisePincodeIds.get(rsmId));
                for(Id pincodeId : rsmWisePincodeIds.get(rsmId)) {
                    pincodeWiseRSM.put(pincodeId, rsmId);
                }
            }

            Map<Id, Asset_Warranty__c> assetWiseExpiredWarranty = new Map<Id, Asset_Warranty__c>();
            Set<Id> expiredAssetIdsWhoseWarrantyExpired = new Set<Id>();
            for(Asset_Warranty__c warranty : [
                SELECT Id, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND Warranty_End_Date__c <= TODAY AND Warranty_End_Date__c >= :todayMinus90Days
            ]) {
                expiredAssetIdsWhoseWarrantyExpired.add(warranty.Asset__c);
                assetWiseExpiredWarranty.put(warranty.Asset__c, warranty);
            }

            Map<Id, Asset_AMC__c> assetWiseRenewedAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> renewedAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND Asset__c IN :expiredAssetIdsWhoseWarrantyExpired AND AMC_Start_Date__c >= :todayMinus90Days
            ]) {
                renewedAssetIds.add(amc.Asset__c);
                assetWiseRenewedAMC.put(amc.Asset__c, amc);
            }

            Map<Id, Map<String, Object>> rsmDetails = new Map<Id, Map<String, Object>>();
            Map<Id, List<Map<String, Object>>> rsmWiseAssetDetails = new Map<Id, List<Map<String, Object>>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name
                FROM Asset
                WHERE Id NOT IN :renewedAssetIds AND Id IN :expiredAssetIdsWhoseWarrantyExpired
            ]) {
                Id rsmId = pincodeWiseRSM.get(a.Pin_Code_Master__c);
                if(rsmDetails.containsKey(rsmId) == false) {
                    Map<String, Object> rsm = new Map<String, Object>();
                    rsm.put('id', rsmId);
                    rsm.put('name', userMap.get(rsmId).Name);
                    rsmDetails.put(rsmId, rsm);
                }

                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('pinCode', a.Pin_Code_Master__c);
                asset.put('pinCodeName', a.Pin_Code_Master__r.Name);

                if(assetWiseExpiredWarranty.containsKey(a.Id)) {
                    Asset_Warranty__c warranty = assetWiseExpiredWarranty.get(a.Id);
                    asset.put('warrantyStartDate', warranty.Warranty_Start_Date__c);
                    asset.put('warrantyEndDate', warranty.Warranty_End_Date__c);
                }

                if (!rsmWiseAssetDetails.containsKey(rsmId)) {
                    rsmWiseAssetDetails.put(rsmId, new List<Map<String, Object>>());
                }
                rsmWiseAssetDetails.get(rsmId).add(asset);
            }

            List<Object> result = new List<Object>();
            for(String key : rsmDetails.keySet()) {
                Map<String, Object> rsm = rsmDetails.get(key);
                result.add(new Map<String, Object> {
                    'rsmId' => rsm.get('id'),
                    'rsmName' => rsm.get('name'),
                    'assets' => rsmWiseAssetDetails.get(key)
                });
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getNonConversionOfWarrantyToAMC: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 7 - Outstanding Report (RSM Wise) // TODO: Not implemented yet
    public static Object getOutstandingReport() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getOutstandingReport: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 8 - Invoicing Due after AMC PM (RSM Wise) // TODO: Not implemented yet
    public static Object getInvoicingDueAfterAMCPM() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getInvoicingDueAfterAMCPM: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 9 - AMC Business Chart (RSM Wise)
    public static Object getAMCBusinessChart() {
        try {
            Map<Id, User> userMap = DataCls.getUsersById();
            Map<Id, Set<Id>> rsmWisePincodeIds = UtilityCls.getRSMWisePincodeList();
            Set<Id> pincodeAssignedToMe = new Set<Id>();
            Map<Id, Id> pincodeWiseRSM = new Map<Id, Id>();
            for(Id rsmId : rsmWisePincodeIds.keySet()) {
                pincodeAssignedToMe.addAll(rsmWisePincodeIds.get(rsmId));
                for(Id pincodeId : rsmWisePincodeIds.get(rsmId)) {
                    pincodeWiseRSM.put(pincodeId, rsmId);
                }
            }

            Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
            Date fyStartDate = (Date) fyDetails.get('start');
            Date fyEndDate = (Date) fyDetails.get('end');

            Date x90DaysBefore = System.today().addDays(-90);


            // Decimal invoiceAmountOfNewAMCs = 0;
            // Decimal invoiceAmountOfRenewedAMCs = 0;
            // Decimal invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry = 0;
            Map<String, Map<String, Decimal>> rsmWiseInvoiceAmount = new Map<String, Map<String, Decimal>>();
            Map<Id, Map<String, Object>> rsmDetails = new Map<Id, Map<String, Object>>();
            for(Asset asset : [
                SELECT Id, Name, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
                (
                    SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c
                    FROM Asset_AMCs__r
                    WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null
                ),
                (
                    SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
                    FROM Asset_Warranty__r
                    WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
                )
                FROM Asset
                WHERE Pin_Code_Master__c IN :pincodeAssignedToMe AND Type__c IN ('Within AMC', 'Within CAMC')
            ]) {
                Id rsmId = pincodeWiseRSM.get(asset.Pin_Code_Master__c);
                if(rsmDetails.containsKey(rsmId) == false) {
                    Map<String, Object> rsm = new Map<String, Object>();
                    rsm.put('id', rsmId);
                    rsm.put('name', userMap.get(rsmId).Name);
                    rsmDetails.put(rsmId, rsm);
                }

                if(asset.Asset_AMCs__r.size() > 0) {
                    if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
                        for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                            if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                                if(amc.AMC_PO_Value__c != null) {
                                    if(rsmWiseInvoiceAmount.containsKey(pincodeWiseRSM.get(asset.Pin_Code_Master__c))) {
                                        if(rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).containsKey('invoiceAmountOfNewAMCs')) {
                                            Decimal invoiceAmountOfNewAMCs = rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).get('invoiceAmountOfNewAMCs');
                                            invoiceAmountOfNewAMCs += amc.AMC_PO_Value__c;
                                            rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfNewAMCs', invoiceAmountOfNewAMCs);
                                        }
                                        else {
                                            rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfNewAMCs', amc.AMC_PO_Value__c);
                                        }
                                    }
                                    else {
                                        rsmWiseInvoiceAmount.put(pincodeWiseRSM.get(asset.Pin_Code_Master__c), new Map<String, Decimal>());
                                        rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfNewAMCs', amc.AMC_PO_Value__c);
                                    }
                                }
                            }
                        }
                    }
                    else if(asset.Asset_AMCs__r.size() > 1) {
                        for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                            if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                                if(amc.AMC_PO_Value__c != null) {
                                    if(rsmWiseInvoiceAmount.containsKey(pincodeWiseRSM.get(asset.Pin_Code_Master__c))) {
                                        if(rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).containsKey('invoiceAmountOfRenewedAMCs')) {
                                            Decimal invoiceAmountOfRenewedAMCs = rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).get('invoiceAmountOfRenewedAMCs');
                                            invoiceAmountOfRenewedAMCs += amc.AMC_PO_Value__c;
                                            rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfRenewedAMCs', invoiceAmountOfRenewedAMCs);
                                        }
                                        else {
                                            rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfRenewedAMCs', amc.AMC_PO_Value__c);
                                        }
                                    }
                                    else {
                                        rsmWiseInvoiceAmount.put(pincodeWiseRSM.get(asset.Pin_Code_Master__c), new Map<String, Decimal>());
                                        rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfRenewedAMCs', amc.AMC_PO_Value__c);
                                    }
                                }
                            }
                        }
                    }
                    else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
                        Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
                        Boolean isWarrantyExpiredWithinLast90Days = warranty.Warranty_End_Date__c >= x90DaysBefore;
                        if(isWarrantyExpiredWithinLast90Days) {
                            for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
                                if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                                    if(amc.AMC_PO_Value__c != null) {
                                        // invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry += amc.AMC_PO_Value__c;
                                        if(rsmWiseInvoiceAmount.containsKey(pincodeWiseRSM.get(asset.Pin_Code_Master__c))) {
                                            if(rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).containsKey('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry')) {
                                                Decimal invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry = rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).get('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry');
                                                invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry += amc.AMC_PO_Value__c;
                                                rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry', invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry);
                                            }
                                            else {
                                                rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry', amc.AMC_PO_Value__c);
                                            }
                                        }
                                        else {
                                            rsmWiseInvoiceAmount.put(pincodeWiseRSM.get(asset.Pin_Code_Master__c), new Map<String, Decimal>());
                                            rsmWiseInvoiceAmount.get(pincodeWiseRSM.get(asset.Pin_Code_Master__c)).put('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry', amc.AMC_PO_Value__c);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            List<Object> result = new List<Object>();
            for(String key : rsmDetails.keySet()) {
                Map<String, Object> rsm = rsmDetails.get(key);
                result.add(new Map<String, Object> {
                    'rsmId' => rsm.get('id'),
                    'rsmName' => rsm.get('name'),
                    'invoiceAmountOfNewAMCs' => rsmWiseInvoiceAmount.get(key).get('invoiceAmountOfNewAMCs'),
                    'invoiceAmountOfRenewedAMCs' => rsmWiseInvoiceAmount.get(key).get('invoiceAmountOfRenewedAMCs'),
                    'invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry' => rsmWiseInvoiceAmount.get(key).get('invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry')
                });
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 10 - Business Revenue (RSM Wise)
    public static Object getBusinessRevenue() {
        try {
            Map<Id, User> userMap = DataCls.getUsersById();
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();

            Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
            String fyName = (String) fyDetails.get('fyName');

            Map<Id, Map<String, Object>> result = new Map<Id, Map<String, Object>>();
            for(Service_Goal__c sg : [
                SELECT Id, Name, Sales_Goal__c, Teams_Goal__c, Service_Resource__c, Financial_Year__c, Teams_Achievement__c, Sales_Achievement__c, Business_Verticals__c,
                Service_Resource__r.User__r.ManagerId, Service_Resource__r.User__r.Manager.Name
                FROM Service_Goal__c
                WHERE Service_Resource__r.User__c IN :usersReportingToMe AND Financial_Year__c = :fyName
            ]) {
                Id managerId = sg.Service_Resource__r.User__r.ManagerId;
                Map<String, Object> goal = result.get(managerId);

                if (goal != null) {
                    goal = new Map<String, Object>{
                        'id' => sg.Id,
                        'name' => sg.Name,
                        'salesGoal' => sg.Sales_Goal__c,
                        'teamsGoal' => sg.Teams_Goal__c,
                        'rsmId' => managerId,
                        'rsmName' => sg.Service_Resource__r.User__r.Manager.Name,
                        'financialYear' => sg.Financial_Year__c,
                        'teamsAchievement' => sg.Teams_Achievement__c,
                        'salesAchievement' => sg.Sales_Achievement__c,
                        'businessVerticals' => sg.Business_Verticals__c
                    };
                    result.put(managerId, goal);
                } else {
                    goal.put('salesGoal', goal.get('salesGoal') !=null?(Decimal)goal.get('salesGoal') + sg.Sales_Goal__c:0);
                    goal.put('teamsGoal', goal.get('teamsGoal') !=null?(Decimal)goal.get('teamsGoal') + sg.Teams_Goal__c:0);
                    goal.put('teamsAchievement',goal.get('teamsAchievement')!=null? (Decimal)goal.get('teamsAchievement') + sg.Teams_Achievement__c:0);
                    goal.put('salesAchievement',goal.get('salesAchievement')!=null? (Decimal)goal.get('salesAchievement') + sg.Sales_Achievement__c:0);
                }
            }

            return result.values();
        }
        catch (Exception e) {
            System.debug('❌ Error in getBusinessRevenue: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true) 
    public static Object getListOfReturnableSampleQuoteLineItemsSHWise() {
        try {
            return FieldServiceSEDashboardController.getListOfReturnableSampleQuoteLineItems();
        }
        catch (Exception e) {
            System.debug('❌ Error in getWarrantyToOutOfWarranty: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}