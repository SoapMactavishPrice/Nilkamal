public with sharing class FieldServiceOpenAppointmentsController {

    @AuraEnabled
    public static List<Service_Appointment__c> getServiceAppointments(Integer ofst, Integer lmt, String sortBy, String sortDirection) {
        try {
            String query = 'SELECT Id, Remote_Support__c, Is_Additional_Resource__c, Name, OwnerId, WO_Type__c, Activity__c, Approver__c, Assigned_Date__c, Status__c, ' +
                            'Work_Order__c, Due_Date__c, Territory__c, Scheduled_Start__c, ' +
                            'Case__c, Case__r.CaseNumber, Case__r.AccountId, Case__r.Account.Name, Case__r.Type, Case__r.Case_Sub_Type__c, ' +
                            'Case__r.ContactId, Case__r.Contact.Name, Case__r.Contact.Email, Case__r.Contact.MobilePhone, ' +
                            'Case__r.Asset.SerialNumber, Case__r.Asset.Ship_to_Address__c, Case__r.Asset.Ship_To_City__c, Case__r.Asset.Ship_To_Region__c, Case__r.Asset.Ship_to_Pin__c, Case__r.Asset.Ship_to_Country__c, ' +
                            '( ' +
                                'SELECT Id, Name, IsCheckedOut__c, ' +
                                'Check_In_Date_Time__c, Check_In_GeoLocation__c, Check_In_GeoLocation__latitude__s, Check_In_GeoLocation__longitude__s, ' +
                                'Check_Out_Date_Time__c, Check_Out_GeoLocation__c, Check_Out_GeoLocation__latitude__s, Check_Out_GeoLocation__longitude__s ' +
                                'FROM Service_Appointment_Check_Ins_and_Outs__r ' +
                                'WHERE Check_In_Date_Time__c != null AND IsCheckedOut__c = false ' +
                                'ORDER BY CreatedDate DESC ' +
                                'LIMIT 1 ' +
                            ') ' +
                            'FROM Service_Appointment__c ' +
                            'WHERE OwnerId = \'' + UserInfo.getUserId() + '\' ' +
                            'AND Case__r.IsClosed = false ' +
                            'AND (Case__r.OwnerId = \'' + UserInfo.getUserId() + '\' OR Is_Additional_Resource__c = true) ' +
                            'AND (Scheduled_Start__c = TODAY OR Check_In_Date_Time__c = null) ';

            if (String.isNotBlank(sortBy) && String.isNotBlank(sortDirection)) {
                query += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' ';
            }
            else {
                query += 'ORDER BY Scheduled_Start__c ASC ';
            }

            if(ofst != null && lmt != null) {
                query += 'LIMIT ' + lmt + ' OFFSET ' + ofst;
            }

            System.debug(query);

            return Database.query(query);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}