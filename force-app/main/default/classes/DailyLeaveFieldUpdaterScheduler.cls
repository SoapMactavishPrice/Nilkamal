global class DailyLeaveFieldUpdaterScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        ServiceResourceLeaveBatch batch = new ServiceResourceLeaveBatch();
        Database.executeBatch(batch, 200);
    }
}