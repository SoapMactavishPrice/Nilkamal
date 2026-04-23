/**
 * @author Aditya Zagade
 * @since 1 Dec 2024
 *
 * @group Field Service
 */
public with sharing class FieldServiceInProgressScheduleController {

    /**
     * @description Method to get schedule list
     * @param month
     * @param year
     * @return  `Object`
     * @exception Throws an AuraHandledException
     * @example
     * Object scheduleList = FieldServiceInProgressScheduleController.getScheduleList('1', '2023');
     */
    @AuraEnabled(cacheable=true)
    public static Object getScheduleList(String month, String year) {
        try {
            Date startDate = Date.newInstance(Integer.valueOf(year), Integer.valueOf(month) + 1, 1);
            Date endDate = startDate.addMonths(1).addDays(-1);

            List<Service_Appointment__c> serviceAppointments;
            serviceAppointments = [SELECT Id, Name, OwnerId, WO_Type__c, Activity__c, Approver__c, Assigned_Date__c, Status__c,
                                Work_Order__c, Due_Date__c, Territory__c, Scheduled_Start__c, Scheduled_End__c,
                                Case__c, Case__r.CaseNumber, Case__r.AccountId, Case__r.Account.Name,
                                Case__r.Contact.FirstName, Case__r.Contact.LastName, Case__r.Contact.Salutation, Case__r.Contact.Email, Case__r.Contact.MobilePhone,
                                Partner_Function_Address_Information__c, Partner_Function_Address_Information__r.Name,
                                Partner_Function_Address_Information__r.Address_line_1__c, Partner_Function_Address_Information__r.Address_line_2__c,
                                Partner_Function_Address_Information__r.Address_line_3__c,
                                Partner_Function_Address_Information__r.City__c, Partner_Function_Address_Information__r.District__c,
                                Partner_Function_Address_Information__r.State__c, Partner_Function_Address_Information__r.Country__c,
                                Partner_Function_Address_Information__r.Pin_Code__c, Partner_Function_Address_Information__r.GeoLocation__c,
                                Partner_Function_Address_Information__r.GeoLocation__Latitude__s, Partner_Function_Address_Information__r.GeoLocation__Longitude__s
                                FROM Service_Appointment__c
                                WHERE OwnerId =: UserInfo.getUserId()
                                AND Scheduled_Start__c >=: startDate AND Scheduled_Start__c <=: endDate];

            return serviceAppointments;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}