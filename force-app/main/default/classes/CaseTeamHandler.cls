public without sharing class CaseTeamHandler {

    public static void manageSharingOnInsertUpdate(List<Case_Team__c> caseTeamRecords, Map<Id, Case_Team__c> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Case_Team__c>();
        }

        Set<Id> caseIds = new Set<Id>();
        for (Case_Team__c ct : caseTeamRecords) {
            if(oldMap.containsKey(ct.Id)) {
                if(oldMap.get(ct.Id).Member__c != ct.Member__c || oldMap.get(ct.Id).Access_Level__c != ct.Access_Level__c) {
                    caseIds.add(ct.Case__c);
                }
            }
            else {
                caseIds.add(ct.Case__c);
            }
        }
        if(caseIds.isEmpty()) {
            return;
        }


        Map<String, CaseShare> caseShareMap = new Map<String, CaseShare>();
        for(CaseShare cs : [SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel FROM CaseShare WHERE CaseId IN :caseIds AND RowCause = 'Manual'])
        {
            caseShareMap.put(cs.CaseId + '-' + cs.UserOrGroupId, cs);
        }

        Map<String, Work_Order__Share> workOrderShareMap = new Map<String, Work_Order__Share>();
        for(Work_Order__Share wos : [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Work_Order__Share WHERE Parent.Case__c IN :caseIds AND RowCause = 'Case_Team__c'])
        {
            workOrderShareMap.put(wos.ParentId + '-' + wos.UserOrGroupId, wos);
        }

        Map<String, Service_Appointment__Share> serviceAppointmentShareMap = new Map<String, Service_Appointment__Share>();
        for(Service_Appointment__Share sas : [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Service_Appointment__Share
                                            WHERE Parent.Work_Order__r.Case__c IN :caseIds AND RowCause = 'Case_Team__c'])
        {
            serviceAppointmentShareMap.put(sas.ParentId + '-' + sas.UserOrGroupId, sas);
        }


        Map<Id, List<Work_Order__c>> mapCaseIdToWorkOrders = new Map<Id, List<Work_Order__c>>();
        Map<Id, List<Service_Appointment__c>> mapCaseIdToServiceAppointments = new Map<Id, List<Service_Appointment__c>>();
        for(Work_Order__c wo : [SELECT Id, Case__c FROM Work_Order__c WHERE Case__c IN :caseIds])
        {
            if(!mapCaseIdToWorkOrders.containsKey(wo.Case__c)) {
                mapCaseIdToWorkOrders.put(wo.Case__c, new List<Work_Order__c>());
            }
            mapCaseIdToWorkOrders.get(wo.Case__c).add(wo);
        }
        for(Service_Appointment__c sa : [SELECT Id, Work_Order__r.Case__c FROM Service_Appointment__c WHERE Work_Order__r.Case__c IN :caseIds])
        {
            if(!mapCaseIdToServiceAppointments.containsKey(sa.Work_Order__r.Case__c)) {
                mapCaseIdToServiceAppointments.put(sa.Work_Order__r.Case__c, new List<Service_Appointment__c>());
            }
            mapCaseIdToServiceAppointments.get(sa.Work_Order__r.Case__c).add(sa);
        }


        List<CaseShare> caseShares = new List<CaseShare>();
        List<Work_Order__Share> workOrderShares = new List<Work_Order__Share>();
        List<Service_Appointment__Share> serviceAppointmentShares = new List<Service_Appointment__Share>();

        for (Case_Team__c ct : caseTeamRecords) {
            String key = ct.Case__c + '-' + ct.Member__c;

            CaseShare caseShare = new CaseShare();
            if(caseShareMap.containsKey(key)) {
                caseShare = caseShareMap.get(key);
            } else {
                caseShare.CaseId = ct.Case__c;
                caseShare.UserOrGroupId = ct.Member__c;
                caseShare.RowCause = 'Manual';
            }
            if(caseShare.CaseAccessLevel != ct.Access_Level__c) {
                caseShare.CaseAccessLevel = ct.Access_Level__c;
                caseShares.add(caseShare);
            }

            if(mapCaseIdToWorkOrders.containsKey(ct.Case__c)) {
                for (Work_Order__c wo : mapCaseIdToWorkOrders.get(ct.Case__c)) {
                    String workOrderKey = wo.Id + '-' + ct.Member__c;
                    Work_Order__Share workOrderShare = new Work_Order__Share();
                    if(workOrderShareMap.containsKey(workOrderKey)) {
                        workOrderShare = workOrderShareMap.get(workOrderKey);
                    } else {
                        workOrderShare.ParentId = wo.Id;
                        workOrderShare.UserOrGroupId = ct.Member__c;
                        workOrderShare.RowCause = Schema.Work_Order__Share.RowCause.Case_Team__c;
                    }
                    if(workOrderShare.AccessLevel != ct.Access_Level__c) {
                        workOrderShare.AccessLevel = ct.Access_Level__c;
                        workOrderShares.add(workOrderShare);
                    }
                }
            }

            if(mapCaseIdToServiceAppointments.containsKey(ct.Case__c)) {
                for(Service_Appointment__c sa : mapCaseIdToServiceAppointments.get(ct.Case__c)) {
                    String serviceAppointmentKey = sa.Id + '-' + ct.Member__c;
                    Service_Appointment__Share serviceAppointmentShare = new Service_Appointment__Share();
                    if(serviceAppointmentShareMap.containsKey(serviceAppointmentKey)) {
                        serviceAppointmentShare = serviceAppointmentShareMap.get(serviceAppointmentKey);
                    } else {
                        serviceAppointmentShare.ParentId = sa.Id;
                        serviceAppointmentShare.UserOrGroupId = ct.Member__c;
                        serviceAppointmentShare.RowCause = Schema.Service_Appointment__Share.RowCause.Case_Team__c;
                    }
                    if(serviceAppointmentShare.AccessLevel != ct.Access_Level__c) {
                        serviceAppointmentShare.AccessLevel = ct.Access_Level__c;
                        serviceAppointmentShares.add(serviceAppointmentShare);
                    }
                }
            }
        }

        if (caseShares.size() > 0) {
            Database.insert(caseShares, false);
        }

        if (workOrderShares.size() > 0) {
            Database.insert(workOrderShares, false);
        }

        if (serviceAppointmentShares.size() > 0) {
            Database.insert(serviceAppointmentShares, false);
        }
    }


    public static void manageSharingOnDelete(List<Case_Team__c> caseTeamRecords) {
        Set<Id> caseIds = new Set<Id>();
        for (Case_Team__c ct : caseTeamRecords) {
            caseIds.add(ct.Case__c);
        }

        Map<String, CaseShare> caseShareMap = new Map<String, CaseShare>();
        for(CaseShare cs : [SELECT Id, CaseId, UserOrGroupId, CaseAccessLevel FROM CaseShare WHERE CaseId IN :caseIds AND RowCause = 'Manual'])
        {
            caseShareMap.put(cs.CaseId + '-' + cs.UserOrGroupId, cs);
        }

        Map<String, Work_Order__Share> workOrderShareMap = new Map<String, Work_Order__Share>();
        for(Work_Order__Share wos : [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Work_Order__Share WHERE Parent.Case__c IN :caseIds AND RowCause = 'Case_Team__c'])
        {
            workOrderShareMap.put(wos.ParentId + '-' + wos.UserOrGroupId, wos);
        }

        Map<String, Service_Appointment__Share> serviceAppointmentShareMap = new Map<String, Service_Appointment__Share>();
        for(Service_Appointment__Share sas : [SELECT Id, ParentId, UserOrGroupId, AccessLevel FROM Service_Appointment__Share
                                            WHERE Parent.Work_Order__r.Case__c IN :caseIds AND RowCause = 'Case_Team__c'])
        {
            serviceAppointmentShareMap.put(sas.ParentId + '-' + sas.UserOrGroupId, sas);
        }


        Map<Id, List<Work_Order__c>> mapCaseIdToWorkOrders = new Map<Id, List<Work_Order__c>>();
        Map<Id, List<Service_Appointment__c>> mapCaseIdToServiceAppointments = new Map<Id, List<Service_Appointment__c>>();
        for(Work_Order__c wo : [SELECT Id, Case__c FROM Work_Order__c WHERE Case__c IN :caseIds])
        {
            if(!mapCaseIdToWorkOrders.containsKey(wo.Case__c)) {
                mapCaseIdToWorkOrders.put(wo.Case__c, new List<Work_Order__c>());
            }
            mapCaseIdToWorkOrders.get(wo.Case__c).add(wo);
        }
        for(Service_Appointment__c sa : [SELECT Id, Work_Order__r.Case__c FROM Service_Appointment__c WHERE Work_Order__r.Case__c IN :caseIds])
        {
            if(!mapCaseIdToServiceAppointments.containsKey(sa.Work_Order__r.Case__c)) {
                mapCaseIdToServiceAppointments.put(sa.Work_Order__r.Case__c, new List<Service_Appointment__c>());
            }
            mapCaseIdToServiceAppointments.get(sa.Work_Order__r.Case__c).add(sa);
        }


        List<CaseShare> caseSharesToDelete = new List<CaseShare>();
        List<Work_Order__Share> workOrderSharesToDelete = new List<Work_Order__Share>();
        List<Service_Appointment__Share> serviceAppointmentSharesToDelete = new List<Service_Appointment__Share>();

        for (Case_Team__c ct : caseTeamRecords) {
            if(caseShareMap.containsKey(ct.Case__c + '-' + ct.Member__c)) {
                caseSharesToDelete.add(caseShareMap.get(ct.Case__c + '-' + ct.Member__c));
            }
            if(mapCaseIdToWorkOrders.containsKey(ct.Case__c)) {
                for(Work_Order__c wo : mapCaseIdToWorkOrders.get(ct.Case__c)) {
                    if(workOrderShareMap.containsKey(wo.Id + '-' + ct.Member__c)) {
                        workOrderSharesToDelete.add(workOrderShareMap.get(wo.Id + '-' + ct.Member__c));
                    }
                }
            }

            if(mapCaseIdToServiceAppointments.containsKey(ct.Case__c)) {
                for(Service_Appointment__c sa : mapCaseIdToServiceAppointments.get(ct.Case__c)) {
                    if(serviceAppointmentShareMap.containsKey(sa.Id + '-' + ct.Member__c)) {
                        serviceAppointmentSharesToDelete.add(serviceAppointmentShareMap.get(sa.Id + '-' + ct.Member__c));
                    }
                }
            }
        }

        if(caseSharesToDelete.size() > 0) {
            Database.delete(caseSharesToDelete, false);
        }
        if(workOrderSharesToDelete.size() > 0) {
            Database.delete(workOrderSharesToDelete, false);
        }
        if(serviceAppointmentSharesToDelete.size() > 0) {
            Database.delete(serviceAppointmentSharesToDelete, false);
        }
    }


    /*
    public static void shareServiceAppointment(List<Case_Team__c> caseTeamRecords) {
        List<Service_Appointment__Share> serviceAppointmentShares = new List<Service_Appointment__Share>();

        // Collect Case IDs and User IDs
        Set<Id> caseIds = new Set<Id>();
        Map<Id, List<Id>> serviceAppointmentToUserMap = new Map<Id, List<Id>>();

        for (Case_Team__c ct : caseTeamRecords) {
            if (ct.Case__c != null) {
                caseIds.add(ct.Case__c);
                if (!serviceAppointmentToUserMap.containsKey(ct.Case__c)) {
                    serviceAppointmentToUserMap.put(ct.Case__c, new List<Id>());
                }
                serviceAppointmentToUserMap.get(ct.Case__c).add(ct.Member__c);
            }
        }

        // Query Service Appointments
        List<Service_Appointment__c> serviceAppointments = [SELECT Id, Case__c FROM Service_Appointment__c WHERE Case__c IN :caseIds];

        for (Service_Appointment__c sa : serviceAppointments) {
            List<Id> userIds = serviceAppointmentToUserMap.get(sa.Case__c);
            for (Id userId : userIds) {
                Service_Appointment__Share serviceAppointmentShare = new Service_Appointment__Share();
                serviceAppointmentShare.ParentId = sa.Id;
                serviceAppointmentShare.UserOrGroupId = userId;
                serviceAppointmentShare.AccessLevel = 'Edit'; // Adjusted AccessLevel
                serviceAppointmentShare.RowCause = Schema.Service_Appointment__Share.RowCause.Case_Team__c;
                serviceAppointmentShares.add(serviceAppointmentShare);
            }
        }

        if (!serviceAppointmentShares.isEmpty()) {
            Database.insert(serviceAppointmentShares, false);
        }
    }
    */


    public static void handleCaseTeamChange(List<Case_Team__c> newList, Map<Id, Case_Team__c> oldMap) {
        System.debug('🚀 Entered handleCaseTeamChange method');

        List<AssetShare> assetSharesToInsert = new List<AssetShare>();

        for (Case_Team__c ct : newList) {
            Case_Team__c oldCt = oldMap != null ? oldMap.get(ct.Id) : null;

            System.debug('🔍 Checking CaseTeam record: ' + ct.Id);
            System.debug('   Case Id: ' + ct.Case__c);
            System.debug('   Member: ' + ct.Member__c);
            System.debug('   Access Level: ' + ct.Access_Level__c);

            // Proceed only if Case and Member exist
            if (ct.Case__c != null && ct.Member__c != null) {
                // Fetch related Case's Asset
                Case relatedCase = [
                    SELECT Id, AssetId
                    FROM Case
                    WHERE Id = :ct.Case__c
                    LIMIT 1
                ];

                if (relatedCase.AssetId != null) {
                    System.debug('✅ Related Asset found: ' + relatedCase.AssetId);

                    AssetShare share = new AssetShare();
                    share.AssetId = relatedCase.AssetId;
                    share.UserOrGroupId = ct.Member__c;
                    share.AssetAccessLevel = ct.Access_Level__c != null ? ct.Access_Level__c : 'Read'; // default Read
                    assetSharesToInsert.add(share);
                } else {
                    System.debug('⚠️ No Asset linked to this Case.');
                }
            } else {
                System.debug('⚠️ Skipping CaseTeam record — missing Case or Member.');
            }
        }

        System.debug('🧾 Total AssetShare records to insert: ' + assetSharesToInsert.size());

        if (!assetSharesToInsert.isEmpty()) {
            try {
                insert assetSharesToInsert;
                System.debug('🎉 Successfully inserted AssetShare records: ' + assetSharesToInsert);
            } catch (DmlException e) {
                System.debug('❌ Error inserting AssetShare: ' + e.getMessage());
            }
        } else {
            System.debug('ℹ️ No AssetShare records to insert.');
        }

        System.debug('🏁 Exiting handleCaseTeamChange method');
    }

}