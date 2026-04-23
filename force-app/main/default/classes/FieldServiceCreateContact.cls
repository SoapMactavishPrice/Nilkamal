public without sharing class FieldServiceCreateContact {

    @AuraEnabled
    public static Object createContact(Contact contact, Id assetId, Id caseId, Id serviceAppointmentId) {
        try {
            insert contact;

            if(caseId != null) {
                Case caseObj = new Case();
                caseObj.Id = caseId;
                caseObj.Case_Notified_By__c = contact.Id;
                Database.update(caseObj, true, AccessLevel.SYSTEM_MODE);
            }

            if(serviceAppointmentId != null && contact != null) {
                Service_Appointment__c serviceAppointment = new Service_Appointment__c();
                serviceAppointment.Id = serviceAppointmentId;
                serviceAppointment.Contact__c = contact.Id;
                Database.update(serviceAppointment, true, AccessLevel.SYSTEM_MODE);
            }

            return contact;
        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}