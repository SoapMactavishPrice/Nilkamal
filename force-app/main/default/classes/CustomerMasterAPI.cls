@RestResource(urlMapping='/CustomerMasterAPI/*')
global class CustomerMasterAPI {
    @HttpPost
    global static void processCustomerMaster() {
        API_log__c apiLog=new API_log__c();
        try {
            // Parse the JSON request
            RestRequest req = RestContext.request;
            //String jsonBody = req.requestBody.toString();
            //String jsonBody = req.requestBody.toString().replace('\n', '\\n').replace('\r', '\\r');
            String jsonBody = req.requestBody.toString().replace('\n', '').replace('\r', ''); //10-12-2025

            apiLog.Log_Name__c ='Customer Master';
            apiLog.Request__c='Total Size = '+jsonBody;
            List<IntegrationRequestBuilder.CustomerWrapper> customers = IntegrationRequestBuilder.customerMasterParse(jsonBody);

            // Process each customer record
            for (IntegrationRequestBuilder.CustomerWrapper customer : customers) {
                // 1. Create or Update Account
                Account account = upsertAccount(customer);
				apiLog.Customer__c=account.id;
                // 2. Process Partner Functions
                if (customer.PARTNERFUNCTION_LIST != null) {
                    //processPartnerFunctions(customer.PARTNERFUNCTION_LIST, account.Id);
                }

            }
            apiLog.Status__c='Success';
            Map<String,Object> mpResponse=new Map<String,Object>();
            mpResponse.put('Status','success');
            mpResponse.put('msg','Created Successfully');
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(mpResponse));
        } catch (Exception e) {
            RestContext.response.statusCode = 500;
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
            RestContext.response.responseBody = Blob.valueOf('{"error": "' + e.getMessage()+e.getLineNumber()+ + '"}');
        }finally{

            INSERT apiLog;
        }
    }

    private static Account upsertAccount(IntegrationRequestBuilder.CustomerWrapper customer) {
        Account acc;
        List<Account> accList = [SELECT Id, Name, SAP_Customer_code__c FROM Account WHERE
                                    SAP_Customer_code__c = :customer.CUSTOMER_NO];

        if (!accList.isEmpty()) {
            acc = accList[0];
        } else {
            acc = new Account();
        }

        if(customer.PARENT_ACCOUNT!=''){
            List<Account> acca =new List<Account>();
            acca= [SELECT Id  FROM Account WHERE SAP_Customer_code__c = :customer.PARENT_ACCOUNT LIMIT 1];
            if(acca.size()>0){
                acc.ParentId=acca[0].Id;
            }

        }
        if(customer.COMPANY_CODE!=''){
            Company_Master__c cm = [SELECT ID,Code__c FROM Company_Master__c WHERE Code__c = : customer.COMPANY_CODE LIMIT 1];
            acc.Company_Code__c=cm.Id;
        }
        // if(customer.SALES_ORG!=''){
        //  	Sales_Organizations__c dcList = [SELECT ID,Sales_Org_Code__c  FROM Sales_Organizations__c WHERE Sales_Org_Code__c =: customer.SALES_ORG LIMIT 1];
        //     acc.Sales_Organizations__c=dcList.Id;
        // }
        //  if(customer.DISTRIBUTION_CHANNEL!=''){
        //  	Distribution_Channel__c dcList = [SELECT ID,Distribution_Code__c  FROM Distribution_Channel__c WHERE Distribution_Code__c =: customer.DISTRIBUTION_CHANNEL LIMIT 1];

        //     acc.Distribution_Channel__c=dcList.Id;
        // }

        // if(customer.DIVISION!=''){
        //  	Division__c dcList = [SELECT ID,Division_Code__c  FROM Division__c WHERE Division_Code__c =: customer.DIVISION LIMIT 1];
        //     acc.Division__c=dcList.Id;
        // }

        acc.Name = customer.CUST_NAME;
        acc.SAP_Customer_code__c = customer.CUSTOMER_NO;
        acc.Account_Group__c = customer.ACCOUNT_GROUP;
        acc.City__c = customer.CITY;
        acc.Postal_code__c = customer.POST_CODE;
        acc.Country__c = customer.COUNTRY;
        acc.Mobile_Number__c = customer.MOBILE_NUMBER;
        acc.Phone = customer.PHONE1;
        acc.Email_Id__c = customer.EMAIL_ID;
        acc.Landline_No_1__c = customer.PHONE2;
        acc.Street_House_Number__c = customer.STREET;
        acc.Street1__c = customer.STREET1;
        acc.Street2__c = customer.STREET2;
        acc.Industry = customer.INDUSTRY;
        acc.CurrencyIsoCode = customer.CURRENCY_SF;
        acc.GST_No__c = customer.GST_NUMBER;
        acc.Pan_No__c = customer.PAN_NUMBER;
        acc.Inco_Term_1__c = customer.INCOTERMS1!=''?customer.INCOTERMS1:null;
        acc.Inco_Term_2_Description__c = customer.INCOTERMS2;
        acc.TCS_Applicable__c = customer.TCS_APPLICABLE!=''?customer.TCS_APPLICABLE:null;
        acc.Terms_of_Payment__c = customer.TERMS_OF_PAYMENT!=''?customer.TERMS_OF_PAYMENT:null;
        acc.Classification__c = customer.CLASSIFICATION!=''?customer.CLASSIFICATION:null;
        acc.Sub_Industry__c = customer.SUB_INDUSTRY!=''?customer.SUB_INDUSTRY:null;
        acc.Sub_Industry2__c = customer.SUB_INDUSTRY2!=''?customer.SUB_INDUSTRY2:null;
        acc.Sales_District__c = customer.SALES_DISTRICT!=''?customer.SALES_DISTRICT:null;
        acc.Sales_office__c = customer.SALES_OFF!=''?customer.SALES_OFF:null;
        acc.Sales_Group__c = customer.SALES_GRP!=''?customer.SALES_GRP:null;
        acc.Virtual_Account_No__c = customer.VIRTUAL_ACCOUNT_NUMBER;
        if(customer.BANK_DETAILS != null && customer.BANK_DETAILS.size() > 0) {
            acc.Customer_Blocked__c = Boolean.valueOf(customer.BANK_DETAILS[0].CUST_BLOCK_STATUS);
        }

        try {
            Pin_Code_Master__c pinCode = [SELECT Id, Name, State__c FROM Pin_Code_Master__c WHERE Name = :customer.POST_CODE LIMIT 1];
            acc.State__c = pinCode.State__c;
            acc.Pin_Code__c = pinCode.Id;
        }
        catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }

        // Add additional fields here
        upsert acc;

        List<Customer_Sales_Area_Line_Item__c> custSalesAreaLi=new List<Customer_Sales_Area_Line_Item__c>();
        custSalesAreaLi=[SELECT Id, Name FROM Customer_Sales_Area_Line_Item__c WHERE
                                    Customer__r.SAP_Customer_code__c = :customer.CUSTOMER_NO
                                    AND Sales_Organizations__r.Sales_Org_Code__c=: customer.SALES_ORG
                                    AND Distribution_Channel__r.Distribution_Code__c =: customer.DISTRIBUTION_CHANNEL
                                    AND Division__r.Division_Code__c=:customer.DIVISION];
        if(custSalesAreaLi.size()==0){
            Customer_Sales_Area_Line_Item__c cs=new Customer_Sales_Area_Line_Item__c();
            cs.Customer__c=acc.Id;
            if(customer.SALES_ORG!=''){
                Sales_Organizations__c dcList = [SELECT ID,Sales_Org_Code__c  FROM Sales_Organizations__c WHERE Sales_Org_Code__c =: customer.SALES_ORG LIMIT 1];
                cs.Sales_Organizations__c=dcList.Id;
            }
            if(customer.DISTRIBUTION_CHANNEL!=''){
                Distribution_Channel__c dcList = [SELECT ID,Distribution_Code__c  FROM Distribution_Channel__c WHERE Distribution_Code__c =: customer.DISTRIBUTION_CHANNEL LIMIT 1];
                cs.Distribution_Channel__c=dcList.Id;
            }

            if(customer.DIVISION!=''){
                Division__c dcList = [SELECT ID,Division_Code__c  FROM Division__c WHERE Division_Code__c =: customer.DIVISION LIMIT 1];
                cs.Division__c=dcList.Id;
            }
            INSERT cs;
        }

        // 3. Process Bank Details
        if (customer.BANK_DETAILS != null) {
            processBankDetails(customer.BANK_DETAILS, acc.Id,customer.SALES_ORG);
        }
        return acc;
    }
