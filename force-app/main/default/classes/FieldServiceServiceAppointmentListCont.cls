/**
 * @author Aditya Zagade
 * @since 3 jan 2025
 *
 * @group Field Service
 */
public with sharing class FieldServiceServiceAppointmentListCont {

    /**
     * @description Method to get service appointment list by year, month or year, month, day
     * @param params
     * @return  `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object serviceAppointments = FieldServiceServiceAppointmentListCont.getServiceAppointmentList(new Map<String, Object>{'year' => '2023', 'month' => '1', 'day' => '1'});
     */
    @AuraEnabled
    public static Object getServiceAppointmentList(Map<String, Object> params) {
        try {
            String year, month, day;
            List<Service_Appointment__c> serviceAppointments;

            if(params.containsKey('year')) {
                year = String.valueOf(params.get('year'));
            }
            if(params.containsKey('month')) {
                month = String.valueOf(params.get('month'));
            }
            if(params.containsKey('day')) {
                day = String.valueOf(params.get('day'));
            }

            if(String.isNotBlank(year) && String.isNotBlank(month) && String.isNotBlank(day)) {
                Date dt = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day));

                serviceAppointments = [SELECT Id, Name, OwnerId, WO_Type__c, Activity__c, Approver__c, Assigned_Date__c, Status__c,
                                    Work_Order__c, Due_Date__c, Territory__c, Scheduled_Start__c,
                                    Case__c, Case__r.CaseNumber, Case__r.AccountId, Case__r.Account.Name,
                                    Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.MobilePhone,
                                    Case__r.Contact.Name, Case__r.Contact.Email, Case__r.Contact.MobilePhone,
                                    Case__r.Asset.SerialNumber
                                    FROM Service_Appointment__c
                                    WHERE OwnerId =: UserInfo.getUserId() AND Scheduled_Start__c =: dt AND Case__r.IsClosed = false];
            }
            else if(String.isNotBlank(year) && String.isNotBlank(month) && String.isBlank(day)) {
                Date startDt = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month) + 1, 1);
                Date endDt = startDt.addMonths(1).addDays(-1);

                serviceAppointments = [SELECT Id, Name, OwnerId, WO_Type__c, Activity__c, Approver__c, Assigned_Date__c, Status__c,
                                    Work_Order__c, Due_Date__c, Territory__c, Scheduled_Start__c,
                                    Case__c, Case__r.CaseNumber, Case__r.AccountId, Case__r.Account.Name,
                                    Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.MobilePhone,
                                    Case__r.Contact.Name, Case__r.Contact.Email, Case__r.Contact.MobilePhone,
                                    Case__r.Asset.SerialNumber
                                    FROM Service_Appointment__c
                                    WHERE OwnerId =: UserInfo.getUserId() AND Scheduled_Start__c >=: startDt AND Scheduled_Start__c <=: endDt AND Case__r.IsClosed = false];
            }
            return serviceAppointments;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}