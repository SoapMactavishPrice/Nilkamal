public with sharing class FieldServiceHomeController {

    @AuraEnabled
    public static Object getSummarizedData() {
        try {
            Map<String, Object> result = new Map<String, Object>();
            try {
                result.put('caseSummary', getCaseSummary());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('eventsList', getEventsList());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('countOfAssets', FieldServiceAssetListController.getCountOfAssets());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('userDetails', UtilityCls.getUserDetails());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('dashboardId', getDashboardId());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('approvalItemsWithCount', FieldServiceAssetListController.getApprovalItemsWithCount());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('newCaseCountForRSM', getNewCaseCountForRSM());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            try {
                result.put('countOfCasesAndFeedItems', getCountOfCasesAndFeedItems());
            } catch (Exception e) { System.debug('Exception: ' + e.getMessage()); }

            return result;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Map<String, Integer> getCaseSummary() {
        Map<String, Integer> caseSummary = new Map<String, Integer>();
        try {
            Integer newCases = [SELECT COUNT()
                                FROM Case
                                WHERE IsClosed = false
                                AND Is_Service_Appointment_Created__c = false];
            caseSummary.put('newCases', newCases);

            Integer missedCases = [SELECT COUNT()
                                    FROM Case
                                    WHERE IsClosed = false
                                    AND Assigned_Date_Time__c < TODAY
                                    AND Is_service_appointment_checked_in__c = false];
            caseSummary.put('missedCases', missedCases);

            Integer todaysActions = [SELECT COUNT()
                                FROM Service_Appointment__c
                                WHERE Case__r.IsClosed = false
                                AND Scheduled_Start__c = TODAY
                                AND OwnerId = :UserInfo.getUserId()];
            caseSummary.put('todaysActions', todaysActions);

            Integer openCases = [SELECT COUNT()
                                        FROM Case
                                        WHERE IsClosed = false];
            caseSummary.put('openCases', openCases);
        }
        catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
        return caseSummary;
    }


    @AuraEnabled(cacheable=true)
    public static Object getEventsList() {
        try {
            // Set<Id> setOfUsersReportingToMe = UtilityCls.getUserIdsReportingToMe();

            List<Service_Appointment__c> missedEvents = new List<Service_Appointment__c>();
            // List<Service_Appointment__c> todaysEvents = new List<Service_Appointment__c>();
            List<Service_Appointment__c> openEvents = new List<Service_Appointment__c>();
            List<Service_Appointment__c> upcomingEvents = new List<Service_Appointment__c>();

            for(Service_Appointment__c sa : [SELECT Id, Name, Scheduled_Start__c, Due_Date__c,
                                            Work_Order__r.Case__r.SuppliedEmail, Account__c, Account__r.Name, Work_Order__r.Case__r.CreatedDate,
                                            Work_Order__r.Case__r.Account.Name, Work_Order__r.Case__r.Asset.SerialNumber,
                                            Work_Order__r.Case__r.Asset.Ship_to_Address__c, Work_Order__r.Case__r.Asset.Ship_To_City__c, Work_Order__r.Case__r.Asset.Ship_To_Region__c, Work_Order__r.Case__r.Asset.Ship_to_Pin__c, Case__r.Asset.Ship_to_Country__c,
                                            Work_Order__r.Case__r.Asset.Asset_GeoLocation__c, Work_Order__r.Case__r.CaseNumber,
                                            Work_Order__r.Case__r.Asset.Asset_GeoLocation__Latitude__s, Work_Order__r.Case__r.Asset.Asset_GeoLocation__Longitude__s
                                            FROM Service_Appointment__c
                                            WHERE OwnerId = :UserInfo.getUserId()
                                            // AND Status__c != 'Completed'
                                            AND Case__r.IsClosed = false
                                            ORDER BY CreatedDate DESC, Due_Date__c ASC]
            ) {
                if(sa.Scheduled_Start__c != null) {
                    if(sa.Scheduled_Start__c.date() < System.today()) {
                        missedEvents.add(sa);
                    }
                    else if(sa.Scheduled_Start__c.date() == System.today()) {
                        openEvents.add(sa);
                    }
                    else if(sa.Scheduled_Start__c.date() > System.today()) {
                        upcomingEvents.add(sa);
                    }
                }
            }
            return new Map<String, List<Service_Appointment__c>>{
                'missedEvents' => missedEvents,
                'openEvents' => openEvents,
                'upcomingEvents' => upcomingEvents
            };

        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }


    @AuraEnabled(cacheable=true)
    public static Id getDashboardId() {
        try {
            User u = [SELECT Id, Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
            String dashboardName;
            if(u.UserRole.Name.contains('Service Head') || u.UserRole.Name.contains('System Administrator')) {
                dashboardName = 'Service Head Dashboard';
            }
            else if(u.UserRole.Name.contains('Coordinator')) {
                dashboardName = 'Service Coordinator Dashboard';
            }
            else if(u.UserRole.Name.contains('RSM')) {
                dashboardName = 'RSM Dashboard';
            }
            else if(u.UserRole.Name.contains('Service Engineer')) {
                dashboardName = 'Service Engineer Dashboard';
            }

            if(String.isNotBlank(dashboardName)) {
                return [SELECT Id FROM Dashboard WHERE Title = :dashboardName LIMIT 1].Id;
            }
            else {
                throw new CustomException('Dashboard not found for the user. Please contact your administrator.');
            }
        }
        catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
            // throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled(cacheable=true)
    public static Integer getNewCaseCountForRSM() {
        // User currentUser = [SELECT Id, Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];

        // if (currentUser.UserRole != null && currentUser.UserRole.Name.contains('RSM')) {
            Integer caseCount = [
                SELECT COUNT()
                FROM Case
                WHERE OwnerId = :UserInfo.getUserId()
                // AND Status = 'New'
                AND IsClosed = false
            ];
            return caseCount;
        // } else {
        //     return 0;
        // }
    }


    @AuraEnabled(cacheable=true)
    public static Integer getCountOfCasesAndFeedItems() {
        try {
            String caseQuery = 'SELECT Id,CaseNumber,OwnerId,Owner.Id,Owner.Name, ' +
                '(SELECT Id FROM Feeds WHERE Type = \'TextPost\')' +
                'FROM Case ' +
                'WHERE Tech_Support_Status__c IN (\'Opened by Service Engineer\', \'Comment by Service Engineer\') ';

            System.debug('caseQuery: ' + caseQuery);

            List<Case> caseList = Database.query(caseQuery);

            if(caseList.size() == 0) {
                return 0;
            }

            Set<Id> feedItemIds = new Set<Id>();
            for (Case c : caseList) {
                for(sObject f : c.Feeds) {
                    feedItemIds.add(f.Id);
                }
            }

            return feedItemIds.size();
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


}