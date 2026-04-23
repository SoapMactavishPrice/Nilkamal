public class ServiceAppointmentHandler {

    public static void generateUniqueKey(List<Service_Appointment__c> serviceAppointments) {
        for(Service_Appointment__c sa : serviceAppointments) {
            sa.Unique_Key__c = sa.Case__c + '-' + sa.OwnerId + '-' + sa.Scheduled_Start__c.format('ddMMyyyy') + '-' + sa.Remote_Support__c;
        }
    }

    public static void rollUpOwnerToCaseTeam(List<Service_Appointment__c> serviceAppointments, Map<Id, Service_Appointment__c> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        for (Service_Appointment__c sa : serviceAppointments) {
            if(oldMap == null) {
                oldMap = new Map<Id, Service_Appointment__c>();
            }
            if (oldMap.containsKey(sa.Id)) {
                if (sa.OwnerId != oldMap.get(sa.Id).OwnerId) {
                    caseIds.add(sa.Case__c);
                }
            } else {
                caseIds.add(sa.Case__c);
            }
        }
        if(caseIds.isEmpty()) {
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        Map<String, Case_Team__c> caseTeamMap = new Map<String, Case_Team__c>();
        for(Case_Team__c ct : [SELECT Case__c, Member__c FROM Case_Team__c WHERE Case__c IN :caseIds]) {
            caseTeamMap.put(ct.Case__c + '-' + ct.Member__c, ct);
        }

        List<Case_Team__c> caseTeamToInsert = new List<Case_Team__c>();
        for(Service_Appointment__c sa : serviceAppointments) {
            Boolean isNewOrUpdated = false;
            if(oldMap.containsKey(sa.Id)) {
                if(sa.OwnerId != oldMap.get(sa.Id).OwnerId) {
                    isNewOrUpdated = true;
                }
            } else {
                isNewOrUpdated = true;
            }

            if(isNewOrUpdated) {
                String key = sa.Case__c + '-' + sa.OwnerId;
                if(caseTeamMap.containsKey(key) == false && caseMap.get(sa.Case__c).OwnerId != sa.OwnerId) {
                    Case_Team__c ct = new Case_Team__c();
                    ct.Case__c = sa.Case__c;
                    ct.Member__c = sa.OwnerId;
                    ct.Access_Level__c = 'Read';
                    ct.Case_Team_Role__c = 'Support Agent';
                    caseTeamMap.put(key, ct);
                    caseTeamToInsert.add(ct);
                }
            }
        }

        if(!caseTeamToInsert.isEmpty()) {
            insert caseTeamToInsert;
        }
    }


    public static void updateStatus(List<Service_Appointment__c> serviceAppointments) {
        for (Service_Appointment__c sa : serviceAppointments) {
            sa.Status__c = 'In Progress';
        }
    }


    public static void updateStatus(List<Service_Appointment__c> serviceAppointments, Map<Id, Service_Appointment__c> oldMap) {
        for (Service_Appointment__c sa : serviceAppointments) {
            if (sa.Check_In_GeoLocation__Latitude__s != oldMap.get(sa.Id).Check_In_GeoLocation__Latitude__s ||
                sa.Check_In_GeoLocation__Longitude__s != oldMap.get(sa.Id).Check_In_GeoLocation__Longitude__s) {
                    sa.Status__c = 'In Progress';
            }
            if(sa.Check_Out_GeoLocation__Latitude__s != oldMap.get(sa.Id).Check_Out_GeoLocation__Latitude__s ||
                sa.Check_Out_GeoLocation__Longitude__s != oldMap.get(sa.Id).Check_Out_GeoLocation__Longitude__s) {
                    sa.Status__c = 'Completed';
            }
        }
    }


    public static void manageSharingOnInsert(List<Service_Appointment__c> saRecords) {
        Set<Id> caseIds = new Set<Id>();
        for (Service_Appointment__c sa : saRecords) {
            caseIds.add(sa.Case__c);
        }
        if (caseIds.isEmpty()) {
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        Map<String, Case_Team__c> caseTeamMap = new Map<String, Case_Team__c>();

        for (Case_Team__c ct : [SELECT Case__c, Member__c FROM Case_Team__c WHERE Case__c IN :caseIds]) {
            caseTeamMap.put(ct.Case__c + '-' + ct.Member__c, ct);
        }

        List<Case_Team__c> caseTeamToInsert = new List<Case_Team__c>();
        for (Service_Appointment__c sa : saRecords) {
            String key = sa.Case__c + '-' + sa.OwnerId;
            System.debug('key ' + key);
            System.debug('caseTeamMap.containsKey(key) ' + caseTeamMap.containsKey(key) + caseTeamMap);
            System.debug('caseMap.get(sa.Case__c).OwnerId ' + caseMap.containsKey(sa.Case__c) + caseMap);
            System.debug('sa.OwnerId ' + sa.OwnerId);
            if (!caseTeamMap.containsKey(key) && caseMap.get(sa.Case__c).OwnerId != sa.OwnerId) {
                Case_Team__c ct = new Case_Team__c();
                ct.Case__c = sa.Case__c;
                ct.Member__c = sa.OwnerId;
                ct.Access_Level__c = 'Read';
                ct.Case_Team_Role__c = 'Support Agent';
                caseTeamMap.put(key, ct);
                caseTeamToInsert.add(ct);
            }
        }

        if (!caseTeamToInsert.isEmpty()) {
            insert caseTeamToInsert;
        }
    }


    public static void updateGeoLocation(List<Service_Appointment__c> serviceAppointments, Map<Id, Service_Appointment__c> oldMap) {
        Map<Id, Map<String, Double>> assetMap = new Map<Id, Map<String, Double>>();
        for (Service_Appointment__c eachSa:serviceAppointments) {
            System.debug('eachSa ' + eachSa.Check_In_GeoLocation__c + ' ' + oldMap.get(eachSa.Id).Check_In_GeoLocation__c);
            // if(eachSa.Check_In_GeoLocation__c != oldMap.get(eachSa.Id).Check_In_GeoLocation__c) {
                if (eachSa.Is_Asset_GeoLocation_Populated__c == false) {
                    if (eachSa.case__c != null) {
                        assetMap.put(eachSa.case__c, new Map<String, Double> {
                            'latitude' => eachSa.Check_In_GeoLocation__latitude__s,
                            'longitude' =>  eachSa.Check_In_GeoLocation__longitude__s});
                    }
                }
            // }
        }

        List<case> cases = [SELECT Id, AssetId FROM Case WHERE Id IN :assetMap.keySet()];

        for (case eachCase:cases) {
            Map<String, Double> location = assetMap.get(eachCase.Id);
            assetMap.remove(eachCase.Id);
            assetMap.put(eachCase.AssetId, location);
        }

        if (!assetMap.isEmpty()) {
            List<Asset> toBeUpdatedAsset = new List<Asset>();
            for (Id eachAsset:assetMap.keySet()) {
                Asset asset = new Asset();
                asset.Id = eachAsset;
                asset.Asset_GeoLocation__Latitude__s = assetMap.get(eachAsset).get('latitude');
                asset.Asset_GeoLocation__Longitude__s = assetMap.get(eachAsset).get('longitude');
                toBeUpdatedAsset.add(asset);
            }
            UPDATE toBeUpdatedAsset;
        }
    }


    public static void updateAccountInAsset(List<Service_Appointment__c> serviceAppointments, Map<Id, Service_Appointment__c> oldMap) {
        Map<Id, Id> assetAccountMap = new Map<Id, Id>();
        for (Service_Appointment__c eachSa:serviceAppointments) {
            if(eachSa.Account__c != null && eachSa.case__c != null && (eachSa.Account__c != oldMap.get(eachSa.Id).Account__c)) {
                if (eachSa.Is_End_Customer_Populated__c) {
                    System.debug('Success Condition');
                    System.debug('Case');
                    System.debug(eachSa.case__c);
                    System.debug('Account');
                    System.debug(eachSa.Account__c);

                    assetAccountMap.put(eachSa.case__c, eachSa.Account__c);
                }
                else{
                    System.debug('Failed Condition');
                }
            }
        }
        if (assetAccountMap.isEmpty()) {
            System.debug('Empty map');
            return;
        }
        System.debug('Near Query');
        List<case> cases = [SELECT Id, AssetId FROM Case WHERE Id IN :assetAccountMap.keySet()];
        for (case eachCase:cases) {
            Id acc = assetAccountMap.get(eachCase.Id);
            assetAccountMap.remove(eachCase.Id);
            assetAccountMap.put(eachCase.AssetId, acc);
        }
        updateAssetAccount(assetAccountMap);
    }

    private static void updateAssetAccount(Map<Id, Id> assetAccountMap) {
        List<Asset> toBeUpdatedAssets = new List<Asset>();
        for (Id assetId:assetAccountMap.keySet()) {
            Asset asset = new Asset();
            asset.Id = assetId;
            asset.End_Customer__c = assetAccountMap.get(assetId);
            toBeUpdatedAssets.add(asset);
        }
        UPDATE toBeUpdatedAssets;
    }
}