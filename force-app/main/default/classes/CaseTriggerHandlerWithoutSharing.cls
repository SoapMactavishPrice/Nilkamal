public without sharing class CaseTriggerHandlerWithoutSharing {

    public static void checkoutAppointmentsWhenCaseIsTransferred(List<Case> newRecords, Map<Id, Case> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        for (Case c : newRecords) {
            if(c.OwnerId != oldMap.get(c.Id).OwnerId) {
                caseIds.add(c.Id);
            }
        }

        if(caseIds.isEmpty()) {
            return;
        }

        map<Id, Service_Appointment__c> saMapToUpdate = new map<Id, Service_Appointment__c>();
        List<Service_Appointment_Check_In_and_Out__c> saCheckInOutList = new List<Service_Appointment_Check_In_and_Out__c>();
        for(Service_Appointment_Check_In_and_Out__c record : [
            SELECT Id, Service_Appointment__c
            FROM Service_Appointment_Check_In_and_Out__c
            WHERE Service_Appointment__r.Case__c IN :caseIds AND IsCheckedOut__c = FALSE
        ]) {
            record.Is_auto_checked_out_by_system_on_Transf__c = true;
            saCheckInOutList.add(record);

            Service_Appointment__c sa = new Service_Appointment__c();
            sa.Id = record.Service_Appointment__c;
            sa.Check_Out_Address_Error__c = 'Auto Checked Out by System on Case Transfer';
            sa.Status__c = 'Completed';
            saMapToUpdate.put(sa.Id, sa);
        }

        if(!saCheckInOutList.isEmpty()) {
            update saCheckInOutList;
        }

        if(!saMapToUpdate.isEmpty()) {
            update saMapToUpdate.values();
        }

        List<ServiceAppointmentUpdate__e> eventsToPublish = new List<ServiceAppointmentUpdate__e>();
        for(Service_Appointment__c sa : saMapToUpdate.values()) {
            eventsToPublish.add(new ServiceAppointmentUpdate__e(
                RecordId__c = sa.Id
            ));
        }

        if(!eventsToPublish.isEmpty()) {
            Database.SaveResult[] results =  EventBus.publish(eventsToPublish);
            for(Database.SaveResult result : results) {
                System.debug(result);
            }
        }
    }


    public static void updateWorkOrderOwner(List<Case> cases, Map<Id, Case> oldCaseMap) {
        Map<Id, Case> caseMap = new Map<Id, Case>();
        for (Case each:cases) {
            if(oldCaseMap == null) {
                caseMap.put(each.Id, each);
            }
            else if (each.OwnerId != oldCaseMap.get(each.Id).OwnerId) {
                caseMap.put(each.Id, each);
            }
        }
        List<Work_Order__c> wos = [SELECT Id, Case__c FROM Work_Order__c WHERE Case__c IN:caseMap.keySet()];
        List<Work_Order__c> wosToUpdate = new List<Work_Order__c>();
        for (Work_Order__c wo:wos) {
            wo.OwnerId = caseMap.get(wo.Case__c).OwnerId;
            wosToUpdate.add(wo);
        }
        if (wosToUpdate.size() > 0) {
            // update wosToUpdate;
            Database.update(wosToUpdate, true, AccessLevel.SYSTEM_MODE);
        }
    }


    public static void preventDuplicateCaseOnAsset(List<Case> newCases) {
        // 11-12-2025 Disable duplicate case check for System Admin and Integration User
        if (newCases == null || newCases.isEmpty()) return;
        User currentUser = [SELECT Id, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        String integrationUsername = 'integrationuser@nikamal.com';
        Boolean isSystemAdmin = currentUser.Profile != null && currentUser.Profile.Name == 'System Administrator';
        Boolean isIntegrationUser = currentUser.Username != null && currentUser.Username.equalsIgnoreCase(integrationUsername);
        if (isSystemAdmin || isIntegrationUser) {
        return;
        }
        // End 11-12-2025


        Set<Id> assetIds = new Set<Id>();
        for(Case c : newCases) {
            if(c.AssetId != null && c.Type != 'Preventive Maintenance') {
                assetIds.add(c.AssetId);
            }
        }

        if(assetIds.isEmpty()) return;

        Map<Id, Asset> assetMap = new Map<Id, Asset>([
            SELECT Id,
            (
                SELECT Id, CaseNumber, Status, Owner.Name, CreatedDate
                FROM Cases
                WHERE IsClosed = false
                AND Type != 'Installation'
                AND Type != 'Preventive Maintenance'
                ORDER BY CreatedDate DESC LIMIT 1
            ),
            (
                SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Asset_Warranty_PO_Status__c
                FROM Asset_Warranty__r
                WHERE Asset_Warranty_PO_Status__c = 'Active'
            ),
            (
                SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c, Asset_AMC_PO_Status__c, Product_Category_Type__c
                FROM Asset_AMCs__r
                WHERE Asset_AMC_PO_Status__c = 'Active'
            )
            FROM Asset
            WHERE Id IN :assetIds
        ]);

        for(Case c : newCases) {
            if(c.AssetId != null && assetMap.containsKey(c.AssetId) && c.Type != 'Preventive Maintenance') {
                Asset ast = assetMap.get(c.AssetId);

                if(ast.Cases != null && !ast.Cases.isEmpty()) {
                    c.addError('A case is already open for this Asset. Cannot create another case.');
                }
            }
        }
    }

}