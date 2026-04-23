@isTest
public class CreateCCRSComplaint_APITest {
    
    @isTest
    static void testCreateCCRSComplaintAPI() {
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'P123', isActive = true);
        insert prod;

        Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = 'CUST001');
        insert acc;

        String jsonBody = '[{'+
            '"Plant": "Plant001",'+
            '"Complaint_Registration": "2024-04-01",'+
            '"Notification_No": "NTF001",'+
            '"Notification_type": "TypeA",'+
            '"Material_Code": "P123",'+
            '"Version_No": "V1",'+
            '"Supplied_Quantity": "100",'+
            '"Complaint_Quantity": "5",'+
            '"Invoice_No": "INV001",'+
            '"Invoice_date": "2024-04-02",'+
            '"Marketing_Decision": "Replace",'+
            '"SOLD_TO": "CUST001",'+
            '"Customer_Address": "123 Street",'+
            '"Nature_of_Complaint": "Crack",'+
            '"Manuf_Month_Year": "Mar 2024",'+
            '"Defect_Decs": "Broken",'+
            '"Root_Cause": "Handling",'+
            '"Route_Cause_Text": "Transport Issue",'+
            '"Preventive_action_1": "Handle Better",'+
            '"Preventive_Action_Date": "2024-04-10",'+
            '"Material_Category": "CatA",'+
            '"Shipping_Plant": "SP001",'+
            '"Registration_Office": "RO001",'+
            '"Status": "Open",'+
            '"Complaint_Close_date": "2024-04-15",'+
            '"Shipping_Plant_Desc": "Main Plant",'+
            '"Cycle_Time_on_Complaint_Closure": "14",'+
            '"Marketing_Dec_date": "2024-04-03",'+
            '"Material_Description": "Test Desc",'+
            '"Marketing_Dec_Text": "Approved",'+
            '"Valuation_Class": "VC001",'+
            '"RESOLUTION_IMPLEMENTED": "Yes",'+
            '"RESOLUTION_DESCRIPTION": "Replaced",'+
            '"RESOLUTION_IMPLEMENTED_DESCRIPTION": "Delivered New",'+
            '"COMMERCIAL_COMPLETION_DATE": "2024-04-20",'+
            '"COCO_STATUS": "Completed",'+
            '"CN_AMOUNT": "200",'+
            '"COMPLAINT_CATEGORY": "Quality",'+
            '"Resolution_given_Date": "2024-04-05",'+
            '"Resolution_Implemented_Date": "2024-04-10",'+
            '"Complaint_Qty_Net_Val": "1500",'+
            '"Root_Cause_Related_Resolution": "Yes",'+
            '"Material_Group": "MG001",'+
            '"Registration_Office_Name": "Mumbai",'+
            '"Sales_Employee": "EMP001"'+
        '}]';

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/CreateCCRSComplaint';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        CreateCCRSComplaint_API.doPost();
        Test.stopTest();

        List<CCSR_Complaint__c> complaints = [SELECT Id, Plant__c, Material_Code__c FROM CCSR_Complaint__c];
        
    }
}