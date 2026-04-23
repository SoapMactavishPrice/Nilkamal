public with sharing class InstallationReportController {

     @AuraEnabled
    public static String getInstallationReport(String workOrderId) {
        List<Installation_Report__c> reports = [
            SELECT Id,Installation_Status__c
            FROM Installation_Report__c
            WHERE Work_Order__c = :workOrderId
            LIMIT 1
        ];

        if (reports.isEmpty()) {
            return '';
        }
        
        Map<String, Object> response = new Map<String, Object>();
        response.put('recordId', reports[0].Id);
        response.put('status', reports[0].Installation_Status__c);
        return JSON.serialize(response);
        // return reports.isEmpty() ? '' : json.serialize(reports[0]);
    }

    @AuraEnabled(cacheable=true)
    public static Work_Order__c getWorkOrderDetails(String workOrderId) {
        return [
            SELECT Id, Case__c,Case__r.Asset.Product2Id
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];
    }


    @AuraEnabled
    public static String getServiceReport(String workOrderId) {
        List<Service_Report__c> reports = [
            SELECT Id,SR_Status__c
            FROM Service_Report__c
            WHERE Work_Order__c = :workOrderId
            LIMIT 1
        ];
        Map<String, Object> response = new Map<String, Object>();
        response.put('recordId', reports[0].Id);
        response.put('status', reports[0].SR_Status__c);
        return JSON.serialize(response);
        // return reports.isEmpty() ? '' : json.serialize(reports[0]);
    }


    @AuraEnabled
    public static void saveSignature(Id recordId, String base64Data) {
        if (String.isBlank(recordId) || String.isBlank(base64Data)) {
            throw new AuraHandledException('Record ID or Signature Data is missing.');
        }

        try {
            Installation_Report__c report = [SELECT Id, Signature__c FROM Installation_Report__c WHERE Id = :recordId LIMIT 1];
            String imageTag = '<img src="data:image/png;base64,' + base64Data + '" />';
            report.Signature__c = imageTag;
            update report;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving signature: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id generatePdf(Id recordId, String mode, Boolean isPreview, String previewDocId) {
        try {
            PageReference pdfPage;
            sObject record;
            
            if (mode == 'InstallationReport') {
                pdfPage = Page.InstallationReportPDF;
                record = [SELECT Id, Name FROM Installation_Report__c WHERE Id = :recordId LIMIT 1];
            }
            if (mode == 'ServiceReport') {
                pdfPage = Page.ServiceReportPDF;
                record = [SELECT Id, Name FROM Service_Report__c WHERE Id = :recordId LIMIT 1];
            }
            pdfPage.getParameters().put('id', recordId);
            pdfPage.getParameters().put('mode', mode);
            pdfPage.getParameters().put('isPreview', isPreview ? 'true' : 'false');

            Blob pdfBlob;
            ContentVersion contentVersion = new ContentVersion();

            if(Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Test PDF');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            if(isPreview) {
                if (mode == 'InstallationReport') {
                    contentVersion.Title = 'Installation Report Preview';
                    contentVersion.PathOnClient = 'Installation Report Preview.pdf';
                }
                if (mode == 'ServiceReport') {
                    contentVersion.Title = 'Service Report Preview';
                    contentVersion.PathOnClient = 'Service Report Preview.pdf';
                }
            } else {
                // if(previewDocId !=  null) {
                if (!String.isBlank(previewDocId)) {
                    delete new ContentDocument(Id = previewDocId);
                }
                if (mode == 'InstallationReport') {
                    contentVersion.Title = 'Installation Report ' + record.get('Name');
                    contentVersion.PathOnClient = 'Installation Report ' + record.get('Name') + '.pdf';
                }
                if (mode == 'ServiceReport') {
                    contentVersion.Title = 'Service Report ' + record.get('Name');
                    contentVersion.PathOnClient = 'Service Report ' + record.get('Name') + '.pdf';
                }
            }

            contentVersion.VersionData = pdfBlob;
            contentVersion.IsMajorVersion = true;
            insert contentVersion;

            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            return contentDocId;
        } catch (Exception e) {
            System.debug('Error generating PDF: ' + e.getMessage() +e.getLineNumber());
            return null;
        }
    }
}