// public with sharing class MarkLeaveController {

//     @AuraEnabled
//     public static void submitLeaveApplication(Map<String, Object> leaveData) {
//         if (!leaveData.containsKey('LeaveFrom') || !leaveData.containsKey('LeaveTo')) {
//             throw new AuraHandledException('Start Date and End Date are required.');
//         }
//         Service_Resource__c serviceResource = [
    //             SELECT Id, Name
    //             FROM Service_Resource__c
    //             WHERE User__c = :UserInfo.getUserId()
    //             LIMIT 1
//         ];

//         Service_Resource_Leave__c leaveApplication = new Service_Resource_Leave__c();
//         leaveApplication.Service_Resource__c = serviceResource.Id;
//         leaveApplication.Start_Date__c = Date.valueOf((String) leaveData.get('LeaveFrom'));
//         leaveApplication.End_Date__c = Date.valueOf((String) leaveData.get('LeaveTo'));

//         Database.insert(leaveApplication, true, AccessLevel.SYSTEM_MODE);
//     }

// }


// public with sharing class MarkLeaveController {
    
//     @AuraEnabled
//     public static void submitLeaveApplication(Map<String, Object> leaveData) {
//         if (!leaveData.containsKey('LeaveFrom') || !leaveData.containsKey('LeaveTo')) {
//             throw new AuraHandledException('Start Date and End Date are required.');
//         }
        
//         try {
//             Service_Resource__c serviceResource = [
//                 SELECT Id, Name, RSM__c, RSM__r.Name 
//                 FROM Service_Resource__c 
//                 WHERE User__c = :UserInfo.getUserId() 
//                 LIMIT 1
//             ];
//             if(serviceResource == null) {
//                 throw new AuraHandledException('No Service Resource found for current user.');
//             }
//             Service_Resource_Leave__c leaveApplication = new Service_Resource_Leave__c();
//             leaveApplication.Service_Resource__c = serviceResource.Id;
//             leaveApplication.Start_Date__c = Date.valueOf((String) leaveData.get('LeaveFrom'));
//             leaveApplication.End_Date__c = Date.valueOf((String) leaveData.get('LeaveTo'));
//             insert as system leaveApplication;

//             if(serviceResource.RSM__c != null) {
//                 sendRSMNotification(serviceResource, leaveApplication);
//             }
            
//         } catch(Exception e) {
//             throw new AuraHandledException('Error submitting leave application: ' + e.getMessage());
//         }
//     }
    
//     private static void sendRSMNotification(Service_Resource__c resource, Service_Resource_Leave__c leave) {
//         try {
//             List<Service_Resource__c> rsmRecord = [
//                 SELECT User__c 
//                 FROM Service_Resource__c 
//                 WHERE Id = :resource.RSM__c 
//                 LIMIT 1
//             ];
            
//             if(rsmRecord.isEmpty() || rsmRecord[0].User__c == null) {
//                 System.debug('RSM user not found');
//                 return;
//             }
            
//             String recipientUserId = rsmRecord[0].User__c;
//             Messaging.CustomNotification notification = new Messaging.CustomNotification();
//             notification.setTitle('New Leave Application Submitted');
//             notification.setBody(resource.Name + ' has submitted a leave request from ' + 
//                                 leave.Start_Date__c.format() + ' to ' + leave.End_Date__c.format());
//             notification.setTargetId(leave.Id);
//             notification.setNotificationTypeId(getNotificationTypeId());
//             notification.send(new Set<String>{ recipientUserId });
//         } catch(Exception e) {
//             System.debug('Error sending RSM notification: ' + e.getMessage());
//         }
//     }
    
//     private static String getNotificationTypeId() {
//         List<CustomNotificationType> notificationTypes = [
//             SELECT Id, DeveloperName 
//             FROM CustomNotificationType 
//             WHERE DeveloperName = 'Leave_Application_Notification'
//             LIMIT 1
//         ];
        
//         if(!notificationTypes.isEmpty()) {
//             return notificationTypes[0].Id;
//         }
//         return null;
//     }
// }

public with sharing class MarkLeaveController {
    
    @AuraEnabled
    public static void submitLeaveApplication(Map<String, Object> leaveData) {
        if (!leaveData.containsKey('LeaveFrom') || !leaveData.containsKey('LeaveTo')) {
            throw new AuraHandledException('Start Date and End Date are required.');
        }
        
        try {
            Service_Resource__c serviceResource = [
                SELECT Id, Name, RSM__c, Coordinator__c 
                FROM Service_Resource__c 
                WHERE User__c = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            if(serviceResource == null) {
                throw new AuraHandledException('No Service Resource found for current user.');
            }
            
            Service_Resource_Leave__c leaveApplication = new Service_Resource_Leave__c(
                Service_Resource__c = serviceResource.Id,
                Start_Date__c = Date.valueOf((String) leaveData.get('LeaveFrom')),
                End_Date__c = Date.valueOf((String) leaveData.get('LeaveTo'))
            );
            insert leaveApplication;
            
            Set<String> recipientIds = new Set<String>();
            if(serviceResource.RSM__c != null) recipientIds.add(serviceResource.RSM__c);
            if(serviceResource.Coordinator__c != null) recipientIds.add(serviceResource.Coordinator__c);
            if(!recipientIds.isEmpty()) {
                sendNotifications(serviceResource, leaveApplication, recipientIds);
            }
            
        } catch(Exception e) {
            throw new AuraHandledException('Error submitting leave application: ' + e.getMessage());
        }
    }
    
    private static void sendNotifications(Service_Resource__c resource, Service_Resource_Leave__c leave, Set<String> recipientUserIds) {
        try {
            String notificationTypeId = getNotificationTypeId();
            if(notificationTypeId == null) {
                System.debug('Notification type not found');
                return;
            }
            
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('New Leave Application Submitted');
            notification.setBody(resource.Name + ' has submitted a leave request from ' + 
                              leave.Start_Date__c.format() + ' to ' + leave.End_Date__c.format());
            notification.setTargetId(leave.Id);
            notification.setNotificationTypeId(notificationTypeId);
            notification.send(recipientUserIds);
            
        } catch(Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
    }
    
    private static String notificationTypeIdCache;
    private static String getNotificationTypeId() {
        if(notificationTypeIdCache != null) {
            return notificationTypeIdCache;
        }
        
        List<CustomNotificationType> notificationTypes = [
            SELECT Id 
            FROM CustomNotificationType 
            WHERE DeveloperName = 'Leave_Application_Notification'
            LIMIT 1
        ];
        
        if(!notificationTypes.isEmpty()) {
            notificationTypeIdCache = notificationTypes[0].Id;
        }
        return notificationTypeIdCache;
    }
}