global class allSchedular implements Schedulable {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new OutstandingBatch(), 200);
        Database.executeBatch(new ReturnableSampleBatch(), 200);
        Database.executeBatch(new PendingOrderBatch(), 200);
        Database.executeBatch(new NonReturnableSampleBatch(), 200);
    }
}