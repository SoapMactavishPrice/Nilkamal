public without sharing class CaseTriggerHandler {

    public static void updateCaseType(List<Case> cases) {
        for (Case caseObj:cases) {
            if (caseObj.SuppliedEmail != null) {
                caseObj.Type = 'Breakdown';
            }
        }
    }


    public static void checkForReturnableQuotes(List<Case> cases, Map<Id, Case> oldMap) {
        Set<Id> closedCaseIds = new Set<Id>();
        for (Case caseObj : cases) {
            if((caseObj.Status == 'Closed' || caseObj.Status == 'Withdrawn' || caseObj.Status == 'Deferred')  && oldMap.get(caseObj.Id).Status != caseObj.Status) {
                closedCaseIds.add(caseObj.Id);
            }
        }

        if(!closedCaseIds.isEmpty()) {
            List<Quote> quotes = [
                SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
                FROM Quote
                WHERE Case__c IN :closedCaseIds AND Billing_Type__c = 'FOC and Returnable' AND SAP_Order_No__c != null AND Returnable_Received__c = false
            ];

            Set<Id> caseIdsWithPendingReturnables = new Set<Id>();
            for (Quote quote : quotes) {
                caseIdsWithPendingReturnables.add(quote.Case__c);
            }

            for (Case caseObj : cases) {
                if (caseIdsWithPendingReturnables.contains(caseObj.Id)) {
                    caseObj.Status.addError('Returnable sample is not yet received. Case cannot be closed.');
                }
            }
        }
    }


    public static void updateCaseAssignedDate(List<Case> caseList, Map<Id, Case> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Case>();
        }

        for (Case caseObj : caseList) {
            if(oldMap.containsKey(caseObj.Id)) {
                if(caseObj.OwnerId != oldMap.get(caseObj.Id).OwnerId) {
                    caseObj.Assigned_Date_Time__c = System.now();
                }
            }
            else {
                caseObj.Assigned_Date_Time__c = System.now();
            }
        }
    }


    public static void createWorkOrders(List<Case> newRecords) {
        List<Work_Order__c> workOrdersToInsert = new List<Work_Order__c>();
        System.debug('Starting to process the Case records');
        for (Case c : newRecords) {
            System.debug('Processing Case: ' + c.Id);
            if (c.Is_AMC_Required__c == true || c.Is_Warranty_Required__c == true) {
                System.debug('Skipping Case because AMC or Warranty is required: ' + c.Id);
                continue;
            }

            Work_Order__c wo = new Work_Order__c();
            wo.WO_Subject__c = c.Subject;
            wo.Status__c = 'New';
            wo.Case__c = c.Id;
            wo.OwnerId = c.OwnerId;
            wo.WO_Description__c = c.Description;
            wo.Work_Order_Type__c = c.Type;
            wo.Work_Order_Priority__c = c.Priority;
            wo.Work_Order_Start_Date__c = System.today();
            System.debug('Work Order created: ' + wo);
            workOrdersToInsert.add(wo);
        }

        if (!workOrdersToInsert.isEmpty()) {
            System.debug('Inserting Work Orders: ' + workOrdersToInsert.size());
            insert workOrdersToInsert;
        }else {
            System.debug('No Work Orders to insert');
        }
    }


    public static void updateCaseTerritoryAndPincode(List<Case> caseList) {
        List<Id> assetIds = new List<Id>();
        for (Case caseObj : caseList) {
            if(caseObj.AssetId != null && (caseObj.Division__c == null || caseObj.Case_Territory__c == null || caseObj.Case_Pincode__c == null)) {
                assetIds.add(caseObj.AssetId);
            }
        }

        if(assetIds.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>();
            if(assetIds.size() > 0) {
                assetMap = new Map<Id, Asset>([SELECT Id, Territory_Master__c, Pin_Code_Master__c, Business_Vertical__c FROM Asset WHERE Id IN :assetIds]);
            }

            for (Case caseObj : caseList) {
                if(assetMap.containsKey(caseObj.AssetId)) {
                    Asset asset = assetMap.get(caseObj.AssetId);

                    caseObj.Division__c = asset.Business_Vertical__c;

                    if(asset.Territory_Master__c != null) {
                        caseObj.Case_Territory__c = assetMap.get(caseObj.AssetId).Territory_Master__c;
                    }
                    if(asset.Pin_Code_Master__c != null) {
                        caseObj.Case_Pincode__c = assetMap.get(caseObj.AssetId).Pin_Code_Master__c;
                    }
                }
            }
        }
    }


    /*
    public static void customCaseAssignmentByTerritory(List<Case> newRecords, Map<Id, Case> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Case>();
        }

        Id openQueueId;
        // Map<Id, User> usersById = DataCls.getUsersById();
        Map<String, Group> groupsByName = DataCls.getGroupsByName();
        if(groupsByName.containsKey('Open Queue')) {
            openQueueId = groupsByName.get('Open Queue').Id;
        } else {
            throw new CustomException('Open Queue not found.');
        }

        Set<Id> assetIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> territoryIds = new Set<Id>();
        Map<Id, Id> caseWiseTerritory = new Map<Id, Id>();
        for(Case c : newRecords) {
            caseWiseTerritory.put(c.Id, c.Case_Territory__c);
            if(c.Case_Territory__c != null && c.OwnerId == openQueueId) {
                if(c.AssetId != null) {
                    assetIds.add(c.AssetId);
                }
                if(c.AccountId != null) {
                    accountIds.add(c.AccountId);
                }
                territoryIds.add(c.Case_Territory__c);
            }
        }

        if(territoryIds.isEmpty()) {
            return;
        }



        Set<Id> todayWorkingDayServiceResourceIds = new Set<Id>();
        String todayWeekday = DateTime.now().format('EEEE');
        List<Service_Resource_Working_Hour__c> serviceResourceWorkingHours = [SELECT Id, Name, Service_Resource__c, Weekday__c, Start_Hour__c, End_Hour__c
                                                                            FROM Service_Resource_Working_Hour__c
                                                                            WHERE Weekday__c = :todayWeekday AND
                                                                            Service_Resource__r.User__r.isActive = TRUE AND
                                                                            Service_Resource__r.isActive__c = TRUE];
        for(Service_Resource_Working_Hour__c srw : serviceResourceWorkingHours) {
            todayWorkingDayServiceResourceIds.add(srw.Service_Resource__c);
        }

        Set<Id> userIdsWhoAreOnLeaveToday = new Set<Id>();
        for(Service_Resource_Leave__c srl : [SELECT Id, Service_Resource__c, Service_Resource__r.User__c, Start_Date__c, End_Date__c
                                            FROM Service_Resource_Leave__c
                                            WHERE Service_Resource__c IN :todayWorkingDayServiceResourceIds AND
                                            Start_Date__c <= :Date.today() AND End_Date__c >= :Date.today() AND
                                            Service_Resource__r.User__r.isActive = TRUE AND Service_Resource__r.isActive__c = TRUE]
        ) {
            userIdsWhoAreOnLeaveToday.add(srl.Service_Resource__c);
        }


        Map<Id, Map<Id, Integer>> territoryWiseUserWiseCaseCount = new Map<Id, Map<Id, Integer>>();
        Map<Id, List<Service_Resource__c>> usersByTerritory = new Map<Id, List<Service_Resource__c>>();

        for(Service_Resource_Territory__c sr : [SELECT Id, Territory_Master__c, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Service_Resource__r.Role__c
                                                FROM Service_Resource_Territory__c
                                                WHERE Territory_Master__c IN :territoryIds AND Service_Resource__r.isActive__c = TRUE AND Service_Resource__r.User__r.isActive = TRUE AND Service_Resource__c NOT IN :userIdsWhoAreOnLeaveToday AND Service_Resource__c IN :todayWorkingDayServiceResourceIds
                                                ORDER BY Territory_Master__c, Service_Resource__r.User__r.Name]
        ) {
            Id territoryId = sr.Territory_Master__c;
            Id userId = sr.Service_Resource__r.User__c;

            if(!usersByTerritory.containsKey(territoryId)) {
                usersByTerritory.put(territoryId, new List<Service_Resource__c>());
            }
            usersByTerritory.get(territoryId).add(sr.Service_Resource__r);

            if(!territoryWiseUserWiseCaseCount.containsKey(territoryId)) {
                territoryWiseUserWiseCaseCount.put(territoryId, new Map<Id, Integer>());
            }
            if(!territoryWiseUserWiseCaseCount.get(territoryId).containsKey(userId)) {
                territoryWiseUserWiseCaseCount.get(territoryId).put(userId, 0);
            }
            territoryWiseUserWiseCaseCount.get(territoryId).put(userId, territoryWiseUserWiseCaseCount.get(territoryId).get(userId) + 1);
        }


        for(AggregateResult ar : [SELECT Case_Territory__c, OwnerId, COUNT(Id)
                                FROM Case
                                WHERE Case_Territory__c IN :territoryIds AND IsClosed = false AND Id NOT IN :newRecords
                                GROUP BY Case_Territory__c, OwnerId]
        ) {
            Id territoryId = (Id) ar.get('Case_Territory__c');
            Id ownerId = (Id) ar.get('OwnerId');
            Integer caseCount = (Integer) ar.get('expr0');
            if(!territoryWiseUserWiseCaseCount.containsKey(territoryId)) {
                territoryWiseUserWiseCaseCount.put(territoryId, new Map<Id, Integer>());
            }
            territoryWiseUserWiseCaseCount.get(territoryId).put(ownerId, caseCount);
        }


        for(Case c : newRecords) {
            // System.debug(caseWiseTerritory.get(c.Id) + ' ' + usersByTerritory.containsKey(caseWiseTerritory.get(c.Id)) + ' ' + JSON.serialize(usersByTerritory));
            if(c.Case_Territory__c != null && c.OwnerId == openQueueId && caseWiseTerritory.containsKey(c.Id) && usersByTerritory.containsKey(caseWiseTerritory.get(c.Id))) {
                Id territoryId = caseWiseTerritory.get(c.Id);
                List<Service_Resource__c> usersFromTerritory = usersByTerritory.get(territoryId);
                Map<Id, Integer> userWiseCaseCount = territoryWiseUserWiseCaseCount.get(territoryId);

                for(Service_Resource__c sr : usersFromTerritory) {
                    System.debug('User: ' + sr.User__c + ' Name: ' +  sr.User__r.Name + ' Case Count: ' + userWiseCaseCount.get(sr.User__c));
                }

                Integer minCaseCount = 0;
                Id userWithMinCases;
                for(Service_Resource__c sr : usersFromTerritory) {
                    if(userWiseCaseCount.containsKey(sr.User__c)) {
                        if(userWiseCaseCount.containsKey(sr.User__c)) {
                            if(minCaseCount == 0 || userWiseCaseCount.get(sr.User__c) < minCaseCount) {
                                minCaseCount = userWiseCaseCount.get(sr.User__c);
                                userWithMinCases = sr.User__c;
                            }
                        }
                    }
                    else {
                        minCaseCount = 0;
                        userWithMinCases = sr.User__c;
                    }
                }
                if(userWithMinCases != null) {
                    c.OwnerId = userWithMinCases;
                    if(userWiseCaseCount.containsKey(userWithMinCases)) {
                        userWiseCaseCount.put(userWithMinCases, userWiseCaseCount.get(userWithMinCases) + 1);
                    }
                    else {
                        userWiseCaseCount.put(userWithMinCases, 1);
                    }
                }
            }
        }
    }
    */


    public static void customCaseAssignmentByPincode(List<Case> newRecords, Map<Id, Case> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Case>();
        }

        Id openQueueId;
        Map<String, Group> groupsByName = DataCls.getGroupsByName();
        if(groupsByName.containsKey('Open Queue')) {
            openQueueId = groupsByName.get('Open Queue').Id;
        } else {
            throw new CustomException('Open Queue not found.');
        }


        set<Id> assetIds = new set<Id>();
        set<Id> pincodeIds = new set<Id>();
        Set<String> businessVerticals = new Set<String>();
        for(Case c : newRecords) {
            if(c.Case_Pincode__c != null && c.OwnerId == openQueueId) {
                if(c.AssetId != null) {
                    assetIds.add(c.AssetId);
                }
                if(c.Case_Pincode__c != null) {
                    pincodeIds.add(c.Case_Pincode__c);
                }
                if(c.Division__c != null) {
                    businessVerticals.add(c.Division__c);
                }
            }
        }

        if(pincodeIds.isEmpty()) {
            return;
        }


        Set<Id> serviceResourceWorkingInGivenPincode = new Set<Id>();
        Set<Id> userIdsWorkInGivenPincode = new Set<Id>();
        Map<Id, Id> mapOfServiceResourceAndUser = new Map<Id, Id>();
        Map<String, Map<Id, List<Id>>> verticalWiseServiceResourceIdsByPincode = new Map<String, Map<Id, List<Id>>>();
        Map<Id, String> serviceResourceIdToRole = new Map<Id, String>();

        for(Service_Resource_Pincode__c srp : [
            SELECT Id, Service_Resource__c,  Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Pin_Code_Master__c,
            Service_Resource__r.Business_Vertical__c, Service_Resource__r.Role__c
            FROM Service_Resource_Pincode__c
            WHERE Pin_Code_Master__c IN :pincodeIds AND
            Is_Active__c = TRUE AND
            Service_Resource__r.isActive__c = TRUE AND
            Service_Resource__r.User__r.isActive = TRUE AND
            Service_Resource__r.Business_Vertical__c IN :businessVerticals AND
            Service_Resource__r.Role__c IN ('Service Engineer', 'RSM', 'Coordinator', 'Service Head')
        ]) {
            serviceResourceWorkingInGivenPincode.add(srp.Service_Resource__c);
            userIdsWorkInGivenPincode.add(srp.Service_Resource__r.User__c);
            mapOfServiceResourceAndUser.put(srp.Service_Resource__c, srp.Service_Resource__r.User__c);
            mapOfServiceResourceAndUser.put(srp.Service_Resource__r.User__c, srp.Service_Resource__c);

            serviceResourceIdToRole.put(srp.Service_Resource__c, srp.Service_Resource__r.Role__c);

            if(verticalWiseServiceResourceIdsByPincode.containsKey(srp.Service_Resource__r.Business_Vertical__c)) {
                if(verticalWiseServiceResourceIdsByPincode.get(srp.Service_Resource__r.Business_Vertical__c).containsKey(srp.Pin_Code_Master__c)) {
                    verticalWiseServiceResourceIdsByPincode.get(srp.Service_Resource__r.Business_Vertical__c).get(srp.Pin_Code_Master__c).add(srp.Service_Resource__c);
                } else {
                    verticalWiseServiceResourceIdsByPincode.get(srp.Service_Resource__r.Business_Vertical__c).put(srp.Pin_Code_Master__c, new List<Id>{srp.Service_Resource__c});
                }
            } else {
                verticalWiseServiceResourceIdsByPincode.put(srp.Service_Resource__r.Business_Vertical__c, new Map<Id, List<Id>>{srp.Pin_Code_Master__c => new List<Id>{srp.Service_Resource__c}});
            }
        }

        // Set<Id> todayWorkingDayServiceResourceIds = new Set<Id>();
        // String todayWeekday = DateTime.now().format('EEEE');
        // for(Service_Resource_Working_Hour__c srw : [SELECT Id, Name, Service_Resource__c, Service_Resource__r.User__r.Name, Weekday__c, Start_Hour__c, End_Hour__c
        //                                             FROM Service_Resource_Working_Hour__c
        //                                             WHERE Service_Resource__c IN :serviceResourceWorkingInGivenPincode AND Weekday__c = :todayWeekday]) {
        //     todayWorkingDayServiceResourceIds.add(srw.Service_Resource__c);
        // }

        Set<Id> serviceResourceIdsWhoAreOnLeaveToday = new Set<Id>();
        for(Service_Resource_Leave__c srl : [SELECT Id, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Start_Date__c, End_Date__c
                                            FROM Service_Resource_Leave__c
                                            WHERE
                                            // Service_Resource__c IN :todayWorkingDayServiceResourceIds AND
                                            Start_Date__c <= :Date.today() AND End_Date__c >= :Date.today() AND
                                            Service_Resource__r.User__r.isActive = TRUE]) {
            serviceResourceIdsWhoAreOnLeaveToday.add(srl.Service_Resource__c);
        }

        /*
        Map<Id, Id> assetWiseLastCaseAttendedBy = new Map<Id, Id>();
        for(Asset a : [SELECT Id, Business_Vertical__c,
                    (SELECT Id, OwnerId FROM Cases ORDER BY CreatedDate DESC LIMIT 1)
                    FROM Asset
                    WHERE Id IN :assetIds]) {
            if(a.Cases.size() > 0) {
                assetWiseLastCaseAttendedBy.put(a.Id, a.Cases[0].OwnerId);
            }
        }
        */

        Map<Id, Map<Id, Integer>> pincodeWiseServiceResourceWiseCaseCount = new Map<Id, Map<Id, Integer>>();
        for(String division : verticalWiseServiceResourceIdsByPincode.keySet()) {
            Map<Id, List<Id>> serviceResourceIdsByPincode = verticalWiseServiceResourceIdsByPincode.get(division);
            for(Id pincodeId : serviceResourceIdsByPincode.keySet()) {
                for(Id serviceResourceId : serviceResourceIdsByPincode.get(pincodeId)) {
                    if(pincodeWiseServiceResourceWiseCaseCount.containsKey(pincodeId)) {
                        pincodeWiseServiceResourceWiseCaseCount.get(pincodeId).put(serviceResourceId, 0);
                    }
                    else {
                        pincodeWiseServiceResourceWiseCaseCount.put(pincodeId, new Map<Id, Integer>{serviceResourceId => 0});
                    }
                }
            }
        }

        for(AggregateResult ar : [SELECT Case_Pincode__c, OwnerId, COUNT(Id)
                                FROM Case
                                WHERE Case_Pincode__c IN :pincodeIds AND IsClosed = FALSE AND Id NOT IN :newRecords AND OwnerId IN :userIdsWorkInGivenPincode
                                GROUP BY Case_Pincode__c, OwnerId
                                ORDER BY Count(Id)]) {
            Id pincodeId = (Id) ar.get('Case_Pincode__c');
            Id ownerId = (Id) ar.get('OwnerId');
            Integer caseCount = (Integer) ar.get('expr0');
            System.debug('pincodeId ' + pincodeId + ' ownerId ' + ownerId + ' caseCount ' + caseCount);
            if(!pincodeWiseServiceResourceWiseCaseCount.containsKey(pincodeId)) {
                pincodeWiseServiceResourceWiseCaseCount.put(pincodeId, new Map<Id, Integer>());
            }
            if(mapOfServiceResourceAndUser.containsKey(ownerId)) {
                Id serviceResourceId = mapOfServiceResourceAndUser.get(ownerId);
                pincodeWiseServiceResourceWiseCaseCount.get(pincodeId).put(serviceResourceId, caseCount);
            }
        }


        Map<Id, Integer> userCaseCount = new Map<Id, Integer>();
        for (Id pincodeId : pincodeWiseServiceResourceWiseCaseCount.keySet()) {
            for (Id serviceResourceId : pincodeWiseServiceResourceWiseCaseCount.get(pincodeId).keySet()) {
                Id userId = mapOfServiceResourceAndUser.get(serviceResourceId);
                if(userCaseCount.containsKey(userId)) {
                    userCaseCount.put(userId, userCaseCount.get(userId) + pincodeWiseServiceResourceWiseCaseCount.get(pincodeId).get(serviceResourceId));
                }
                else {
                    userCaseCount.put(userId, pincodeWiseServiceResourceWiseCaseCount.get(pincodeId).get(serviceResourceId));
                }
            }
        }


        for(Case c : newRecords) {
            System.debug('Case c :' + c.Id + ' ' + c.Case_Pincode__c + ' ' + c.OwnerId + ' ' + c.Division__c + ' ' + openQueueId);

            if (c.Case_Pincode__c == null || c.OwnerId != openQueueId || c.Division__c == null) {
                continue;
            }

            Map<Id, List<Id>> serviceResourceIdsByPincode = verticalWiseServiceResourceIdsByPincode.get(c.Division__c);

            if(serviceResourceIdsByPincode == null || !serviceResourceIdsByPincode.containsKey(c.Case_Pincode__c)) {
                continue;
            }

            List<Id> serviceResourceIds = serviceResourceIdsByPincode.get(c.Case_Pincode__c);
            Map<Id, Integer> serviceResourceWiseCaseCount = pincodeWiseServiceResourceWiseCaseCount.get(c.Case_Pincode__c);

            List<Id> availableEngineers = new List<Id>();
            List<Id> availableRSMs = new List<Id>();
            List<Id> availableCoordinators = new List<Id>();
            List<Id> availableServiceHeads = new List<Id>();

            for(Id serviceResourceId : serviceResourceIds) {
                if(serviceResourceIdsWhoAreOnLeaveToday.contains(serviceResourceId)) {
                    continue;
                }

                String role = serviceResourceIdToRole.get(serviceResourceId);
                switch on role {
                    when 'Service Engineer' {
                        availableEngineers.add(serviceResourceId);
                    }
                    when 'RSM' {
                        availableRSMs.add(serviceResourceId);
                    }
                    when 'Coordinator' {
                        availableCoordinators.add(serviceResourceId);
                    }
                    when 'Service Head' {
                        availableServiceHeads.add(serviceResourceId);
                    }
                }
            }

            Id selectedUserId = null;
            Id selectedServiceResourceId = null;
            Integer minCaseCount = 999999999;

            List<Id> candidateResources = !availableEngineers.isEmpty() ? availableEngineers :
                                        !availableRSMs.isEmpty() ? availableRSMs :
                                        !availableCoordinators.isEmpty() ? availableCoordinators :
                                        !availableServiceHeads.isEmpty() ? availableServiceHeads : new List<Id>();

            for (Id serviceResourceId : candidateResources) {
                Integer count = serviceResourceWiseCaseCount.containsKey(serviceResourceId) ? serviceResourceWiseCaseCount.get(serviceResourceId) : 0;
                if(count < minCaseCount) {
                    minCaseCount = count;
                    selectedUserId = mapOfServiceResourceAndUser.get(serviceResourceId);
                    selectedServiceResourceId = serviceResourceId;
                }
            }

            if(selectedUserId != null) {
                c.OwnerId = selectedUserId;
                if(c.Status == 'New') {
                    c.Status = 'Assigned';
                }

                if(serviceResourceWiseCaseCount.containsKey(selectedServiceResourceId)) {
                    serviceResourceWiseCaseCount.put(selectedServiceResourceId, serviceResourceWiseCaseCount.get(selectedServiceResourceId) + 1);
                }
                else {
                    serviceResourceWiseCaseCount.put(selectedServiceResourceId, 1);
                }
            }
        }
    }


    public static void rollUpVisitCountToActiveAMCOrWarranty(List<Case> newRecords, Map<Id, Case> oldMap) {
        Set<Id> assetIds = new Set<Id>();
        for(Case c : newRecords) {
            if(c.Type == 'Preventive Maintenance' || c.Type == 'Breakdown') {
                if(c.AssetId != null) {
                    if(c.IsClosed && oldMap.containsKey(c.Id) && oldMap.get(c.Id).Status != c.Status) {
                        assetIds.add(c.AssetId);
                    }
                }
            }
        }

        if(assetIds.size() > 0) {
            Map<Id, Asset> assetMap = new Map<Id, Asset>([
                SELECT Id,
                (
                    SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c, Breakdown_Visits__c, Warranty_Visit__c
                    FROM Asset_Warranty__r
                ),
                (
                    SELECT Id, name, AMC_Start_Date__c, AMC_End_Date__c, Breakdown_Visits__c, PM_Visits__c
                    FROM Asset_AMCs__r
                )
                FROM Asset
                WHERE Id IN :assetIds
            ]);

            List<Asset_Warranty__c> warrantiesToUpdate = new List<Asset_Warranty__c>();
            List<Asset_AMC__c> amcsToUpdate = new List<Asset_AMC__c>();

            for(Case c : newRecords) {
                if(c.Type == 'Preventive Maintenance' || c.Type == 'Breakdown') {
                    if(c.AssetId != null) {
                        if(c.IsClosed && oldMap.containsKey(c.Id) && oldMap.get(c.Id).Status != c.Status) {
                            if(assetMap.containsKey(c.AssetId)) {
                                Asset a = assetMap.get(c.AssetId);
                                for(Asset_Warranty__c aw : a.Asset_Warranty__r) {
                                    if(aw.Warranty_Start_Date__c <= Date.today() && aw.Warranty_End_Date__c >= Date.today()) {
                                        if(c.Type == 'Preventive Maintenance') {
                                            if(aw.Warranty_Visit__c == null) {
                                                aw.Warranty_Visit__c = 0;
                                            }
                                            aw.Warranty_Visit__c += 1;
                                            warrantiesToUpdate.add(aw);
                                        }
                                        else if(c.Type == 'Breakdown') {
                                            if(aw.Breakdown_Visits__c == null) {
                                                aw.Breakdown_Visits__c = 0;
                                            }
                                            aw.Breakdown_Visits__c += 1;
                                            warrantiesToUpdate.add(aw);
                                        }
                                    }
                                }
                                for(Asset_AMC__c aa : a.Asset_AMCs__r) {
                                    if(aa.AMC_Start_Date__c <= Date.today() && aa.AMC_End_Date__c >= Date.today()) {
                                        if(c.Type == 'Preventive Maintenance') {
                                            if(aa.PM_Visits__c == null) {
                                                aa.PM_Visits__c = 0;
                                            }
                                            aa.PM_Visits__c += 1;
                                            amcsToUpdate.add(aa);
                                        }
                                        else if(c.Type == 'Breakdown') {
                                            if(aa.Breakdown_Visits__c == null) {
                                                aa.Breakdown_Visits__c = 0;
                                            }
                                            aa.Breakdown_Visits__c += 1;
                                            amcsToUpdate.add(aa);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if(!warrantiesToUpdate.isEmpty()) {
                Database.update(warrantiesToUpdate, true, AccessLevel.SYSTEM_MODE);
            }
            if(!amcsToUpdate.isEmpty()) {
                Database.update(amcsToUpdate, true, AccessLevel.SYSTEM_MODE);
            }

        }
    }


    public static void assignEntitlementProcess(List<Case> newRecords, Map<Id, Case> oldMap) {
        List<Entitlement> entList = [SELECT Id, Name FROM Entitlement WHERE Status = 'Active'];
        Map<String, Entitlement> entMap = new Map<String, Entitlement>();
        for(Entitlement ent : entList) {
            entMap.put(ent.Name, ent);
        }
        for(case cs : newRecords) {
            if(oldMap == null) {
                if(String.isNotBlank(cs.Division__c)) {
                    if(entMap.containsKey(cs.Division__c)) {
                        cs.entitlementId = entMap.get(cs.Division__c).Id;
                    }
                }
            }
            else if(cs.EntitlementId == null || (String.isNotBlank(cs.Division__c) && cs.Division__c != oldMap.get(cs.Id).Division__c)) {
                if(entMap.containsKey(cs.Division__c)) {
                    cs.entitlementId = entMap.get(cs.Division__c).Id;
                }
            }
        }
    }


    public static void sendEmailAndCustomNotification_Escalation(Id caseID, Id userId, String EscType) {
        Case CasesToNotify = [SELECT Id, CaseNumber, SuppliedName, owner.Name, SuppliedEmail, Subject, Status, Account.Name
                            FROM Case
                            WHERE Id = :caseID];

        user mailUser = new user();

        List<Service_Resource__c> serviceList = [SELECT Id, RSM__c, Coordinator__c
                                                FROM Service_Resource__c
                                                WHERE User__c = :userId AND (Coordinator__c != null OR RSM__c != null)];
        if(serviceList.size() > 0) {
            mailUser = [SELECT Id, Name, Email FROM User WHERE Id = :serviceList[0].Coordinator__c];
        }

        CustomNotificationType type = [SELECT Id, DeveloperName, CustomNotifTypeName, Mobile, Desktop, MasterLabel
                                    FROM CustomNotificationType
                                    WHERE DeveloperName = 'Case_Escalation'];

        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setBody('Following case ' + CasesToNotify.CaseNumber + ' has been escalated as the ' + EscType + ' has not been completed in the Scheduled Hours');
        notification.setTitle('Case Escalated');
        notification.setSenderId(UserInfo.getUserId());
        notification.setNotificationTypeId(type.Id);
        notification.setTargetId(CasesToNotify.Id);
        try {
            if(serviceList.size() > 0) {
                if(serviceList[0].Coordinator__c != null) {
                    notification.send(new Set<String> {serviceList[0].Coordinator__c});
                }
                if(serviceList[0].RSM__c != null) {
                    notification.send(new Set<String> {serviceList[0].RSM__c});
                }
            } else {
                notification.send(new Set<String> {userId});
            }
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }

        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        List<String> recipientList = new  List<String>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> ToAddresses = new List<String>();
        String strBody = '';

        if(mailUser != null) {
            //recipientList.add(mailUser.Email);
            recipientList.add('rohit.jaiswal@finesse.com');
            email.setSubject('Escalation Alert - ' + CasesToNotify.CaseNumber);
            email.setToAddresses(recipientList);

            strBody = '<p>Hi,</p> '+
                    '<p>The Following Case <b> ' + CasesToNotify.CaseNumber + ' </b> with subject <b> ' + CasesToNotify.Subject + ' ' +
                    '</b> has been Escalated as the ' + EscType + ' has not been completed in the Scheduled Hours </p>' +
                    '<p>Regards <br/>' + CasesToNotify.owner.Name + '</p>';

            email.setHtmlBody(strBody);
            mailList.add(email);

            // Messaging.sendEmail(mailList);
        }
    }


    public static void submitCaseForApprovalIfCustomerIsBlocked(List<Case> newRecords, Map<Id, Case> oldMap) {
        Set<Id> accIds = new Set<Id>();
        for(Case c : newRecords) {
            if(oldMap == null) {
                if(c.AccountId != null) {
                    accIds.add(c.AccountId);
                }
            }
            else {
                if(c.AccountId != oldMap.get(c.Id).AccountId) {
                    accIds.add(c.AccountId);
                }
            }
        }

        if(!accIds.isEmpty()) {
            Map<Id, Account> accMap = new Map<Id, Account>([SELECT Id, Name, Customer_Blocked__c FROM Account WHERE Id IN: accIds]);

            Map<String, List<User>> vhUsersDivisionWise = new Map<String, List<User>>();
            for(User u : [SELECT Id, Business_Unit__c FROM User WHERE Business_Unit__c != null AND IsActive = true AND UserRole.Name LIKE 'Service Head%']) {
                if(!vhUsersDivisionWise.containsKey(u.Business_Unit__c)) {
                    vhUsersDivisionWise.put(u.Business_Unit__c, new List<User>());
                }
                vhUsersDivisionWise.get(u.Business_Unit__c).add(u);
            }

            for(Case c : newRecords) {
                if(accMap.containsKey(c.AccountId) && accMap.get(c.AccountId).Customer_Blocked__c) {
                    if(oldMap == null) {
                        if(c.Approval_Status__c != 'Submitted') {
                            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                            req.setObjectId(c.Id);
                            req.setProcessDefinitionNameOrId('Approval_Process_for_Blocked_Customer');
                            // req.setSkipEntryCriteria(true);
                            req.setNextApproverIds(new List<Id> {vhUsersDivisionWise.get(c.Division__c)[0].Id});
                            req.setComments('The Case "' + c.CaseNumber + '" is generated against a blocked customer "' + accMap.get(c.AccountId).Name + '".');

                            Approval.ProcessResult result = Approval.process(req);
                        }
                    }
                    else {
                        if(c.AccountId != null && c.AccountId != oldMap.get(c.Id).AccountId && accMap.get(c.AccountId).Customer_Blocked__c && c.Approval_Status__c != 'Submitted') {
                            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                            req.setObjectId(c.Id);
                            req.setProcessDefinitionNameOrId('Approval_Process_for_Blocked_Customer');
                            // req.setSkipEntryCriteria(true);
                            req.setNextApproverIds(new List<Id> {vhUsersDivisionWise.get(c.Division__c)[0].Id});
                            req.setComments('The Case "' + c.CaseNumber + '" is generated against a blocked customer "' + accMap.get(c.AccountId).Name + '".');

                            Approval.ProcessResult result = Approval.process(req);
                        }
                    }
                }
            }
        }
    }


    public static void updateActivityDateToAsset(List<Case> newRecords, Map<Id, Case> oldMap) {
        Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
        for(Case c : newRecords) {
            if(oldMap == null) {
                if(c.AssetId != null) {
                    if(assetsToUpdate.containsKey(c.AssetId)) {
                        assetsToUpdate.get(c.AssetId).Last_Case_Created_Date__c = Date.valueOf(c.CreatedDate);
                    }
                    else {
                        assetsToUpdate.put(c.AssetId, new Asset(Id = c.AssetId, Last_Case_Created_Date__c = Date.valueOf(c.CreatedDate)));
                    }
                }
            }
            else {
                if(c.AssetId != null && c.AssetId != oldMap.get(c.Id).AssetId) {
                    if(assetsToUpdate.containsKey(c.AssetId)) {
                        assetsToUpdate.get(c.AssetId).Last_Case_Created_Date__c = Date.valueOf(c.CreatedDate);
                    }
                    else {
                        assetsToUpdate.put(c.AssetId, new Asset(Id = c.AssetId, Last_Case_Created_Date__c = Date.valueOf(c.CreatedDate)));
                    }
                }
                if(c.IsClosed && oldMap.get(c.Id).IsClosed == false) {
                    if(assetsToUpdate.containsKey(c.AssetId)) {
                        assetsToUpdate.get(c.AssetId).Last_Case_Closed_Date__c = System.today();
                    }
                    else {
                        assetsToUpdate.put(c.AssetId, new Asset(Id = c.AssetId, Last_Case_Closed_Date__c = System.today()));
                    }
                }
            }
        }

        if(!assetsToUpdate.isEmpty()) {
            Database.update(assetsToUpdate.values(), true, AccessLevel.SYSTEM_MODE);
        }
    }


    public static void trackTechnicalSupportHistory(List<Case> newList, Map<Id, Case> oldMap) { 
        String currentUserName = UserInfo.getName();

        for (Case cs : newList) {
            Case oldCase = oldMap.get(cs.Id);
            String history = cs.Technical_Support_History__c != null ? cs.Technical_Support_History__c : '';
            String formattedDate = Datetime.now().format('MMMM d, yyyy - h:mm a');
            String newEntry = '';

            // Check Response changes
            if (cs.Technical_Support_Response__c != oldCase.Technical_Support_Response__c
                && cs.Technical_Support_Response__c != null) {
                newEntry += formattedDate + '\n' +
                        currentUserName + ' updated Response:\n' +
                        '▶ ' + String.valueOf(cs.Technical_Support_Response__c) + '\n\n';
            }

            // Check SE Comment changes
            if (cs.Technical_Support_SE_Comment__c != oldCase.Technical_Support_SE_Comment__c
                && cs.Technical_Support_SE_Comment__c != null) {
                newEntry += formattedDate + '\n' +
                        currentUserName + ' updated SE Comment:\n' +
                        '▶ ' + String.valueOf(cs.Technical_Support_SE_Comment__c) + '\n\n';
            }

            if (!String.isBlank(newEntry)) {
                // Add new entry at the beginning of history (most recent first)
                history = newEntry + history;
                cs.Technical_Support_History__c = history.trim();
            }
        }
    }
    // 

    //  public static void updateCaseFromChatter(Set<Id> caseIds) {
    //     if (caseIds.isEmpty()) return;
        
    //     // Get current user
    //     Id currentUserId = UserInfo.getUserId();
    //     String currentUserName = UserInfo.getName();
        
    //     // Check if user is engineer (Profile name contains 'Engineer' but NOT 'Technical')
    //     User currentUser = [SELECT Id, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1];
    //     String profileName = currentUser.Profile.Name;
    //     Boolean isEngineer = profileName.contains('System Administrator') && !profileName.contains('Technical');
        
    //     System.debug('Profile: ' + profileName + ', isEngineer: ' + isEngineer);
        
    //     if (!isEngineer) return; // Only engineers should trigger this
        
    //     List<Case> casesToUpdate = new List<Case>();
        
    //     for (Case cs : [SELECT Id, Tech_Support_Status__c,SE_Action_History__c  FROM Case WHERE Id IN :caseIds]) {
    //         system.debug('Processing Case Id: ' + cs.Id + ', Tech_Support_Status__c: ' + cs.Tech_Support_Status__c);
    //         // if (String.isBlank(cs.Tech_Support_Status__c)) {
    //             system.debug('Updating Case Id: ' + cs.Id);
    //             system.debug('before update: ' + cs.Tech_Support_Status__c);
    //             cs.Tech_Support_Status__c = 'Opened by Service Engineer';
    //             cs.Technical_Support_SE_DateTime__c = Datetime.now();
                
    //             // Add to history
    //             String history = cs.SE_Action_History__c != null ? cs.SE_Action_History__c : '';
    //             String newEntry = Datetime.now().format('MMMM d, yyyy - h:mm a') + '\n' +
    //                              currentUserName + ' posted in Chatter:\n' +
    //                              '▶ Tech Support Status: Opened by Service Engineer\n\n';
                
    //             cs.SE_Action_History__c = newEntry + history;
    //             System.debug('SE_Action_History__c: ' + history + ', newEntry: ' + newEntry + ', updatedHistory: ' + cs.SE_Action_History__c);
    //             casesToUpdate.add(cs);
    //         // }
    //     }
        
    //     if (!casesToUpdate.isEmpty()) {
    //         update casesToUpdate;
    //     }
    // }



    // public static void updateCaseFromChatter(Set<Id> caseIds) {
    //     if (caseIds == null || caseIds.isEmpty()) return;

    //     // Current user
    //     Id currentUserId = UserInfo.getUserId();
    //     String currentUserName = UserInfo.getName();

    //     User currentUser = [
    //         SELECT Id, Profile.Name
    //         FROM User
    //         WHERE Id = :currentUserId
    //         LIMIT 1
    //     ];
    //     String profileName = currentUser.Profile.Name;

    //     Boolean isServiceEngineer =
    //         (profileName.contains('Service Engineer') || profileName.contains('Service') || profileName.contains('System Administrator')) &&
    //         !profileName.contains('Technical');

    //     Boolean isTechnicalUser = profileName.contains('Technical');

    //     // If neither SE nor Technical user → exit
    //     if (!isServiceEngineer && !isTechnicalUser) return;

    //     Integer SAFE_MAX = 32700;

    //     List<Case> casesToUpdate = new List<Case>();

    //     for (Case cs : [
    //         SELECT Id,
    //             Tech_Support_Status__c,
    //             SE_Action_History__c,
    //             Tech_Action_History__c,
    //             Technical_Support_SE_DateTime__c,
    //             Technical_Support_Response_DateTime__c
    //         FROM Case
    //         WHERE Id IN :caseIds
    //     ]) {

    //         String status = cs.Tech_Support_Status__c;
    //         String timestamp = Datetime.now().format('MMMM d, yyyy - h:mm a');

    //         Boolean shouldUpdateCase = false;

    //         // For Tech_Action_History__c (common for SE + Technical)
    //         String userTypePrefix = isServiceEngineer ? 'se - ' : 'tu - ';
    //         String commonTechEntry = userTypePrefix + currentUserName + ' wrote in Chatter - ' + timestamp + '\n\n';
    //         String oldTechHistory = cs.Tech_Action_History__c != null ? cs.Tech_Action_History__c : '';
    //         String newTechHistory = commonTechEntry + oldTechHistory;

    //         // Truncate if necessary
    //         if (newTechHistory.length() > SAFE_MAX) {
    //             newTechHistory = newTechHistory.substring(0, SAFE_MAX);
    //         }
    //         cs.Tech_Action_History__c = newTechHistory;

    //         // ----------------------------
    //         // SERVICE ENGINEER LOGIC
    //         // ----------------------------
    //         if (isServiceEngineer) {

    //             if (String.isBlank(status) || status == 'Closed by Technical Support') {
    //                 system.debug('Updating status for Case Id: ' + cs.Id);

    //                 shouldUpdateCase = true;

    //                 cs.Tech_Support_Status__c = 'Opened by Service Engineer';

    //                 // If reopening from technical closed → clear datetime
    //                 if (status == 'Closed by Technical Support') {
    //                     cs.Technical_Support_Response_DateTime__c = null;
    //                 }

    //                 // Set SE open time only once
    //                 if (cs.Technical_Support_SE_DateTime__c == null) {
    //                     cs.Technical_Support_SE_DateTime__c = Datetime.now();
    //                 }

    //                 String oldSE = cs.SE_Action_History__c != null ? cs.SE_Action_History__c : '';
    //                 String newSE = timestamp + '\n' +
    //                             currentUserName + ' posted in Chatter:\n' +
    //                             '▶ Status changed to: Opened by Service Engineer\n\n';

    //                 String combinedSE = newSE + oldSE;

    //                 if (combinedSE.length() > SAFE_MAX) {
    //                     combinedSE = combinedSE.substring(0, SAFE_MAX);
    //                 }

    //                 cs.SE_Action_History__c = combinedSE;
    //             }

    //             else if (status == 'Opened by Service Engineer') {
    //                 system.debug('No status change for Case Id: ' + cs.Id);
    //                 shouldUpdateCase = true;

    //                 String oldSE = cs.SE_Action_History__c != null ? cs.SE_Action_History__c : '';
    //                 String newSE = timestamp + '\n' +
    //                             currentUserName + ' wrote in Chatter (SE)\n\n';

    //                 String combinedSE = newSE + oldSE;

    //                 if (combinedSE.length() > SAFE_MAX) {
    //                     combinedSE = combinedSE.substring(0, SAFE_MAX);
    //                 }

    //                 cs.SE_Action_History__c = combinedSE;
    //             }
    //         }

    //         // Add to update list
    //         casesToUpdate.add(cs);
    //     }

    //     if (!casesToUpdate.isEmpty()) {
    //         update casesToUpdate;
    //     }
    // }

    public static void updateCaseFromChatter(Set<Id> caseIds, Map<Id, String> chatterMessages) {
        if (caseIds == null || caseIds.isEmpty()) return;

        Id currentUserId = UserInfo.getUserId();
        String currentUserName = UserInfo.getName();

        User currentUser = [
            SELECT Id, Profile.Name
            FROM User
            WHERE Id = :currentUserId
            LIMIT 1
        ];
        String profileName = currentUser.Profile.Name;

        Boolean isServiceEngineer =
            (profileName.contains('Service Engineer') ||
            profileName.contains('Service') ||
            profileName.contains('System Administrator')) &&
            !profileName.contains('Technical');

        Boolean isTechnicalUser = profileName.contains('Technical');

        if (!isServiceEngineer && !isTechnicalUser) return;

        Integer SAFE_MAX = 32700;

        List<Case> casesToUpdate = new List<Case>();

        for (Case cs : [
            SELECT Id,
                Tech_Support_Status__c,
                Technical_Support_History__c,
                Technical_Support_SE_DateTime__c,
                Technical_Support_Response_DateTime__c
            FROM Case
            WHERE Id IN :caseIds
        ]) {

            String status = cs.Tech_Support_Status__c;
            String timestamp = Datetime.now().format('MMMM d, yyyy - h:mm a');
            Boolean shouldUpdateCase = false;

            // Get chatter message text
            String chatterText = chatterMessages.containsKey(cs.Id)
                ? chatterMessages.get(cs.Id)
                : '(no message)';

            // Prefix for SE or Technical User
            String userPrefix = isServiceEngineer ? 'se' : 'tu';

            // Build entry with actual chatter message text
            String entry =
                userPrefix + ' - ' + currentUserName + ': "' +
                chatterText + '" - ' + timestamp + '\n\n';

            // Prepend new entry
            String oldHistory = cs.Technical_Support_History__c != null ? cs.Technical_Support_History__c : '';
            String newHistory = entry + oldHistory;

            if (newHistory.length() > SAFE_MAX) {
                newHistory = newHistory.substring(0, SAFE_MAX);
            }

            cs.Technical_Support_History__c = newHistory;

            // -----------------------------
            // SERVICE ENGINEER STATUS LOGIC
            // -----------------------------
            if (isServiceEngineer) {

                // 1️⃣ FIRST TIME OPEN (status blank)
                if (String.isBlank(status)) {
                    system.debug('1status:' + status);
                    shouldUpdateCase = true;
                    cs.Tech_Support_Status__c = 'Opened by Service Engineer';
                    cs.Technical_Support_SE_DateTime__c = Datetime.now();
                    String statusEntry =
                        'se - ' + currentUserName +
                        ' changed status to "Opened by Service Engineer" - ' +
                        timestamp + '\n\n';

                    cs.Technical_Support_History__c =
                        statusEntry + cs.Technical_Support_History__c;
                }

                else if (status == 'Closed by Technical Support') {
                    system.debug('2status:' + status);
                    shouldUpdateCase = true;
                    //cs.Technical_Support_Response_DateTime__c = null;

                    // if (cs.Technical_Support_SE_DateTime__c == null) {
                    //     cs.Technical_Support_SE_DateTime__c = Datetime.now();
                    // }

                    String statusEntry =
                        'se - ' + currentUserName +
                        ' reopened the case (status set to "Opened by Service Engineer") - ' +
                        timestamp + '\n\n';

                    cs.Technical_Support_History__c =
                        statusEntry + cs.Technical_Support_History__c;
                }

                else if (status == 'Opened by Service Engineer') {
                    system.debug('3status:' + status);  
                    shouldUpdateCase = true;
                    if (cs.Technical_Support_SE_DateTime__c == null) {
                        cs.Technical_Support_SE_DateTime__c = Datetime.now();
                    }
                    cs.Technical_Support_Response_DateTime__c = null;

                }
            }

            casesToUpdate.add(cs);
        }

        update casesToUpdate;
    }










   


    
    // 


    public static void mapServiceResourceFromOwner(List<Case> cases, Map<Id, Case> oldMap) {
        if(oldMap == null) {
            oldMap = new Map<Id, Case>();
        }

        Set<Id> ownerIds = new Set<Id>();
        for(Case c : cases) {
            if(String.isBlank(c.Service_Resource__c) || (oldMap.containsKey(c.Id) && c.OwnerId != oldMap.get(c.Id).OwnerId)) {
                ownerIds.add(c.OwnerId);
            }
        }

        if(!ownerIds.isEmpty()) {
            Map<Id, Id> mapOfUserIdToServiceResourceId = new Map<Id, Id>();
            for(Service_Resource__c sr : [SELECT Id, User__c FROM Service_Resource__c]) {
                mapOfUserIdToServiceResourceId.put(sr.User__c, sr.Id);
            }

            for(Case c : cases) {
                if(mapOfUserIdToServiceResourceId.containsKey(c.OwnerId)) {
                    c.Service_Resource__c = mapOfUserIdToServiceResourceId.get(c.OwnerId);
                }
                else {
                    c.Service_Resource__c = null;
                }
            }
        }
    }


    public static void notifyUserWhenCaseIsAssignedOrTransferredOnInsert(List<Case> newRecords) {
        Boolean isApplicableForNotification = false;
        for(Case c : newRecords) {
            if(c.OwnerId != c.CreatedById) {
                isApplicableForNotification = true;
                break;
            }
        }
        if(!isApplicableForNotification) {
            return;
        }


        Id notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Assign' LIMIT 1].Id;

        for (Case c : newRecords) {
            // Skip self-assigned cases
            if (c.OwnerId == c.CreatedById) continue;

            if (isUser(c.OwnerId)) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('New Case Assigned - ' + c.CaseNumber);
                notification.setBody('Case ' + c.CaseNumber + ' has been assigned to you.');
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTargetId(c.Id);

                notification.send(new Set<String> {c.OwnerId});
            }
        }
    }


    private static Boolean isUser(Id ownerId) {
        return ownerId.getSObjectType().getDescribe().getName() == 'User';
    }


    public static void notifyUserWhenCaseIsAssignedOrTransferredOnUpdate(List<Case> newRecords, Map<Id, Case> oldMap) {
        Boolean isApplicableForNotification = false;
        for(Case c : newRecords) {
            if(c.OwnerId != oldMap.get(c.Id).OwnerId) {
                isApplicableForNotification = true;
                break;
            }
        }
        if(!isApplicableForNotification) {
            return;
        }


        Id openQueueId;
        Map<String, Group> groupsByName = DataCls.getGroupsByName();
        if(groupsByName.containsKey('Open Queue')) {
            openQueueId = groupsByName.get('Open Queue').Id;
        }

        Id notificationTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Assign' LIMIT 1].Id;

        Map<Id, User> usersById = DataCls.getUsersById();
        Map<Id, Group> groupsById = DataCls.getGroupsById();

        for (Case c : newRecords) {
            Case oldCase = oldMap.get(c.Id);

            if (c.OwnerId == oldCase.OwnerId) continue;
            if (!isUser(c.OwnerId)) continue;
            if (c.LastModifiedById == c.OwnerId) continue;

            String previousOwnerName = usersById.containsKey(oldCase.ownerId) ? usersById.get(oldCase.ownerId).Name : groupsById.containsKey(oldCase.ownerId) ? groupsById.get(oldCase.ownerId).Name : '';
            String currentUserName = usersById.containsKey(UserInfo.getUserId()) ? usersById.get(UserInfo.getUserId()).Name : '';


            if(c.OwnerId != UserInfo.getUserId()) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTargetId(c.Id);
                if(oldCase.OwnerId == openQueueId) {
                    notification.setTitle('New Case assigned - ' + c.CaseNumber);
                    notification.setBody('Case ' + c.CaseNumber + ' has been assigned to you by ' + currentUserName + '.');
                }
                else {
                    notification.setTitle('Case transferred - ' + c.CaseNumber);
                    notification.setBody('Case ' + c.CaseNumber + ' has been transferred to you by ' + currentUserName + ' from ' + previousOwnerName + '.');
                }
                notification.send(new Set<String> {c.OwnerId});
            }
        }
    }


    public static void onOwnerChangePersistSharing(List<Case> newRecords, Map<Id, Case> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        for(Case c : newRecords) {
            if(c.OwnerId != oldMap.get(c.Id).OwnerId) {
                caseIds.add(c.Id);
            }
        }

        if(caseIds.size() > 0) {
            CaseTeamHandler.manageSharingOnInsertUpdate([SELECT Id, Case__c, Member__c, Access_Level__c FROM Case_Team__c WHERE Case__c IN :caseIds], null);
        }
    }


    public static void preventCaseAssignmentIfResourceOnLeave(List<Case> newRecords, Map<Id, Case> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for(Case c : newRecords) {
            if(c.OwnerId != oldMap.get(c.Id).OwnerId) {
                caseIds.add(c.Id);
                ownerIds.add(c.OwnerId);
            }
        }

        if(caseIds.size() == 0) {
            return;
        }

        Map<Id, Service_resource__c> mapOfUserIdToServiceResource = new Map<Id, Service_resource__c>();
        for(Service_Resource_Leave__c srl : [
            SELECT Id, Service_Resource__r.Name, Service_Resource__r.User__c, Service_Resource__r.User__r.Name, Is_Active__c, Start_Date__c, End_Date__c
            FROM Service_Resource_Leave__c
            WHERE Service_Resource__r.isActive__c = true AND Is_Active__c = TRUE AND Service_Resource__r.User__c IN :ownerIds
        ]) {
            mapOfUserIdToServiceResource.put(srl.Service_Resource__r.User__c, srl.Service_Resource__r);
        }

        for(Case c : newRecords) {
            if(mapOfUserIdToServiceResource.containsKey(c.OwnerId)) {
                c.addError('Cannot assign case to ' + mapOfUserIdToServiceResource.get(c.OwnerId).User__r.Name + ' as they are on leave');
            }
        }
    }


    public static void preventCaseClose(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        Set<Id> caseIdsToCheck = new Set<Id>();
        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            if (c.Status == 'Closed' && oldCase.Status != 'Closed') {
                caseIdsToCheck.add(c.Id);
            }
        }

        if (caseIdsToCheck.isEmpty()) return;

        Set<Id> caseIdsWithNewSpareRequests = new Set<Id>();
        for (Spare_Material_Request__c smr : [
            SELECT Id, Case__c, Status__c
            FROM Spare_Material_Request__c
            WHERE Case__c IN :caseIdsToCheck
            AND Status__c != 'Completed'
        ]) {
            caseIdsWithNewSpareRequests.add(smr.Case__c);
        }

        for (Case c : newCases) {
            Case oldCase = oldCaseMap.get(c.Id);
            if (c.Status == 'Closed' && oldCase.Status != 'Closed') {
                // if (c.OEM_Discussion__c == true || caseIdsWithNewSpareRequests.contains(c.Id)) {
                //     c.addError('You cannot close this Case while OEM Discussion is true or there is a Spare Material Request with Status = New.');
                // }
                if (c.OEM_Discussion__c == true) {
                    c.addError('You cannot close this Case because OEM Discussion is true.');
                }

                if (caseIdsWithNewSpareRequests.contains(c.Id)) {
                    c.addError('You cannot close this case because a material code has not been generated.');
                }
            }
        }
    }

    public static void handleOwnerChange(List<Case> newList, Map<Id, Case> oldMap) {
        System.debug('🚀 Entered handleOwnerChange method');

        List<AssetShare> assetSharesToInsert = new List<AssetShare>();

        for (Case c : newList) {
            Case oldCase = oldMap.get(c.Id);

            System.debug('🔍 Checking Case: ' + c.Id);
            System.debug('   Old Owner: ' + oldCase.OwnerId);
            System.debug('   New Owner: ' + c.OwnerId);
            System.debug('   Asset Id: ' + c.AssetId);

            if (c.OwnerId != oldCase.OwnerId && c.AssetId != null) {
                System.debug('✅ Owner changed and Asset exists — creating AssetShare record');

                AssetShare newShare = new AssetShare();
                newShare.AssetId = c.AssetId;
                newShare.UserOrGroupId = c.OwnerId;
                newShare.AssetAccessLevel = 'Read'; // Read-only access

                assetSharesToInsert.add(newShare);
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
            System.debug('ℹ️ No AssetShare records to insert');
        }

        System.debug('🏁 Exiting handleOwnerChange method');
    }




    public static void deleteAssetManualShare(List<Case> newList, Map<Id, Case> oldMap) {
    Set<Id> assetIdsToProcess = new Set<Id>();

    for (Case c : newList) {
        Case oldCase = oldMap.get(c.Id);
        if (
            c.Status != oldCase.Status &&
            (c.Status == 'Closed' || c.Status == 'Deferred' || c.Status == 'Withdrawn') &&
            c.AssetId != null
        ) {
            assetIdsToProcess.add(c.AssetId);
        }
    }

    if (assetIdsToProcess.isEmpty()) {
        System.debug('⚠️ No qualifying cases found — no AssetShare records will be deleted.');
        return;
    }

    // Fetch all manual shares for those Assets
    List<AssetShare> sharesToDelete = [
        SELECT Id, AssetId, UserOrGroupId, RowCause
        FROM AssetShare
        WHERE AssetId IN :assetIdsToProcess
        AND RowCause = 'Manual'
    ];

    System.debug('✅ Found Manual AssetShare records to delete: ' + sharesToDelete);

    if (!sharesToDelete.isEmpty()) {
        try {
            delete sharesToDelete;
            System.debug('🗑️ Successfully deleted ' + sharesToDelete.size() + ' manual AssetShare records.');
        } catch (DmlException e) {
            System.debug('❌ Error while deleting AssetShare records: ' + e.getMessage());
        }
    } else {
        System.debug('ℹ️ No manual AssetShare records found for deletion.');
    }
}



    public static void trackStageDays(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        
        for(Case newCase : newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            
            // Check if status changed
            if(newCase.Status != oldCase.Status) {
                
                // Calculate days spent in OLD status
                Integer daysSpent = 0;
                if(oldCase.LastModifiedDate != null) {
                    Date lastModified = Date.valueOf(oldCase.LastModifiedDate);
                    Date today = System.today();
                    daysSpent = today.daysBetween(lastModified);
                    if(daysSpent < 0) daysSpent = -daysSpent; // Absolute value
                }
                
                // If no days calculated, assume 1 day minimum
                if(daysSpent == 0) {
                    daysSpent = 1;
                }
                
                // Add days to the appropriate stage field
                if(oldCase.Status == 'New') {
                    newCase.Days_in_New__c = (oldCase.Days_in_New__c != null ? oldCase.Days_in_New__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Assigned') {
                    newCase.Days_in_Assigned__c = (oldCase.Days_in_Assigned__c != null ? oldCase.Days_in_Assigned__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Working') {
                    newCase.Days_in_Working__c = (oldCase.Days_in_Working__c != null ? oldCase.Days_in_Working__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Tech Support') {
                    newCase.Days_in_Tech_Support__c = (oldCase.Days_in_Tech_Support__c != null ? oldCase.Days_in_Tech_Support__c : 0) + daysSpent;
                } else if(oldCase.Status == 'PO Awaited') {
                    newCase.Days_in_PO_Awaited__c = (oldCase.Days_in_PO_Awaited__c != null ? oldCase.Days_in_PO_Awaited__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Dispatch Awaited') {
                    newCase.Days_in_Dispatch_Awaited__c = (oldCase.Days_in_Dispatch_Awaited__c != null ? oldCase.Days_in_Dispatch_Awaited__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Return Pending') {
                    newCase.Days_in_Return_Pending__c = (oldCase.Days_in_Return_Pending__c != null ? oldCase.Days_in_Return_Pending__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Return to Depot') {
                    newCase.Days_in_Return_to_Depot__c = (oldCase.Days_in_Return_to_Depot__c != null ? oldCase.Days_in_Return_to_Depot__c : 0) + daysSpent;
                } else if(oldCase.Status == 'Pending for Close') {
                    newCase.Days_in_Pending_for_Close__c = (oldCase.Days_in_Pending_for_Close__c != null ? oldCase.Days_in_Pending_for_Close__c : 0) + daysSpent;
                }
            }
        }
    }




    // public static void trackStageDays(List<Case> newList,Map<Id, Case> oldMap) {
    //     for (Case c : newList) {

    //         // First time creation
    //         if (Trigger.isInsert) {
    //             c.Last_Status_Change_Date__c = System.now();
    //             continue;
    //         }

    //         Case oldCase = oldMap.get(c.Id);

    //         // If status not changed, skip
    //         if (c.Status == oldCase.Status) continue;

    //         // Calculate days spent
    //         Integer daysSpent = 0;
    //         if (oldCase.Last_Status_Change_Date__c != null) {
    //             daysSpent = oldCase.Last_Status_Change_Date__c
    //                 .date()
    //                 .daysBetween(System.today());
    //         }

    //         // Store days based on previous status
    //         switch on oldCase.Status {

    //             when 'New' {
    //                 c.Days_in_New__c =
    //                     (c.Days_in_New__c == null ? 0 : c.Days_in_New__c)
    //                     + daysSpent;
    //             }

    //             when 'Assigned' {
    //                 c.Days_in_Assigned__c =
    //                     (c.Days_in_Assigned__c == null ? 0 : c.Days_in_Assigned__c)
    //                     + daysSpent;
    //             }

    //             when 'Working' {
    //                 c.Days_in_Working__c =
    //                     (c.Days_in_Working__c == null ? 0 : c.Days_in_Working__c)
    //                     + daysSpent;
    //             }

    //             when 'Tech Support' {
    //                 c.Days_in_Tech_Support__c =
    //                     (c.Days_in_Tech_Support__c == null ? 0 : c.Days_in_Tech_Support__c)
    //                     + daysSpent;
    //             }

    //             when 'PO Awaited' {
    //                 c.Days_in_PO_Awaited__c =
    //                     (c.Days_in_PO_Awaited__c == null ? 0 : c.Days_in_PO_Awaited__c)
    //                     + daysSpent;
    //             }

    //             when 'Dispatch Awaited' {
    //                 c.Days_in_Dispatch_Awaited__c =
    //                     (c.Days_in_Dispatch_Awaited__c == null ? 0 : c.Days_in_Dispatch_Awaited__c)
    //                     + daysSpent;
    //             }

    //             when 'Return Pending' {
    //                 c.Days_in_Return_Pending__c =
    //                     (c.Days_in_Return_Pending__c == null ? 0 : c.Days_in_Return_Pending__c)
    //                     + daysSpent;
    //             }
    //         }

    //         // Update last status change date
    //         c.Last_Status_Change_Date__c = System.now();
    //     }
    // }
















}