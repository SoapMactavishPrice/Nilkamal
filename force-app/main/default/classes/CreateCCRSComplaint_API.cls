@RestResource(urlMapping = '/CreateCCRSComplaint')
global class CreateCCRSComplaint_API {
    @HttpPost
    global static void doPost() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String jSONRequestBody = request.requestBody.toString().replace('\n', '');

        // ------------------- API LOG to track the request -------------------
        // API_Log__c api_log = new API_Log__c();
        // api_log.API_log_Name__c = 'CreateCCRSComplaint_API';
        // api_log.Request__c = jSONRequestBody;
        // api_log.Request_Created_Time__c = Datetime.now();

        List < JSONData2Apex > jsonDataAccountList = JSONData2Apex.parse(jSONRequestBody);
        System.debug('======----->jsonDataAccountList' + jsonDataAccountList);

        try {

            Map < String, Object > responseMap = new Map < String, Object > ();
            List<CCSR_Complaint__c> insertCCSRList = new List<CCSR_Complaint__c>();
            Set<String> materialCodeSet = new Set<String>();
            Map<String, String> productCodeIdMap = new Map<String, String>();

            Set<String> customerCodeSet = new Set<String>();
            Map<String, String> customerCodeIdMap = new Map<String, String>();

            for (JSONData2Apex v : jsonDataAccountList) {
                materialCodeSet.add(v.Material_Code);
                customerCodeSet.add(v.SOLD_TO);
            }

            List<Product2> exProduct = [
                SELECT Id, Name, ProductCode
                FROM Product2
                WHERE ProductCode IN :materialCodeSet
            ];

            List<Account> exAccount = [
                SELECT Id, Name, SAP_Customer_code__c
                FROM Account
                WHERE SAP_Customer_code__c IN :customerCodeSet
            ];

            for (Product2 p : exProduct) {
                productCodeIdMap.put(p.ProductCode, p.Id);
            }

            for (Account p : exAccount) {
                customerCodeIdMap.put(p.SAP_Customer_code__c, p.Id);
            }

            for (JSONData2Apex v : jsonDataAccountList) {
                CCSR_Complaint__c ccsrObject = new CCSR_Complaint__c();
                if (String.IsNotBlank(v.Plant)) {
                    ccsrObject.Plant__c = v.Plant;
                }
                if (String.IsNotBlank(v.Complaint_Registration)) {
                    ccsrObject.Complaint_Registration__c = Date.valueOf(parseDate(v.Complaint_Registration));
                }
                if (String.IsNotBlank(v.Notification_No)) {
                    ccsrObject.Notification_No__c = v.Notification_No;
                }
                if (String.IsNotBlank(v.Notification_type)) {
                    ccsrObject.Notification_type__c = v.Notification_type;
                }
                if (String.IsNotBlank(v.Material_Code)) {
                    if (productCodeIdMap.containsKey(v.Material_Code)) {
                        ccsrObject.Material__c = productCodeIdMap.get(v.Material_Code);
                    }
                    ccsrObject.Material_Code__c = v.Material_Code;
                }
                if (String.IsNotBlank(v.Version_No)) {
                    ccsrObject.Version_No__c = v.Version_No;
                }
                if (String.IsNotBlank(v.Supplied_Quantity)) {
                    ccsrObject.Supplied_Quantity__c = Decimal.valueOf(v.Supplied_Quantity);
                }
                if (String.IsNotBlank(v.Complaint_Quantity)) {
                    ccsrObject.Complaint_Quantity__c = Decimal.valueOf(v.Complaint_Quantity);
                }
                if (String.IsNotBlank(v.Invoice_No)) {
                    ccsrObject.Invoice_No__c = v.Invoice_No;
                }
                if (String.IsNotBlank(v.Invoice_date)) {
                    ccsrObject.Invoice_date__c = Date.valueOf(parseDate(v.Invoice_date));
                }
                if (String.IsNotBlank(v.Marketing_Decision)) {
                    ccsrObject.Marketing_Decision__c = v.Marketing_Decision;
                }
                if (String.IsNotBlank(v.SOLD_TO)) {
                    if (customerCodeIdMap.containsKey(v.SOLD_TO)) {
                        ccsrObject.SOLD_TO__c = customerCodeIdMap.get(v.SOLD_TO);
                    }
                }
                // if (String.IsNotBlank(v.Customer_Name)) {
                //     ccsrObject.Customer_Name__c = v.Customer_Name;
                // }
                if (String.IsNotBlank(v.Customer_Address)) {
                    ccsrObject.Customer_Address__c = v.Customer_Address;
                }
                if (String.IsNotBlank(v.Nature_of_Complaint)) {
                    ccsrObject.Nature_of_Complaint__c = v.Nature_of_Complaint;
                }
                if (String.IsNotBlank(v.Manuf_Month_Year)) {
                    ccsrObject.Manuf_Month_Year__c = v.Manuf_Month_Year;
                }
                if (String.IsNotBlank(v.Defect_Decs)) {
                    ccsrObject.Defect_Decs__c = v.Defect_Decs;
                }
                if (String.IsNotBlank(v.Root_Cause)) {
                    ccsrObject.Root_Cause__c = v.Root_Cause;
                }
                if (String.IsNotBlank(v.Route_Cause_Text)) {
                    ccsrObject.Route_Cause_Text__c = v.Route_Cause_Text;
                }
                if (String.IsNotBlank(v.Preventive_action_1)) {
                    ccsrObject.Preventive_action_1__c = v.Preventive_action_1;
                }
                if (String.IsNotBlank(v.Preventive_Action_Date)) {
                    ccsrObject.Preventive_Action_Date__c = Date.valueOf(parseDate(v.Preventive_Action_Date));
                }
                if (String.IsNotBlank(v.Material_Category)) {
                    ccsrObject.Material_Category__c = v.Material_Category;
                }
                if (String.IsNotBlank(v.Shipping_Plant)) {
                    ccsrObject.Shipping_Plant__c = v.Shipping_Plant;
                }
                if (String.IsNotBlank(v.Registration_Office)) {
                    ccsrObject.Registration_Office__c = v.Registration_Office;
                }
                if (String.IsNotBlank(v.Status)) {
                    ccsrObject.Status__c = v.Status;
                }
                if (String.IsNotBlank(v.Complaint_Close_date)) {
                    ccsrObject.Complaint_Close_date__c = Date.valueOf(parseDate(v.Complaint_Close_date));
                }
                if (String.IsNotBlank(v.Shipping_Plant_Desc)) {
                    ccsrObject.Shipping_Plant_Desc__c = v.Shipping_Plant_Desc;
                }
                if (String.IsNotBlank(v.Cycle_Time_on_Complaint_Closure)) {
                    ccsrObject.Cycle_Time_on_Complaint_Closure__c = Decimal.valueOf(v.Cycle_Time_on_Complaint_Closure);
                }
                if (String.IsNotBlank(v.Marketing_Dec_date)) {
                    ccsrObject.Marketing_Dec_date__c = Date.valueOf(parseDate(v.Marketing_Dec_date));
                }
                if (String.IsNotBlank(v.Material_Description)) {
                    ccsrObject.Material_Description__c = v.Material_Description;
                }
                if (String.IsNotBlank(v.Marketing_Dec_Text)) {
                    ccsrObject.Marketing_Dec_Text__c = v.Marketing_Dec_Text;
                }
                if (String.IsNotBlank(v.Valuation_Class)) {
                    ccsrObject.Valuation_Class__c = v.Valuation_Class;
                }
                if (String.IsNotBlank(v.RESOLUTION_IMPLEMENTED)) {
                    ccsrObject.RESOLUTION_IMPLEMENTED__c = v.RESOLUTION_IMPLEMENTED;
                }
                if (String.IsNotBlank(v.RESOLUTION_DESCRIPTION)) {
                    ccsrObject.RESOLUTION_DESCRIPTION__c = v.RESOLUTION_DESCRIPTION;
                }
                if (String.IsNotBlank(v.RESOLUTION_IMPLEMENTED_DESCRIPTION)) {
                    ccsrObject.RESOLUTION_IMPLEMENTED_DESCRIPTION__c = v.RESOLUTION_IMPLEMENTED_DESCRIPTION;
                }
                if (String.IsNotBlank(v.COMMERCIAL_COMPLETION_DATE)) {
                    ccsrObject.COMMERCIAL_COMPLETION_DATE__c = Date.valueOf(parseDate(v.COMMERCIAL_COMPLETION_DATE));
                }
                if (String.IsNotBlank(v.COCO_STATUS)) {
                    ccsrObject.COCO_STATUS__c = v.COCO_STATUS;
                }
                if (String.IsNotBlank(v.CN_AMOUNT)) {
                    ccsrObject.CN_AMOUNT__c = Decimal.valueOf(v.CN_AMOUNT);
                }
                if (String.IsNotBlank(v.COMPLAINT_CATEGORY)) {
                    ccsrObject.COMPLAINT_CATEGORY__c = v.COMPLAINT_CATEGORY;
                }
                if (String.IsNotBlank(v.Resolution_given_Date)) {
                    ccsrObject.Resolution_given_Date__c = Date.valueOf(parseDate(v.Resolution_given_Date));
                }
                if (String.IsNotBlank(v.Resolution_Implemented_Date)) {
                    ccsrObject.Resolution_Implemented_Date__c = Date.valueOf(parseDate(v.Resolution_Implemented_Date));
                }
                if (String.IsNotBlank(v.Complaint_Qty_Net_Val)) {
                    ccsrObject.Complaint_Qty_Net_Val__c = Decimal.valueOf(v.Complaint_Qty_Net_Val);
                }
                if (String.IsNotBlank(v.Root_Cause_Related_Resolution)) {
                    ccsrObject.Root_Cause_Related_Resolution__c = v.Root_Cause_Related_Resolution;
                }
                if (String.IsNotBlank(v.Material_Group)) {
                    ccsrObject.Material_Group__c = v.Material_Group;
                }
                if (String.IsNotBlank(v.Registration_Office_Name)) {
                    ccsrObject.Registration_Office_Name__c = v.Registration_Office_Name;
                }
                if (String.IsNotBlank(v.Sales_Employee)) {
                    ccsrObject.Sales_Employee__c = v.Sales_Employee;
                }
                insertCCSRList.add(ccsrObject);
            }


            if (insertCCSRList.size() > 0) {
                insert insertCCSRList;
            }

            responseMap.put('status', 'success');
            responseMap.put('message', 'Successfully Inserted');

            String resp = JSON.serialize(responseMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 200;

            // api_log.Status__c = 'Success';
            // api_log.Response_Code__c = '200';
            // api_log.Response__c = String.valueOf(resp);
            // api_log.response_time__c = Datetime.now();

        } catch (Exception e) {
            System.debug('Catch Error' + e.getStackTraceString());
            System.debug('Catch Error' + e.getMessage());
            System.debug('Catch Error' + e.getlineNumber());

            // ------------------- Create Response Map -------------------
            Map < string, string > errorResMap = new Map < string, string > ();
            // errorResMap.put('Message', 'Something went wrong');
            // errorResMap.put('Error1', e.getMessage());
            // errorResMap.put('Error2', '' + e.getlineNumber());
            // errorResMap.put('Error3', '' + String.valueOf(e));

            errorResMap.put('status', 'fail');
            errorResMap.put('message', e.getMessage());

            // ------------------- Send Response Map -------------------
            String resp = JSON.serialize(errorResMap);
            response.responseBody = Blob.valueOf(resp);
            response.addHeader('Content-Type', 'application/json');
            response.statusCode = 400;

            // api_log.Status__c = 'Failure';
            // api_log.Response_Code__c = '400';
            // api_log.Exception_Description__c = 'Line Number : ' + e.getLineNumber() + ' \n\n ' + e.getMessage() + '\n\n' + e.getStackTraceString();
            // api_log.response_time__c = Datetime.now();

        }

        // insert api_log;

    }

    public static Date parseDate(String dateStr) {
        List<String> parts = dateStr.split('-');
        if (parts.size() != 3) return null;
        Integer day = Integer.valueOf(parts[0]);
        Integer month = Integer.valueOf(parts[1]);
        Integer year = Integer.valueOf(parts[2]);
        return Date.newInstance(year, month, day);
    }

    public class JSONData2Apex {
        public String Plant;
        public String Complaint_Registration;
        public String Notification_No;
        public String Notification_type;
        public String Material_Code;
        public String Version_No;
        public String Supplied_Quantity;
        public String Complaint_Quantity;
        public String Invoice_No;
        public String Invoice_date;
        public String Marketing_Decision;
        public String SOLD_TO;
        public String Customer_Name;
        public String Customer_Address;
        public String Nature_of_Complaint;
        public String Manuf_Month_Year;
        public String Defect_Decs;
        public String Root_Cause;
        public String Route_Cause_Text;
        public String Preventive_action_1;
        public String Preventive_Action_Date;
        public String Material_Category;
        public String Shipping_Plant;
        public String Registration_Office;
        public String Status;
        public String Complaint_Close_date;
        public String Shipping_Plant_Desc;
        public String Cycle_Time_on_Complaint_Closure;
        public String Marketing_Dec_date;
        public String Material_Description;
        public String Marketing_Dec_Text;
        public String Valuation_Class;
        public String RESOLUTION_IMPLEMENTED;
        public String RESOLUTION_DESCRIPTION;
        public String RESOLUTION_IMPLEMENTED_DESCRIPTION;
        public String COMMERCIAL_COMPLETION_DATE;
        public String COCO_STATUS;
        public String CN_AMOUNT;
        public String COMPLAINT_CATEGORY;
        public String Resolution_given_Date;
        public String Resolution_Implemented_Date;
        public String Complaint_Qty_Net_Val;
        public String Root_Cause_Related_Resolution;
        public String Material_Group;
        public String Registration_Office_Name;
        public String Sales_Employee;
    }    

    public static List < JSONData2Apex > parse(String json) {
        return (List < JSONData2Apex > ) System.JSON.deserialize(json, List < JSONData2Apex > .class);
    }

}