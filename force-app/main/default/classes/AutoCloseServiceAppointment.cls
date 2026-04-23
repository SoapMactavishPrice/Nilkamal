global with sharing class AutoCloseServiceAppointment implements Database.Batchable<SObject>,Schedulable {

    global AutoCloseServiceAppointment() {}

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new AutoCloseServiceAppointment());
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Service_Appointment__c ' +
                    'FROM Service_Appointment_Check_In_and_Out__c ' +
                    'WHERE IsCheckedOut__c = FALSE';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Service_Appointment_Check_In_and_Out__c> scope) {
        Map<Id, Service_Appointment__c> saMapToUpdate = new Map<Id, Service_Appointment__c>();
        for (Service_Appointment_Check_In_and_Out__c record : scope) {
            record.Is_auto_checked_out_by_system__c = true;

            Service_Appointment__c sa = new Service_Appointment__c();
            sa.Id = record.Service_Appointment__c;
            sa.Check_Out_Address_Error__c = 'Auto Checked Out by System';
            sa.Status__c = 'Completed';

            saMapToUpdate.put(sa.Id, sa);
        }
        update scope;

        update saMapToUpdate.values();
    }

    global void finish(Database.BatchableContext BC) {}

}