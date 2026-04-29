/**
 * One-time script to reset Spare Request records to make them available for quote creation again
 * Usage: Execute from Anonymous Apex with the Work Order ID
 */
public class ResetSpareRequestsScript {
    
    /**
     * Reset spare requests for a specific Work Order
     * @param workOrderId The ID of the Work Order
     */
    public static void resetSpareRequestsByWorkOrder(Id workOrderId) {
        List<Spare_Request__c> spareRequests = [
            SELECT Id, Name, Opportunity_Product__c, Quote_Line_item__c, 
                   Quote__c, Opportunity__c, Opp_Raised__c, Quote_Raised__c
            FROM Spare_Request__c
            WHERE Work_Order__c = :workOrderId
        ];
        
        if(spareRequests.isEmpty()) {
            System.debug('No Spare Requests found for Work Order: ' + workOrderId);
            return;
        }
        
        System.debug('Found ' + spareRequests.size() + ' Spare Requests to reset');
        
        for(Spare_Request__c sr : spareRequests) {
            // Clear the linking fields to make them "open" again
            sr.Opportunity_Product__c = null;
            sr.Quote_Line_item__c = null;
            
            // Optionally clear these as well for complete reset
            sr.Quote__c = null;
            sr.Opportunity__c = null;
            sr.Opp_Raised__c = false;
            sr.Quote_Raised__c = false;
        }
        
        update spareRequests;
        System.debug('Successfully reset ' + spareRequests.size() + ' Spare Request records');
    }
    
    /**
     * Reset all spare requests that have been linked to opportunities/quotes
     */
    public static void resetAllLinkedSpareRequests() {
        List<Spare_Request__c> spareRequests = [
            SELECT Id, Name, Opportunity_Product__c, Quote_Line_item__c,
                   Quote__c, Opportunity__c, Opp_Raised__c, Quote_Raised__c
            FROM Spare_Request__c
            WHERE (Opportunity_Product__c != null OR Quote_Line_item__c != null)
            LIMIT 10000
        ];
        
        if(spareRequests.isEmpty()) {
            System.debug('No linked Spare Requests found');
            return;
        }
        
        System.debug('Found ' + spareRequests.size() + ' linked Spare Requests');
        
        for(Spare_Request__c sr : spareRequests) {
            sr.Opportunity_Product__c = null;
            sr.Quote_Line_item__c = null;
            sr.Quote__c = null;
            sr.Opportunity__c = null;
            sr.Opp_Raised__c = false;
            sr.Quote_Raised__c = false;
        }
        
        update spareRequests;
        System.debug('Successfully reset ' + spareRequests.size() + ' Spare Request records');
    }
}