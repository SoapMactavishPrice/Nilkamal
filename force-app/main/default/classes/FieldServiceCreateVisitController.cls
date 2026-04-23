/**
 * @author Aditya Zagade
 * @since 3 jan 2025
 *
 * @group Field Service
 */
public with sharing class FieldServiceCreateVisitController {

    public class CaseWithWarrantyWrapper {
        @AuraEnabled public Case caseRecord;
        @AuraEnabled public Decimal breakdownVisitsAllowed;
        @AuraEnabled public Decimal breakdownVisits;
    }

    @AuraEnabled
    public static List<CaseWithWarrantyWrapper> getOpenCasesList(String year, String month) {
        try {
            Date startDate = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month) + 1, 1);
            Date endDate = startDate.addMonths(1);

            List<Case> openCases = [
                SELECT Id, CaseNumber, Subject, Status, Type, Origin, Priority, AccountId, Account.Name,
                ContactId, Contact.Name, CreatedDate, Description, AssetId, Asset.SerialNumber,
                Assigned_Date_Time__c, Account.Customer_Blocked__c, Division__c, Approval_Status__c,
                (SELECT Id FROM Work_Orders__r ORDER BY CreatedDate DESC LIMIT 1),
                (SELECT Id FROM Service_Appointment__r)
                FROM Case
                WHERE IsClosed = false
                AND OwnerId = :UserInfo.getUserId()
                ORDER BY Assigned_Date_Time__c DESC, CreatedDate DESC
            ];

            Set<Id> assetIds = new Set<Id>();
            for (Case c : openCases) {
                if (c.AssetId != null) {
                    assetIds.add(c.AssetId);
                }
            }

            Map<Id, Asset_Warranty__c> warrantyMap = new Map<Id, Asset_Warranty__c>();
            if (!assetIds.isEmpty()) {
                for (Asset_Warranty__c aw : [
                    SELECT Id, Asset__c, Breakdown_Visits_Allowed__c, Breakdown_Visits__c
                    FROM Asset_Warranty__c
                    WHERE Asset__c IN :assetIds AND Asset_Warranty_PO_Status__c = 'Active' ORDER BY Warranty_Start_Date__c
                ]) {
                    warrantyMap.put(aw.Asset__c, aw);
                }
            }

            Map<Id, Asset_AMC__c> amcMap = new Map<Id, Asset_AMC__c>();
            if (!assetIds.isEmpty()) {
                for (Asset_AMC__c amc : [
                    SELECT Id, Asset__c, Breakdown_Visits_Allowed__c, Breakdown_Visits__c
                    FROM Asset_AMC__c
                    WHERE Asset__c IN :assetIds AND Asset_AMC_PO_Status__c = 'Active' ORDER BY AMC_Start_Date__c
                ]) {
                    amcMap.put(amc.Asset__c, amc);
                }
            }

            List<CaseWithWarrantyWrapper> result = new List<CaseWithWarrantyWrapper>();
            for (Case c : openCases) {
                CaseWithWarrantyWrapper wrapper = new CaseWithWarrantyWrapper();
                wrapper.caseRecord = c;

                if (warrantyMap.containsKey(c.AssetId)) {
                    Asset_Warranty__c aw = warrantyMap.get(c.AssetId);
                    wrapper.breakdownVisitsAllowed = aw.Breakdown_Visits_Allowed__c;
                    wrapper.breakdownVisits = aw.Breakdown_Visits__c == null ? 0 : aw.Breakdown_Visits__c;
                }

                if(amcMap.containsKey(c.AssetId)) {
                    Asset_AMC__c amc = amcMap.get(c.AssetId);
                    wrapper.breakdownVisitsAllowed = amc.Breakdown_Visits_Allowed__c;
                    wrapper.breakdownVisits = amc.Breakdown_Visits__c == null ? 0 : amc.Breakdown_Visits__c;
                }

                result.add(wrapper);
            }

            return result;
        } catch (Exception e) {
            System.debug('Error in getOpenCasesList: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @TestVisible
    private static Map<String, Object> checkAssetLimits(Id assetId) {
        Map<String, Object> result = new Map<String, Object>();
        String warningMessage = '';

        List<Asset_Warranty__c> warranties = [
            SELECT Breakdown_Visits__c, Breakdown_Visits_Allowed__c
            FROM Asset_Warranty__c
            WHERE Asset__c = :assetId
            AND Warranty_Start_Date__c <= TODAY
            AND Warranty_End_Date__c >= TODAY
            LIMIT 1
        ];

        List<Asset_AMC__c> amcs = [
            SELECT Breakdown_Visits__c, Breakdown_Visits_Allowed__c
            FROM Asset_AMC__c
            WHERE Asset__c = :assetId
            AND AMC_Start_Date__c <= TODAY
            AND AMC_End_Date__c >= TODAY
            LIMIT 1
        ];

        if (!warranties.isEmpty() &&
            warranties[0].Breakdown_Visits_Allowed__c != null &&
            warranties[0].Breakdown_Visits__c >= warranties[0].Breakdown_Visits_Allowed__c) {
            warningMessage = 'Warranty limit reached: ' +
                            warranties[0].Breakdown_Visits__c + '/' +
                            warranties[0].Breakdown_Visits_Allowed__c;
        }

        if (!amcs.isEmpty() &&
            amcs[0].Breakdown_Visits_Allowed__c != null &&
            amcs[0].Breakdown_Visits__c >= amcs[0].Breakdown_Visits_Allowed__c) {
            if(!String.isEmpty(warningMessage)) warningMessage += ' | ';
            warningMessage += 'AMC limit reached: ' +
                            amcs[0].Breakdown_Visits__c + '/' +
                            amcs[0].Breakdown_Visits_Allowed__c;
        }

        if(!String.isEmpty(warningMessage)) {
            result.put('warningMessage', warningMessage);
        }

        return result;
    }


    /**
     * @description Method to get service appointments
     * @param year
     * @param month
     * @return  `List<Service_Appointment__c>`
     * @exception Throws an AuraHandledException
     * @example
     * List<Service_Appointment__c> serviceAppointments = FieldServiceCreateVisitController.getServiceAppointments('2023', '1');
     */
    @AuraEnabled
    public static List<Service_Appointment__c> getServiceAppointments(String year, String month) {
        try {
            Set<Id> userIdsReportingToMe = UtilityCls.getUserIdsReportingToMe();

            Date startDate = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month) + 1, 1);
            Date endDate = startDate.addMonths(1);

            List<Service_Appointment__c> serviceAppointments;
            serviceAppointments = [SELECT Id, Remote_Support__c, Is_Additional_Resource__c, Name, OwnerId, WO_Type__c, Activity__c, Approver__c, Assigned_Date__c, Status__c,
                                Work_Order__c, Due_Date__c, Territory__c, Scheduled_Start__c,
                                Case__c, Case__r.CaseNumber, Case__r.AccountId, Case__r.Account.Name, Case__r.Asset.SerialNumber,
                                Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.MobilePhone, Case__r.Type,
                                Case__r.ContactId, Case__r.Contact.Name, Case__r.Contact.Email, Case__r.Contact.MobilePhone,
                                Case__r.Asset.Ship_to_Address__c, Case__r.Asset.Ship_To_City__c, Case__r.Asset.Ship_To_Region__c, Case__r.Asset.Ship_to_Pin__c, Case__r.Asset.Ship_to_Country__c,
                                (
                                    SELECT Id, Name, IsCheckedOut__c,
                                    Check_In_Date_Time__c, Check_In_GeoLocation__c, Check_In_GeoLocation__latitude__s, Check_In_GeoLocation__longitude__s,
                                    Check_Out_Date_Time__c, Check_Out_GeoLocation__c, Check_Out_GeoLocation__latitude__s, Check_Out_GeoLocation__longitude__s
                                    FROM Service_Appointment_Check_Ins_and_Outs__r
                                    WHERE Check_In_Date_Time__c != null AND IsCheckedOut__c = false
                                    ORDER BY CreatedDate DESC
                                    LIMIT 1
                                )
                                FROM Service_Appointment__c
                                WHERE OwnerId = :UserInfo.getUserId() AND
                                Case__r.IsClosed = false AND
                                (Case__r.OwnerId = :UserInfo.getUserId() OR Is_Additional_Resource__c = true) AND
                                Scheduled_Start__c >= :startDate AND
                                Scheduled_Start__c <= :endDate
                                ORDER BY Work_Order__r.Case__r.CreatedDate, CreatedDate DESC];

            return serviceAppointments;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to create visit
     * @param serviceAppointment
     * @return  `Service_Appointment__c`
     * @exception Throws an AuraHandledException
     * @example
     * Service_Appointment__c serviceAppointment = FieldServiceCreateVisitController.createVisit(new Service_Appointment__c());
     */
    @AuraEnabled
    public static Service_Appointment__c createVisit(Service_Appointment__c serviceAppointment) {
        try {
            insert serviceAppointment;

            Case cs = new Case();
            cs.Id = serviceAppointment.Case__c;
            cs.Is_service_appointment_created__c = true;
            update cs;

            return serviceAppointment;
        }
        catch(DmlException e) {
            String msg = '';
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg += e.getDmlMessage(i) + '\n';
            }
            throw new AuraHandledException(msg);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}