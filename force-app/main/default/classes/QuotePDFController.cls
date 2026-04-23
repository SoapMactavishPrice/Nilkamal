public with sharing class QuotePDFController {
    public Quote quoteRecord { get; set; }
    public string PaymentTerms{get; set; }
    public Boolean showOutstanding { get; set; }
    public List<QuoteLineItem> quoteLineItems { get; set; }
    public Boolean isValid { get; set; }
    public Boolean formSubmitted { get; set; }
    public String Emailid { get; set; }  // Correct email variable
    public String body { get; set; }
    public Boolean createNew { get; set; }
    public Id recordId { get; set; }
    public String docType { get; set; }
    public PageReference pdf { get; set; }
    public String pdfUrl { get; set; }
    public String subject { get; set; }
    public String To_Addresses {get; set;}
    public string CC_Addresses { get; set;}
    public String CreatedById { get; set;}
    public Partner_Function_Address_Information__c pfai {get; set;}
    public Plant_Master__c plantMaster {get; set;}
    public String coordinatorName {get; set;}
    public String serviceHeadName {get; set;}
    public Service_Resource__c serviceResource { get; set; }
    public List<Quote_Terms_Conditons__c> quoteTerms { get; set; }
    public String termsandconditions {get; set;}
    public List<Customer_Outstanding__c> customerOutstandings {get; set;}
    public String reportName {get; set;}

    public String defaultToAddress {get; set;}
    public String defaultCCAddresses {get; set;}
    public String mainHeaderHeading {get; set;}

    public String mainSubject {get; set;}
    public String subSubject {get; set;}


    public Boolean isPOcustomer {get; set;}
    public Boolean isMHE {get; set;}
    public Boolean isPrinter {get; set;}
    public Boolean isHanel {get; set;}
    public Boolean isCNPL {get; set;}
    public Boolean hasWarranty { get; set; }

    public Integer qtyTotal { get; set; }
    public Decimal basicUPTotal { get; set; }
    public Decimal discBasicUPTotal { get; set; }
    public Decimal totaldiscBasicUPTotal { get; set; }
    public String ownerMobile { get; set; }
    public Boolean hasCategory { get; set; }
    public Boolean showDiscountInValueColumn { get; set; }




    // Constructor to initialize the Quote record
    public QuotePDFController() {
        recordId = ApexPages.currentPage().getParameters().get('id');
        docType = ApexPages.currentPage().getParameters().get('docType');
		

        body = '';
        isValid = true;
        formSubmitted = false;
        createNew = true;

        qtyTotal = 0;
        basicUPTotal = 0;
        discBasicUPTotal = 0;
        totaldiscBasicUPTotal = 0;

        // Get the Quote Id from the URL parameter; if not provided, use a default
        Id quoteId = ApexPages.currentPage().getParameters().get('id');

        if(quoteId != null) {
            quoteRecord = [
                SELECT Id,Account.Virtual_Account_No__c, Name, QuoteNumber, Account.Name, Account.Street1__c, Account.Street2__c, Account.Street_House_Number__c, Account.City__c,
                Account.Postal_code__c, Grand_Total_Price__c, GST_Value__c, Taxable_Value__c, Grand_Total_Value__c, Account.Country__c, Account.GST_No__c,
                AccountId, ExpirationDate, BillingStreet, Business_Vertical__c, Opportunity.Serial_Number__r.SerialNumber, Asset_Serial_Number__r.Territory_Master__r.Name,
                Quote_Start_Date__c, Partner_function__c, Kind_Attn__c, Phone, Email, Referance__c, Delivery_Plant__c, Partner_Function_Address_Information__c,
                Document_No_1__c, Customer_PO_Number__c, Customer_PO_Date__c, Required_Approval__c, Approval_Status__c,
                Account.SAP_Customer_code__c, TotalPrice, Subtotal, GrandTotal, Sub__c, Owner.Email,Street1__c,Street2__c,Street_House_Number__c,CreatedBy.Name,CreatedBy.mobilePhone,
                City__c,Postal_Code__c,Country__c,Asset_Serial_Number__r.Product2.Name,Total_Amount__c, ContactId, Contact.Name, Terms_and_Condition_for_PO1__c,
                L_D_Applicable__c,LD_Terms__c,Additional_Bank_Guarantee__c,ABG_Terms__c,Performance_Bank_Guarantee__c,Performance_Bank_Guarantee_Terms__c,
                Terms_and_Condition_for_Payment1__c, CreatedById, Owner.Name, Delivary_Time1__c,Description,Quote_Document_Type__c,OwnerId,
                toLabel(Inco_Terms__c),toLabel(Payment_Terms__c),Case__c,Service_Appointment__c,Street_House_Number_Bill_To__c,City_Bill_To__c,Country_Bill_To__c,Postal_Code_Bill_To__c,
                Asset_Serial_Number__r.Business_Vertical__c,Bill_to_Party__c,Bill_to_Party__r.Name,Ship_to_Party__c,Ship_to_Party__r.Name,Additional_Charges__c,Owner.Type,Document_Version__c,PI_Date__c,
                Bill_to_Party__r.GST_No__c,Ship_to_Party__r.GST_No__c,Street1_Bill_To__c,Street2_Bill_To__c
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if(quoteRecord.Required_Approval__c == true && quoteRecord.Approval_Status__c != 'Approved') {
                if(Test.isRunningTest() == false) {
                    throw new CustomException('The quote is not yet approved. Please submit the quote for approval.');
                    // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The quote is not yet approved. Please submit the quote for approval.'));
                }
            }

            quoteLineItems = [SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, GST_Tax__c, Product2.Base_UOM__r.Name,Delivery_Time_Remark__c,Stock__c,
                            HSN_Code__r.Name, Description, SAP_Code__c, Unit__c, GST_Percentage__c, Amount__c, Advanced_Received__c, Discount_In__c,Delivery_Time__c,Discount_In_Value__c,Grand_Price__c,Warranty_Months__c,OEM_Material_Code__c,Category__c,Discount_In_Value_new__c, Product2.Plant_Master__r.Plant_Code__c
                            FROM QuoteLineItem
                            WHERE QuoteId = :quoteId];
            Set<Id> qliMaterialIds = new Set<Id>();
            for (QuoteLineItem eq : quoteLineItems) {
                qliMaterialIds.add(eq.Product2Id);
            }

            showDiscountInValueColumn = false;
            for (QuoteLineItem item : quoteLineItems) {
                if (item.Discount_In_Value_new__c > 0) {
                    showDiscountInValueColumn = true;
                    break;
                }
            }

            List<Inventory__c> inventoryList=new List<Inventory__c>();
            Map<String,Decimal> mpInv=new Map<String,Decimal>();
            inventoryList=[SELECT Id, Material__c, Material__r.Plant_Master__r.Plant_Code__c, Quantity__c FROM Inventory__c WHERE Material__c IN :qliMaterialIds];
            for(Inventory__c inv:inventoryList){
                mpInv.put(inv.Material__c + '_' + inv.Material__r.Plant_Master__r.Plant_Code__c, inv.Quantity__c);
                System.debug('mpInv: ' + inv.Material__c + '_' + inv.Material__r.Plant_Master__r.Plant_Code__c);
            }

            List<QuoteLineItem> newQuoteLineItem=new List<QuoteLineItem>();
            for(QuoteLineItem qli: quoteLineItems){
                System.debug('qli: ' + qli.Product2Id + '_' + qli.Product2.Plant_Master__r.Plant_Code__c);
                if(mpInv.containsKey(qli.Product2Id + '_' + qli.Product2.Plant_Master__r.Plant_Code__c)) {
                    qli.Stock__c=mpInv.get(qli.Product2Id + '_' + qli.Product2.Plant_Master__r.Plant_Code__c);
                }else{
                    qli.Stock__c=0;
                }
            }

            for(QuoteLineItem qli: quoteLineItems){
                System.debug('Delivery_Time_Remark__c' + qli.Delivery_Time_Remark__c);
            }

            Formula.recalculateFormulas(quoteLineItems);

            for(QuoteLineItem qli: quoteLineItems){
                System.debug('Delivery_Time_Remark__c' + qli.Delivery_Time_Remark__c);
            }

            // if (quoteRecord.Customer_PO_Number__c != null && quoteRecord.Customer_PO_Date__c != null) {
            if(docType == 'ProformaInvoice') {
                isPOcustomer = true;
                mainHeaderHeading = 'PROFORMA INVOICE';
                mainSubject = 'Proforma Invoice for Advance Payment';
                subSubject = 'We are pleased to submit our Proforma Invoice for Spares of above mentioned equipment';
            } else {
                isPOcustomer = false;
                mainHeaderHeading = 'QUOTATION';
                mainSubject = 'Offer for ' + quoteRecord.Quote_Document_Type__c + ' ' + quoteRecord.Opportunity.Serial_Number__r.SerialNumber;
                subSubject = 'We are pleased to submit our Quotation for Spares of above mentioned equipment';
            }

            if(quoteRecord.Asset_Serial_Number__r.Business_Vertical__c == 'MHE') {
                isMHE = true;
            }
            else if(quoteRecord.Asset_Serial_Number__r.Business_Vertical__c == 'Printer') {
                isPrinter = true;
            }
            else if(quoteRecord.Asset_Serial_Number__r.Business_Vertical__c == 'Hanel') {
                isHanel = true;
            }
            else if(quoteRecord.Asset_Serial_Number__r.Business_Vertical__c == 'CNPL') {
                isCNPL = true;
            }

            if (quoteRecord.OwnerId != null && String.valueOf(quoteRecord.OwnerId).startsWith('005')) {
                User ownerUser = [SELECT MobilePhone FROM User WHERE Id = :quoteRecord.OwnerId];
                ownerMobile = ownerUser.MobilePhone;
            }


            serviceResource = [SELECT Id, Name, User__c, Coordinator__c, Coordinator__r.Name,Coordinator__r.Email,Coordinator__r.MobilePhone,RSM__c,RSM__r.Name,RSM__r.MobilePhone,RSM__r.Email FROM Service_Resource__c WHERE User__c =: quoteRecord.OwnerId LIMIT 1];
            coordinatorName = serviceResource.Coordinator__r.Name;
            System.debug('serviceResource.RSM__c ' + serviceResource.RSM__c);

            defaultToAddress = quoteRecord.Email;
            if(quoteRecord.Payment_Terms__c!=null)
                PaymentTerms= (quoteRecord.Payment_Terms__c).substring(quoteRecord.Payment_Terms__c.indexOf('-')+1);
            defaultCCAddresses = '';
            if(serviceResource.RSM__c != null) {
                defaultCCAddresses += serviceResource.RSM__r.Email;
            }
            if(serviceResource.Coordinator__c != null) {
                if(defaultCCAddresses != null) {
                    defaultCCAddresses += '; ' + serviceResource.Coordinator__r.Email;
                } else {
                    defaultCCAddresses += serviceResource.Coordinator__r.Email;
                }
            }

            System.debug('defaultToAddress ' + defaultToAddress);
            System.debug('defaultCCAddresses ' + defaultCCAddresses);

            customerOutstandings = [SELECT Id,Accounting_Document_Number__c,Document_Date_in_Document__c, Account_Name__c, SAP_document_No__c, SAP_document_Date__c,
                        Customer_PO_Number__c, Customer_PO_date__c, Amount_in_Local_Currency__c,
                        Net_Outstanding__c
                        FROM Customer_Outstanding__c
                        WHERE Net_Outstanding__c > 0
                        AND Account_Name__c = :quoteRecord.AccountId];
            System.debug('customerOutstandings' + customerOutstandings );
            if(customerOutstandings.size() > 0) {
                showOutstanding=true;
            }

            quoteTerms = [
                SELECT Id,Name,Business_Vertical__c,Terms_And_Conditions__c
                FROM Quote_Terms_Conditons__c
                WHERE Name = :quoteRecord.Quote_Document_Type__c
                AND Business_Vertical__c = :quoteRecord.Business_Vertical__c
                LIMIT 1
            ];
            System.debug('quoteTerms' + quoteTerms);
            if(quoteTerms.size() > 0){
                // termsandconditions = quoteTerms[0].Terms_And_Conditions__c;
                String rawHtml = quoteTerms[0].Terms_And_Conditions__c;

                rawHtml = rawHtml.replaceAll('<tr(.*?)>', '<tr style="height:0;" $1>');

                rawHtml = rawHtml.replaceAll('<td(.*?)>', '<td style="height:0; padding:0;" $1>');

                rawHtml = rawHtml.replaceAll('<p>&nbsp;</p>', '');
                rawHtml = rawHtml.replaceAll('<br\\s*/?>', '');

                termsandconditions = rawHtml;
                System.debug('termsandconditions ' + termsandconditions );
            }

            if(String.isNotBlank(quoteRecord.Service_Appointment__c)) {
                List<Service_Appointment__c> serviceAppointment = [
                    SELECT Id, Name, Case__c,
                    (SELECT Id, Name FROM Service_Reports__r WHERE IsSavedByUser__c = true ORDER BY CreatedDate DESC LIMIT 1)
                    FROM Service_Appointment__c
                    WHERE Case__c = :quoteRecord.Case__c AND Id = :quoteRecord.Service_Appointment__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (serviceAppointment.size() > 0) {
                    reportName = serviceAppointment[0].Name;
                    if(serviceAppointment[0].Service_Reports__r.size() > 0) {
                        reportName += ' / ' + serviceAppointment[0].Service_Reports__r[0].Name;
                    }
                }
            }
            else {
                List<Service_Appointment__c> serviceAppointment = [
                    SELECT Id, Name, Case__c
                    FROM Service_Appointment__c
                    WHERE Case__c = :quoteRecord.Case__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];

                if (serviceAppointment.size() > 0) {
                    reportName = serviceAppointment[0].Name;
                }
            }


            List<User> serviceHeads = [SELECT Id, Name FROM User WHERE UserRole.Name LIKE :'Service Head%'+quoteRecord.Business_Vertical__c];
            if (serviceHeads.size() > 0) {
                serviceHeadName = serviceHeads[0].Name;
            }

            List<Partner_Function_Address_Information__c> pfaiList = [SELECT Id, Address_line_1__c, Address_line_2__c, Address_line_3__c FROM Partner_Function_Address_Information__c
                    WHERE Id = :quoteRecord.Partner_Function_Address_Information__c LIMIT 1];

            System.debug(pfaiList);
            if (pfaiList.size() > 0) {
                this.pfai = pfaiList[0];
            }

            if (quoteRecord.Delivery_Plant__c != null) {
                this.plantMaster = [SELECT Id, Address__c,Street_4__c,Street_5__c,Pin_Code__c,City__c, GST_No__c FROM Plant_Master__c
                                WHERE Id = :quoteRecord.Delivery_Plant__c LIMIT 1];
            }

            // quoteLineItems = [SELECT Id, Product2.Name, Quantity, UnitPrice, TotalPrice, GST_Tax__c, Product2.Base_UOM__r.Name,Delivery_Time_Remark__c,Stock__c,
            //                 HSN_Code__r.Name, Description, SAP_Code__c, Unit__c, GST_Percentage__c, Amount__c, Advanced_Received__c, Discount_In__c,Delivery_Time__c,Discount_In_Value__c,Grand_Price__c,Warranty_Months__c,OEM_Material_Code__c,Category__c
            //                 FROM QuoteLineItem
            //                 WHERE QuoteId = :quoteId];


            if (quoteLineItems == null || quoteLineItems.size() == 0) {
                throw new CustomException('No Quote Line Items found.');
            }

            hasCategory = false;
            hasWarranty = false;
            for (QuoteLineItem qli : quoteLineItems) {
                if (String.isNotBlank(qli.Category__c)) {
                    hasCategory = true;
                }
                if (qli.Warranty_Months__c != null && qli.Warranty_Months__c != 0) {
                    hasWarranty = true;
                }
            }
            System.debug('hasWarranty ' + hasWarranty);

            if(String.isNotBlank(quoteRecord.Email)) {
                EmailId = quoteRecord.Email;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Please fill Email'));
                isValid = false;
            }
            createNew = true;
            subject = 'Offer for ' + quoteRecord.Quote_Document_Type__c + ' ' + quoteRecord.Opportunity.Serial_Number__r.SerialNumber;
            body = 'Dear ' + (String.isNotBlank(quoteRecord.Contact.Name) ? quoteRecord.Contact.Name : 'Sir/Madam') + ',<br/><br/>';
            body += 'Thank you for choosing Nilkamal. <br/>';
            body += 'Please find the attached ' + subject + '.<br/>';
            body += 'Incase of any query please discuss with undersigned.<br/><br/>';
            body += 'Regards, <br/>' + quoteRecord.Owner.Name;
            // body += 'I hope this email finds you well. Attached to this document, you will find the PDF containing your Product Quote details.<br/>';
            // body += 'Please take a moment to review the information provided. If you have any questions or need further assistance regarding your Quote, please feel free to contact our billing department.<br/>';
            // body += 'We are here to help and ensure any concerns are addressed promptly.<br/><br/>Thanks And Regards, <br/>' + quoteRecord.Owner.Name;
            pdfUrl = '/apex/QuotePDF?id=' + quoteRecord.Id + '&docType=' + docType + '#toolbar=0';
        }
    }

    // Method to generate and save the PDF
    public PageReference save() {
        String finalString = '%' + quoteRecord.Name + '%';
        List<ContentDocument> contentDocs = [SELECT Id, Title FROM ContentDocument
                                            WHERE Title LIKE :finalString
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1];
        String version = '0';
        if(contentDocs.size() > 0) {
            version = contentDocs[0].Title.substringAfterLast('_').substringBeforeLast('.');
        }

        if(!createNew && contentDocs.size() > 0) {
            Database.delete(contentDocs, false);
        }

        formSubmitted = true;
        // Reference your Visualforce page to generate PDF
        PageReference pdfPage = Page.QuotePDF; // Visualforce page name
        pdfPage.getParameters().put('id', quoteRecord.id);
        Blob pdfBlob;

        // Attempt to get the PDF content
        try {
            if(Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('1234');
            } else {
            pdfBlob = pdfPage.getContentAsPDF();
            }// Get the PDF content
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error generating PDF: ' + e.getMessage()));
            return null; // Exit early if there is an error
        }

        // Create a new ContentVersion record for the PDF
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.ContentLocation = 'S';
        Integer newVersion = Integer.valueOf(version) + 1;
        contentVersion.PathOnClient = quoteRecord.Name + '_' + newVersion + '.pdf';
        contentVersion.Title = quoteRecord.Name + '_' + newVersion + '.pdf';
        contentVersion.isMajorVersion = false;
        contentVersion.VersionData = pdfBlob;

        // Insert ContentVersion record
        upsert contentVersion;

        contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.id];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
        contentDocumentLink.LinkedEntityId = quoteRecord.id;
        contentDocumentLink.ShareType = 'V';
        upsert contentDocumentLink;

        // Redirect back to the invoice record page
        PageReference pageRef = new PageReference('/' + quoteRecord.id);
        pageRef.setRedirect(true);
        return pageRef;
    }

    // Method to generate, save the PDF, and send it as an email attachment
    public PageReference saveAndSend() {
        try {
            if(String.isNotBlank(Emailid) && String.isNotBlank(subject)) {
                String finalString = '%' + quoteRecord.Name + '%';
                List<ContentDocument> contentDocs = [SELECT Id, Title FROM ContentDocument
                                                    WHERE Title LIKE :finalString
                                                    ORDER BY CreatedDate DESC
                                                    LIMIT 1];
                String version = '0';
                if(contentDocs.size() > 0) {
                    version = contentDocs[0].Title.substringAfterLast('_').substringBeforeLast('.');
                }

                if (!createNew) {
                    if (contentDocs.size() > 0) {
                        Database.delete(contentDocs, false);
                    }
                }

                Set<String> LatestPublishedVersionIds = new Set<String>();
                formSubmitted = true;

                // Create a new ContentVersion record for the PDF
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.ContentLocation = 'S';
                Integer newVersion = Integer.valueOf(version) + 1;
                contentVersion.PathOnClient = quoteRecord.Name + '_' + newVersion + '.pdf';
                contentVersion.Title = quoteRecord.Name + '_' + newVersion + '.pdf';
                contentVersion.isMajorVersion = false;

                // Generate the PDF content
                PageReference pdfPage = Page.QuotePDF; // Visualforce page reference
                pdfPage.getParameters().put('id', quoteRecord.id);
                Blob pdfBlob;
                try {
                    if(Test.isRunningTest()) {
                        pdfBlob = Blob.valueOf('1234');
                    } else {
                        pdfBlob = pdfPage.getContentAsPDF();
                    }
                    } catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Error generating PDF: ' + e.getMessage()));
                        return null;
                    }
                contentVersion.VersionData = pdfBlob;
                upsert contentVersion;

                contentVersion = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, Title
                                FROM ContentVersion
                                WHERE Id = :contentVersion.id];

                // Link the document to the Quote record
                ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                contentDocumentLink.ContentDocumentId = contentVersion.ContentDocumentId;
                contentDocumentLink.LinkedEntityId = quoteRecord.id;
                contentDocumentLink.ShareType = 'V';
                upsert contentDocumentLink;

                LatestPublishedVersionIds.add(contentVersion.ContentDocument.LatestPublishedVersionId);


                System.debug('To_Addresses ' + To_Addresses);
                System.debug('CC_Addresses ' + CC_Addresses);
                System.debug('defaultToAddress ' + defaultToAddress);
                System.debug('defaultCCAddresses ' + defaultCCAddresses);

                List<String> toAddresses = new List<String>();
                List<String> ccAddresses = new List<String>();

                if(String.isNotBlank(To_Addresses)) {
                    To_Addresses = To_Addresses.replaceAll('[;,:]', ',');
                    defaultToAddress = defaultToAddress.replaceAll('[;,:]', ',');
                    Set<String> toEmails = new Set<String>();
                    for(String Str : To_Addresses.split(',')) {
                        if(String.isNotBlank(Str)) {
                            toEmails.add(str.trim());
                        }
                    }
                    for(String Str : defaultToAddress.split(',')) {
                        if(String.isNotBlank(Str)) {
                            toEmails.add(str.trim());
                        }
                    }
                    toAddresses = new List<String>(toEmails);
                }

                if(String.isNotBlank(CC_Addresses)) {
                    CC_Addresses = CC_Addresses.replaceAll('[;,:]', ',');
                    defaultCCAddresses = defaultCCAddresses.replaceAll('[;,:]', ',');
                    Set<String> CCEmails = new Set<String>();
                    for(String Str : CC_Addresses.split(',')) {
                        if(String.isNotBlank(Str)) {
                            CCEmails.add(str.trim());
                        }
                    }
                    for(String Str : defaultCCAddresses.split(',')) {
                        if(String.isNotBlank(Str)) {
                            CCEmails.add(str.trim());
                        }
                    }
                    ccAddresses = new List<String>(CCEmails);
                }

                System.debug('toAddresses ' + toAddresses);
                System.debug('ccAddresses ' + ccAddresses);


                // Prepare and send the email
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                email.setToAddresses(toAddresses);
                email.setCcAddresses(ccAddresses);

                if(LatestPublishedVersionIds.size() > 0) {
                    email.setEntityAttachments(new List<String>(LatestPublishedVersionIds));
                }

                email.setReplyTo(quoteRecord.Owner.Email);

                if (String.isNotBlank(quoteRecord.Owner.Email)) {
                    email.setBccAddresses(new List<String> { quoteRecord.Owner.Email });
                }

                email.setSubject(subject);
                email.setHtmlBody(body);

                if (Label.External_Email_Disabled != 'True') {

                Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Email Id and subject are mandatory fields, please verify'));
                return null;
            }

            PageReference pageRef = new PageReference('/' + quoteRecord.id);
            pageRef.setRedirect(true);
            return pageRef;
        } catch(Exception ex) {
            // Handle exceptions
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'An error occurred: ' + ex.getMessage()));
            return null;
        }
    }

    // Method to handle the cancel action
    public PageReference cancel() {
        // Redirect to the invoice record page
        PageReference pageRef = new PageReference('/' + quoteRecord.id);
        pageRef.setRedirect(true);
        return pageRef;
    }
}