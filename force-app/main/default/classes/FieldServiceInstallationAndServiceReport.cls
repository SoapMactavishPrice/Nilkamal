public without sharing class FieldServiceInstallationAndServiceReport {

    @AuraEnabled
    public static Object getReportDetails(String workOrderId, String serviceAppointmentId, String reportType) {
        try {
            Work_Order__c workOrder = [
                SELECT Id, Case__c, Case__r.Contact.Email,
                Case__r.AssetId, Case__r.Asset.Name, Case__r.Asset.Product2Id, Case__r.Asset.Is_Temp_Serial_Number__c, Case__r.Division__c,Case__r.Asset.OEM_Serial_Number__c,Case__r.Asset.Product2.Name,Case__r.Asset.Product2.Material_Group_6__c
                FROM Work_Order__c
                WHERE Id = :workOrderId
            ];

            Service_Appointment__c serviceAppointment = [
                SELECT Id, Remote_Support__c, Case__r.Description
                FROM Service_Appointment__c
                WHERE Id = :serviceAppointmentId
            ];

            Boolean hourMeterRequired = false;
            if (workOrder.Case__r.Asset.Product2Id != null) {
                List<MG6_Mapping__mdt> mappings = [SELECT Id, Hour_Meter_Applicable__c, MG6_Type__c
                                                FROM MG6_Mapping__mdt
                                                WHERE MG6_Type__c = :workOrder.Case__r.Asset.Product2.Material_Group_6__c
                                                LIMIT 1];

                if (!mappings.isEmpty()) {
                    hourMeterRequired = mappings[0].Hour_Meter_Applicable__c;
                }
            }

            Installation_Report__c installationReport;
            Service_Report__c serviceReport;
            List<Service_Report_Observation__c> sroList;
            List<Cause_Sub_Cause_Master__c> causeSubCauseList;

            if(reportType == 'InstallationReport') {
                installationReport = getInstallationReportRecordFromDB(workOrder);
            }
            else if(reportType == 'ServiceReport') {
                serviceReport = getServiceReportRecordFromDB(workOrder, serviceAppointment, hourMeterRequired);

                causeSubCauseList = [
                    SELECT Id, Name, Cause__c, Sub_Cause__c
                    FROM Cause_Sub_Cause_Master__c
                    WHERE Product__c =: workOrder.Case__r.Asset.Product2Id AND Cause__c != null AND Sub_Cause__c != null AND Business_Vertical__c =: workOrder.Case__r.Division__c
                    ORDER BY Cause__c, Sub_Cause__c
                ];
                causeSubCauseList.addAll([
                    SELECT Id, Name, Cause__c, Sub_Cause__c
                    FROM Cause_Sub_Cause_Master__c
                    WHERE Product__c = null AND Material_Group__c =: workOrder.Case__r.Asset.Product2.Material_Group_6__c
                    AND Cause__c != null AND Sub_Cause__c != null AND Business_Vertical__c =: workOrder.Case__r.Division__c
                    ORDER BY Cause__c, Sub_Cause__c
                ]);

                sroList = [
                    SELECT Id, Cause__c, Sub_Cause__c, Correction__c, Actual_Observation_by_Engineer__c
                    FROM Service_Report_Observation__c
                    WHERE Service_Report__c = :serviceReport.Id
                ];
            }

            return new Map<String, Object>{
                'workOrder' => workOrder,
                'serviceAppointment' => serviceAppointment,
                'installationReport' => installationReport,
                'serviceReport' => serviceReport,
                'sroList' => sroList,
                'causeSubCauseList' => causeSubCauseList,
                'email' => workOrder.Case__r.Contact.Email,
                'hourMeterRequired' => hourMeterRequired
            };
        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Installation_Report__c getInstallationReportRecordFromDB(Work_Order__c workOrder) {
        List<Installation_Report__c> irList = [
            SELECT Id, Name, Case__c, Installation_Asset_Serial_Number__c, Installation_Start_Date__c, Installation_End_Date__c,
            Installation_Status__c, Reason_for_Hold__c, Signature__c, Signature_by__c, Warranty_Start_Date__c, Work_Order__c,
            Customer_Email__c, Customer_Contact_Number__c, Customer_Feedback__c, Customer_Remark__c, IsSavedByUser__c, Hour_Meter__c
            FROM Installation_Report__c
            WHERE Work_Order__c = :workOrder.Id ORDER BY CreatedDate DESC
        ];

        List<Installation_Report__c> irToDelete = new List<Installation_Report__c>();
        if(irList.size() > 1) {
            for(Integer i = 1; i < irList.size(); i++) {
                irToDelete.add(irList[i]);
            }
            delete irToDelete;

            return irList[0];
        }
        else if(irList.size() == 1) {
            return irList[0];
        }
        else if(irList.size() == 0) {
            return createInstallationReportRecord(workOrder);
        }
        else {
            throw new CustomException('Something went wrong, please get in touch with your system administrator.');
        }
    }

    private static Service_Report__c getServiceReportRecordFromDB(Work_Order__c workOrder, Service_Appointment__c serviceAppointment, Boolean hourMeterRequired) {
        List<Service_Report__c> srList = [
            SELECT Id, Name, Case__c, Customer_Feedback__c, Customer_Remark__c, Reason_for_Hold__c, Root_Cause_Analysis__c,
            Signature__c, Signature_by__c, SR_End_Date__c, SR_Remark__c, SR_Start_Date__c, SR_Status__c, Work_Order__c,
            Case__r.Asset.Product2Id, OEM_Serial_Number__c, Hour_Meter__c, Customer_Email__c, Customer_Contact_Number__c, IsSavedByUser__c
            FROM Service_Report__c
            WHERE Work_Order__c = :workOrder.Id AND Service_Appointment__c = :serviceAppointment.Id ORDER BY CreatedDate DESC
        ];

        List<Service_Report__c> srToDelete = new List<Service_Report__c>();
        if(srList.size() > 1) {
            for(Integer i = 1; i < srList.size(); i++) {
                srToDelete.add(srList[i]);
            }
            delete srToDelete;
            return srList[0];
        }
        else if(srList.size() == 1) {
            return srList[0];
        }
        else if(srList.size() == 0) {
            return createServiceReportRecord(workOrder, serviceAppointment, hourMeterRequired);
        }
        else {
            throw new CustomException('Something went wrong, please get in touch with your system administrator.');
        }
    }

    private static Installation_Report__c createInstallationReportRecord(Work_Order__c workOrder) {
        Installation_Report__c installationReport = new Installation_Report__c();
        installationReport.Case__c = workOrder.Case__c;
        installationReport.Work_Order__c = workOrder.Id;
        installationReport.Installation_Asset_Serial_Number__c = workOrder.Case__r.Asset.Name;
        installationReport.Item_Master__c = workOrder.Case__r.Asset.Product2Id;
        insert installationReport;
        return installationReport;
    }

    private static Service_Report__c createServiceReportRecord(Work_Order__c workOrder, Service_Appointment__c serviceAppointment, Boolean hourMeterRequired) {
        Service_Report__c prevSrFromSameCase;
        try {
            prevSrFromSameCase = [SELECT Id, Name, Case__c, Service_Appointment__c, Work_Order__c, Case__r.Asset.Product2Id, Action_Taken__c,
                                Cause__c, Sub_Cause__c, Other_Cause__c, Correction__c, Customer_Problem_Statement__c, Hour_Meter__c,OEM_Serial_Number__c
                                FROM Service_Report__c
                                WHERE Case__c = :workOrder.Case__c
                                ORDER BY CreatedDate DESC
                                LIMIT 1];
        } catch (Exception ex) {
            prevSrFromSameCase = new Service_Report__c();
            prevSrFromSameCase.Customer_Problem_Statement__c  = serviceAppointment.Case__r.Description;
        }

        Service_Report__c serviceReport = new Service_Report__c();
        serviceReport.Case__c = workOrder.Case__c;
        serviceReport.Service_Appointment__c = serviceAppointment.Id;
        serviceReport.Work_Order__c = workOrder.Id;
        serviceReport.Product__c = workOrder.Case__r.Asset.Product2Id;
        serviceReport.SR_Start_Date__c = System.today();
        serviceReport.SR_End_Date__c = System.today();
        serviceReport.Customer_Problem_Statement__c = prevSrFromSameCase.Customer_Problem_Statement__c;
        serviceReport.Cause__c = prevSrFromSameCase.Cause__c;
        serviceReport.Sub_Cause__c = prevSrFromSameCase.Sub_Cause__c;
        serviceReport.Other_Cause__c = prevSrFromSameCase.Other_Cause__c;
        serviceReport.Correction__c = prevSrFromSameCase.Correction__c;
        serviceReport.Action_Taken__c = prevSrFromSameCase.Action_Taken__c;
        serviceReport.Hour_Meter__c = prevSrFromSameCase.Hour_Meter__c;
        serviceReport.OEM_Serial_Number__c = workOrder.Case__r.Asset.OEM_Serial_Number__c;
        if (hourMeterRequired && serviceReport.Hour_Meter__c == null) {
            serviceReport.Hour_Meter__c = prevSrFromSameCase.Hour_Meter__c;
        }
        insert serviceReport;
        return serviceReport;
    }


    @AuraEnabled
    public static Object previewReport(Installation_Report__c installationReportRecord, Service_Report__c serviceReportRecord, String reportType) {
        try {
            if(reportType == 'InstallationReport') {
                update installationReportRecord;

                installationReportRecord = [SELECT Id, Name, Sr_No_Preview__c
                                            FROM Installation_Report__c
                                            WHERE Id = :installationReportRecord.Id];

                Integer srNo = installationReportRecord.Sr_No_Preview__c != null ? Integer.valueOf(installationReportRecord.Sr_No_Preview__c) + 1 : 1;
                Id contentDocumentId = createPreviewDocument(installationReportRecord.Id, Page.InstallationReportPDF, 'Installation_Report_Preview_' + installationReportRecord.Name + '_' + srNo + '.pdf');

                installationReportRecord.Sr_No_Preview__c = srNo;
                update installationReportRecord;

                return contentDocumentId;
            }
            else if(reportType == 'ServiceReport') {
                update serviceReportRecord;

                serviceReportRecord = [SELECT Id, Name, Sr_No_Preview__c
                                        FROM Service_Report__c
                                        WHERE Id = :serviceReportRecord.Id];

                Integer srNo = serviceReportRecord.Sr_No_Preview__c != null ? Integer.valueOf(serviceReportRecord.Sr_No_Preview__c) + 1 : 1;
                Id contentDocumentId = createPreviewDocument(serviceReportRecord.Id, Page.ServiceReportPDF, 'Service_Report_Preview_' + serviceReportRecord.Name + '_' + srNo + '.pdf');

                serviceReportRecord.Sr_No_Preview__c = srNo;
                update serviceReportRecord;

                return contentDocumentId;
            }

            return null;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Object saveReport(Installation_Report__c installationReportRecord, Service_Report__c serviceReportRecord, String reportType, List<Service_Report_Observation__c> serviceReportObservations,List<Work_Order_Checklist__c> workOrderChecklist, Id serviceAppointmentId) {
        try {
            Map<string,Object> result = new Map<string,Object>();
            if(reportType == 'InstallationReport') {
                // if(installationReportRecord.Id == null) {
                installationReportRecord.IsSavedByUser__c = true;
                upsert installationReportRecord;
                // }
                Installation_Report__c irFromDB = [SELECT Id, Name, Case__c, Case__r.AssetId, Case__r.Asset.Name, Case__r.Asset.SerialNumber, Case__r.Asset.Is_Temp_Serial_Number__c
                                                    FROM Installation_Report__c
                                                    WHERE Id = :installationReportRecord.Id];

                if(irFromDB.Case__r.Asset.Is_Temp_Serial_Number__c) {
                    update installationReportRecord;

                    Asset assetToUpdate = new Asset();
                    assetToUpdate.Id = irFromDB.Case__r.AssetId;
                    assetToUpdate.Name = installationReportRecord.Installation_Asset_Serial_Number__c;
                    assetToUpdate.SerialNumber = installationReportRecord.Installation_Asset_Serial_Number__c;
                    assetToUpdate.Is_Temp_Serial_Number__c = false;
                    assetToUpdate.InstallDate = installationReportRecord.Installation_End_Date__c;
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);

                } else {
                    // if(installationReportRecord.Installation_Asset_Serial_Number__c != irFromDB.Case__r.Asset.SerialNumber) {
                    //     throw new CustomException('Serial number doesn\'t match, please check the serial number of the related Asset record.');
                    // }

                    Asset assetToUpdate = new Asset();
                    assetToUpdate.Id = irFromDB.Case__r.AssetId;
                    assetToUpdate.InstallDate = installationReportRecord.Installation_End_Date__c;
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);

                    update installationReportRecord;
                }

                installationReportRecord = [SELECT Id, Name, Work_Order__c
                                            FROM Installation_Report__c
                                            WHERE Id = :installationReportRecord.Id];

                string t1 = createFinalDocument(installationReportRecord, Page.InstallationReportPDF, 'Installation_Report_' + installationReportRecord.Name + '.pdf');
                result.put('Id',t1);
                return JSON.serialize(result);
            }
            else if(reportType == 'ServiceReport') {
                // if(serviceReportRecord.Id == null) {
                serviceReportRecord.IsSavedByUser__c = true;
                upsert serviceReportRecord;
                // }

                Service_Report__c srFromDB = [SELECT Id, Name, Signature__c, Signature_by__c,Case__c, Case__r.AssetId, Case__r.Asset.OEM_Serial_Number__c
                                            FROM Service_Report__c
                                            WHERE Id = :serviceReportRecord.Id];

                if(serviceReportRecord.OEM_Serial_Number__c != null &&
                serviceReportRecord.OEM_Serial_Number__c != srFromDB.Case__r.Asset.OEM_Serial_Number__c) {
                    Asset assetToUpdate = new Asset();
                    assetToUpdate.Id = srFromDB.Case__r.AssetId;
                    assetToUpdate.OEM_Serial_Number__c = serviceReportRecord.OEM_Serial_Number__c;
                    Database.update(assetToUpdate, true, AccessLevel.SYSTEM_MODE);
                }

                update serviceReportRecord;
                serviceReportRecord = [SELECT Id, Name, OEM_Serial_Number__c, Work_Order__c
                                        FROM Service_Report__c
                                        WHERE Id = :serviceReportRecord.Id];

                for(Service_Report_Observation__c sro : serviceReportObservations) {
                    if(sro.Id == null) {
                        sro.Service_Report__c = serviceReportRecord.Id;
                    }
                }
                if(!serviceReportObservations.isEmpty()) {
                    upsert serviceReportObservations;
                }

                if(!result.containsKey('OEM_Serial_Number__c')) {
                    result.put('OEM_Serial_Number__c', srFromDB.Case__r.Asset.OEM_Serial_Number__c);
                }

                string t2 = createFinalDocument(serviceReportRecord, Page.ServiceReportPDF, 'Service_Report_' + serviceReportRecord.Name + '.pdf');

                result.put('result', serviceReportObservations);
                result.put('Id', t2);
                result.put('OEM_Serial_Number__c', serviceReportRecord.OEM_Serial_Number__c);

				FieldServiceCaptureInteraction.saveChecklistData(null,workOrderChecklist,serviceAppointmentId);
                return JSON.serialize(result);
            }

            return null;
        }
        catch (Exception e) {
            system.debug('srvId'+e.getMessage() + e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static string deleteRecord(Id recordId) {
        system.debug(recordId);
        try {
            List<Service_Report_Observation__c> relatedObservations = [SELECT Id FROM Service_Report_Observation__c WHERE Id = :recordId limit 1];
            if(relatedObservations.size() > 0){
                delete relatedObservations;
            }
            return 'Success';
        }catch(exception e){
            return e.getMessage();
        }
    }


    @AuraEnabled
    public static Object getDocumentId(String recordId, String reportType) {
        try {
            if(reportType == 'InstallationReport') {
                Installation_Report__c installationReportRecord = [SELECT Id, Name
                                                                FROM Installation_Report__c
                                                                WHERE Id = :recordId];
                return createFinalDocument(installationReportRecord, Page.InstallationReportPDF, 'Installation_Report_' + installationReportRecord.Name + '.pdf');
            }
            else if(reportType == 'ServiceReport') {
                Service_Report__c serviceReportRecord = [SELECT Id, Name
                                                        FROM Service_Report__c
                                                        WHERE Id = :recordId];
                return createFinalDocument(serviceReportRecord, Page.ServiceReportPDF, 'Service_Report_' + serviceReportRecord.Name + '.pdf');
            }
            return null;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    private static Id createFinalDocument(sObject record, PageReference pageRef, String title) {
        try {
            pageRef.getParameters().put('id', record.Id);

            try {
                delete [SELECT Id
                        FROM contentDocument
                        WHERE Title = :title
                        LIMIT 1];
            }
            catch(Exception e) {
                System.debug(e.getMessage());
            }

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            contentVersion.PathOnClient = title;
            contentVersion.isMajorVersion = true;
            contentVersion.Title = title;
            if(Test.isRunningTest()) {
                contentVersion.VersionData = Blob.valueOf('test');
            } else {
                contentVersion.VersionData = pageRef.getContentAsPDF();
            }
            insert contentVersion;

            ContentVersion = [SELECT Id, ContentDocumentId, Title, PathOnClient
                            FROM ContentVersion
                            WHERE Id = :contentVersion.Id];

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = record.Id;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;

            return contentVersion.ContentDocumentId;
        }
        catch (Exception e) {
            system.debug('createFinalDocument'+e.getMessage() + e.getLineNumber());
            throw new CustomException(e.getMessage());
        }
    }


    private static Id createPreviewDocument(String recordId, PageReference pageRef, String title) {
        try {
            pageRef.getParameters().put('id', recordId);
            pageRef.getParameters().put('isPreview',  'true');

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';
            contentVersion.PathOnClient = title;
            contentVersion.Title = title;
            if(Test.isRunningTest()) {
                contentVersion.VersionData = Blob.valueOf('test');
            } else {
                contentVersion.VersionData = pageRef.getContentAsPDF();
            }
            insert contentVersion;

            ContentVersion = [SELECT Id, ContentDocumentId, Title, PathOnClient
                            FROM ContentVersion
                            WHERE Id = :contentVersion.Id];

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ShareType = 'V';
            insert contentDocumentLink;

            return contentVersion.ContentDocumentId;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }



}