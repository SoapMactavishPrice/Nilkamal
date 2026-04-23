public with sharing class PricebookTriggerHandler {

    public static void copyStandardPricebookEntries(List<Pricebook2> newRecords) {
        for(Pricebook2 pb : newRecords) {
            if(pb.Is_ARC_Pricebook__c) {
                CopyStandardPricesToARCPricebook batch = new CopyStandardPricesToARCPricebook(pb.Id);
                Database.executeBatch(batch, 200);
            }
        }
    }

}