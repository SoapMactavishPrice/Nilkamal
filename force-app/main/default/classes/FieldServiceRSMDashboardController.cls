public with sharing class FieldServiceRSMDashboardController {


    @AuraEnabled(cacheable=true) // 1 - Quote Status / Stages
    public static Object getQuoteCountStatusWise(String dateFilter) {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();

            Map<String, String> statusPicklistValues = UtilityCls.getPickList('Quote', 'Status');
            Map<String, Integer> result = new Map<String, Integer>();
            for(String status : statusPicklistValues.keySet()) {
                result.put(status, 0);
            }

             // Build dynamic query using Date Literal
            String query = 'SELECT Status, COUNT(Id) quoteCount FROM Quote WHERE Case__r.OwnerId IN :usersReportingToMe';
            if (!String.isBlank(dateFilter)) {
                query += ' AND Quote_Start_Date__c = ' + dateFilter;
            }
            query += ' GROUP BY Status';

            List<AggregateResult> records = Database.query(query);

            // for(AggregateResult ar : [
            //     SELECT Status, COUNT(Id) quoteCount
            //     FROM Quote
            //     WHERE Case__r.OwnerId IN :usersReportingToMe
            //     GROUP BY Status
            // ]) 
            for (AggregateResult ar : records) 
            {
                String status = (String) ar.get('Status');
                String mappedStatus = statusPicklistValues.containsKey(status) ? statusPicklistValues.get(status) : 'Other';
                Integer quoteCount = (Integer) ar.get('quoteCount');
                result.put(mappedStatus, quoteCount);
            }

            System.debug(JSON.serialize(result));
            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getQuoteCountStatusWise: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 2 - List of Warranty TO Out of Warranty Assets in coming 60 days
    public static Object getListOfAssetsWhoseWarrantyInNearingExpire() {
        try {
            Date todayPlus60Days = System.today().addDays(60);
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            Map<Id, Asset_Warranty__c> assetWiseWarrantyNearingExpire = new Map<Id, Asset_Warranty__c>();
            Set<Id> assetIdsWhoseWarrantyNearingExpire = new Set<Id>();
            for(Asset_Warranty__c aw : [
                SELECT Id, Name, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Warranty_End_Date__c >= TODAY AND Warranty_End_Date__c <= :todayPlus60Days
            ]) {
                assetIdsWhoseWarrantyNearingExpire.add(aw.Asset__c);
                assetWiseWarrantyNearingExpire.put(aw.Asset__c, aw);
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name
                FROM Asset
                WHERE Id IN :assetIdsWhoseWarrantyNearingExpire
            ]) {
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('pinCodeId', a.Pin_Code_Master__c);
                asset.put('pinCodeName', a.Pin_Code_Master__r.Name);

                if(assetWiseWarrantyNearingExpire.containsKey(a.Id)) {
                    Asset_Warranty__c aw = assetWiseWarrantyNearingExpire.get(a.Id);
                    asset.put('warrantyId', aw.Id);
                    asset.put('warrantyName', aw.Name);
                    asset.put('warrantyStartDate', aw.Warranty_Start_Date__c);
                    asset.put('warrantyEndDate', aw.Warranty_End_Date__c);
                }
                result.add(asset);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfAssetsWhoseWarrantyInNearingExpire: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 3 - AMC Renewal due in coming 60 days
    public static Object getListAssetsWhoseAMCInNearingExpire() {
        try {
            Date todayPlus60Days = System.today().addDays(60);
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            Map<Id, Asset_AMC__c> assetWiseAMCExpiringWithin60Days = new Map<Id, Asset_AMC__c>();
            Set<Id> assetIdsWhoseAMCExpiringWithin60Days = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Name, Asset__c, AMC_Start_Date__c, AMC_End_Date__c, SE_Name__c, SE_Name__r.Name
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND AMC_End_Date__c >= TODAY AND AMC_End_Date__c <= :todayPlus60Days
                ORDER BY SE_Name__r.Name
            ]) {
                assetIdsWhoseAMCExpiringWithin60Days.add(amc.Asset__c);
                assetWiseAMCExpiringWithin60Days.put(amc.Asset__c, amc);
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Product2.Description
                FROM Asset
                WHERE Id IN :assetIdsWhoseAMCExpiringWithin60Days
                ORDER BY AMC_End_Date__c ASC
            ]) {
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('productDescription', a.Product2.Description);

                if(assetWiseAMCExpiringWithin60Days.containsKey(a.Id)) {
                    Asset_AMC__c amc = assetWiseAMCExpiringWithin60Days.get(a.Id);
                    asset.put('amcId', amc.Id);
                    asset.put('amcName', amc.Name);
                    asset.put('amcStartDate', amc.AMC_Start_Date__c);
                    asset.put('amcEndDate', amc.AMC_End_Date__c);
                    asset.put('seName', amc.SE_Name__r.Name);
                }
                result.add(asset);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListAssetsWhoseAMCInNearingExpire: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 4 - AMC not renewed in Last 90 days
    public static Object getListOfAssetsWhoseAmcExpiredButNotRenewed() {
        try {
            Date todayMinus90Days = System.today().addDays(-90);
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            Map<Id, Asset_AMC__c> assetWiseExpiredAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> expiredAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Name, Asset__c, AMC_Start_Date__c, AMC_End_Date__c, SE_Name__c, SE_Name__r.Name
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND AMC_End_Date__c <= TODAY AND AMC_End_Date__c >= :todayMinus90Days
                ORDER BY SE_Name__r.Name
            ]) {
                expiredAssetIds.add(amc.Asset__c);
                assetWiseExpiredAMC.put(amc.Asset__c, amc);
            }

            Map<Id, Asset_AMC__c> assetWiseRenewedAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> renewedAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Name, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Asset__c IN :expiredAssetIds AND AMC_Start_Date__c >= :todayMinus90Days
            ]) {
                renewedAssetIds.add(amc.Asset__c);
                assetWiseRenewedAMC.put(amc.Asset__c, amc);
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Product2.Description
                FROM Asset
                WHERE Id NOT IN :renewedAssetIds AND Id IN :expiredAssetIds
                ORDER BY AMC_End_Date__c ASC
            ]) {
                Asset_AMC__c amc = assetWiseExpiredAMC.get(a.Id);
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('productDescription', a.Product2.Description);

                if(assetWiseExpiredAMC.containsKey(a.Id)) {
                    asset.put('amcId', amc.Id);
                    asset.put('amcName', amc.Name);
                    asset.put('amcStartDate', amc.AMC_Start_Date__c);
                    asset.put('amcEndDate', amc.AMC_End_Date__c);
                    asset.put('seName', amc.SE_Name__r.Name);
                }

                result.add(asset);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfAssetsWhoseAmcExpiredButNotRenewed: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 5 - Customer wise Outstanding Report // TODO: Not implemented
    public static Object getCustomerWiseOutstandingReport() {
        try {
            return null;
        } catch (Exception e) {
            System.debug('❌ Error in getCustomerWiseOutstandingReport: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 6 - NON Conversion of Warranty TO AMC in last 90 days
    public static Object getListOfAssetsWhoseWarrantyExpiredButAMCNotRenewed() {
        try {
            Date todayMinus90Days = System.today().addDays(-90);
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            Map<Id, Asset_Warranty__c> assetWiseExpiredWarranty = new Map<Id, Asset_Warranty__c>();
            Set<Id> expiredAssetIdsWhoseWarrantyExpired = new Set<Id>();
            for(Asset_Warranty__c warranty : [
                SELECT Id, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Warranty_End_Date__c <= TODAY AND Warranty_End_Date__c >= :todayMinus90Days
            ]) {
                expiredAssetIdsWhoseWarrantyExpired.add(warranty.Asset__c);
                assetWiseExpiredWarranty.put(warranty.Asset__c, warranty);
            }

            Map<Id, Asset_AMC__c> assetWiseRenewedAMC = new Map<Id, Asset_AMC__c>();
            Set<Id> renewedAssetIds = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Asset__c IN :expiredAssetIdsWhoseWarrantyExpired AND AMC_Start_Date__c >= :todayMinus90Days
            ]) {
                renewedAssetIds.add(amc.Asset__c);
                assetWiseRenewedAMC.put(amc.Asset__c, amc);
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Product2.Description, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.Name
                FROM Asset
                WHERE Id NOT IN :renewedAssetIds AND Id IN :expiredAssetIdsWhoseWarrantyExpired
            ]) {
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('assetId', a.Id);
                asset.put('serialNumber', a.SerialNumber);
                asset.put('accountId', a.AccountId);
                asset.put('accountName', a.Account.Name);
                asset.put('productDescription', a.Product2.Description);
                asset.put('seName', a.Service_Resource__r.User__r.Name);

                if(assetWiseExpiredWarranty.containsKey(a.Id)) {
                    Asset_Warranty__c warranty = assetWiseExpiredWarranty.get(a.Id);
                    asset.put('warrantyStartDate', warranty.Warranty_Start_Date__c);
                    asset.put('warrantyEndDate', warranty.Warranty_End_Date__c);
                }

                result.add(asset);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfAssetsWhoseWarrantyExpiredButAMCNotRenewed: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 7 - NON Active Customer / Asset, Within Last 180 Days, Within Last 90 days
    public static Object getNonActiveCustomers() {
        try {
            Map<String, Date> dates = new Map<String, Date>();
            dates.put('x90days', System.today().addDays(-90));
            dates.put('x180days', System.today().addDays(-180));

            return getNonActiveCustomers(dates);
        }
        catch (Exception e) {
            System.debug('❌ Error in getNonActiveCustomers: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    private static Map<String, List<Map<String, Object>>> getNonActiveCustomers(Map<String, Date> dates) {
        try {
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            Map<String, List<Map<String, Object>>> finalResult = new Map<String, List<Map<String, Object>>>();

            for(String key : dates.keySet()) {

                /*
                    Set<Id> expiredAssetIds = new Set<Id>();
                    Map<Id, Asset_Warranty__c> assetWiseExpiredWarranty = new Map<Id, Asset_Warranty__c>();
                    for(Asset_Warranty__c warranty : [
                        SELECT Id, Name, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                        FROM Asset_Warranty__c
                        WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Warranty_End_Date__c <= TODAY AND Warranty_End_Date__c >= :dates.get(key)
                    ]) {
                        expiredAssetIds.add(warranty.Asset__c);
                        assetWiseExpiredWarranty.put(warranty.Asset__c, warranty);
                    }
                    Map<Id, Asset_AMC__c> assetWiseExpiredAMC = new Map<Id, Asset_AMC__c>();
                    for(Asset_AMC__c amc : [
                        SELECT Id, Name, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                        FROM Asset_AMC__c
                        WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND AMC_End_Date__c <= TODAY AND AMC_End_Date__c >= :dates.get(key)
                    ]) {
                        expiredAssetIds.add(amc.Asset__c);
                        assetWiseExpiredAMC.put(amc.Asset__c, amc);
                    }

                    Set<Id> activeAssetIds = new Set<Id>();
                    for(Asset_Warranty__c warranty : [
                        SELECT Id, Name, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                        FROM Asset_Warranty__c
                        WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND Warranty_End_Date__c >= TODAY
                    ]) {
                        activeAssetIds.add(warranty.Asset__c);
                    }
                    for(Asset_AMC__c amc : [
                        SELECT Id, Name, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                        FROM Asset_AMC__c
                        WHERE Asset__r.Pin_Code_Master__c IN :pincodeIds AND AMC_End_Date__c >= TODAY
                    ]) {
                        activeAssetIds.add(amc.Asset__c);
                    }

                    List<Map<String, Object>> result = new List<Map<String, Object>>();
                    for(Asset a : [
                        SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
                        Service_Resource__r.User__c, Service_Resource__r.User__r.Name
                        FROM Asset
                        WHERE Id NOT IN :expiredAssetIds AND Id IN :activeAssetIds
                        ORDER BY Service_Resource__r.User__r.Name, Pin_Code_Master__r.Name
                    ]) {
                */

                String query = 'SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name, ' +
                    'Service_Resource__r.User__c, Service_Resource__r.User__r.Name ' +
                    'FROM Asset ';
                if(key == 'x180days') {
                    query += 'WHERE Is_inactive_for_more_than_last_180_days__c = true ';
                }
                if(key == 'x90days') {
                    query += 'WHERE Is_inactive_for_more_than_last_90_days__c = true ';
                }
                // query += 'AND Pin_Code_Master__c IN :pincodeIds ' +
                query += 'ORDER BY Service_Resource__r.User__r.Name, Pin_Code_Master__r.Name';

                List<Map<String, Object>> result = new List<Map<String, Object>>();
                for(Asset a : Database.query(query)) {
                    Map<String, Object> asset = new Map<String, Object>();
                    asset.put('assetId', a.Id);
                    asset.put('serialNumber', a.SerialNumber);
                    asset.put('accountId', a.AccountId);
                    asset.put('accountName', a.Account.Name);
                    asset.put('pinCode', a.Pin_Code_Master__c);
                    asset.put('pinCodeName', a.Pin_Code_Master__r.Name);

                    asset.put('serviceEngineer', a.Service_Resource__r.User__c);
                    asset.put('serviceEngineerName', a.Service_Resource__r.User__r.Name);

                    /*
                        if(assetWiseExpiredWarranty.containsKey(a.Id)) {
                            Asset_Warranty__c warranty = assetWiseExpiredWarranty.get(a.Id);
                            asset.put('warrantyId', warranty.Id);
                            asset.put('warrantyName', warranty.Name);
                            asset.put('warrantyStartDate', warranty.Warranty_Start_Date__c);
                            asset.put('warrantyEndDate', warranty.Warranty_End_Date__c);
                        }
                        if(assetWiseExpiredAMC.containsKey(a.Id)) {
                            Asset_AMC__c amc = assetWiseExpiredAMC.get(a.Id);
                            asset.put('amcId', amc.Id);
                            asset.put('amcName', amc.Name);
                            asset.put('amcStartDate', amc.AMC_Start_Date__c);
                            asset.put('amcEndDate', amc.AMC_End_Date__c);
                        }
                    */

                    result.add(asset);
                }
                finalResult.put(key, result);
            }

            return finalResult;
        }
        catch (Exception e) {
            System.debug('❌ Error in getNonActiveCustomers: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 8 - Highest QTY in a Particular PIN CODE for NON-Active Customers
    public static Object getPinCodeWiseNonActiveAssets() {
        try {
            Map<String, Date> dates = new Map<String, Date>();
            dates.put('x90days', System.today().addDays(-90));
            dates.put('x180days', System.today().addDays(-180));

            return getNonActiveCustomers(dates);

            // Map<String, List<Map<String, Object>>> result = getNonActiveCustomers(dates);

            /*
            Map<String, Integer> finalResult = new Map<String, Integer>();
            for(String key : result.keySet()) {
                for(Map<String, Object> asset : result.get(key)) {
                    String pinCodeName = (String) asset.get('pinCodeName');
                    String serviceEngineerName = (String) asset.get('serviceEngineerName');

                    String mapKey = pinCodeName + '-' + serviceEngineerName;
                    if(finalResult.containsKey(mapKey)) {
                        finalResult.put(mapKey, finalResult.get(mapKey) + 1);
                    } else {
                        finalResult.put(mapKey, 1);
                    }
                }
            }

            return finalResult;
            */
        }
        catch (Exception e) {
            System.debug('❌ Error in getPinCodeWiseNonActiveAssets: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 9 - Invoicing Due after AMC PM // TODO: To be implemented
    public static string getListOfAssetsWhoseAMCDueEvenAfterPMVisit() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();
            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getListOfAssetsWhoseAMCDueEvenAfterPMVisit: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 10 - Team Attendance / Leave Plan
    public static Object getTeamAttendance() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Service_Resource_Leave__c srl : [
                SELECT Id, Name, Service_Resource__c, Service_Resource__r.Name, Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Start_Date__c, End_Date__c
                FROM Service_Resource_Leave__c
                WHERE Service_Resource__r.User__c IN :usersReportingToMe AND ((Start_Date__c >= YESTERDAY AND Start_Date__c <= NEXT_N_DAYS:7) OR (End_Date__c >= YESTERDAY AND End_Date__c <= NEXT_N_DAYS:7))
            ]) {
                Map<String, Object> leave = new Map<String, Object>();
                leave.put('id', srl.Id);
                leave.put('serviceResourceId', srl.Service_Resource__c);
                leave.put('serviceResourceName', srl.Service_Resource__r.Name);
                leave.put('userId', srl.Service_Resource__r.User__c);
                leave.put('userName', srl.Service_Resource__r.User__r.Name);
                leave.put('startDate', srl.Start_Date__c);
                leave.put('endDate', srl.End_Date__c);
                result.add(leave);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getTeamAttendance: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 11 - Engineer Tour Plan // TODO: To be implemented
    public static Object getEngineerTourPlan() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getEngineerTourPlan: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 12 - GEO Mapping // TODO: To be implemented
    public static Object getGEOMapping() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getGEOMapping: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 13 - Business Revenue
    public static Object getBusinessRevenue() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();

            Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
            String fyName = (String) fyDetails.get('fyName');

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Service_Goal__c sg : [
                SELECT Id, Name, Service_Resource__c, Financial_Year__c,
                Sales_Goal__c, Sales_Achievement__c, Sales_Achievement_Percentage__c,
                Service_Goal__c, Service_Achievement__c, Service_Achievement_Percentage__c,
                Total_Goal__c, Total_Achievement__c, Total_Achievement_Percentage__c,
                Service_Resource__r.Name, Service_Resource__r.User__c, Service_Resource__r.User__r.Name
                FROM Service_Goal__c
                WHERE Service_Resource__r.User__c IN :usersReportingToMe AND Financial_Year__c = :fyName
                ORDER BY Service_Resource__r.User__r.Name
            ]) {
                Map<String, Object> goal = new Map<String, Object>();
                goal.put('id', sg.Id);
                goal.put('name', sg.Name);
                goal.put('serviceResourceId', sg.Service_Resource__c);
                goal.put('serviceResourceName', sg.Service_Resource__r.Name);
                goal.put('userId', sg.Service_Resource__r.User__c);
                goal.put('userName', sg.Service_Resource__r.User__r.Name);
                goal.put('serviceEngineerName', sg.Service_Resource__r.User__r.Name);
                goal.put('financialYear', sg.Financial_Year__c);

                goal.put('spareGoal', sg.Sales_Goal__c);
                goal.put('spareAchieve', sg.Sales_Achievement__c);
                goal.put('sparePercentage', sg.Sales_Achievement_Percentage__c);

                goal.put('serviceGoal', sg.Service_Goal__c);
                goal.put('serviceAchieve', sg.Service_Achievement__c);
                goal.put('servicePercentage', sg.Service_Achievement_Percentage__c);

                goal.put('totalGoal', sg.Total_Goal__c);
                goal.put('totalAchieve', sg.Total_Achievement__c);
                goal.put('totalPercentage', sg.Total_Achievement_Percentage__c);

                result.add(goal);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getBusinessRevenue: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    // @AuraEnabled(cacheable=true) // 14 - AMC Business Chart
    // public static Object getAMCBusinessChart() {
    //     try {
    //         Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
    //         Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

    //         Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
    //         Date fyStartDate = (Date) fyDetails.get('start');
    //         Date fyEndDate = (Date) fyDetails.get('end');

    //         Date x90DaysBefore = System.today().addDays(-90);


    //         Decimal invoiceAmountOfNewAMCs = 0;
    //         Decimal invoiceAmountOfRenewedAMCs = 0;
    //         Decimal invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry = 0;

    //         for(Asset asset : [
    //             SELECT Id, Name, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
    //             (
    //                 SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c
    //                 FROM Asset_AMCs__r
    //                 WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null
    //             ),
    //             (
    //                 SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
    //                 FROM Asset_Warranty__r
    //                 WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
    //             )
    //             FROM Asset
    //             WHERE Pin_Code_Master__c IN :pincodeIds AND Type__c IN ('Within AMC', 'Within CAMC')
    //         ]) {
    //             if(asset.Asset_AMCs__r.size() > 0) {
    //                 if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
    //                     for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                         if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                             if(amc.AMC_PO_Value__c != null) {
    //                                 invoiceAmountOfNewAMCs += amc.AMC_PO_Value__c;
    //                             }
    //                         }
    //                     }
    //                 }
    //                 else if(asset.Asset_AMCs__r.size() > 1) {
    //                     for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                         if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                             if(amc.AMC_PO_Value__c != null) {
    //                                 invoiceAmountOfRenewedAMCs += amc.AMC_PO_Value__c;
    //                             }
    //                         }
    //                     }
    //                 }
    //                 else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
    //                     Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
    //                     Boolean isWarrantyExpiredWithinLast90Days = warranty.Warranty_End_Date__c >= x90DaysBefore;
    //                     if(isWarrantyExpiredWithinLast90Days) {
    //                         for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                             if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
    //                                 if(amc.AMC_PO_Value__c != null) {
    //                                     invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry += amc.AMC_PO_Value__c;
    //                                 }
    //                             }
    //                         }
    //                     }
    //                 }
    //             }
    //         }

    //         return new Map<String, Object> {
    //             'invoiceAmountOfNewAMCs' => invoiceAmountOfNewAMCs,
    //             'invoiceAmountOfRenewedAMCs' => invoiceAmountOfRenewedAMCs,
    //             'invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry' => invoiceAmountOfAMCWhichGotWithin90DaysOfWarrantyExpiry
    //         };
    //     }
    //     catch (Exception e) {
    //         System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }


    //

//     @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getAMCBusinessChart() {
//     try {
//         Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
//         Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

//         Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
//         Date fyStartDate = (Date) fyDetails.get('start');
//         Date fyEndDate = (Date) fyDetails.get('end');
//         Date x90DaysBefore = System.today().addDays(-90);

//         // Create a list to hold our table data
//         List<Map<String, Object>> amcTableData = new List<Map<String, Object>>();

//         // Temporary maps to hold data grouped by SE Name
//         Map<String, Decimal> newAMCsBySE = new Map<String, Decimal>();
//         Map<String, Decimal> renewedAMCsBySE = new Map<String, Decimal>();
//         Map<String, Decimal> amcWithin90DaysBySE = new Map<String, Decimal>();

//         // First pass: Collect all data grouped by SE Name
//         for(Asset asset : [
//             SELECT Id, Name, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
//             (
//                 SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c, SE_Name__r.Name
//                 FROM Asset_AMCs__r
//                 WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null
//                 ORDER BY SE_Name__r.Name
//             ),
//             (
//                 SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
//                 FROM Asset_Warranty__r
//                 WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
//             )
//             FROM Asset
//             WHERE Pin_Code_Master__c IN :pincodeIds AND Type__c IN ('Within AMC', 'Within CAMC')
//         ]) {
//             if(asset.Asset_AMCs__r.size() > 0) {
//                 for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
//                     String seName = amc.SE_Name__r != null ? amc.SE_Name__r.Name : 'Blank';

//                     if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
//                         if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
//                             // New AMC
//                             Decimal currentValue = newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0;
//                             newAMCsBySE.put(seName, currentValue + (amc.AMC_PO_Value__c != null ? amc.AMC_PO_Value__c : 0));
//                         } else if(asset.Asset_AMCs__r.size() > 1) {
//                             // Renewed AMC
//                             Decimal currentValue = renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0;
//                             renewedAMCsBySE.put(seName, currentValue + (amc.AMC_PO_Value__c != null ? amc.AMC_PO_Value__c : 0));
//                         } else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
//                             Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
//                             Boolean isWarrantyExpiredWithinLast90Days = warranty.Warranty_End_Date__c >= x90DaysBefore;
//                             if(isWarrantyExpiredWithinLast90Days) {
//                                 // AMC within 90 days of warranty expiry
//                                 Decimal currentValue = amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0;
//                                 amcWithin90DaysBySE.put(seName, currentValue + (amc.AMC_PO_Value__c != null ? amc.AMC_PO_Value__c : 0));
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         // Get all unique SE Names and sort them
//         Set<String> allSENames = new Set<String>();
//         allSENames.addAll(newAMCsBySE.keySet());
//         allSENames.addAll(renewedAMCsBySE.keySet());
//         allSENames.addAll(amcWithin90DaysBySE.keySet());
//         List<String> sortedSENames = new List<String>(allSENames);
//         sortedSENames.sort();

//         // Prepare the table data
//         for(String seName : sortedSENames) {
//             Map<String, Object> row = new Map<String, Object>{
//                 'seName' => seName,
//                 'newAMCs' => newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0,
//                 'renewedAMCs' => renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0,
//                 'amcWithin90Days' => amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0
//             };
//             amcTableData.add(row);
//         }

//         // Add a total row
//         Decimal totalNewAMCs = 0;
//         Decimal totalRenewedAMCs = 0;
//         Decimal totalAMCWithin90Days = 0;

//         for(Map<String, Object> row : amcTableData) {
//             totalNewAMCs += (Decimal)row.get('newAMCs');
//             totalRenewedAMCs += (Decimal)row.get('renewedAMCs');
//             totalAMCWithin90Days += (Decimal)row.get('amcWithin90Days');
//         }

//         Map<String, Object> totalRow = new Map<String, Object>{
//             'seName' => 'Total',
//             'newAMCs' => totalNewAMCs,
//             'renewedAMCs' => totalRenewedAMCs,
//             'amcWithin90Days' => totalAMCWithin90Days
//         };
//         amcTableData.add(totalRow);

//         return amcTableData;
//     }
//     catch (Exception e) {
//         System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
//         throw new AuraHandledException(e.getMessage());
//     }
// }

// @AuraEnabled(cacheable=true)
// public static List<Map<String, Object>> getAMCBusinessChart() {
//     try {
//         Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
//         Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

//         Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
//         Date fyStartDate = (Date) fyDetails.get('start');
//         Date fyEndDate = (Date) fyDetails.get('end');
//         Date x90DaysBefore = System.today().addDays(-90);

//         List<Map<String, Object>> amcTableData = new List<Map<String, Object>>();

//         Map<String, Decimal> newAMCsBySE = new Map<String, Decimal>();
//         Map<String, Decimal> renewedAMCsBySE = new Map<String, Decimal>();
//         Map<String, Decimal> amcWithin90DaysBySE = new Map<String, Decimal>();

//         Map<String, Integer> newAMCsCountBySE = new Map<String, Integer>();
//         Map<String, Integer> renewedAMCsCountBySE = new Map<String, Integer>();
//         Map<String, Integer> amcWithin90DaysCountBySE = new Map<String, Integer>();

//         for(Asset asset : [
//             SELECT Id, Name, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
//             (
//                 SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c, SE_Name__r.Name
//                 FROM Asset_AMCs__r
//                 WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null
//                 ORDER BY SE_Name__r.Name
//             ),
//             (
//                 SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
//                 FROM Asset_Warranty__r
//                 WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
//             )
//             FROM Asset
//             WHERE Pin_Code_Master__c IN :pincodeIds AND Type__c IN ('Within AMC', 'Within CAMC')
//         ]) {
//             if(asset.Asset_AMCs__r.size() > 0) {
//                 for(Asset_AMC__c amc : asset.Asset_AMCs__r) {
//                     String seName = amc.SE_Name__r != null ? amc.SE_Name__r.Name : 'Blank';

//                     if(amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
//                         Decimal poValue = amc.AMC_PO_Value__c != null ? amc.AMC_PO_Value__c : 0;

//                         if(asset.Asset_AMCs__r.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
//                             // New AMC
//                             newAMCsBySE.put(seName, (newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0) + poValue);
//                             newAMCsCountBySE.put(seName, (newAMCsCountBySE.get(seName) != null ? newAMCsCountBySE.get(seName) : 0) + 1);
//                         } else if(asset.Asset_AMCs__r.size() > 1) {
//                             // Renewed AMC
//                             renewedAMCsBySE.put(seName, (renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0) + poValue);
//                             renewedAMCsCountBySE.put(seName, (renewedAMCsCountBySE.get(seName) != null ? renewedAMCsCountBySE.get(seName) : 0) + 1);
//                         } else if(asset.Asset_Warranty__r.size() > 0 && asset.Asset_AMCs__r.size() == 1) {
//                             Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
//                             if(warranty.Warranty_End_Date__c >= x90DaysBefore) {
//                                 amcWithin90DaysBySE.put(seName, (amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0) + poValue);
//                                 amcWithin90DaysCountBySE.put(seName, (amcWithin90DaysCountBySE.get(seName) != null ? amcWithin90DaysCountBySE.get(seName) : 0) + 1);
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         Set<String> allSENames = new Set<String>();
//         allSENames.addAll(newAMCsBySE.keySet());
//         allSENames.addAll(renewedAMCsBySE.keySet());
//         allSENames.addAll(amcWithin90DaysBySE.keySet());
//         List<String> sortedSENames = new List<String>(allSENames);
//         sortedSENames.sort();

//         for(String seName : sortedSENames) {
//             Map<String, Object> row = new Map<String, Object>{
//                 'seName' => seName,
//                 'newAMCs' => newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0,
//                 'newAMCsCount' => newAMCsCountBySE.get(seName) != null ? newAMCsCountBySE.get(seName) : 0,
//                 'renewedAMCs' => renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0,
//                 'renewedAMCsCount' => renewedAMCsCountBySE.get(seName) != null ? renewedAMCsCountBySE.get(seName) : 0,
//                 'amcWithin90Days' => amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0,
//                 'amcWithin90DaysCount' => amcWithin90DaysCountBySE.get(seName) != null ? amcWithin90DaysCountBySE.get(seName) : 0
//             };
//             amcTableData.add(row);
//         }

//         // Total row
//         Decimal totalNewAMCs = 0, totalRenewedAMCs = 0, totalAMCWithin90Days = 0;
//         Integer totalNewAMCsCount = 0, totalRenewedAMCsCount = 0, totalAMCWithin90DaysCount = 0;

//         for(Map<String, Object> row : amcTableData) {
//             totalNewAMCs += (Decimal)row.get('newAMCs');
//             totalNewAMCsCount += (Integer)row.get('newAMCsCount');
//             totalRenewedAMCs += (Decimal)row.get('renewedAMCs');
//             totalRenewedAMCsCount += (Integer)row.get('renewedAMCsCount');
//             totalAMCWithin90Days += (Decimal)row.get('amcWithin90Days');
//             totalAMCWithin90DaysCount += (Integer)row.get('amcWithin90DaysCount');
//         }

//         Map<String, Object> totalRow = new Map<String, Object>{
//             'seName' => 'Total',
//             'newAMCs' => totalNewAMCs,
//             'newAMCsCount' => totalNewAMCsCount,
//             'renewedAMCs' => totalRenewedAMCs,
//             'renewedAMCsCount' => totalRenewedAMCsCount,
//             'amcWithin90Days' => totalAMCWithin90Days,
//             'amcWithin90DaysCount' => totalAMCWithin90DaysCount
//         };
//         amcTableData.add(totalRow);

//         return amcTableData;
//     } catch (Exception e) {
//         System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
//         throw new AuraHandledException(e.getMessage());
//     }
// }

@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getAMCBusinessChart() {
    try {
        Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
        Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

        Map<String, Object> fyDetails = UtilityCls.getCurrentFYDetails();
        Date fyStartDate = (Date) fyDetails.get('start');
        Date fyEndDate = (Date) fyDetails.get('end');
        Date x90DaysBefore = System.today().addDays(-90);

        List<Map<String, Object>> amcTableData = new List<Map<String, Object>>();

        Map<String, Decimal> newAMCsBySE = new Map<String, Decimal>();
        Map<String, Decimal> renewedAMCsBySE = new Map<String, Decimal>();
        Map<String, Decimal> amcWithin90DaysBySE = new Map<String, Decimal>();
        Map<String, Decimal> notRenewedWithin90DaysBySE = new Map<String, Decimal>();

        Map<String, Integer> newAMCsCountBySE = new Map<String, Integer>();
        Map<String, Integer> renewedAMCsCountBySE = new Map<String, Integer>();
        Map<String, Integer> amcWithin90DaysCountBySE = new Map<String, Integer>();
        Map<String, Integer> notRenewedWithin90DaysCountBySE = new Map<String, Integer>();

        for (Asset asset : [
            SELECT Id, Name, AMC_purchase_w_in_90d_of_warranty_exp__c, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
                (
                    SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Invoice__c, AMC_PO_Value__c, SE_Name__r.Name
                    FROM Asset_AMCs__r
                    WHERE AMC_PO_Value__c != null AND AMC_Start_Date__c != null AND AMC_End_Date__c != null
                    ORDER BY AMC_Start_Date__c
                ),
                (
                    SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Invoice__c, Invoice__r.Net_Invoice_Amount__c
                    FROM Asset_Warranty__r
                    WHERE Invoice__r.Net_Invoice_Amount__c != null AND Warranty_Start_Date__c != null AND Warranty_End_Date__c != null
                )
            FROM Asset
            WHERE Pin_Code_Master__c IN :pincodeIds AND Type__c IN ('Within AMC', 'Within CAMC')
        ]) {
            List<Asset_AMC__c> amcList = asset.Asset_AMCs__r;

            for (Integer i = 0; i < amcList.size(); i++) {
                Asset_AMC__c amc = amcList[i];
                String seName = amc.SE_Name__r != null ? amc.SE_Name__r.Name : 'Blank';

                if (amc.AMC_Start_Date__c >= fyStartDate && amc.AMC_Start_Date__c <= fyEndDate) {
                    Decimal poValue = amc.AMC_PO_Value__c != null ? amc.AMC_PO_Value__c : 0;

                    if (amcList.size() == 1 && asset.Asset_Warranty__r.size() == 0) {
                        // New AMC
                        newAMCsBySE.put(seName, (newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0) + poValue);
                        newAMCsCountBySE.put(seName, (newAMCsCountBySE.get(seName) != null ? newAMCsCountBySE.get(seName) : 0) + 1);
                    } else if (amcList.size() > 1) {
                        // Renewed AMC
                        renewedAMCsBySE.put(seName, (renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0) + poValue);
                        renewedAMCsCountBySE.put(seName, (renewedAMCsCountBySE.get(seName) != null ? renewedAMCsCountBySE.get(seName) : 0) + 1);
                    } else if (asset.Asset_Warranty__r.size() > 0 && amcList.size() == 1) {
                        Asset_Warranty__c warranty = asset.Asset_Warranty__r[0];
                        if (warranty.Warranty_End_Date__c >= x90DaysBefore) {
                            amcWithin90DaysBySE.put(seName, (amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0) + poValue);
                            amcWithin90DaysCountBySE.put(seName, (amcWithin90DaysCountBySE.get(seName) != null ? amcWithin90DaysCountBySE.get(seName) : 0) + 1);
                        }
                    }

                    // ✅ New logic: asset-level field for NOT renewed within 90 days
                    if (asset.AMC_purchase_w_in_90d_of_warranty_exp__c == false) {
                        notRenewedWithin90DaysBySE.put(seName, (notRenewedWithin90DaysBySE.get(seName) != null ? notRenewedWithin90DaysBySE.get(seName) : 0) + poValue);
                        notRenewedWithin90DaysCountBySE.put(seName, (notRenewedWithin90DaysCountBySE.get(seName) != null ? notRenewedWithin90DaysCountBySE.get(seName) : 0) + 1);
                    }
                }
            }
        }

        Set<String> allSENames = new Set<String>();
        allSENames.addAll(newAMCsBySE.keySet());
        allSENames.addAll(renewedAMCsBySE.keySet());
        allSENames.addAll(amcWithin90DaysBySE.keySet());
        allSENames.addAll(notRenewedWithin90DaysBySE.keySet());

        List<String> sortedSENames = new List<String>(allSENames);
        sortedSENames.sort();

        for (String seName : sortedSENames) {
            Map<String, Object> row = new Map<String, Object>{
                'seName' => seName,
                'newAMCs' => newAMCsBySE.get(seName) != null ? newAMCsBySE.get(seName) : 0,
                'newAMCsCount' => newAMCsCountBySE.get(seName) != null ? newAMCsCountBySE.get(seName) : 0,
                'renewedAMCs' => renewedAMCsBySE.get(seName) != null ? renewedAMCsBySE.get(seName) : 0,
                'renewedAMCsCount' => renewedAMCsCountBySE.get(seName) != null ? renewedAMCsCountBySE.get(seName) : 0,
                'amcWithin90Days' => amcWithin90DaysBySE.get(seName) != null ? amcWithin90DaysBySE.get(seName) : 0,
                'amcWithin90DaysCount' => amcWithin90DaysCountBySE.get(seName) != null ? amcWithin90DaysCountBySE.get(seName) : 0,
                'notRenewedWithin90Days' => notRenewedWithin90DaysBySE.get(seName) != null ? notRenewedWithin90DaysBySE.get(seName) : 0,
                'notRenewedWithin90DaysCount' => notRenewedWithin90DaysCountBySE.get(seName) != null ? notRenewedWithin90DaysCountBySE.get(seName) : 0
            };
            amcTableData.add(row);
        }

        // Totals row
        Map<String, Object> totalRow = new Map<String, Object>{
            'seName' => 'Total',
            'newAMCs' => 0,
            'newAMCsCount' => 0,
            'renewedAMCs' => 0,
            'renewedAMCsCount' => 0,
            'amcWithin90Days' => 0,
            'amcWithin90DaysCount' => 0,
            'notRenewedWithin90Days' => 0,
            'notRenewedWithin90DaysCount' => 0
        };

        for (Map<String, Object> row : amcTableData) {
            totalRow.put('newAMCs', (Decimal)totalRow.get('newAMCs') + (Decimal)row.get('newAMCs'));
            totalRow.put('newAMCsCount', (Integer)totalRow.get('newAMCsCount') + (Integer)row.get('newAMCsCount'));
            totalRow.put('renewedAMCs', (Decimal)totalRow.get('renewedAMCs') + (Decimal)row.get('renewedAMCs'));
            totalRow.put('renewedAMCsCount', (Integer)totalRow.get('renewedAMCsCount') + (Integer)row.get('renewedAMCsCount'));
            totalRow.put('amcWithin90Days', (Decimal)totalRow.get('amcWithin90Days') + (Decimal)row.get('amcWithin90Days'));
            totalRow.put('amcWithin90DaysCount', (Integer)totalRow.get('amcWithin90DaysCount') + (Integer)row.get('amcWithin90DaysCount'));
            totalRow.put('notRenewedWithin90Days', (Decimal)totalRow.get('notRenewedWithin90Days') + (Decimal)row.get('notRenewedWithin90Days'));
            totalRow.put('notRenewedWithin90DaysCount', (Integer)totalRow.get('notRenewedWithin90DaysCount') + (Integer)row.get('notRenewedWithin90DaysCount'));
        }

        amcTableData.add(totalRow);
        return amcTableData;

    } catch (Exception e) {
        System.debug('❌ Error in getAMCBusinessChart: ' + e.getLineNumber() + ' - ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}





    //


    // @AuraEnabled(cacheable=true) // 15 - Last 07 Days Case History
    // public static Object getLast7DaysCaseHistory() {
    //     try {
    //         Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
    //         Date last7Days = System.today().addDays(-7);

    //         AggregateResult casesAssignedInLast7Days = [
    //             SELECT COUNT(Id) totalCases
    //             FROM Case
    //             WHERE Assigned_Date_Time__c >= :last7Days AND Assigned_Date_Time__c <= TODAY AND OwnerId IN :usersReportingToMe
    //         ];

    //         AggregateResult casesAttendedInLast7Days = [
    //             SELECT COUNT(Case__c) totalCases
    //             FROM Service_Appointment__c
    //             WHERE Assigned_Date__c >= :last7Days AND Assigned_Date__c <= TODAY AND OwnerId IN :usersReportingToMe
    //         ];

    //         AggregateResult casesClosedInLast7Days = [
    //             SELECT COUNT(Id) totalCases
    //             FROM Case
    //             WHERE ClosedDate >= :last7Days AND ClosedDate <= TODAY AND OwnerId IN :usersReportingToMe
    //         ];

    //         AggregateResult openCasesAsOnToday = [
    //             SELECT COUNT(Id) totalCases
    //             FROM Case
    //             WHERE OwnerId IN :usersReportingToMe
    //         ];

    //         return new Map<String, Object>{
    //             'casesAssignedInLast7Days' => casesAssignedInLast7Days.get('totalCases'),
    //             'casesAttendedInLast7Days' => casesAttendedInLast7Days.get('totalCases'),
    //             'casesClosedInLast7Days' => casesClosedInLast7Days.get('totalCases'),
    //             'openCasesAsOnToday' => openCasesAsOnToday.get('totalCases')
    //         };
    //     }
    //     catch (Exception e) {
    //         System.debug('❌ Error in getLast7DaysCaseHistory: ' + e.getLineNumber() + ' - ' + e.getMessage());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getLast7DaysCaseHistory() {
    try {
        Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
        Date last7Days = System.today().addDays(-7);

        Map<String, Map<String, Object>> resultMap = new Map<String, Map<String, Object>>();

        for (AggregateResult ar : [
            SELECT Owner.Name ownerName, COUNT(Id) totalAssigned
            FROM Case
            WHERE Assigned_Date_Time__c >= :last7Days AND Assigned_Date_Time__c <= TODAY AND OwnerId IN :usersReportingToMe
            GROUP BY Owner.Name
        ]) {
            String ownerName = (String)ar.get('ownerName');
            if (!resultMap.containsKey(ownerName)) {
                resultMap.put(ownerName, new Map<String, Object>());
            }
            resultMap.get(ownerName).put('ownerName', ownerName);
            resultMap.get(ownerName).put('assigned', ar.get('totalAssigned'));
        }

        for (AggregateResult ar : [
            SELECT Owner.Name ownerName, COUNT(Case__c) totalAttended
            FROM Service_Appointment__c
            WHERE Assigned_Date__c >= :last7Days AND Assigned_Date__c <= TODAY AND OwnerId IN :usersReportingToMe
            GROUP BY Owner.Name
        ]) {
            String ownerName = (String)ar.get('ownerName');
            if (!resultMap.containsKey(ownerName)) {
                resultMap.put(ownerName, new Map<String, Object>());
            }
            resultMap.get(ownerName).put('ownerName', ownerName);
            resultMap.get(ownerName).put('attended', ar.get('totalAttended'));
        }

        for (AggregateResult ar : [
            SELECT Owner.Name ownerName, COUNT(Id) totalClosed
            FROM Case
            WHERE ClosedDate >= :last7Days AND ClosedDate <= TODAY AND OwnerId IN :usersReportingToMe
            GROUP BY Owner.Name
        ]) {
            String ownerName = (String)ar.get('ownerName');
            if (!resultMap.containsKey(ownerName)) {
                resultMap.put(ownerName, new Map<String, Object>());
            }
            resultMap.get(ownerName).put('ownerName', ownerName);
            resultMap.get(ownerName).put('closed', ar.get('totalClosed'));
        }

        for (AggregateResult ar : [
            SELECT Owner.Name ownerName, COUNT(Id) totalOpen
            FROM Case
            WHERE OwnerId IN :usersReportingToMe AND IsClosed = false
            GROUP BY Owner.Name
        ]) {
            String ownerName = (String)ar.get('ownerName');
            if (!resultMap.containsKey(ownerName)) {
                resultMap.put(ownerName, new Map<String, Object>());
            }
            resultMap.get(ownerName).put('ownerName', ownerName);
            resultMap.get(ownerName).put('open', ar.get('totalOpen'));
        }

        return resultMap.values();
    } catch (Exception e) {
        System.debug('❌ Error in getLast7DaysCaseHistoryGroupedByOwner: ' + e.getLineNumber() + ' - ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}



    @AuraEnabled(cacheable=true) // 16 - List of OPEN Cases for Reason other than "WAITING FOR CUSTOMER PO"
    public static Object getListOfOpenCases() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeIds = UtilityCls.getPincodeListAssignedToMe();

            List<Case> casesAssignedToMyTeam = [
                SELECT Id
                FROM Case
                WHERE OwnerId IN :usersReportingToMe AND IsClosed = false
            ];

            List<Quote> openQuotes = [
                SELECT Id, Opportunity.Case__c
                FROM Quote
                WHERE Opportunity.Case__c IN :casesAssignedToMyTeam AND Status IN ('Presented', 'Negotiation')
            ];
            Set<Id> caseIdsWhereQuoteIsAccepted = new Set<Id>();
            for(Quote q : openQuotes) {
                caseIdsWhereQuoteIsAccepted.add(q.Opportunity.Case__c);
            }

            List<Case> listOfOpenCaseWhereQuoteIsNotAccepted = [
                SELECT Id, CaseNumber, AccountId, Account.Name, CreatedDate, Status, Assigned_Date_Time__c, OwnerId, Owner.Name
                FROM Case
                WHERE OwnerId IN :usersReportingToMe AND Id NOT IN :caseIdsWhereQuoteIsAccepted AND IsClosed = false
            ];

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Case c : listOfOpenCaseWhereQuoteIsNotAccepted) {
                result.add(new Map<String, Object> {
                    'id' => c.Id,
                    'caseNumber' => c.CaseNumber,
                    'accountId' => c.AccountId,
                    'accountName' => c.Account.Name,
                    'createdDate' => c.CreatedDate,
                    'status' => c.Status,
                    'assignedDateTime' => c.Assigned_Date_Time__c,
                    'ownerId' => c.OwnerId,
                    'ownerName' => c.Owner.Name
                });
            }

            return result;
        }
        catch(Exception e) {
            System.debug('❌ Error in getListOfOpenCases: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
public static List<Map<String, String>> getOpenCasesOlderThan4Days() {
    try {
        Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
        Date fourDaysAgo = System.today().addDays(-4);

        List<Map<String, String>> result = new List<Map<String, String>>();

        List<Case> oldOpenCases = [
            SELECT Id, CaseNumber, Account.Name, Priority, Status, Owner.Name
            FROM Case
            WHERE Status != 'Closed'
            AND CreatedDate <= :fourDaysAgo
            AND OwnerId IN :usersReportingToMe
        ];

        for (Case c : oldOpenCases) {
            Map<String, String> row = new Map<String, String>();
            row.put('serviceEngineer', c.Owner.Name);
            row.put('caseNumber', c.CaseNumber);
            row.put('customerName', c.Account != null ? c.Account.Name : '');
            row.put('casePriority', c.Priority);
            row.put('caseStage', c.Status);
            result.add(row);
        }

        return result;
    } catch (Exception e) {
        System.debug('❌ Error in getOpenCasesOlderThan4Days: ' + e.getLineNumber() + ' - ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}


    @AuraEnabled(cacheable=true)
    public static List<Pending_Order__c> getPendingOrders() {
        try {
            Set<Id> userIdsReportingToMe = UtilityCls.getUserIdsReportingToMe();

            Set<String> sapOrderNumbers = new Set<String>();
            for(Quote qt : [
                SELECT SAP_Order_No__c
                FROM Quote
                WHERE SAP_Order_No__c != null AND Opportunity.OwnerId IN :userIdsReportingToMe AND Expected_Close_Date__c = THIS_YEAR
                ]
            ) {
                sapOrderNumbers.add(qt.SAP_Order_No__c);
            }

            return [
                SELECT Id, Name, Sale_Order_Number__c, Customer_Purchase_Order_Date__c,
                    Customer_Name__c, Customer_Name__r.Name, Delivery_Status__c,Document_Amount__c
                FROM Pending_Order__c
                WHERE Sale_Order_Number__c IN :sapOrderNumbers
                ORDER BY Customer_Purchase_Order_Date__c ASC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching pending orders: ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) 
    public static Object getListOfReturnableSampleQuoteLineItemsRSMWise() {
        try {
            return FieldServiceSEDashboardController.getListOfReturnableSampleQuoteLineItems();
        }
        catch (Exception e) {
            System.debug('❌ Error in getWarrantyToOutOfWarranty: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }



}