@RestResource(urlMapping='/InvoiceAPI/*')
global class InvoiceAPI {
    @HttpPost
    global static void doPost() {
        API_log__c apiLog = new API_log__c();
        try {
            // Parse the JSON request
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString().replace('\n', '\\n').replace('\r', '\\r');
            //String jsonBody = req.requestBody.toString().replace('\n', '');
            jsonBody = jsonBody.replace('\r', '');
			String Message='Successfully Sync to SF';
            apiLog.Log_Name__c = 'Invoice API';
            apiLog.Request__c = 'Total Size = ' + jsonBody;
            List<IntegrationRequestBuilder.InvoiceWrapper> invoices = IntegrationRequestBuilder.InvoiceParse(jsonBody);

            // Prepare data for bulk processing
            Set<String> invoiceNames = new Set<String>();
            Set<String> OrderIds = new Set<String>();
            Set<String> salesOrgCodes = new Set<String>();
            Set<String> distributionChannelCodes = new Set<String>();
            Set<String> divisionCodes = new Set<String>();
            Set<String> productCodes = new Set<String>();
            Set<String> plantCodes = new Set<String>();
            Set<String> employeeCodes = new Set<String>();
            Set<String> sapCustomerCodes = new Set<String>();
            Set<String> serialNumber=new Set<String>();

            for (IntegrationRequestBuilder.InvoiceWrapper invoice : invoices) {
                serialNumber.add(invoice.Serial_No);
                invoiceNames.add(invoice.SAPInvoiceNo+'_'+invoice.Line_Item);
                OrderIds.add(invoice.SAPOrderNo);
                if (!String.isBlank(invoice.Sales_org)) salesOrgCodes.add(invoice.Sales_org);
                if (!String.isBlank(invoice.Distribution_Channel)) distributionChannelCodes.add(invoice.Distribution_Channel);
                if (!String.isBlank(invoice.Division)) divisionCodes.add(invoice.Division);
                if (!String.isBlank(invoice.Material)) productCodes.add(invoice.Material);
                if (!String.isBlank(invoice.Plant_Name)) plantCodes.add(invoice.Plant_Name);
                if (!String.isBlank(invoice.Sales_Employee_code)) employeeCodes.add(invoice.Sales_Employee_code);
                if (!String.isBlank(invoice.Ship_to_Party)) sapCustomerCodes.add(invoice.Ship_to_Party);
                if (!String.isBlank(invoice.Sold_to_Party_No)) sapCustomerCodes.add(invoice.Sold_to_Party_No);
            }

             // Query necessary data in bulk
            Map<String, String> existingAssets = new Map<String, String>();
            for(Asset ast:[SELECT Id, Name FROM Asset WHERE Name IN :serialNumber]){
            existingAssets.put(ast.Name,ast.Id);
            }
            // Query necessary data in bulk
            Map<String, String> existingInvoices = new Map<String, String>();
            for(Invoice__c inv:[SELECT Id, Name,Unique__c FROM Invoice__c WHERE Unique__c IN :invoiceNames]){
                existingInvoices.put(inv.Unique__c,inv.Id);
            }

             // Query necessary data in bulk
            Map<String, String> existingQuote = new Map<String, String>();
            for(Quote quo:[SELECT Id, SAP_Order_No__c FROM Quote WHERE SAP_Order_No__c IN :OrderIds]){
                existingQuote.put(quo.SAP_Order_No__c,quo.Id);
            }

            // Sales_Organizations__c Map
            Map<String, Sales_Organizations__c> salesOrgMap = new Map<String, Sales_Organizations__c>();
            for (Sales_Organizations__c salesOrg : [SELECT Id, Sales_Org_Code__c FROM Sales_Organizations__c WHERE Sales_Org_Code__c IN :salesOrgCodes]) {
                salesOrgMap.put(salesOrg.Sales_Org_Code__c, salesOrg);
            }

            // Distribution_Channel__c Map
            Map<String, Distribution_Channel__c> distributionChannelMap = new Map<String, Distribution_Channel__c>();
            for (Distribution_Channel__c distChannel : [SELECT Id, Distribution_Code__c FROM Distribution_Channel__c WHERE Distribution_Code__c IN :distributionChannelCodes]) {
                distributionChannelMap.put(distChannel.Distribution_Code__c, distChannel);
            }

            // Division__c Map
            Map<String, Division__c> divisionMap = new Map<String, Division__c>();
            for (Division__c division : [SELECT Id, Division_Code__c FROM Division__c WHERE Division_Code__c IN :divisionCodes]) {
                divisionMap.put(division.Division_Code__c, division);
            }

            // Product2 Map
            Map<String, Product2> productMap = new Map<String, Product2>();
            for (Product2 product : [SELECT Id, ProductCode,Category__c,Business_Vertical__c FROM Product2 WHERE ProductCode IN :productCodes]) {
                productMap.put(product.ProductCode, product);
            }

            // Plant_Master__c Map
            Map<String, Plant_Master__c> plantMap = new Map<String, Plant_Master__c>();
            for (Plant_Master__c plant : [SELECT Id, Plant_Code__c FROM Plant_Master__c WHERE Plant_Code__c IN :plantCodes]) {
                plantMap.put(plant.Plant_Code__c, plant);
            }

            // User Map
            Map<String, User> userMap = new Map<String, User>();
            for (User user : [SELECT Id, UID__c FROM User WHERE UID__c IN :employeeCodes]) {
                userMap.put(user.UID__c, user);
            }

            // Account Map
            Map<String, Account> accountMap = new Map<String, Account>();
            for (Account account : [SELECT Id, SAP_Customer_code__c FROM Account WHERE SAP_Customer_code__c IN :sapCustomerCodes]) {
                accountMap.put(account.SAP_Customer_code__c, account);
            }

            //map contact
            Map<String, String> conMap = new Map<String, String>();
            for(Contact con:[SELECT Id, Email FROM Contact WHERE Account.SAP_Customer_code__c IN :accountMap.keySet()]){
                if(con.Email !=null){
                    String s=con.Email;
                    conMap.put(s.toLowerCase(),con.Id);
                }

            }

            // Create or update invoices
            System.debug('existingInvoices.get(invoice.SAPInvoiceNo) '+existingInvoices);
            List<Invoice__c> invoicesToUpsert = new List<Invoice__c>();
            List<Contact> con=new List<Contact>();
            for (IntegrationRequestBuilder.InvoiceWrapper invoice : invoices) {
                String invoiceNo = String.isNotBlank(invoice.SAPInvoiceNo) ? invoice.SAPInvoiceNo : '';
                String lineItem = String.isNotBlank(invoice.Line_Item) ? invoice.Line_Item : '';
                String serialNo = String.isNotBlank(invoice.Serial_No) ? invoice.Serial_No : '';

                String key = invoiceNo + '_' + lineItem + '_' + serialNo;

                System.debug('existingInvoices.get(invoice.SAPInvoiceNo) '+existingInvoices.get(key));
                // System.debug('existingInvoices.get(invoice.SAPInvoiceNo) '+invoice.SAPInvoiceNo);
                Invoice__c billingRecord = new Invoice__c();
                billingRecord.SAPOrderNo__c=invoice.SAPOrderNo;
                billingRecord.Nilkamal_Sr_No__c=invoice.NilkamalSrno;
                billingRecord.Vendor_Sr_No__c=invoice.VendorSrno;
                if(invoice.WarrantyPeriods!='NO'){
                    billingRecord.Warrenty_Periods__c=invoice.WarrantyPeriods;
                }
                if(existingQuote.containsKey(invoice.SAPOrderNo)) {
                    billingRecord.Quote__c=existingQuote.get(invoice.SAPOrderNo);
                }

                if(existingInvoices.containsKey(key)) {
                    billingRecord.Id = existingInvoices.get(key);
                }else{
                    billingRecord.Name = invoice.SAPInvoiceNo;
                }


                if (!String.isBlank(invoice.Sales_org) && salesOrgMap.containsKey(invoice.Sales_org)) {
                    billingRecord.Sales_Organizations__c = salesOrgMap.get(invoice.Sales_org).Id;
                    billingRecord.Sales_Organization__c = invoice.Sales_org;
                }
                if (!String.isBlank(invoice.Distribution_Channel) && distributionChannelMap.containsKey(invoice.Distribution_Channel)) {
                    billingRecord.Distribution_Channel_1__c = distributionChannelMap.get(invoice.Distribution_Channel).Id;
                    billingRecord.Distribution_Channel__c = invoice.Distribution_Channel;
                }
                if (!String.isBlank(invoice.Division) && divisionMap.containsKey(invoice.Division)) {
                    billingRecord.Division_1__c = divisionMap.get(invoice.Division).Id;
                    billingRecord.Division__c = invoice.Division;
                }

                if (!String.isBlank(invoice.Material)) {
                    if(productMap.containsKey(invoice.Material)) {
                        billingRecord.Item_Master__c = productMap.get(invoice.Material).Id;
                        billingRecord.Business_Vertical__c=productMap.get(invoice.Material).Business_Vertical__c;
                    }
                    else {
                        throw new CustomException('Material is not present in the system.');
                    }
                }
                else {
                    throw new CustomException('Material is mandatory to create an invoice.');
                }

                if (!String.isBlank(invoice.Plant_Name) && plantMap.containsKey(invoice.Plant_Name)) {
                    billingRecord.Plant_Master__c = plantMap.get(invoice.Plant_Name).Id;
                    billingRecord.Plant_Name__c = invoice.Plant_Name;
                }
                if (!String.isBlank(invoice.Sales_Employee_code) && userMap.containsKey(invoice.Sales_Employee_code)) {
                    billingRecord.Sales_Person_Name__c = userMap.get(invoice.Sales_Employee_code).Id;
                    billingRecord.OwnerId = userMap.get(invoice.Sales_Employee_code).Id;
                }

                if (!String.isBlank(invoice.Sold_to_Party_No) && accountMap.containsKey(invoice.Sold_to_Party_No)) {
                    billingRecord.Sold_To_Party_1__c = accountMap.get(invoice.Sold_to_Party_No).Id;
                }
                else {
                    throw new CustomException('Sold to Party is not present in the system.');
                }

                if (!String.isBlank(invoice.Ship_to_Party) && accountMap.containsKey(invoice.Ship_to_Party)) {
                    billingRecord.Ship_To_Party_1__c = accountMap.get(invoice.Ship_to_Party).Id;
                }
                else {
                    throw new CustomException('Ship to Party is not present in the system.');
                }

                billingRecord.Sales_Employee_code__c = invoice.Sales_Employee_code;
                billingRecord.Valuation_Class__c = invoice.Valuation_Class;
                billingRecord.MFG_Part_No__c = invoice.MFG_part_no;
                billingRecord.X2nd_LR_number__c = invoice.X2nd_LR_number;
                billingRecord.X2nd_Transporter_Name__c = invoice.X2nd_Transporter_name;
                billingRecord.Billing_Date__c = !String.isBlank(invoice.Billing_Date) ? Date.valueOf(invoice.Billing_Date) : null;
                billingRecord.Billing_Document__c = invoice.Billing_Document;
                billingRecord.Billing_Qty__c = invoice.Billing_Qty;
                billingRecord.Billing_Type__c = invoice.Billing_Type;
                billingRecord.Customer_Mobile__c = invoice.Customer_Mobile;
                billingRecord.Customer_Contact_Name__c = invoice.Customer_Contact_Name;
                billingRecord.Customer_Contact_Email__c = invoice.Customer_Contact_Email;
                String s=invoice.Customer_Contact_Email;
                if(s!=null && s!=''){
                    String s_email=invoice.Customer_Contact_Email;
                    billingRecord.Contact__c=conMap.get(s_email.toLowerCase());
                    if(conMap.get(s_email.toLowerCase())==null){
                        Contact c=new Contact();
                        c.LastName=invoice.Customer_Contact_Name;
                        c.Email=invoice.Customer_Contact_Email;
                        c.MobilePhone=invoice.Customer_Mobile;
                        c.Phone = invoice.Customer_Mobile;
                        if (!String.isBlank(invoice.Sold_to_Party_No) && accountMap.containsKey(invoice.Sold_to_Party_No)) {
                            c.AccountId = accountMap.get(invoice.Sold_to_Party_No).Id;
                        }
                        con.add(c);
                    }
                }
				billingRecord.Item_Text__c = invoice.Item_Text;
                billingRecord.LR_Number__c = invoice.LR_number;
                billingRecord.Line_Item__c = invoice.Line_Item;
                billingRecord.Material__c = invoice.Material;
                billingRecord.Material_Description__c = invoice.Material_Description;
                billingRecord.Net_Invoice_Amount__c = invoice.Net_Invoice_Amount;
                billingRecord.PO_Date__c = (String.isNotBlank(invoice.PO_Date) && invoice.PO_Date != '0000-00-00') ? Date.valueOf(invoice.PO_Date) : null;
                billingRecord.PO_Number__c = invoice.PO_Number;
                billingRecord.Serial_No__c = invoice.Serial_No;
                billingRecord.Ship_to_Address__c = invoice.Ship_to_Address;
                billingRecord.Ship_to_City__c = invoice.Ship_to_City;
                billingRecord.Ship_to_Country__c = invoice.Ship_to_Country;
                billingRecord.Ship_to_Email__c = invoice.Ship_to_Email;
                billingRecord.Ship_to_GST_No__c = invoice.Ship_to_GST_No;
                billingRecord.Ship_to_Mob__c = invoice.Ship_to_Mob;
                billingRecord.Ship_to_Name__c = invoice.Ship_to_Name;
                billingRecord.Ship_to_Pin__c = invoice.Ship_to_Pin;
                billingRecord.Ship_to_Region__c = invoice.Ship_to_Region;
                billingRecord.Ship_to_Tele__c = invoice.Ship_to_Tele;
                billingRecord.Sold_to_Address__c = invoice.Sold_to_Address;
                billingRecord.Sold_to_City__c = invoice.Sold_to_City;
                billingRecord.Sold_to_Country__c = invoice.Sold_to_Country;
                billingRecord.Sold_to_GST_No__c = invoice.Sold_to_GST_No;
                billingRecord.Sold_to_Pin__c = invoice.Sold_to_Pin;
                billingRecord.Sold_to_Email__c = invoice.Sold_to_Email;
                billingRecord.Sold_to_Party_Name__c = invoice.Sold_to_Party_Name;
                billingRecord.Sold_to_Telephone__c = invoice.Sold_to_Telephone;
                billingRecord.Sold_to_Region__c = invoice.Sold_to_Region;
                if(invoice.LR_Date!='') {
                    billingRecord.LR_Date__c = invoice.LR_Date;
                }
                billingRecord.Total_Document_Amount__c = invoice.Total_document_amount;
                billingRecord.Total_Tax_Amount__c = invoice.Total_tax_amount;
                billingRecord.Transporter_Name__c = invoice.Transporter_name;

                billingRecord.Sold_to_Party_Number__c = invoice.Sold_to_Party_No;
                billingRecord.Ship_to_Party_Number__c = invoice.Ship_to_Party;

                billingRecord.Sales_Group_Code__c = invoice.Sales_Group_Code;
                billingRecord.Sales_Group_Description__c = invoice.Sales_Group_Description;
                billingRecord.Sales_Office_Code__c = invoice.Sales_Office_Code;
                billingRecord.Sales_Office_Description__c = invoice.Sales_Office_Description;

                billingRecord.Material_Group_6__c = invoice.Material_Group_6;

                billingRecord.Line_Item_Net_Value__c = invoice.Line_Item_Net_Value;
                billingRecord.Net_Value_per_Piece__c = invoice.Net_Value_per_PC;
                billingRecord.Item_Category__c = invoice.Item_Category;

                if(productMap.containsKey(invoice.Material) && productMap.get(invoice.Material).Category__c == 'Service') {
                    billingRecord.Asset_Serial_No__c = existingAssets.get(invoice.Serial_No);
                }

                invoicesToUpsert.add(billingRecord);
            }



            if(!con.isEmpty()){
                UPSERT con;
                 // Refresh the conMap with newly inserted contacts
                for (Contact c : con) {
                    conMap.put(c.Email.toLowerCase(), c.Id);
                }
            }

            // After inserting contacts, reassign their IDs to the respective invoices
            for (Invoice__c inv : invoicesToUpsert) {
                if (!String.isBlank(inv.Customer_Contact_Email__c) && conMap.containsKey(inv.Customer_Contact_Email__c.toLowerCase())) {
                    inv.Contact__c = conMap.get(inv.Customer_Contact_Email__c.toLowerCase());
                }
            }

            if (!invoicesToUpsert.isEmpty()) {
                upsert invoicesToUpsert;
            }

            apiLog.Status__c = 'Success';
            Map<String,Object> mpResponse=new Map<String,Object>();
            mpResponse.put('Status','success');
            mpResponse.put('msg',Message);
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(mpResponse));
            apiLog.Response__c=(JSON.serialize(mpResponse));
            apiLog.Response_Code__c='200';
        }
        catch (Exception e) {
            RestContext.response.statusCode = 500;
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
            RestContext.response.responseBody = Blob.valueOf('{"error": "' + e.getMessage()+e.getLineNumber()+ + '"}');
        }
        finally {
            insert apiLog;
        }
    }

}