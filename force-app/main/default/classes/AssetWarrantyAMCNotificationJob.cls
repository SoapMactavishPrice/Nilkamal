global with sharing class AssetWarrantyAMCNotificationJob implements Schedulable {
    global void execute(SchedulableContext sc) {
        runUpdateLogic();
    }

    public static void runUpdateLogic() {
        SendWarrantyExpiryNotification warrantyBatch = new SendWarrantyExpiryNotification();
        Database.executeBatch(warrantyBatch, 1);

        SendAmcExpiryNotification amcBatch = new SendAmcExpiryNotification();
        Database.executeBatch(amcBatch, 1);
    }

}