public without sharing class FieldServiceAssetHistoryController {

    @AuraEnabled(cacheable=true)
    public static Object getAssetData(Id recordId) {
        try {
            Id assetId;

            String sObjType = recordId.getSObjectType().getDescribe().getName();
            if(sObjType == 'Asset') {
                assetId = recordId;
            }
            else if (sObjType == 'Case') {
                Case caseRecord = [
                    SELECT Id, AssetId
                    FROM Case
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                assetId = caseRecord.AssetId;
            }
            else if(sObjType == 'Work_Order__c') {
                Work_Order__c workOrder = [
                    SELECT Id, Case__r.AssetId
                    FROM Work_Order__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                assetId = workOrder.Case__r.AssetId;
            }
            else if (sObjType == 'Service_Appointment__c') {
                Service_Appointment__c serviceAppointment = [
                    SELECT Id, Work_Order__r.Case__r.AssetId
                    FROM Service_Appointment__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                assetId = serviceAppointment.Work_Order__r.Case__r.AssetId;
            }
            else if(sObjType == 'Installation_Report__c') {
                Installation_Report__c installationReport = [
                    SELECT Id, Work_Order__r.Case__r.AssetId
                    FROM Installation_Report__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                assetId = installationReport.Work_Order__r.Case__r.AssetId;
            }
            else if(sObjType == 'Service_Report__c') {
                Service_Report__c serviceReport = [
                    SELECT Id, Work_Order__r.Case__r.AssetId
                    FROM Service_Report__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                assetId = serviceReport.Work_Order__r.Case__r.AssetId;
            }

            Asset asset = [
                SELECT Id, Name, InstallDate, PO_Number__c, Service_Resource__c, Service_Resource__r.Name, RSM__c, Type__c, CreatedDate, SerialNumber,
                AccountId, Account.Name, Bill_to_Customer_Code__c, Bill_to_Address__c, Bill_to_City__c, Bill_to_Region__c, Bill_to_Country__c, Bill_to_Pin__c,
                End_Customer__c, Ship_to_Customer_Code__c, Ship_to_Address__c, Ship_to_City__c, Ship_to_Region__c, Ship_to_Country__c, Ship_to_Pin__c,
                ContactId, Contact.Name,
                Product2Id, Product2.Name,
                Invoice__c, Invoice__r.Name, Invoice__r.Billing_Date__c,
                (
                    SELECT Id, Name, Warranty_Start_Date__c, Warranty_End_Date__c
                    FROM Asset_Warranty__r
                    ORDER BY Warranty_Start_Date__c DESC
                ),
                (
                    SELECT Id, Name, AMC_Start_Date__c, AMC_End_Date__c
                    FROM Asset_AMCs__r
                    ORDER BY AMC_Start_Date__c DESC
                ),
                (
                    SELECT Id, AssetId, Field, DataType, OldValue, NewValue, CreatedDate, CreatedBy.Name
                    FROM Histories
                    WHERE Field IN ('Account', 'End_Customer__c')
                )
                FROM Asset
                WHERE Id = :assetId
            ];

            List<Case> caseList = [
                SELECT Id, CaseNumber, Owner.Name, CreatedDate, ClosedDate, Status, Subject, Description, Type, Case_Sub_Type__c
                FROM Case
                WHERE AssetId = :assetId
                ORDER BY CreatedDate DESC, CaseNumber DESC
            ];

            List<Service_Appointment__c> serviceAppointmentList = [
                SELECT Id, Name, Case__c
                FROM Service_Appointment__c
                WHERE Work_Order__r.Case__r.AssetId = :assetId
                ORDER BY CreatedDate DESC
            ];

            List<Installation_Report__c> installationReportList = [
                SELECT Id, Name, Case__c,
                (
                    SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.FileType, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LatestPublishedVersion.ContentSize, ContentDocument.LatestPublishedVersion.VersionDataUrl
                    FROM ContentDocumentLinks
                )
                FROM Installation_Report__c
                WHERE Work_Order__r.Case__r.AssetId = :assetId
                ORDER BY CreatedDate DESC
            ];

            for(Installation_Report__c installationReport : installationReportList) {
                if(installationReport.ContentDocumentLinks.size() > 0) {
                    for(ContentDocumentLink contentDocumentLink : installationReport.ContentDocumentLinks) {
                        if(contentDocumentLink.ContentDocument.LatestPublishedVersion != null) {
                            contentDocumentLink.ContentDocument.LatestPublishedVersion.Title = 'Installation Report ' + contentDocumentLink.ContentDocument.LatestPublishedVersion.Title;
                        }
                    }
                }
            }

            List<Service_Report__c> serviceReportList = [
                SELECT Id, Name, Case__c, Service_Appointment__c,
                (
                    SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.FileType, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LatestPublishedVersion.ContentSize, ContentDocument.LatestPublishedVersion.VersionDataUrl
                    FROM ContentDocumentLinks
                )
                FROM Service_Report__c
                WHERE Work_Order__r.Case__r.AssetId = :assetId
                ORDER BY CreatedDate DESC
            ];

            return new Map<String, Object>{
                'asset' => asset,
                'caseList' => caseList,
                'serviceAppointmentList' => serviceAppointmentList,
                'installationReportList' => installationReportList,
                'serviceReportList' => serviceReportList
            };
        }
        catch (Exception e) {
            System.debug('An error occurred: ' + e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}