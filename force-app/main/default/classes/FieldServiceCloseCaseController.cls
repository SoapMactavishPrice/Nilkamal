public without sharing class FieldServiceCloseCaseController {

    @AuraEnabled
    public static Object getCaseDetails(String caseId) {
        try {
            Case caseRecord = [
                SELECT Id, CaseNumber, Status, Division__c, Type, Case_Sub_Type__c,
                (SELECT Id, Name FROM Service_Appointment__r)
                FROM Case
                WHERE Id = :caseId
            ];

            return caseRecord;
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }


    // @AuraEnabled
    // public static void closeCase(String caseId, String caseCloseReason, String caseClosureComment, string serviceAppointmentId) {
    //     try { 


    //         List<Service_Appointment__c> serviceAppointments = [
    //             SELECT Id, Name, Case__c, Scheduled_Start__c,
    //             (
    //                 SELECT Id, Name, IsCheckedOut__c
    //                 FROM Service_Appointment_Check_Ins_and_Outs__r
    //                 WHERE IsCheckedOut__c = false
    //             )
    //             FROM Service_Appointment__c
    //             WHERE Case__c = :caseId AND (OwnerId = :UserInfo.getUserId() OR Is_Additional_Resource__c = true)
    //         ];

    //         if (!serviceAppointments.isEmpty()) {
    //             for (Service_Appointment__c sa : serviceAppointments) {
    //                 if(!sa.Service_Appointment_Check_Ins_and_Outs__r.isEmpty()) {
    //                     throw new CustomException('Service Appointment is not checked out - ' + sa.Name + ' dated ' + sa.Scheduled_Start__c.format('dd MMM yyyy'));
    //                 }

    //                 /*
    //                 if (
    //                     sa.Check_In_Date_Time__c != null
    //                     &&
    //                     (
    //                         sa.Check_Out_Date_Time__c == null ||
    //                         (
    //                             sa.Check_Out_Address_Error__c != 'Auto Checked Out by System' &&
    //                             sa.Check_Out_Address_Error__c != 'Auto Checked Out by System on Case Transfer' &&
    //                             String.isNotBlank(sa.Check_Out_Address_Error__c)
    //                         )
    //                     )
    //                 ) {
    //                     throw new CustomException('Service Appointment is not checked out - ' + sa.Name + ' dated ' + sa.Scheduled_Start__c.format('dd MMM yyyy'));
    //                 }
    //                 */
    //             }
    //         }


    //         List<Quote> returnableQuotes = [
    //             SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
    //             FROM Quote
    //             WHERE Case__c = :caseId AND Billing_Type__c = 'FOC and Returnable' AND SAP_Order_No__c != null AND Returnable_Received__c = false
    //         ];

            
    //         if(caseCloseReason == 'Case Closed due to Non-receipt of PO')
    //         {
    //                 List<Case> caseRecord1 = [
    //                 SELECT Id
    //                 FROM Case
    //                 WHERE Id = :caseId and Case_Sub_Type__c like '%Chargeable%'];
    //                 if (!caseRecord1.isEmpty())
    //                 {
    //                     List<Quote> PoReceivedQuotes = [
    //                         SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
    //                         FROM Quote
    //                         WHERE Case__c = :caseId  AND Status IN ('Presented','Negotiation','PO Received','Order Created','Error in Order','Denied','Amendment')
    //                     ];


    //                     if(PoReceivedQuotes.isEmpty()){
    //                         throw new CustomException('To close the Case, for Chargable Quote status should be above presented');
    //                     }


    //                 }
            
    //         }




    //         if (!returnableQuotes.isEmpty()) {
    //             throw new CustomException('Returnable sample is not yet received. Case cannot be closed.');
    //         }


    //         Case caseRecord = [
    //             SELECT Id, Status, Comments, IsClosed,OEM_Discussion__c,Additional_Resource_Request__c, Reassignment_Request__c
    //             FROM Case
    //             WHERE Id = :caseId];

    //         if(caseRecord.IsClosed) {
    //             throw new CustomException('Case is already closed');
    //         }

    //         if (caseRecord.OEM_Discussion__c == true) {
    //             throw new CustomException('You cannot close this Case because OEM Discussion is true.');
    //         }

    //         List<Spare_Material_Request__c> smrList = [
    //             SELECT Id, Status__c
    //             FROM Spare_Material_Request__c
    //             WHERE Case__c = :caseId
    //             AND Status__c != 'Completed'
    //         ];

    //         if (!smrList.isEmpty()) {
    //             throw new CustomException('You cannot close this Case because there is a Spare Material Request that is not Completed.');
    //         }
            
    //         caseRecord.Status = 'Closed';
    //         caseRecord.IsClosingFromCustomUI__c = true;
    //         caseRecord.Case_Closure_Reason__c = caseCloseReason;
    //         caseRecord.Case_Closure_Comments__c = caseClosureComment;
    //         if(caseRecord.Additional_Resource_Request__c == 'Requested') { //25-08 
    //             caseRecord.Additional_Resource_Request__c = 'Rejected'; //25-08 
    //             caseRecord.Additional_Resource_Request_RSM_Comment__c = 'Case already closed.'; //25-08
    //         }
    //         if (caseRecord.Reassignment_Request__c == 'Requested'){ //25-08
    //             caseRecord.Reassignment_Request__c = 'Rejected'; //25-08 
    //             caseRecord.Reassignment_Request_Comment__c = 'Case already closed.'; //25-08
    //         }
    //         update caseRecord;

    //         caseRecord = [
    //             SELECT Id, Status, Comments, AssetId,CaseNumber,Case_Comments__c,ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, Contact.Name,OwnerId,ClosedDate
    //             FROM Case
    //             WHERE Id = :caseId];

    //         Asset asset = [
    //             SELECT Id, Service_Resource__c
    //             FROM Asset
    //             WHERE Id = :caseRecord.AssetId
    //         ];

    //         // Fetch Service Resource based on Case Owner
    //         Service_Resource__c serviceResource = [
    //             SELECT Id, Name, User__c, Coordinator__c, Coordinator__r.Name, Coordinator__r.Email, Coordinator__r.MobilePhone,
    //                 RSM__c, RSM__r.Name, RSM__r.Email, RSM__r.MobilePhone,Coordinator__r.Manager.Name,Coordinator__r.Manager.Email,Coordinator__r.Manager.MobilePhone
    //             FROM Service_Resource__c
    //             WHERE User__c = :caseRecord.OwnerId
    //             LIMIT 1
    //         ];

    //         if(asset.Service_Resource__c != serviceResource.Id) {
    //             asset.Service_Resource__c = serviceResource.Id;
    //             Database.update(asset, true, AccessLevel.SYSTEM_MODE);
    //         }

    //         List<String> recipientEmails = new List<String>();

    //         if(caseRecord.Contact.Email != null) {
    //             recipientEmails.add(caseRecord.Contact.Email);
    //         }

    //         if (serviceResource.Coordinator__r != null && serviceResource.Coordinator__r.Email != null) {
    //             recipientEmails.add(serviceResource.Coordinator__r.Email);
    //         }

    //         if (serviceResource.RSM__r != null && serviceResource.RSM__r.Email != null) {
    //             recipientEmails.add(serviceResource.RSM__r.Email);
    //         }

    //         if (serviceResource.Coordinator__r != null && serviceResource.Coordinator__r.Manager != null
    //             && serviceResource.Coordinator__r.Manager.Email != null) {
    //             recipientEmails.add(serviceResource.Coordinator__r.Manager.Email);
    //         }

    //         if (!recipientEmails.isEmpty()) {
    //             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //             mail.setToAddresses(recipientEmails);
    //             mail.setSubject('Case Closed: ' + caseRecord.CaseNumber);

    //             mail.setPlainTextBody(
    //                 'Thank you for choosing Nilkamal.\n\n' +
    //                 'Please be informed that your Case ' + caseRecord.CaseNumber +
    //                 (caseRecord.ClosedDate != null ? ' dated ' + caseRecord.ClosedDate.format('dd-MM-yyyy') : '') +
    //                 ' has been closed successfully.\n\n' +
    //                 'Best Regards,\n' +
    //                 'Nilkamal Service Team'
    //             );

    //             if (Label.External_Email_Disabled != 'True') {
    //                 Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
    //         }
    //         }

    //     }
    //     catch (Exception e) {
    //         System.debug(e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
    //         throw new AuraHandledException(e.getMessage());
    //     }
    // }


    @AuraEnabled
    public static void closeCase(String caseId, String caseCloseReason, String caseClosureComment, string serviceAppointmentId) {
        try { 
            // ---------------------------------------------------
            // NEW VALIDATION ADDED HERE
            System.debug('isCaseClose ' + Label.isCaseClose);
            if(Label.isCaseClose == 'True') {
                if(String.isNotBlank(serviceAppointmentId)) {
                    Case currentCase = [SELECT Id, Type, Case_Sub_Type__c FROM Case WHERE Id = :caseId LIMIT 1];
                    
                    Boolean skipReportCheck = false;
                    if(currentCase.Type == 'Installation') {
                        skipReportCheck = true;
                        System.debug('Skipping report check for Installation case');
                    }
                    
                    else if(currentCase.Type == 'Re-Installation') {
                        skipReportCheck = true;
                        System.debug('Skipping report check for Re-Installation case');
                    }
            
                    else if(currentCase.Type == 'Courtesy') {
                        Set<String> skipSubTypes = new Set<String>{
                            'Quote Negotiation', 
                            'AMC Business', 
                            'Spare Business', 
                            'Payment Collection'
                        };
                        if(skipSubTypes.contains(currentCase.Case_Sub_Type__c)) {skipReportCheck = true;
                        }
                    }
                    
                    if(!skipReportCheck) {
                        System.debug('serviceAppointmentId'+serviceAppointmentId);
                        
                        // Check if service report exists
                        List<Service_Report__c> serviceReports = [
                            SELECT Id 
                            FROM Service_Report__c 
                            WHERE Service_Appointment__c = :serviceAppointmentId
                            LIMIT 1
                        ];
                        
                        System.debug('serviceReports'+serviceReports);
                        
                        // If NO service report exists, throw exception
                        if(serviceReports.isEmpty()) {
                            Service_Appointment__c sa = [SELECT Name, Scheduled_Start__c 
                                                        FROM Service_Appointment__c 
                                                        WHERE Id = :serviceAppointmentId LIMIT 1];
                            System.debug('Saaaaaa'+sa);
                            throw new CustomException('Service Appointment has no report - ' + 
                                sa.Name + ' dated ' + sa.Scheduled_Start__c.format('dd MMM yyyy'));
                        }
                    }
                }
            }
            // ---------------------------------------------------
            
            // EXISTING CODE STARTS HERE
            List<Service_Appointment__c> serviceAppointments = [
                SELECT Id, Name, Case__c, Scheduled_Start__c,
                (
                    SELECT Id, Name, IsCheckedOut__c
                    FROM Service_Appointment_Check_Ins_and_Outs__r
                    WHERE IsCheckedOut__c = false
                )
                FROM Service_Appointment__c
                WHERE Case__c = :caseId AND (OwnerId = :UserInfo.getUserId() OR Is_Additional_Resource__c = true)
            ];

            if (!serviceAppointments.isEmpty()) {
                for (Service_Appointment__c sa : serviceAppointments) {
                    if(!sa.Service_Appointment_Check_Ins_and_Outs__r.isEmpty()) {
                        throw new CustomException('Service Appointment is not checked out - ' + sa.Name + ' dated ' + sa.Scheduled_Start__c.format('dd MMM yyyy'));
                    }

                    /*
                    if (
                        sa.Check_In_Date_Time__c != null
                        &&
                        (
                            sa.Check_Out_Date_Time__c == null ||
                            (
                                sa.Check_Out_Address_Error__c != 'Auto Checked Out by System' &&
                                sa.Check_Out_Address_Error__c != 'Auto Checked Out by System on Case Transfer' &&
                                String.isNotBlank(sa.Check_Out_Address_Error__c)
                            )
                        )
                    ) {
                        throw new CustomException('Service Appointment is not checked out - ' + sa.Name + ' dated ' + sa.Scheduled_Start__c.format('dd MMM yyyy'));
                    }
                    */
                }
            }


            List<Quote> returnableQuotes = [
                SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
                FROM Quote
                WHERE Case__c = :caseId AND Billing_Type__c = 'FOC and Returnable' AND SAP_Order_No__c != null AND Returnable_Received__c = false
            ];

            // if(caseCloseReason == 'Case Closed due to Non-receipt of PO'){
            //         List<Case> caseRecord1 = [
            //         SELECT Id
            //         FROM Case
            //         WHERE Id = :caseId];
            //         if (!caseRecord1.isEmpty())
            //         {
            //             List<Quote> PoReceivedQuotes = [
            //                 SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
            //                 FROM Quote
            //                 WHERE Case__c = :caseId  AND Status IN ('Presented','Negotiation','PO Received','Order Created','Error in Order','Denied','Amendment') AND Billing_Type__c LIKE '%Chargeable%'
            //             ];


            //             if(PoReceivedQuotes.isEmpty()){
            //                 throw new CustomException('To close the Case, for Chargable Quote status should be above presented');
            //             }
            //         }
            // }
            if(Label.isCaseClose == 'True') {
                if (caseCloseReason == 'Case Closed due to Non-receipt of PO') {
                    // First, check if any quotes exist for this case
                    List<Quote> allQuotesForCase = [
                        SELECT Id
                        FROM Quote
                        WHERE Case__c = :caseId
                        LIMIT 1
                    ];
                    
                    // If no quotes exist at all
                    if (allQuotesForCase.isEmpty()) {throw new CustomException('Cannot close the Case. First create at least one Chargeable Quote before closing the case.');
                    }
                    
                    // If quotes exist, check for chargeable quotes with appropriate status
                    List<Quote> PoReceivedQuotes = [
                        SELECT Id, Case__c, Billing_Type__c, SAP_Order_No__c, Returnable_Received__c
                        FROM Quote
                        WHERE Case__c = :caseId 
                        AND Status IN ('Presented', 'Negotiation', 'PO Received', 'Order Created', 'Error in Order', 'Denied', 'Amendment')
                        AND Billing_Type__c LIKE '%Chargeable%'
                    ];
                    
                    if (PoReceivedQuotes.isEmpty()) {throw new CustomException('To close the Case, at least Quote must have status above "Presented"');
                    }
                }
            }
            
            




            if (!returnableQuotes.isEmpty()) {
                throw new CustomException('Returnable sample is not yet received. Case cannot be closed.');
            }


            Case caseRecord = [
                SELECT Id, Status, Comments, IsClosed,OEM_Discussion__c,Additional_Resource_Request__c, Reassignment_Request__c
                FROM Case
                WHERE Id = :caseId];

            if(caseRecord.IsClosed) {
                throw new CustomException('Case is already closed');
            }

            if (caseRecord.OEM_Discussion__c == true) {
                throw new CustomException('You cannot close this Case because OEM Discussion is true.');
            }

            List<Spare_Material_Request__c> smrList = [
                SELECT Id, Status__c
                FROM Spare_Material_Request__c
                WHERE Case__c = :caseId
                AND Status__c != 'Completed'
            ];

            if (!smrList.isEmpty()) {
                throw new CustomException('You cannot close this Case because there is a Spare Material Request that is not Completed.');
            }
            
            caseRecord.Status = 'Closed';
            caseRecord.IsClosingFromCustomUI__c = true;
            caseRecord.Case_Closure_Reason__c = caseCloseReason;
            caseRecord.Case_Closure_Comments__c = caseClosureComment;
            if(caseRecord.Additional_Resource_Request__c == 'Requested') { //25-08 
                caseRecord.Additional_Resource_Request__c = 'Rejected'; //25-08 
                caseRecord.Additional_Resource_Request_RSM_Comment__c = 'Case already closed.'; //25-08
            }
            if (caseRecord.Reassignment_Request__c == 'Requested'){ //25-08
                caseRecord.Reassignment_Request__c = 'Rejected'; //25-08 
                caseRecord.Reassignment_Request_Comment__c = 'Case already closed.'; //25-08
            }
            update caseRecord;

            caseRecord = [
                SELECT Id, Status, Comments, AssetId,CaseNumber,Case_Comments__c,ContactId, Contact.Email, Contact.MobilePhone, Contact.Phone, Contact.Name,OwnerId,ClosedDate
                FROM Case
                WHERE Id = :caseId];

            Asset asset = [
                SELECT Id, Service_Resource__c
                FROM Asset
                WHERE Id = :caseRecord.AssetId
            ];

            // Fetch Service Resource based on Case Owner
            Service_Resource__c serviceResource = [
                SELECT Id, Name, User__c, Coordinator__c, Coordinator__r.Name, Coordinator__r.Email, Coordinator__r.MobilePhone,
                    RSM__c, RSM__r.Name, RSM__r.Email, RSM__r.MobilePhone,Coordinator__r.Manager.Name,Coordinator__r.Manager.Email,Coordinator__r.Manager.MobilePhone
                FROM Service_Resource__c
                WHERE User__c = :caseRecord.OwnerId
                LIMIT 1
            ];

            if(asset.Service_Resource__c != serviceResource.Id) {
                asset.Service_Resource__c = serviceResource.Id;
                Database.update(asset, true, AccessLevel.SYSTEM_MODE);
            }

            List<String> recipientEmails = new List<String>();

            if(caseRecord.Contact.Email != null) {
                recipientEmails.add(caseRecord.Contact.Email);
            }

            if (serviceResource.Coordinator__r != null && serviceResource.Coordinator__r.Email != null) {
                recipientEmails.add(serviceResource.Coordinator__r.Email);
            }

            if (serviceResource.RSM__r != null && serviceResource.RSM__r.Email != null) {
                recipientEmails.add(serviceResource.RSM__r.Email);
            }

            if (serviceResource.Coordinator__r != null && serviceResource.Coordinator__r.Manager != null
                && serviceResource.Coordinator__r.Manager.Email != null) {
                recipientEmails.add(serviceResource.Coordinator__r.Manager.Email);
            }

            if (!recipientEmails.isEmpty()) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(recipientEmails);
                mail.setSubject('Case Closed: ' + caseRecord.CaseNumber);

                mail.setPlainTextBody(
                    'Thank you for choosing Nilkamal.\n\n' +
                    'Please be informed that your Case ' + caseRecord.CaseNumber +
                    (caseRecord.ClosedDate != null ? ' dated ' + caseRecord.ClosedDate.format('dd-MM-yyyy') : '') +
                    ' has been closed successfully.\n\n' +
                    'Best Regards,\n' +
                    'Nilkamal Service Team'
                );

                if (Label.External_Email_Disabled != 'True') {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
            }
            }

        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    








    @AuraEnabled
    public static Object getChecklistData(String caseId) {
        try {
            List<Work_Order__c> workOrders = [
                SELECT Id
                FROM Work_Order__c
                WHERE Case__c = :caseId
            ];

            List<Work_Order_Checklist__c> workOrderChecklists = new List<Work_Order_Checklist__c>();
            for(Work_Order__c workOrder : workOrders) {
                workOrderChecklists.addAll(FieldServiceCaptureInteraction.getChecklistData(workOrder.Id));
            }

            Map<String, Integer> result = new Map<String, Integer>();
            result.put('total', workOrderChecklists.size());
            result.put('markedYes', 0);
            result.put('markedNo', 0);
            result.put('markedNA', 0);
            result.put('blank', 0);

            for(Work_Order_Checklist__c workOrderChecklist : workOrderChecklists) {
                String observation = workOrderChecklist.Observation__c;
                if(observation == 'Ok') {
                    result.put('markedYes', result.get('markedYes') == null ? 1 : result.get('markedYes') + 1);
                }
                else if(observation == 'Not Ok') { result.put('markedNo', result.get('markedNo') == null ? 1 : result.get('markedNo') + 1);
                }
                else if(observation == 'Not Applicable') { result.put('markedNA', result.get('markedNA') == null ? 1 : result.get('markedNA') + 1);
                }
                else { result.put('blank', result.get('blank') == null ? 1 : result.get('blank') + 1);
                }
            }

            List<Report> reports = [SELECT Id FROM Report WHERE Name = 'Work Order Checklist (Close Case Flow)' LIMIT 1];
            String reportId = reports.isEmpty() ? null : reports[0].Id;

            return new Map<String, Object>{
                'reportId' => reportId,
                'result' => result
            };
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }


    /*
    @AuraEnabled
    public static Object getCountOfActivitiesLogged(String caseId) {
        try {
            List<Service_Appointment__c> serviceAppointments = [
                SELECT Id
                FROM Service_Appointment__c
                WHERE Case__c = :caseId
            ];

            AggregateResult count = [
                SELECT COUNT(Id)
                FROM Task
                WHERE WhatId IN :serviceAppointments
            ];

            List<Report> reports = [SELECT Id FROM Report WHERE Name = 'Activities Logged (Close Case Flow)' LIMIT 1];
            String reportId = reports.isEmpty() ? null : reports[0].Id;

            return new Map<String, Object> {
                'reportId' => reportId,
                'count' => (Integer) count.get('expr0')
            };
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
	*/


    @AuraEnabled
    public static Object getSpareRequestsByStatus(String caseId) {
        try {
            List<AggregateResult> spareRequests = [
                SELECT Billing_Type__c, COUNT(Id) cnt
                FROM Spare_Request__c
                WHERE Case__c = :caseId OR Work_Order__r.Case__c = :caseId
                GROUP BY Billing_Type__c
                ORDER BY Billing_Type__c
            ];

            List<Report> reports = [SELECT Id FROM Report WHERE Name = 'Spare Request (Close Case Flow)' LIMIT 1];
            String reportId = reports.isEmpty() ? null : reports[0].Id;

            return new Map<String, Object> {
                'reportId' => reportId,
                'spareRequests' => spareRequests
            };
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Integer getServiceRequestCount(String caseId) {
        try {
            return [SELECT COUNT()
                    FROM Service_Request__c
                    WHERE Case__c = :caseId
                    OR Work_Order__r.Case__c = :caseId];
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Object getReportGeneratedOrNot(String caseId) {
        try {
            List<Installation_Report__c> installationReports = [
                SELECT Id
                FROM Installation_Report__c
                WHERE Case__c = :caseId
            ];

            List<Service_Report__c> serviceReports = [
                SELECT Id
                FROM Service_Report__c
                WHERE Case__c = :caseId
            ];

            Set<Id> reportIds = new Set<Id>();
            for(Installation_Report__c ir : installationReports) {
                reportIds.add(ir.Id);
            }
            for(Service_Report__c sr : serviceReports) {
                reportIds.add(sr.Id);
            }

            if(reportIds.isEmpty()) {
                return 0;
            }

            List<ContentDocumentLink> contentDocumentLinks = [
                SELECT Id, ContentDocumentId, ContentDocument.Title,
                ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.PathOnClient
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :reportIds
            ];

            Integer finalFilesCount = 0;

            List<ContentDocument> previewCDs = new List<ContentDocument>();
            for(ContentDocumentLink cdl : contentDocumentLinks) {
                if(cdl.ContentDocument.Title.contains('Preview') ||
                    cdl.ContentDocument.LatestPublishedVersion.title.contains('Preview') ||
                    cdl.ContentDocument.LatestPublishedVersion.PathOnClient.contains('preview')
                ) {
                    previewCDs.add(new ContentDocument(Id = cdl.ContentDocumentId));
                }
                else {
                    finalFilesCount++;
                }
            }

            if(!previewCDs.isEmpty()) {
                delete previewCDs;
            }

            return finalFilesCount;
        }
        catch (Exception e) { throw new AuraHandledException(e.getMessage());
        }
    }

}