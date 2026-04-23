public class CaseManagement {
    @AuraEnabled
    public static List<Case> getOpenQueueCases() {
        try {
            Id openQueueId = [SELECT Id 
                              FROM Group 
                              WHERE Name = 'Open Queue' AND Type = 'Queue' 
                              LIMIT 1].Id;

            List<Case> openQueueCases = [SELECT Id, CaseNumber, Subject, OwnerId, 
                                                Description, Contact.Name, Account.Name, 
                                                Contact.Email, Contact.Phone, CreatedDate, 
                                                Priority, Division__c, Type
                                         FROM Case 
                                         WHERE OwnerId = null 
                                            OR OwnerId = :openQueueId];

            System.debug('Cases with blank owner or owned by Open Queue: ' + openQueueCases);

            return openQueueCases;
        } catch (Exception e) {
            System.debug('Error fetching Open Queue cases: ' + e.getMessage());
            return new List<Case>();
        }
    }
    /*
    @AuraEnabled
    public static List<Case> getCasesWithReassignNotifications() {
        try {
            CustomNotificationType notificationType = [SELECT Id 
                                                        FROM CustomNotificationType 
                                                        WHERE DeveloperName = 'Case_Reassignment_Alert' 
                                                        LIMIT 1];

            if (notificationType == null) {
                System.debug('⚠️ No Custom Notification Type found with DeveloperName "Case_Reassignment_Alert".');
                return new List<Case>();
            }

            List<Case> reassignedCases = [SELECT Id, CaseNumber, Subject, OwnerId, 
                                                 Description, Contact.Name, Account.Name, 
                                                 Contact.Email, Contact.Phone, CreatedDate, 
                                                 Priority, Division__c, Type
                                          FROM Case 
                                          WHERE OwnerId IN (
                                              SELECT TargetId 
                                              FROM Messaging.NotificationDeliveryLog 
                                              WHERE NotificationTypeId = :notificationType.Id
                                          )];

            System.debug('Cases with Reassignment Notifications: ' + reassignedCases);

            return reassignedCases;
        } catch (Exception e) {
            System.debug('Error fetching reassigned cases: ' + e.getMessage());
            return new List<Case>();
        }
    }*/

}