@TestVisible
    private static void processPartnerFunctions(List<IntegrationRequestBuilder.PartnerFunction> partnerFunctions, Id accountId) {
        List<SObject> partnerFunctionRecords = new List<SObject>();
        for (IntegrationRequestBuilder.PartnerFunction pf : partnerFunctions) {
            Partner_Function_Address_Information__c existingPF ;
            List<Partner_Function_Address_Information__c> existingPFlist=  [
                SELECT Id
                FROM Partner_Function_Address_Information__c
                WHERE Customer_Name__c = :pf.CUSTOMER_NO AND Address_Type__c = :pf.ADDRESS_TYPE LIMIT 1
            ];
            if (!existingPFlist.isEmpty()) {
                existingPF=existingPFlist[0];
            }else{
                existingPF = new Partner_Function_Address_Information__c();
            }
            existingPF.Customer_Name__c = accountId;
            existingPF.Customer_Number__c = pf.CUSTOMER_NO;
            existingPF.Address_Type__c = pf.ADDRESS_TYPE;
            existingPF.GSTIN__c = pf.GST_IN!=''?pf.GST_IN:null;
            if(pf.PAN_NUMBER!=''){
                existingPF.Pan_No__c = pf.PAN_NUMBER;
            }

            existingPF.Address_line_1__c = pf.ADDRESS_LINE1;
            existingPF.Address_line_2__c = pf.ADDRESS_LINE2;
            existingPF.Address_line_3__c = pf.ADDRESS_LINE3;
            existingPF.City__c = pf.CITY;
            if( pf.POSTL_CODE!=''){
                existingPF.Pin_Code__c = Integer.valueOf(pf.POSTL_CODE);
            }
            if(pf.COUNTRY!=''){
                existingPF.Country__c = pf.COUNTRY;
            }
            if(pf.DISTRICT!=''){
                existingPF.District__c = pf.DISTRICT;
            }
            if(pf.STATE!=''){
                existingPF.State__c = pf.DISTRICT;
            }
            if(pf.REGION!=''){
                existingPF.Region__c = pf.DISTRICT;
            }


            // Add additional fields here
            partnerFunctionRecords.add(existingPF);
        }
        upsert partnerFunctionRecords;
    }
