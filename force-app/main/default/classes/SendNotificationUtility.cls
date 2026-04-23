public with sharing class SendNotificationUtility {
    public SendNotificationUtility() {

    }
    public static void sendInAppNotification(String recordId, String notificationTypeId,String title, String body,Set<String> recipientsIds) {
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle(title);
        notification.setBody(body);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(recordId);
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
}