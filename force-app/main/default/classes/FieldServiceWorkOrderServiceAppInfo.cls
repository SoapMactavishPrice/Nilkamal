/**
* @author Aditya Zagade
* @since 3 jan 2025
*
* @group Field Service
*/
public with sharing class FieldServiceWorkOrderServiceAppInfo {

    /**
    * @description Method to get service appointment details
    * @param recordId
    * @return  `Service_Appointment__c`
    * @exception Throws an AuraHandledException
    * @example
    * Service_Appointment__c serviceAppointment = FieldServiceWorkOrderServiceAppInfo.getServiceAppointmentDetails('0015g00000Ie2PfAAL');
    */
    @AuraEnabled
    public static Service_Appointment__c getServiceAppointmentDetails(String recordId) {
        try {
            return [
                SELECT Id, OwnerId, Check_In_Date_Time__c, Remote_Support__c, Is_Additional_Resource__c, Assigned_Date__c, WO_Type__c, Due_Date__c, Work_Order__c, Territory__c,
                Case__r.CaseNumber, Case__r.Type, Case__r.Case_Sub_Type__c, Case__r.Subject, Case__r.Description, Case__r.Approval_Status__c, Case__r.OwnerId,
                Case__r.ContactId, Case__r.Contact.Name, Case__r.Contact.MobilePhone, Case__r.Contact.Email,
                Case__r.Case_Notified_By__c, Case__r.Case_Notified_By__r.Name, Case__r.Case_Notified_By__r.MobilePhone, Case__r.Case_Notified_By__r.Email,
                Case__r.AccountId, Case__r.Account.Name, Case__r.Account.Customer_Blocked__c,
                Case__r.Case_Pincode__c, Case__r.Case_Pincode__r.Name, Case__r.Region__c, Case__r.Division__c,
                Case__r.Asset.Name, Case__r.Asset.Ship_to_Address__c, Case__r.Asset.Ship_To_City__c, Case__r.Asset.Ship_To_Region__c, Case__r.Asset.Ship_to_Pin__c, Case__r.Asset.Ship_to_Country__c,
                Case__r.Asset.Product2.Material_Group_5__c,
                Case__r.IsClosed, Case__r.Additional_Resource_Request_Date_Time__c, Case__r.Additional_Resource_Request_Comment__c,
                Case__r.Additional_Resource_Request_RSM_Comment__c, Case__r.Additional_Resource_Request__c,
                Case__r.Reassignment_Request_Date_Time__c, Case__r.Reassignment_Request_Comment__c,
                Case__r.Reassignment_Request_RSM_Comment__c, Case__r.Reassignment_Request__c,
                (
                    SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId,
                    ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.VersionDataURL,
                    ContentDocument.LatestPublishedVersion.ContentSize
                    FROM ContentDocumentLinks
                    ORDER BY ContentDocument.LatestPublishedVersion.CreatedDate
                ),
                (
                    SELECT Id, Name, Is_auto_checked_out_by_system__c, Is_auto_checked_out_by_system_on_Transf__c, IsCheckedOut__c,
                    Check_In_Date_Time__c, Check_In_GeoLocation__c, Check_In_GeoLocation__latitude__s, Check_In_GeoLocation__longitude__s,
                    Check_Out_Date_Time__c, Check_Out_GeoLocation__c, Check_Out_GeoLocation__latitude__s, Check_Out_GeoLocation__longitude__s
                    FROM Service_Appointment_Check_Ins_and_Outs__r
                    WHERE Check_In_Date_Time__c != null AND IsCheckedOut__c = false
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                )
                FROM Service_Appointment__c
                WHERE Id = :recordId];
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean getCheckInStatus(String recordId) {
        try {
            Service_Appointment__c ser= [
                SELECT Id,Check_In_Date_Time__c
                FROM Service_Appointment__c
                WHERE Id = :recordId];
                if(ser.Check_In_Date_Time__c == null) {
                    return true;
                }
                else {
                    return false;
                }
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to update the check in location of the service appointment
     * @param recordId
     * @param latitude
     * @param longitude
     * @return  `Service_Appointment__c`
     * @exception Throws an AuraHandledException
     * @example
     * Service_Appointment__c serviceAppointment = FieldServiceWorkOrderServiceAppInfo.updateCheckInLocation('0015g00000Ie2PfAAL', 12.971599, 77.594563);
     */
    @AuraEnabled
    public static Service_Appointment__c updateCheckInLocation(String recordId, Decimal latitude, Decimal longitude, String deviceType) {
        try {
            List<Service_Appointment_Check_In_and_Out__c> serviceAppCheckInOutList = [
                SELECT Id, Check_In_Date_Time__c, Check_Out_Date_Time__c,
                Service_Appointment__c, Service_Appointment__r.Name, Service_Appointment__r.Case__r.CaseNumber
                FROM Service_Appointment_Check_In_and_Out__c
                WHERE Service_Appointment__c != :recordId AND
                Service_Appointment__r.OwnerId = :UserInfo.getUserId() AND
                Check_In_Date_Time__c = TODAY AND
                IsCheckedOut__c = FALSE AND
                // Service_Appointment__r.Status__c != 'Completed' AND
                Service_Appointment__r.Case__r.IsClosed = false
            ];

            if(!serviceAppCheckInOutList.isEmpty()) {
                Service_Appointment_Check_In_and_Out__c serviceAppCheckInOut = serviceAppCheckInOutList[0];
                throw new CustomException(
                    'You are already checked in to ' + serviceAppCheckInOut.Service_Appointment__r.Name +
                    ' (Case: ' + serviceAppCheckInOut.Service_Appointment__r.Case__r.CaseNumber + ')' +
                    ' at ' + serviceAppCheckInOut.Check_In_Date_Time__c.format('dd MMM yyyy hh:mm a')
                );
            }

            Service_Appointment__c serviceAppointment = [
                SELECT Id, Check_In_Date_Time__c, Check_In_GeoLocation__c, Check_In_GeoLocation__latitude__s, Check_In_GeoLocation__longitude__s,
                Case__c, Case__r.Status, Case__r.Is_service_appointment_checked_in__c
                FROM Service_Appointment__c
                WHERE Id = :recordId
            ];

            Service_Appointment_Check_In_and_Out__c checkIn = new Service_Appointment_Check_In_and_Out__c();
            checkIn.Service_Appointment__c = serviceAppointment.Id;
            checkIn.Check_In_GeoLocation__latitude__s = latitude;
            checkIn.Check_In_GeoLocation__longitude__s = longitude;
            checkIn.Check_In_Date_Time__c = System.now();
            checkIn.Check_In_Device_Type__c = deviceType;

            insert checkIn;

            if(serviceAppointment.Check_In_Date_Time__c == null) {
                serviceAppointment.Check_In_GeoLocation__latitude__s = latitude;
                serviceAppointment.Check_In_GeoLocation__longitude__s = longitude;
                serviceAppointment.Check_In_Date_Time__c = System.now();
                update serviceAppointment;
            }

            Case caseObj = new Case();
            if(serviceAppointment.Case__r.Is_service_appointment_checked_in__c == false) {
                caseObj.Id = serviceAppointment.Case__c;
                caseObj.Is_service_appointment_checked_in__c = true;
            }
            if(serviceAppointment.Case__r.Status == 'New' || serviceAppointment.Case__r.Status == 'Assigned') {
                caseObj.Id = serviceAppointment.Case__c;
                caseObj.Status = 'Working';
            }
            if(caseObj.Id != null) {
                update caseObj;
            }

            return getServiceAppointmentDetails(recordId);
        }
        catch(DmlException e) {
            String msg;
            if(e.getNumDml() > 0) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            System.debug(msg);
            throw new CustomException(msg);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateRescheduleDate(String recordId,String scheduleDate) {
        try {

            Service_Appointment__c serviceAppointment = [
                SELECT Id, Scheduled_Start__c,Check_In_GeoLocation__c, Check_In_GeoLocation__latitude__s, Check_In_GeoLocation__longitude__s
                FROM Service_Appointment__c
                WHERE Id = :recordId
            ];
            serviceAppointment.Scheduled_Start__c=Date.valueOf(scheduleDate);
            UPDATE serviceAppointment;
        }
        catch(DmlException e) {
            String msg;
            if(e.getNumDml() > 0) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            System.debug(msg);
            throw new CustomException(msg);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * @description Method to update the check out location of the service appointment
     * @param recordId
     * @param latitude
     * @param longitude
     * @return  `Service_Appointment__c`
     * @exception Throws an AuraHandledException
     * @example
     * Service_Appointment__c serviceAppointment = FieldServiceWorkOrderServiceAppInfo.updateCheckOutLocation('0015g00000Ie2PfAAL', 12.971599, 77.594563, Date.today().addDays(1));
     */
    @AuraEnabled
    public static Service_Appointment__c updateCheckOutLocation(String recordId, Decimal latitude, Decimal longitude, String deviceType, Date nextVisitDate) {
        try {
            Service_Appointment__c serviceAppointment = [SELECT Id, Assigned_Date__c, Is_Additional_Resource__c,
                                                        Case__r.Status, Case__r.CaseNumber, Case__r.Asset.SerialNumber, Work_Order__c
                                                        FROM Service_Appointment__c
                                                        WHERE Id = :recordId];

            if(serviceAppointment.Is_Additional_Resource__c == false) {
                Integer spareRequestCount = [
                    SELECT COUNT() FROM Spare_Request__c WHERE Service_Appointment__c = :recordId
                ];
                Integer serviceRequestCount = [
                    SELECT COUNT() FROM Service_Request__c WHERE Service_Appointment__c = :recordId
                ];
                Integer workOrderChecklistCount = [
                    SELECT COUNT() FROM Work_Order_Checklist__c WHERE Service_Appointment__c = :recordId
                ];

                if (spareRequestCount == 0 && serviceRequestCount == 0 && workOrderChecklistCount == 0) {
                    // throw new CustomException('No related records found in Spare Request, Service Request, or Checklist. Please add at least one before checkout.');
                }

                List<Work_Order__c> workOrders = [SELECT Id,
                                                (SELECT Id FROM Installation_Reports__r),
                                                (SELECT Id FROM Service_Reports__r)
                                                FROM Work_Order__c
                                                WHERE Id = :serviceAppointment.Work_Order__c];

                Work_Order__c wo = workOrders[0];

                Boolean hasInstallationReport = !wo.Installation_Reports__r.isEmpty();
                Boolean hasServiceReport = !wo.Service_Reports__r.isEmpty();

                if (!hasInstallationReport && !hasServiceReport) {
                    // throw new CustomException('Service Report or Installation report is mandatory before checkout.');
                }
            }


            List<Service_Appointment_Check_In_and_Out__c> checkInRecords = new List<Service_Appointment_Check_In_and_Out__c>();
            checkInRecords = [SELECT Id, Check_In_GeoLocation__c, Check_Out_GeoLocation__c
                        FROM Service_Appointment_Check_In_and_Out__c
                        WHERE Service_Appointment__c = :recordId AND CreatedById = :UserInfo.getUserId() AND IsCheckedOut__c = FALSE
                        ORDER BY Check_In_Date_Time__c DESC
                        LIMIT 1];

            if(checkInRecords.size() == 0) {
                throw new CustomException('No check-in found for this service appointment, please refresh the page and try again.');
            }


            Service_Appointment_Check_In_and_Out__c checkOut = checkInRecords[0];
            checkOut.Check_Out_GeoLocation__latitude__s = latitude;
            checkOut.Check_Out_GeoLocation__longitude__s = longitude;
            checkOut.Check_Out_Date_Time__c = System.now();
            checkOut.Check_Out_Device_Type__c = deviceType;
            update checkOut;

            serviceAppointment = new Service_Appointment__c();
            serviceAppointment.Id = recordId;
            serviceAppointment.Check_Out_GeoLocation__latitude__s = latitude;
            serviceAppointment.Check_Out_GeoLocation__longitude__s = longitude;
            serviceAppointment.Check_Out_Date_Time__c = System.now();
            serviceAppointment.Check_Out_Address_Error__c = '';
            update serviceAppointment;

            sendEmailOnCheckout(serviceAppointment);

            if(nextVisitDate != null) {
                serviceAppointment = [SELECT Id, Name, WO_Type__c, Activity__c, Assigned_Date__c, Case__c, Account__c, Work_Order__c, Due_Date__c, Address__c, Territory__c,
                                    Scheduled_Start__c, Partner_Function_Address_Information__c, Check_In__c, Meeting_Interaction_Note__c, Contact__c
                                    FROM Service_Appointment__c
                                    WHERE Id = :recordId];

                Service_Appointment__c newServiceAppointment = new Service_Appointment__c();
                newServiceAppointment.Case__c = serviceAppointment.Case__c;
                newServiceAppointment.Work_Order__c = serviceAppointment.Work_Order__c;
                newServiceAppointment.Account__c = serviceAppointment.Account__c;
                newServiceAppointment.Contact__c = serviceAppointment.Contact__c;
                newServiceAppointment.WO_Type__c = serviceAppointment.WO_Type__c;
                newServiceAppointment.Activity__c = serviceAppointment.Activity__c;
                newServiceAppointment.Assigned_Date__c = serviceAppointment.Assigned_Date__c;
                newServiceAppointment.Due_Date__c = serviceAppointment.Due_Date__c;
                newServiceAppointment.Address__c = serviceAppointment.Address__c;
                newServiceAppointment.Territory__c = serviceAppointment.Territory__c;
                newServiceAppointment.Scheduled_Start__c = nextVisitDate;
                newServiceAppointment.Partner_Function_Address_Information__c = serviceAppointment.Partner_Function_Address_Information__c;

                insert newServiceAppointment;
                return newServiceAppointment;
            }

            return serviceAppointment;
        }
        catch(DmlException e) {
            String msg;
            if(e.getNumDml() > 0) {
                msg = e.getDmlMessage(0);
            } else {
                msg = e.getMessage();
            }
            System.debug(msg);
            throw new CustomException(msg);
        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static void sendEmailOnCheckout(Service_Appointment__c sa) {
        try {
            Service_Report__c serviceReport;
            try {
                serviceReport = [SELECT Id, Name, Customer_Email__c,Service_Appointment__r.Case__c,Service_Appointment__r.Scheduled_Start__c
                                FROM Service_Report__c
                                WHERE Service_Appointment__c =: sa.Id AND IsSavedByUser__c = TRUE
                                ORDER BY LastModifiedDate DESC LIMIT 1];
            }
            catch(Exception e) {
                System.debug(e.getLineNumber() + ' ' + e.getMessage());
                return;
            }

            sa = [SELECT Id, Name, WO_Type__c, Activity__c, Assigned_Date__c, Work_Order__c, Due_Date__c, Address__c, Territory__c,
                    Scheduled_Start__c, Partner_Function_Address_Information__c, Check_In__c, Meeting_Interaction_Note__c,
                    Case__r.CaseNumber, Case__r.Asset.SerialNumber, Case__r.Contact.Name, Case__r.Contact.MobilePhone, Case__r.Contact.Email, Case__r.Case_Notified_By__r.Email,
                    Case__r.Status
                    FROM Service_Appointment__c
                    WHERE Id = :sa.Id];

            String formattedDate = 'N/A';
            if (sa.Assigned_Date__c != null) {
                Integer day = sa.Assigned_Date__c.day();
                Integer month = sa.Assigned_Date__c.month();
                Integer year = sa.Assigned_Date__c.year();

                String dayStr = (day < 10 ? '0' : '') + String.valueOf(day);
                String monthStr = (month < 10 ? '0' : '') + String.valueOf(month);
                formattedDate = dayStr + '/' + monthStr + '/' + String.valueOf(year);
            }

            String subject = 'Case Number: ' + sa.Case__r.CaseNumber +
                ' Serial Number: ' + (sa.Case__r.Asset != null ? sa.Case__r.Asset.SerialNumber : 'N/A') +
                ' Visit Date - ' + formattedDate;

            String body = 'Dear ' + sa.Case__r.Contact.Name + ',<br/><br/>' +
                'This is to inform you that your service appointment is now at the "' + sa.Case__r.Status + '" stage.<br/><br/>' +
                'Complaint Number: ' + sa.Case__r.CaseNumber + '<br/>' +
                'Serial Number: ' + (sa.Case__r.Asset != null ? sa.Case__r.Asset.SerialNumber : 'N/A') + '<br/>' +
                'Visit Date: ' + formattedDate + '<br/><br/>' +
                //'Case Owner: ' + sa.Case__r.Owner.Name + '<br/>' +
                //'Case Owner Email: ' + sa.Case__r.Owner.Email + '<br/>' +
                'Thank you for choosing our service.';

            PageReference pdfPage = Page.ServiceReportPDF;
            pdfPage.getParameters().put('id', serviceReport.Id);
            pdfPage.getParameters().put('isPreview',  'true');

            Blob pdfBlob;
            if(Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('test');
            }
            else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            Messaging.EmailFileAttachment pdfAttachment = new Messaging.EmailFileAttachment();
            pdfAttachment.setFileName('Service_Report_' + serviceReport.Name + '.pdf');
            pdfAttachment.setBody(pdfBlob);
            pdfAttachment.setContentType('application/pdf');

            Set<String> emailIds = new Set<String>();
            if(String.isNotBlank(sa.Case__r.Contact.Email)) {
                emailIds.add(sa.Case__r.Contact.Email);
            }
            if(String.isNotBlank(sa.Case__r.Case_Notified_By__r.Email)) {
                emailIds.add(sa.Case__r.Case_Notified_By__r.Email);
            }
            if(String.isNotBlank(serviceReport.Customer_Email__c)) {
                emailIds.add(serviceReport.Customer_Email__c);
            }
            // 
            //     List<Service_Appointment__c> additionalResourceServiceAppointments = [
            //     SELECT Id, Owner.Email
            //     FROM Service_Appointment__c
            //     WHERE Case__c = :serviceReport.Service_Appointment__r.Case__c
            //     // AND Scheduled_Start__c = :serviceReport.Service_Appointment__r.Scheduled_Start__c
            //     AND Check_In_Date_Time__c != NULL
            //     AND Is_Additional_Resource__c = TRUE
            //     AND Remote_Support__c = FALSE
            // ];

            // for (Service_Appointment__c additionalSA : additionalResourceServiceAppointments) {
            //     if (additionalSA.Owner != null && String.isNotBlank(additionalSA.Owner.Email)) {
            //         emailIds.add(additionalSA.Owner.Email);
            //         System.debug('Added Additional Resource Email: ' + additionalSA.Owner.Email + ' (Owner: ' + additionalSA.Owner.Name + ')');
            //     }
            // }

            if (serviceReport.Service_Appointment__r != null) {
                Id caseId = serviceReport.Service_Appointment__r.Case__c;
                DateTime startTime = serviceReport.Service_Appointment__r.Scheduled_Start__c;

                Set<String> additionalEmails = ServiceAppointmentHelper.getAdditionalResourceEmails(caseId, startTime);

                emailIds.addAll(additionalEmails);
            }

            System.debug('Final Email Recipients: ' + emailIds);

            // 

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(emailIds));
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{pdfAttachment});

            if (Label.External_Email_Disabled != 'True') {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
                for (Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        System.debug('Email failed to send. Error: ' + result.getErrors()[0].getMessage());
                    } else {
                        System.debug('Email sent successfully to: ' + sa.Case__r.Contact.Email);
                    }
                }
            }
        }
        catch (Exception e) {
            System.debug('Error while sending email with PDF: ' + e.getMessage());
            throw new CustomException(e.getMessage());
        }
    }

}