@TestVisible
    private static void processBankDetails(List<IntegrationRequestBuilder.BankDetail> bankDetails, Id accountId,String SaleOrg) {
        Sales_Organizations__c dcList = [SELECT ID,Sales_Org_Code__c  FROM Sales_Organizations__c WHERE Sales_Org_Code__c =: SaleOrg LIMIT 1];
        List<SObject> bankDetailRecords = new List<SObject>();
        for (IntegrationRequestBuilder.BankDetail bd : bankDetails) {
            Bank_Information__c existingBD ;
                List<Bank_Information__c> existingBDList= [SELECT Id,Sales_Org__c,Bank_Address__c,IFSC_Code__c,Account_Name__c,Customer_no__c,Name FROM Bank_Information__c WHERE Customer_no__c = :bd.CUSTOMER_NO AND Sales_Org__r.Sales_Org_Code__c = :SaleOrg LIMIT 1];
            if (!existingBDList.isEmpty()) {
                existingBD=existingBDList[0];
            }else{
                existingBD = new Bank_Information__c();
            }
            existingBD.Account_Name__c = accountId;
            existingBD.Customer_no__c = bd.CUSTOMER_NO;
            existingBD.Name = bd.BANKNAME;
            existingBD.IFSC_Code__c = bd.IFSC_CODE;
            existingBD.Bank_Address__c = bd.ADDRESS;


            existingBD.Sales_Org__c = dcList.Id;

            // Add additional fields here
            bankDetailRecords.add(existingBD);
        }
        upsert bankDetailRecords;
    }


}