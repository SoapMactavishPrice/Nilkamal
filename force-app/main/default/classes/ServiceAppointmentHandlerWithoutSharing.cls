public without sharing class ServiceAppointmentHandlerWithoutSharing {

    public static void validateServiceAppointmentForDuplicate(List<Service_Appointment__c> serviceAppointments) {
        Set<Id> caseIds = new Set<Id>();
        for(Service_Appointment__c sa : serviceAppointments) {
            caseIds.add(sa.Case__c);
        }

        List<Service_Appointment__c> existingServiceAppointments = [
            SELECT Id, Case__c, OwnerId, Scheduled_Start__c, Remote_Support__c
            FROM Service_Appointment__c
            WHERE Case__c IN :caseIds AND Id NOT IN :serviceAppointments
        ];

        Map<Id, List<Service_Appointment__c>> caseToServiceAppointments = new Map<Id, List<Service_Appointment__c>>();

        for(Service_Appointment__c sa : existingServiceAppointments) {
            if(!caseToServiceAppointments.containsKey(sa.Case__c)) {
                caseToServiceAppointments.put(sa.Case__c, new List<Service_Appointment__c>());
            }
            caseToServiceAppointments.get(sa.Case__c).add(sa);
        }

        for(Service_Appointment__c sa : serviceAppointments) {
            if(caseToServiceAppointments.containsKey(sa.Case__c) && caseToServiceAppointments.get(sa.Case__c).size() > 0) {
                List<Service_Appointment__c> existingServiceAppointmentsForCase = caseToServiceAppointments.get(sa.Case__c);
                for(Service_Appointment__c existingSA : existingServiceAppointmentsForCase) {
                    if(
                        existingSA.OwnerId == sa.OwnerId &&
                        existingSA.Scheduled_Start__c.date() == sa.Scheduled_Start__c.date() &&
                        existingSA.Remote_Support__c == sa.Remote_Support__c
                    ) {
                        sa.addError('Duplicate appointment detected: A Service Appointment already exists for this Case, Owner, and Date. Only one appointment is allowed per owner per day per case unless one of them is marked as Remote Support.');
                    }
                }
            }
        }
    }

}