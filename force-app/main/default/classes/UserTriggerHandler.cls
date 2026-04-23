public class UserTriggerHandler {

    public static void createServiceResourcesAndHours(List<User> newUsers, Map<Id, User> oldUserMap) {
        Map<Id, Service_Resource__c> mapUserIdToServiceResource = new Map<Id, Service_Resource__c>();
        for(Service_Resource__c sr : [SELECT Id, User__c FROM Service_Resource__c WHERE User__c IN :newUsers]) {
            mapUserIdToServiceResource.put(sr.User__c, sr);
        }

        Set<Id> userIdsToCreateServiceResource = new Set<Id>();
        for(User u : newUsers) {
            if (u.Is_Service_User__c && (Trigger.isInsert || (Trigger.isUpdate && oldUserMap != null && oldUserMap.get(u.Id).Is_Service_User__c != u.Is_Service_User__c))) {
                if(mapUserIdToServiceResource.containsKey(u.Id) == false) {
                    userIdsToCreateServiceResource.add(u.Id);
                }
            }
        }

        if (!userIdsToCreateServiceResource.isEmpty()) {
            createServiceResourcesAndHoursFuture(String.join(userIdsToCreateServiceResource, ','));
        }
    }


    @future
    private static void createServiceResourcesAndHoursFuture(String userIdsString) {
        List<Id> userIds = userIdsString.split(',');

        List<User> users = [SELECT Id, FirstName, LastName, UserRoleId, ManagerId, Manager.ManagerId, Business_Unit__c, UserRole.Name
                            FROM User
                            WHERE Id IN :userIds];

        Map<Id, Service_Resource__c> mapUserIdToServiceResource = new Map<Id, Service_Resource__c>();
        for(Service_Resource__c sr : [SELECT Id, User__c
                                    FROM Service_Resource__c
                                    WHERE User__c IN :users]) {
            mapUserIdToServiceResource.put(sr.User__c, sr);
        }

        // Map<Id, UserRole> mapUserRoles = new Map<Id, UserRole>();
        // for(UserRole ur : [SELECT Id, Name FROM UserRole]) {
        //     mapUserRoles.put(ur.Id, ur);
        // }


        List<Service_Resource__c> serviceResourcesToInsert = new List<Service_Resource__c>();
        List<Service_Resource_Working_Hour__c> serviceResourceHoursToInsert = new List<Service_Resource_Working_Hour__c>();

        for (User u : users) {
            if(mapUserIdToServiceResource.containsKey(u.Id)) {
                continue;
            }

            Service_Resource__c newServiceResource = new Service_Resource__c();
            newServiceResource.Name = u.FirstName + ' ' + u.LastName;
            newServiceResource.User__c = u.Id;
            newServiceResource.isActive__c = true;
            newServiceResource.Business_Vertical__c = u.Business_Unit__c;

            String userRole = u.UserRole.Name;
            if(u.UserRoleId != null && u.UserRole.Name != null) {
                if(userRole != null) {
                    if(userRole.contains('Service Head')) {
                        newServiceResource.Role__c = 'Service Head';
                    }
                    else if(userRole.contains('Coordinator')) {
                        newServiceResource.Role__c = 'Coordinator';
                    }
                    else if(userRole.contains('RSM')) {
                        newServiceResource.Role__c = 'RSM';
                        newServiceResource.Coordinator__c = u.ManagerId;
                    }
                    else if(userRole.contains('Service Engineer')) {
                        newServiceResource.Role__c = 'Service Engineer';
                        newServiceResource.Coordinator__c = u.Manager.ManagerId;
                        newServiceResource.RSM__c = u.ManagerId;
                    }
                }
            }

            serviceResourcesToInsert.add(newServiceResource);
        }

        if (!serviceResourcesToInsert.isEmpty()) {
            insert serviceResourcesToInsert;

            List<String> weekdays = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
            Map<String, Map<String, String>> weekdayHoursMap = new Map<String, Map<String, String>>{
                'Monday' => new Map<String, String>{'start' => '09:00', 'end' => '17:00'},
                'Tuesday' => new Map<String, String>{'start' => '09:00', 'end' => '17:00'},
                'Wednesday' => new Map<String, String>{'start' => '09:00', 'end' => '17:00'},
                'Thursday' => new Map<String, String>{'start' => '09:00', 'end' => '17:00'},
                'Friday' => new Map<String, String>{'start' => '09:00', 'end' => '17:00'}
            };

            for (Service_Resource__c serviceResource : serviceResourcesToInsert) {
                for (String weekday : weekdays) {
                    Service_Resource_Working_Hour__c newServiceResourceHour = new Service_Resource_Working_Hour__c();
                    newServiceResourceHour.Service_Resource__c = serviceResource.Id;
                    newServiceResourceHour.Weekday__c = weekday;

                    Map<String, String> hours = weekdayHoursMap.get(weekday);

                    String startHourString = hours.get('start');
                    String endHourString = hours.get('end');

                    Integer startHour = Integer.valueOf(startHourString.substring(0, 2));
                    Integer startMinute = Integer.valueOf(startHourString.substring(3, 5));

                    Integer endHour = Integer.valueOf(endHourString.substring(0, 2));
                    Integer endMinute = Integer.valueOf(endHourString.substring(3, 5));

                    Time startTime = Time.newInstance(startHour, startMinute, 0, 0);
                    Time endTime = Time.newInstance(endHour, endMinute, 0, 0);

                    newServiceResourceHour.Start_Hour__c = startTime;
                    newServiceResourceHour.End_Hour__c = endTime;

                    serviceResourceHoursToInsert.add(newServiceResourceHour);
                }
            }

            if (!serviceResourceHoursToInsert.isEmpty()) {
                insert serviceResourceHoursToInsert;
            }
        }
    }



    public static void updateServiceResources(List<User> users, Map<Id, User> oldUserMap) {
        Map<Id, User> userMap = new Map<Id, User>();
        for (User user:users) {
            if (user.FirstName != oldUserMap.get(user.Id).FirstName ||
                user.MiddleName != oldUserMap.get(user.Id).MiddleName ||
                user.LastName != oldUserMap.get(user.Id).LastName ||
                user.Suffix != oldUserMap.get(user.Id).Suffix ||
                user.IsActive != oldUserMap.get(user.Id).IsActive ||
                user.UserRoleId != oldUserMap.get(user.Id).UserRoleId ||
                user.Business_Unit__c != oldUserMap.get(user.Id).Business_Unit__c ||
                user.ManagerId != oldUserMap.get(user.Id).ManagerId) {
                userMap.put(user.Id, user);
            }
        }

        if(!userMap.isEmpty()) {
            updateServiceResourcesFuture(String.join(userMap.keySet(), ','));
        }
    }

    @future
    private static void updateServiceResourcesFuture(String userIdsString) {
        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, FirstName, MiddleName, LastName, Suffix, UserRoleId, UserRole.Name, Business_Unit__c, ManagerId, Manager.ManagerId, IsActive
            FROM User
            WHERE Id IN :userIdsString.split(',')]
        );


        for(User u : [SELECT Id, FirstName, MiddleName, LastName, Suffix, UserRoleId, UserRole.Name, Business_Unit__c, ManagerId, Manager.ManagerId, IsActive
                    FROM User
                    WHERE Id IN :userMap.keySet()])
        {
            userMap.put(u.Id, u);
        }

        List<Service_Resource__c> serviceResources = [SELECT Id, User__c
                                                    FROM Service_Resource__c
                                                    WHERE User__c IN :userMap.keySet()];
        for (Service_Resource__c serviceResource : serviceResources) {
            User user = userMap.get(serviceResource.User__c);
            serviceResource.Name = user.FirstName + ' ' + user.LastName;
            serviceResource.isActive__c = user.IsActive;
            serviceResource.Business_Vertical__c = user.Business_Unit__c;

            String userRole = user.UserRole.Name;
            if(userRole != null) {
                if(userRole.contains('Service Head')) {
                    serviceResource.Role__c = 'Service Head';
                }
                else if(userRole.contains('Coordinator')) {
                    serviceResource.Role__c = 'Coordinator';
                }
                else if(userRole.contains('RSM')) {
                    serviceResource.Role__c = 'RSM';
                    serviceResource.Coordinator__c = user.ManagerId;
                }
                else if(userRole.contains('Service Engineer')) {
                    serviceResource.Role__c = 'Service Engineer';
                    serviceResource.Coordinator__c = user.Manager.ManagerId;
                    serviceResource.RSM__c = user.ManagerId;
                }
            }
        }
        UPDATE serviceResources;
    }

}