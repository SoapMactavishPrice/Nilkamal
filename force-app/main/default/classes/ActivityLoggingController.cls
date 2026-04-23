public with sharing class ActivityLoggingController {
    @AuraEnabled
    public static User getCurrentUser() {
        return [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
    }

    @AuraEnabled(cacheable=true)
    public static Service_Appointment__c getServiceAppointmentName(String recordId) {
        if (String.isBlank(recordId)) {
            return null;
        }
        Service_Appointment__c sa = [
            SELECT Id,Name,Case__r.AccountId
            FROM Service_Appointment__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return sa;
    }

    //     @AuraEnabled
    // public static void saveActivities(List<Map<String, Object>> activityData) {
    //     List<Task> tasksToInsert = new List<Task>();

    //     for (Map<String, Object> activity : activityData) {
    //         String type = (String) activity.get('type');
    //         String recordId = (String) activity.get('recordId');
    //         Map<String, Object> fields = (Map<String, Object>) activity.get('fields');

    //         Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c WHERE Id = :recordId LIMIT 1];

    //         if (type == 'New Task') {
    //             Task newTask = new Task(
    //                 Subject = (String) fields.get('Subject'),
    //                 WhoId = (String) fields.get('Name'),
    //                 WhatId = sa.Id,
    //                 ActivityDate = fields.containsKey('Due Date') ? Date.valueOf((String) fields.get('Due Date')) : null,
    //                 Description = (String) fields.get('Task Subtype'),
    //                 OwnerId = (String) fields.get('Assigned To')
    //             );
    //             tasksToInsert.add(newTask);
    //         } else if (type == 'Log a Call') {
    //             Task callTask = new Task(
    //                 Subject = 'Call',
    //                 Description = (String) fields.get('Call'),
    //                 WhoId = (String) fields.get('Name'),
    //                 WhatId = sa.Id,
    //                 Status = 'Completed'
    //             );
    //             tasksToInsert.add(callTask);
    //         }
    //     }

    //     if (!tasksToInsert.isEmpty()) {
    //         insert tasksToInsert;
    //     }
    // }
    @AuraEnabled
public static void saveActivities(List<Map<Object, Object>> activityData) {
    List<Task> tasksToInsert = new List<Task>();
    try {
        for (Map<Object, Object> activity : activityData) {
            String type = (String) activity.get('type');
            String recordId = (String) activity.get('recordId');
            Map<Object, Object> fields = (Map<Object, Object>) activity.get('fields');

            Service_Appointment__c sa = [SELECT Id FROM Service_Appointment__c WHERE Id = :recordId LIMIT 1];

            if (type == 'New Task') {
                Task newTask = new Task(
                    Subject = (String) fields.get('Subject'),
                    WhoId = (String) fields.get('Name'),
                    WhatId = sa.Id,
                    ActivityDate = fields.containsKey('Due Date') ? Date.valueOf((String) fields.get('Due Date')) : null,
                    TaskSubtype = (String) fields.get('Task Subtype'),
                    OwnerId = (String) fields.get('Assigned To'),
                    Description = (String) fields.get('Comments')
                );
                tasksToInsert.add(newTask);
            } else if (type == 'Log a Call') {
                Task callTask = new Task(
                    Subject =  (String) fields.get('Subject'),
                    Description = (String) fields.get('Comments'),
                    WhoId =(String) fields.get('Name'),
                    WhatId = sa.Id,
                    Status = 'Completed'
                );
                tasksToInsert.add(callTask);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    } catch (DmlException e) {
        // Log the error message in the debug log or capture it for front-end error handling
        System.debug('DML Error: ' + e.getMessage()+e.getLineNumber());
        throw new AuraHandledException('Error occurred while inserting tasks: ' + e.getMessage());
    } catch (Exception e) {
        // Catch any other unexpected errors
        System.debug('General Error: ' + e.getMessage()+e.getLineNumber());
        throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
    }
}



    // 
    @AuraEnabled
    public static String getTaskPicklistValues() {
        // Map to store picklist values for both fields
        Map<String, List<Map<String, String>>> picklistValuesMap = new Map<String, List<Map<String, String>>>();

        // Fetch picklist values for 'Subject'
        List<Map<String, String>> subjectOptions = getPicklistValues('Task', 'Subject');
        picklistValuesMap.put('Subject', subjectOptions);

        // Fetch picklist values for 'Task Subtype'
        List<Map<String, String>> taskSubtypeOptions = getPicklistValues('Task', 'TaskSubtype');
        picklistValuesMap.put('TaskSubtype', taskSubtypeOptions);

        // Serialize the map to JSON and return
        return JSON.serialize(picklistValuesMap);
    }

    private static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> options = new List<Map<String, String>>();
        try {
            // Use Schema to describe the field
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Schema.DescribeFieldResult fieldDescribe = objDescribe.fields.getMap().get(fieldName).getDescribe();

            // Fetch picklist entries
            List<Schema.PicklistEntry> picklistEntries = fieldDescribe.getPicklistValues();
            for (Schema.PicklistEntry entry : picklistEntries) {
                if (entry.isActive()) {
                    Map<String, String> option = new Map<String, String>();
                    option.put('label', entry.getLabel());
                    option.put('value', entry.getValue());
                    options.add(option);
                }
            }
        } catch (Exception ex) {
            System.debug('Error fetching picklist values: ' + ex.getMessage());
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> searchContacts(String searchKey) {
        String searchPattern = '%' + searchKey + '%';  // Concatenate the search pattern

        return [
            SELECT Id, Name 
            FROM Contact 
            WHERE Name LIKE : searchPattern
            LIMIT 10
        ];
    }



}