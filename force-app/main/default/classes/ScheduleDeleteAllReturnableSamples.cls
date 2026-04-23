global class ScheduleDeleteAllReturnableSamples implements Schedulable {

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new DeleteAllReturnableSamplesBatch(), 200);
        Database.executeBatch(new DeleteAllOutstandingsBatch(), 200);
        Database.executeBatch(new DeleteAllPendingOrderBatch(), 200);
    }
}