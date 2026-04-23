global class AutoQuoteSummaryJob implements Schedulable{
    global void execute(SchedulableContext sc) {
        runEmailLogic();
    }

    public static void runEmailLogic() {
        autoCaseEmailSummaryBatch emailBatch = new autoCaseEmailSummaryBatch(); 
        Database.executeBatch(emailBatch,200);
    }
}