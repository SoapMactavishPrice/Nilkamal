public with sharing class createServiceAppointmentCls {
    // Wrapper class to hold Case + Warranty fields
    public class CaseWithWarrantyWrapper {
        @AuraEnabled public Case caseRecord;
        @AuraEnabled public Decimal breakdownVisitsAllowed;
        @AuraEnabled public Decimal breakdownVisits;
    }

    @AuraEnabled
    public static List<CaseWithWarrantyWrapper> getCaseRecord(String caseId) {
        try {
            // Query Cases
            List<Case> openCases = [
                SELECT Id, CaseNumber, Subject, Status, Type, Origin, Priority, AccountId, Account.Name,
                ContactId, Contact.Name, CreatedDate, Description, AssetId, Asset.SerialNumber,
                Assigned_Date_Time__c, Account.Customer_Blocked__c, Division__c, Approval_Status__c,
                (SELECT Id FROM Work_Orders__r ORDER BY CreatedDate DESC LIMIT 1),
                (SELECT Id FROM Service_Appointment__r)
                FROM Case
                WHERE IsClosed = false
                AND Id=:caseId
                ORDER BY Assigned_Date_Time__c DESC, CreatedDate DESC
            ];

            // Get all unique Asset IDs
            Set<Id> assetIds = new Set<Id>();
            for (Case c : openCases) {
                if (c.AssetId != null) {
                    assetIds.add(c.AssetId);
                }
            }

            // Map Asset ID to its related Asset_Warranty__c record
            Map<Id, Asset_Warranty__c> warrantyMap = new Map<Id, Asset_Warranty__c>();
            if (!assetIds.isEmpty()) {
                for (Asset_Warranty__c aw : [
                    SELECT Id, Asset__c, Breakdown_Visits_Allowed__c, Breakdown_Visits__c
                    FROM Asset_Warranty__c
                    WHERE Asset__c IN :assetIds
                ]) {
                    warrantyMap.put(aw.Asset__c, aw);
                }
            }

            // Build the wrapper list
            List<CaseWithWarrantyWrapper> result = new List<CaseWithWarrantyWrapper>();
            for (Case c : openCases) {
                CaseWithWarrantyWrapper wrapper = new CaseWithWarrantyWrapper();
                wrapper.caseRecord = c;

                Asset_Warranty__c aw = warrantyMap.get(c.AssetId);
                if (aw != null) {
                    wrapper.breakdownVisitsAllowed = aw.Breakdown_Visits_Allowed__c;
                    wrapper.breakdownVisits = aw.Breakdown_Visits__c == null ? 0 : aw.Breakdown_Visits__c;
                }

                result.add(wrapper);
            }

            return result;
        } catch (Exception e) {
            System.debug('Error in getOpenCasesList: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
}