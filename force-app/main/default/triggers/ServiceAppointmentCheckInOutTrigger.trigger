trigger ServiceAppointmentCheckInOutTrigger on Service_Appointment_Check_In_and_Out__c(before insert, before update) {

    // if the Asset_GeoLocation__c field is null then get it from Service_Appointment__r.Case__r.Asset.Asset_GeoLocation__c and update it
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        Set<Id> serviceAppointmentIds = new Set<Id>();
        for(Service_Appointment_Check_In_and_Out__c checkInOut : Trigger.new) {
            if(checkInOut.Asset_GeoLocation__c == null && checkInOut.Service_Appointment__c != null) {
                serviceAppointmentIds.add(checkInOut.Service_Appointment__c);
            }
        }

        if(!serviceAppointmentIds.isEmpty()) {
            Map<Id, Service_Appointment__c> serviceAppointments = new Map<Id, Service_Appointment__c>([
                SELECT Id, Case__r.Asset.Asset_GeoLocation__latitude__s, Case__r.Asset.Asset_GeoLocation__longitude__s
                FROM Service_Appointment__c
                WHERE Id IN :serviceAppointmentIds]);
            for(Service_Appointment_Check_In_and_Out__c checkInOut : Trigger.new) {
                if(checkInOut.Asset_GeoLocation__c == null && serviceAppointments.containsKey(checkInOut.Service_Appointment__c)) {
                    checkInOut.Asset_GeoLocation__latitude__s = serviceAppointments.get(checkInOut.Service_Appointment__c).Case__r.Asset.Asset_GeoLocation__latitude__s;
                    checkInOut.Asset_GeoLocation__longitude__s = serviceAppointments.get(checkInOut.Service_Appointment__c).Case__r.Asset.Asset_GeoLocation__longitude__s;
                }
            }
        }
    }

}