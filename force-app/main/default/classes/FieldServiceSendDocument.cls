public with sharing class FieldServiceSendDocument {

    @AuraEnabled
    public static Boolean isQuoteValid(Id recordId) {
        try {
            String sObjType = recordId.getSObjectType().getDescribe().getName();
            if(sObjType == 'Quote') {
                Quote qt = [SELECT Required_Approval__c, Approval_Status__c FROM Quote WHERE Id = :recordId];
                if(qt.Required_Approval__c && qt.Approval_Status__c != 'Approved') {
                    return false;
                }
            return true;
            }
            return true;
        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Object getDefaultEmailIds(Id recordId, String docType) {
        try {
            String sObjType = recordId.getSObjectType().getDescribe().getName();

            List<String> defaultToAddresses = new List<String>();
            List<String> defaultCCAddresses = new List<String>();

            String subject = '';
            String body = '';
            String ownerId;
            String accountId;

            String pdfUrl = '';

            if(sObjType == 'Quote') {
                Quote qt = [
                    SELECT Id, Name,PI_Date__c, OwnerId, Owner.Name, ContactId, Contact.Name, Email, Quote_Document_Type__c, Asset_Serial_Number__r.SerialNumber, AccountId, Required_Approval__c, Approval_Status__c, Business_Vertical__c
                    FROM Quote
                    WHERE Id = :recordId
                ];

                if(qt.Business_Vertical__c == 'Printer') {
                    defaultCCAddresses.add('mhd.printer@nilkamal.com');
                }

                // ✅ added by keshav
               if (qt.PI_Date__c == null) {
                    qt.PI_Date__c = Date.today();
                    update qt;
                }

                if(qt.Required_Approval__c && qt.Approval_Status__c != 'Approved') {
                    // throw new CustomException('The quote is not yet approved. Please submit the quote for approval.');
                    return new Map<String, Object>();
                }

                ownerId = qt.OwnerId;
                accountId = qt.AccountId;

                if(qt.Quote_Document_Type__c == 'AMC' || qt.Quote_Document_Type__c == 'Chargeable Service') {
                    pdfUrl = '/apex/QuoteInvoicePdf?id=' + qt.Id + '&docType=' + docType + '#toolbar=0';
                }
                else if(qt.Quote_Document_Type__c == 'Spares') {
                    pdfUrl = '/apex/QuotePDF?id=' + qt.Id + '&docType=' + docType + '#toolbar=0';
                }

                subject = 'Offer for ' + qt.Quote_Document_Type__c + ' ' + qt.Asset_Serial_Number__r.SerialNumber;
                body = 'Dear ' + (String.isNotBlank(qt.Contact.Name) ? qt.Contact.Name : 'Sir/Madam') + ',<br/><br/>' +
                    'Thank you for choosing Nilkamal. <br/>' +
                    'Please find the attached ' + subject + '.<br/>' +
                    'Incase of any query please discuss with undersigned.<br/><br/>' +
                    'Regards, <br/>' + qt.Owner.Name;

                    defaultToAddresses.add(qt.Email);
            }
            else if(sObjType == 'Installation_Report__c') {
                Installation_Report__c ir = [SELECT Id, Name, Work_Order__r.Case__r.OwnerId, Work_Order__r.Case__r.AccountId FROM Installation_Report__c WHERE Id = :recordId];
                ownerId = ir.Work_Order__r.Case__r.OwnerId;
                accountId = ir.Work_Order__r.Case__r.AccountId;

                pdfUrl = '/apex/InstallationReportPDF?id=' + ir.Id + '&docType=' + docType + '#toolbar=0';
            }
            else if(sObjType == 'Service_Report__c') {
                Service_Report__c sr = [SELECT Id, Name, Service_Appointment__r.OwnerId, Service_Appointment__r.Case__r.AccountId FROM Service_Report__c WHERE Id = :recordId];
                ownerId = sr.Service_Appointment__r.OwnerId;
                accountId = sr.Service_Appointment__r.Case__r.AccountId;

                pdfUrl = '/apex/ServiceReportPDF?id=' + sr.Id + '&docType=' + docType + '#toolbar=0';
            }

            List<Contact> contacts = [SELECT FirstName, LastName, Email FROM Contact WHERE AccountId = :accountId];


            List<Service_Resource__c> serviceResources = [SELECT Id, User__c,
                                                        RSM__c, RSM__r.FirstName, RSM__r.LastName, RSM__r.Email,
                                                        Coordinator__c, Coordinator__r.FirstName, Coordinator__r.LastName, Coordinator__r.Email
                                                        FROM Service_Resource__c
                                                        WHERE User__c = :ownerId];

            if(serviceResources.size() > 0) {
                Service_Resource__c sr = serviceResources[0];
                if(sr.RSM__c != null) {
                    defaultCCAddresses.add(sr.RSM__r.Email);
                    contacts.add(new Contact(FirstName = sr.RSM__r.FirstName, LastName = sr.RSM__r.LastName, Email = sr.RSM__r.Email));
                }
                if(sr.Coordinator__c != null) {
                    defaultCCAddresses.add(sr.Coordinator__r.Email);
                    contacts.add(new Contact(FirstName = sr.Coordinator__r.FirstName, LastName = sr.Coordinator__r.LastName, Email = sr.Coordinator__r.Email));
                }
            }


            return new Map<String, Object> {
                'docType' => sObjType,
                'defaultTo' => defaultToAddresses,
                'defaultCC' => defaultCCAddresses,
                'subject' => subject,
                'body' => body,
                'contacts' => contacts,
                'pdfUrl' => pdfUrl
            };
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static Id getAttachmentId(Id recordId, String docType) {
        try {
            String sObjType = recordId.getSObjectType().getDescribe().getName();
            System.debug('sObjType: ' + sObjType);

            String docId;

            if(sObjType == 'Quote') {
                Quote q = [SELECT Id, Name, Quote_Document_Type__c, Document_No_1__c, Document_Version__c FROM Quote WHERE Id = :recordId];
                String title = (docType ?? 'Quotation') + '_' + q.Document_No_1__c + '_' + (q.Document_Version__c ?? 'V0') + '_' + '%';
                List<ContentDocument> docs = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE :title ORDER BY CreatedDate DESC LIMIT 1];
                String lastVersion = '0';
                if(docs.size() > 0) {
                    lastVersion = docs[0].Title.substringAfterLast('_').substringBeforeLast('.');
                }

                PageReference pageRef;
                if(q.Quote_Document_Type__c == 'AMC' || q.Quote_Document_Type__c == 'Chargeable Service') {
                    pageRef = Page.QuoteInvoicePdf;
                }
                else if(q.Quote_Document_Type__c == 'Spares') {
                    pageRef = Page.QuotePdf;
                }
                pageRef.getParameters().put('id', q.Id);
                pageRef.getParameters().put('docType', docType);
                System.debug((docType ?? 'Quotation'));
                System.debug(q.Document_No_1__c);
                System.debug(q.Document_Version__c);
                docId = generateDocument(q.Id, pageRef, (docType ?? 'Quotation') + '_' + q.Document_No_1__c + '_' + (q.Document_Version__c ?? 'V0') + '_' + (Integer.valueOf(lastVersion) + 1) + '.pdf');
            }
            if(sObjType == 'Installation_Report__c') {
                Installation_Report__c ir = [SELECT Id, Name FROM Installation_Report__c WHERE Id = :recordId];
                PageReference pageRef = Page.InstallationReportPDF;
                pageRef.getParameters().put('id', ir.Id);
                docId = generateDocument(ir.Id, pageRef, 'Installation_Report_' + ir.Name + '.pdf');
            }
            if(sObjType == 'Service_Report__c') {
                Service_Report__c sr = [SELECT Id, Name FROM Service_Report__c WHERE Id = :recordId];
                PageReference pageRef = Page.ServiceReportPDF;
                pageRef.getParameters().put('id', sr.Id);
                docId = generateDocument(sr.Id, pageRef, 'Service_Report_' + sr.Name + '.pdf');
            }

            return docId;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    private static Id generateDocument(String recordId, PageReference pageRef, String title) {
        try {
            pageRef.getParameters().put('id', recordId);

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = title;
            contentVersion.PathOnClient = title;
            contentVersion.ContentLocation = 'S';
            contentVersion.isMajorVersion = true;
            if(Test.isRunningTest()) {
                contentVersion.VersionData = Blob.valueOf('test');
            }
            else {
                contentVersion.VersionData = pageRef.getContentAsPDF();
            }
            insert contentVersion;

            contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

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


    @AuraEnabled
    public static void sendEmail(Id recordId, List<String> toAddresses, List<String> ccAddresses, String subject, String body, List<String> attachmentIds, String docType) {
        try {
            if(toAddresses.isEmpty()) {
                throw new AuraHandledException('Please select at least one recipient');
            }
            if(String.isBlank(subject)) {
                throw new AuraHandledException('Please enter a subject');
            }
            if(String.isBlank(body)) {
                throw new AuraHandledException('Please enter a body');
            }

            if(attachmentIds == null || attachmentIds.isEmpty()) {
                attachmentIds = new List<String>();
                attachmentIds.add(getAttachmentId(recordId, docType));
            }
            String sObjType = recordId.getSObjectType().getDescribe().getName();
            system.debug('docType: ' + docType);
            System.debug('sObjTypesObjType: ' + sObjType);

            if(docType != 'ProformaInvoice' && sObjType == 'Quote') {
                System.debug('recordId: ' + recordId);
                Quote quote = [SELECT Status FROM Quote WHERE Id = :recordId LIMIT 1];
                string recordStage = quote.Status;
                if(recordStage == 'Draft' || recordStage == 'In Review' || recordStage == 'Approved') {
                    System.debug('recordStage: ' + recordStage);
                    quote.Status = 'Presented';
                    upsert quote;
                }
            }


            User currentUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId()];
            List<String> bccAddresses = new List<String>();
            if(!bccAddresses.contains(currentUser.Email)) {
                bccAddresses.add(currentUser.Email);
            }


            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setBccAddresses(bccAddresses);
            mail.setSubject(subject);
            mail.setHtmlBody(body);

            if(attachmentIds != null && attachmentIds.size() > 0) {
                List<ContentDocument> attachments = [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id IN :attachmentIds OR LatestPublishedVersionId IN :attachmentIds];
                List<Id> attachmentIdsSet = new List<Id>();
                for(ContentDocument cd : attachments) {
                    attachmentIdsSet.add(cd.LatestPublishedVersionId);
                }
                mail.setEntityAttachments(attachmentIdsSet);
            }
            System.debug(mail);
            if (Label.External_Email_Disabled != 'True') {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
        catch(AuraHandledException e) {
            throw new AuraHandledException(e.getMessage());
        }
        catch (Exception e) {
            System.debug(e.getLineNumber() + ' ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}