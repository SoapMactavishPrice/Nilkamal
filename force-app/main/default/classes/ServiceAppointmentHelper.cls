public without sharing class ServiceAppointmentHelper {
    
    public static Set<String> getAdditionalResourceEmails(Id caseId, DateTime scheduledStart) {
        Set<String> emailIds = new Set<String>();

        List<Service_Appointment__c> additionalResourceServiceAppointments = [
            SELECT Id, Owner.Name, Owner.Email
            FROM Service_Appointment__c
            WHERE Case__c = :caseId
              AND Scheduled_Start__c = :scheduledStart
              AND Check_In_Date_Time__c != NULL
              AND Is_Additional_Resource__c = TRUE
              AND Remote_Support__c = FALSE
        ];

        for (Service_Appointment__c additionalSA : additionalResourceServiceAppointments) {
            if (additionalSA.Owner != null && String.isNotBlank(additionalSA.Owner.Email)) {
                emailIds.add(additionalSA.Owner.Email);
                System.debug('🔍 Added Additional Resource Email: ' + additionalSA.Owner.Email + ' (Owner: ' + additionalSA.Owner.Name + ')');
            }
        }

        return emailIds;
    }
}