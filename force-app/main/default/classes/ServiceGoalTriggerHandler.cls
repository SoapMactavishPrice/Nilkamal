public with sharing class ServiceGoalTriggerHandler {

    public static void updateStartAndEndDate(List<Service_Goal__c> newRecords, Map<Id, Service_Goal__c> oldMap) {
        for(Service_Goal__c sg : newRecords) {
            if(sg.Financial_Year__c != null) {
                if(oldMap == null) {
                    Map<String, Date> startEndDate = UtilityCls.getStartEndDateFromFYName(sg.Financial_Year__c);
                    sg.Start_Date__c = startEndDate.get('start');
                    sg.End_Date__c = startEndDate.get('end');
                }
                else {
                    if(sg.Financial_Year__c != oldMap.get(sg.Id).Financial_Year__c || sg.Start_Date__c == null || sg.End_Date__c == null) {
                        Map<String, Date> startEndDate = UtilityCls.getStartEndDateFromFYName(sg.Financial_Year__c);
                        sg.Start_Date__c = startEndDate.get('start');
                        sg.End_Date__c = startEndDate.get('end');
                    }
                }
            }
        }
    }

}