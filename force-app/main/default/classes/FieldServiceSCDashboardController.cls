public with sharing class FieldServiceSCDashboardController {

    /**
     * @description Get New Cases to Assign
     * @return `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object newCaseToAssign = FieldServiceSCDashboardController.getNewCaseToAssign();
     */
    @AuraEnabled(cacheable=true) // 1 - New Case to Assign
    public static Object getNewCaseToAssign() {
        try {
            Set<Id> pincodeAssignedToMe = UtilityCls.getPincodeListAssignedToMe();

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Case c : [
                SELECT Id, CaseNumber, AccountId, Account.Name, CreatedDate, Case_Pincode__c, Case_Pincode__r.Name, Asset.Pin_Code_Master__c, Asset.Pin_Code_Master__r.Name,Type
                FROM Case
                WHERE Owner.Name = 'Open Queue'
                AND (Case_Pincode__c IN :pincodeAssignedToMe OR Asset.Pin_Code_Master__c IN :pincodeAssignedToMe)
            ]) {
                Map<String, Object> caseData = new Map<String, Object>();
                caseData.put('id', c.Id);
                caseData.put('caseNumber', c.CaseNumber);
                caseData.put('accountId', c.AccountId);
                caseData.put('accountName', c.Account.Name);
                caseData.put('createdDate', c.CreatedDate);
                caseData.put('pincode', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__c : c.Asset.Pin_Code_Master__c);
                caseData.put('pincodeName', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__r.Name : c.Asset.Pin_Code_Master__r.Name);
                caseData.put('type', c.Type);
                result.add(caseData);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getNewCaseToAssign: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 2 - Re-assign a Case if engineer is on leave
    public static Object getReassignCaseIfEngineerIsOnLeave() {
        try {
            Set<Id> pincodeAssignedToMe = UtilityCls.getPincodeListAssignedToMe();

            Set<Id> setOfUserIdsWhoAreOnLeaveTodayOrTomorrow = new Set<Id>();
            Set<Id> setOfServiceResourcesWhoAreOnLeaveTodayOrTomorrow = new Set<Id>();
            for(Service_Resource_Leave__c srl : [
                SELECT Id, Service_Resource__c, Service_Resource__r.User__c, Start_Date__c, End_Date__c
                FROM Service_Resource_Leave__c
                WHERE Start_Date__c <= :Date.today() AND End_Date__c >= :Date.today()
            ]) {
                setOfUserIdsWhoAreOnLeaveTodayOrTomorrow.add(srl.Service_Resource__r.User__c);
                setOfServiceResourcesWhoAreOnLeaveTodayOrTomorrow.add(srl.Service_Resource__c);
            }

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Case c : [
                SELECT Id, CaseNumber, OwnerId, Owner.Name, Case_Pincode__c, Case_Pincode__r.Name, Asset.Pin_Code_Master__c, Asset.Pin_Code_Master__r.Name
                FROM Case
                WHERE Case_Pincode__c IN :pincodeAssignedToMe AND OwnerId IN :setOfUserIdsWhoAreOnLeaveTodayOrTomorrow
            ]) {
                Map<String, Object> caseData = new Map<String, Object>();
                caseData.put('id', c.Id);
                caseData.put('caseNumber', c.CaseNumber);
                caseData.put('ownerId', c.OwnerId);
                caseData.put('ownerName', c.Owner.Name);
                caseData.put('pincode', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__c : c.Asset.Pin_Code_Master__c);
                caseData.put('pincodeName', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__r.Name : c.Asset.Pin_Code_Master__r.Name);
                result.add(caseData);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getReassignCase: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 3 - OPEN Sale Order (Pending Dispatches) // TODO: Not implemented yet
    public static Object getOpenSaleOrder() {
        try {

            return null;
        }
        catch (Exception e) {
            System.debug('❌ Error in getOpenSaleOrder: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 4 - List of Warranty TO Out of Warranty Assets in coming 60 days (RSM Wise)
    public static Object getWarrantyToOutOfWarrantyRSMWise() {
        try {
            Date todayPlus60Days = System.today().addDays(60);

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

            Map<Id, Asset_Warranty__c> assetWiseWarrantyNearingExpire = new Map<Id, Asset_Warranty__c>();
            Set<Id> assetIdsWhoseWarrantyNearingExpire = new Set<Id>();
            for(Asset_Warranty__c aw : [
                SELECT Id, Asset__c, Warranty_Start_Date__c, Warranty_End_Date__c
                FROM Asset_Warranty__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND Warranty_End_Date__c >= TODAY AND Warranty_End_Date__c <= :todayPlus60Days
            ]) {
                assetIdsWhoseWarrantyNearingExpire.add(aw.Asset__c);
                assetWiseWarrantyNearingExpire.put(aw.Asset__c, aw);
            }

            Map<Id, Map<String, Object>> rsmDetails = new Map<Id, Map<String, Object>>();
            Map<Id, List<Map<String, Object>>> rsmWiseAssetDetails = new Map<Id, List<Map<String, Object>>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name
                FROM Asset
                WHERE Id IN :assetIdsWhoseWarrantyNearingExpire
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
                asset.put('pinCodeId', a.Pin_Code_Master__c);
                asset.put('pinCodeName', a.Pin_Code_Master__r.Name);
                if(assetWiseWarrantyNearingExpire.containsKey(a.Id)) {
                    asset.put('warrantyId', assetWiseWarrantyNearingExpire.get(a.Id).Id);
                    asset.put('warrantyStartDate', assetWiseWarrantyNearingExpire.get(a.Id).Warranty_Start_Date__c);
                    asset.put('warrantyEndDate', assetWiseWarrantyNearingExpire.get(a.Id).Warranty_End_Date__c);
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
            System.debug('❌ Error in getWarrantyToOutOfWarranty: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 5 - AMC Renewal due in coming 60 days (RSM Wise)
    public static Object getAMCRenewalRSMWiseInNext60Days() {
        try {
            Date todayPlus60Days = System.today().addDays(60);

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

            Map<Id, Asset_AMC__c> assetWiseAMCExpiringWithin60Days = new Map<Id, Asset_AMC__c>();
            Set<Id> assetIdsWhoseAMCExpiringWithin60Days = new Set<Id>();
            for(Asset_AMC__c amc : [
                SELECT Id, Asset__c, AMC_Start_Date__c, AMC_End_Date__c
                FROM Asset_AMC__c
                WHERE Asset__r.Pin_Code_Master__c IN :pincodeAssignedToMe AND AMC_End_Date__c >= TODAY AND AMC_End_Date__c <= :todayPlus60Days
            ]) {
                assetIdsWhoseAMCExpiringWithin60Days.add(amc.Asset__c);
                assetWiseAMCExpiringWithin60Days.put(amc.Asset__c, amc);
            }

            Map<Id, Map<String, Object>> rsmDetails = new Map<Id, Map<String, Object>>();
            Map<Id, List<Map<String, Object>>> rsmWiseAssetDetails = new Map<Id, List<Map<String, Object>>>();
            for(Asset a : [
                SELECT Id, SerialNumber, AccountId, Account.Name, Pin_Code_Master__c, Pin_Code_Master__r.Name,
                Service_Resource__r.User__c, Service_Resource__r.User__r.Name,
                Service_Resource__r.User__r.ManagerId, Service_Resource__r.User__r.Manager.Name
                FROM Asset
                WHERE Id IN :assetIdsWhoseAMCExpiringWithin60Days
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
                asset.put('pinCodeId', a.Pin_Code_Master__c);
                asset.put('pinCodeName', a.Pin_Code_Master__r.Name);

                if(assetWiseAMCExpiringWithin60Days.containsKey(a.Id)) {
                    Asset_AMC__c amc = assetWiseAMCExpiringWithin60Days.get(a.Id);
                    asset.put('amcId', amc.Id);
                    asset.put('amcStartDate', amc.AMC_Start_Date__c);
                    asset.put('amcEndDate', amc.AMC_End_Date__c);
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
            System.debug('❌ Error in getAMCRenewal: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 6 - Any Case OPEN more than 04 Days
    public static Object getOpenCasesForMoreThan4Days() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeAssignedToMe = UtilityCls.getPincodeListAssignedToMe();

            List<Map<String, Object>> result = new List<Map<String, Object>>();
            for(Case c : [
                SELECT Id, CaseNumber, CreatedDate, AccountId, Account.Name, AssetId, Asset.SerialNumber, Case_Pincode__c, Case_Pincode__r.Name,Assigned_Date_Time__c,
                OwnerId, Owner.Name
                FROM Case
                WHERE (OwnerId IN :usersReportingToMe OR Case_Pincode__c IN :pincodeAssignedToMe) AND Assigned_Date_Time__c >= LAST_N_DAYS:4 AND IsClosed = false
            ]) {
                Map<String, Object> caseData = new Map<String, Object>();
                caseData.put('id', c.Id);
                caseData.put('caseNumber', c.CaseNumber);
                caseData.put('accountId', c.AccountId);
                caseData.put('accountName', c.Account.Name);
                caseData.put('assetId', c.AssetId);
                caseData.put('serialNumber', c.Asset.SerialNumber);
                caseData.put('pinCodeId', c.Case_Pincode__c);
                caseData.put('pinCodeName', c.Case_Pincode__r.Name);
                caseData.put('createdDate', c.CreatedDate);
                caseData.put('assignedToId', c.OwnerId);
                caseData.put('assignedToName', c.Owner.Name);
                caseData.put('assignedDateTime', c.Assigned_Date_Time__c);
                result.add(caseData);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getOpenCases: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 7 - Last 07 Days Case History
    public static Object getLast7DaysCaseHistory() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeAssignedToMe = UtilityCls.getPincodeListAssignedToMe();
            Date last7Days = System.today().addDays(-7);

            AggregateResult casesAssignedInLast7Days = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE Assigned_Date_Time__c >= :last7Days AND Assigned_Date_Time__c <= TODAY AND (OwnerId IN :usersReportingToMe OR Case_Pincode__c IN :pincodeAssignedToMe)
            ];

            AggregateResult casesAttendedInLast7Days = [
                SELECT COUNT(Case__c) totalCases
                FROM Service_Appointment__c
                WHERE Assigned_Date__c >= :last7Days AND Assigned_Date__c <= TODAY AND OwnerId IN :usersReportingToMe
            ];

            AggregateResult casesClosedInLast7Days = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE ClosedDate >= :last7Days AND ClosedDate <= TODAY AND (OwnerId IN :usersReportingToMe OR Case_Pincode__c IN :pincodeAssignedToMe)
            ];

            AggregateResult openCasesAsOnToday = [
                SELECT COUNT(Id) totalCases
                FROM Case
                WHERE OwnerId IN :usersReportingToMe
            ];

            return new Map<String, Object>{
                'casesAssignedInLast7Days' => casesAssignedInLast7Days.get('totalCases'),
                'casesAttendedInLast7Days' => casesAttendedInLast7Days.get('totalCases'),
                'casesClosedInLast7Days' => casesClosedInLast7Days.get('totalCases'),
                'openCasesAsOnToday' => openCasesAsOnToday.get('totalCases')
            };
        }
        catch (Exception e) {
            System.debug('❌ Error in getLast7DaysCaseHistory: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true) // 8 - List of OPEN Cases for Reason other than "WAITING FOR CUSTOMER PO".
    public static Object getOpenCasesForReasonOtherThanWaitingForCustomerPO() {
        try {
            Set<Id> usersReportingToMe = UtilityCls.getUserIdsReportingToMe();
            Set<Id> pincodeAssignedToMe = UtilityCls.getPincodeListAssignedToMe();

            List<Case> casesAssignedToMyTeam = [
                SELECT Id
                FROM Case
                WHERE (OwnerId IN :usersReportingToMe OR Case_Pincode__c IN :pincodeAssignedToMe) AND IsClosed = false
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
                WHERE (OwnerId IN :usersReportingToMe OR Case_Pincode__c IN :pincodeAssignedToMe) AND Id NOT IN :caseIdsWhereQuoteIsAccepted
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
        catch (Exception e) {
            System.debug('❌ Error in getOpenCasesForReason: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
public static List<Map<String, Object>> getReassignedRequestCases() {
    try {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        for(Case c : [
            SELECT Id, CaseNumber, Account.Name, Type,
                   Case_Pincode__c, Case_Pincode__r.Name,
                   Asset.Pin_Code_Master__c, Asset.Pin_Code_Master__r.Name,
                   Asset.Product2.Name, Owner.Name, OwnerId
            FROM Case
            WHERE Reassignment_Request__c = 'Requested'
            ORDER BY CreatedDate DESC
        ]) {
            Map<String, Object> caseData = new Map<String, Object>();
            caseData.put('id', c.Id);
            caseData.put('caseNumber', c.CaseNumber);
            caseData.put('customerName', c.Account.Name);
            caseData.put('type', c.Type);
            caseData.put('pincode', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__c : c.Asset.Pin_Code_Master__c);
            caseData.put('pincodeName', String.isNotBlank(c.Case_Pincode__c) ? c.Case_Pincode__r.Name : c.Asset.Pin_Code_Master__r.Name);
            caseData.put('model', c.Asset != null ? c.Asset.Product2.Name : null);
            caseData.put('currentSE', c.Owner.Name);
            caseData.put('currentSEId', c.OwnerId);

            result.add(caseData);
        }

        return result;
    }
    catch (Exception e) {
        System.debug('❌ Error in getReassignedRequestCases: ' + e.getLineNumber() + ' - ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
    }
}


    // @AuraEnabled(cacheable=true)
    // public static List<Map<String, Object>> getProductsWithMissingLeadTime(String businessVertical) {
    //     try {
    //         List<Map<String, Object>> result = new List<Map<String, Object>>();

    //         String query = 'SELECT Id, Name, ProductCode, Business_Vertical__c, Family, IsActive ' +
    //                       'FROM Product2 ' +
    //                       'WHERE Lead_Time__c = null ';

    //         if (String.isNotBlank(businessVertical)) {
    //             query += 'AND Business_Vertical__c = :businessVertical ';
    //         }

    //         query += 'ORDER BY CreatedDate DESC';

    //         for(Product2 prod : Database.query(query)) {
    //             Map<String, Object> productData = new Map<String, Object>();
    //             productData.put('id', prod.Id);
    //             productData.put('name', prod.Name);
    //             productData.put('productCode', prod.ProductCode);
    //             productData.put('businessVertical', prod.Business_Vertical__c);
    //             productData.put('family', prod.Family);
    //             productData.put('isActive', prod.IsActive);
    //             result.add(productData);
    //         }

    //         return result;
    //     }
    //     catch (Exception e) {
    //         System.debug('❌ Error in getProductsWithMissingLeadTime: ' + e.getLineNumber() + ' - ' + e.getMessage());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getProductsWithMissingLeadTime() {
        try {
            User currentUser = [SELECT Business_Unit__c FROM User WHERE Id = :UserInfo.getUserId()];
            String userBusinessUnit = currentUser.Business_Unit__c;

            List<Map<String, Object>> result = new List<Map<String, Object>>();

            if (String.isBlank(userBusinessUnit)) {
                throw new AuraHandledException('Your user record does not have a Business Unit defined.');
            }

            for(Product2 prod : [
                SELECT Id, Name, ProductCode, Business_Vertical__c, Family, IsActive,Category__c,HSN_Code__c, HSN_Code__r.name,Description
                FROM Product2
                WHERE Lead_Time__c = null
                AND Business_Vertical__c = :userBusinessUnit AND IsActive = true AND Category__c = 'Spare'
                ORDER BY CreatedDate DESC
            ]) {
                Map<String, Object> productData = new Map<String, Object>();
                productData.put('id', prod.Id);
                productData.put('name', prod.Name);
                productData.put('productCode', prod.ProductCode);
                productData.put('businessVertical', prod.Business_Vertical__c);
                productData.put('family', prod.Family);
                productData.put('isActive', prod.IsActive);
                productData.put('category', prod.Category__c);
                productData.put('hsnCode', prod.HSN_Code__c);
                productData.put('hsnName', prod.HSN_Code__r.name);
                productData.put('description', prod.Description);
                result.add(productData);
            }

            return result;
        }
        catch (Exception e) {
            System.debug('❌ Error in getProductsWithMissingLeadTime: ' + e.getLineNumber() + ' - ' + e.getMessage());
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
        }catch (Exception e) {
            throw new AuraHandledException('Error fetching pending orders: ' + e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static Object getListOfReturnableSampleQuoteLineItemsSCWise() {
        try {
            return FieldServiceSEDashboardController.getListOfReturnableSampleQuoteLineItems();
        }
        catch (Exception e) {
            System.debug('❌ Error in getWarrantyToOutOfWarranty: ' + e.getLineNumber() + ' - ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }



}