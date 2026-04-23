global class priceBookScheduleClass  implements Schedulable{
   global void execute(SchedulableContext sc){
        Database.executeBatch(new PricebookEntryBatch(), 200);
        Database.executeBatch(new PricebookEntryBatchProdPrice4000(), 200);
        Database.executeBatch(new PricebookEntryBatchProdGroup4000(),100);
        Database.executeBatch(new PricebookEntryBatchProdGroup1000(), 100);
   }
}