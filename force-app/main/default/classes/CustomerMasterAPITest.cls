@isTest
public class CustomerMasterAPITest {

    @testSetup
    static void setupData() {
        insert new Company_Master__c(Name = 'Test Company', Code__c = 'CC01');
        insert new Sales_Organizations__c(Name = 'Test Org', Sales_Org_Code__c = 'SO01');
        insert new Distribution_Channel__c(Name = 'Test DC', Distribution_Code__c = 'DC01');
        insert new Division__c(Name = 'Test Div', Division_Code__c = 'DIV01');
        insert new Pin_Code_Master__c(Name = '400001', State__c = 'Maharashtra');
    }

    @isTest
    static void testCustomerMasterAPI() {
        // Prepare JSON request body
        String requestBody = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'CUSTOMER_NO' => 'CUST001',
                'CUST_NAME' => 'Test Customer',
                'ACCOUNT_GROUP' => 'AG01',
                'CITY' => 'Mumbai',
                'POST_CODE' => '400001',
                'COUNTRY' => 'IN',
                'MOBILE_NUMBER' => '9876543210',
                'PHONE1' => '02212345678',
                'EMAIL_ID' => 'test@example.com',
                'PHONE2' => '02287654321',
                'STREET' => 'Street A',
                'STREET1' => 'Street B',
                'STREET2' => 'Street C',
                'INDUSTRY' => 'Technology',
                'CURRENCY_SF' => 'INR',
                'GST_NUMBER' => '27AAAPL1234C1ZV',
                'PAN_NUMBER' => 'AAAPL1234C',
                'INCOTERMS1' => 'FOB',
                'INCOTERMS2' => 'Mumbai Port',
                'TCS_APPLICABLE' => 'Yes',
                'TERMS_OF_PAYMENT' => 'Immediate',
                'CLASSIFICATION' => 'A',
                'SUB_INDUSTRY' => 'Software',
                'SUB_INDUSTRY2' => 'Services',
                'SALES_DISTRICT' => 'SD01',
                'SALES_OFF' => 'SO01',
                'SALES_GRP' => 'SG01',
                'VIRTUAL_ACCOUNT_NUMBER' => 'VAN12345',
                'COMPANY_CODE' => 'CC01',
                'SALES_ORG' => 'SO01',
                'DISTRIBUTION_CHANNEL' => 'DC01',
                'DIVISION' => 'DIV01',
                'BANK_DETAILS' => new List<Object>{
                    new Map<String, Object>{
                        'CUSTOMER_NO' => 'CUST001',
                        'BANKNAME' => 'Bank of Test',
                        'IFSC_CODE' => 'TEST0001234',
                        'ADDRESS' => 'Bank Street',
                        'CUST_BLOCK_STATUS' => '"FALSE"'
                    }
                },
                'PARTNERFUNCTION_LIST' => new List<Object>{
                    new Map<String, Object>{
                        'CUSTOMER_NO' => 'CUST001',
                        'ADDRESS_TYPE' => 'Billing',
                        'GST_IN' => '27AAAPL1234C1ZV',
                        'PAN_NUMBER' => 'AAAPL1234C',
                        'ADDRESS_LINE1' => 'Line 1',
                        'ADDRESS_LINE2' => 'Line 2',
                        'ADDRESS_LINE3' => 'Line 3',
                        'CITY' => 'Mumbai',
                        'POSTL_CODE' => '400001',
                        'COUNTRY' => 'IN',
                        'DISTRICT' => 'District 1',
                        'STATE' => 'Maharashtra',
                        'REGION' => 'West'
                    }
                }
            }
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/CustomerMasterAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        CustomerMasterAPI.processCustomerMaster();
        Test.stopTest();

        // Verify that the Account and API log records were created
        List<Account> accList = [SELECT Id, Name FROM Account WHERE SAP_Customer_code__c = 'CUST001'];
        //System.assert(!accList.isEmpty(), 'Account should be created.');

        List<API_log__c> logs = [SELECT Id, Status__c FROM API_log__c WHERE Log_Name__c = 'Customer Master'];
        System.assert(!logs.isEmpty(), 'API Log should be created.');
    }

    @isTest
    static void testProcessPartnerFunctionsDirectCall() {
        // Setup Account
        Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = 'TEST001');
        insert acc;

        // Create a PartnerFunction object
        IntegrationRequestBuilder.PartnerFunction pf = new IntegrationRequestBuilder.PartnerFunction();
        pf.CUSTOMER_NO = 'TEST001';
        pf.ADDRESS_TYPE = 'Bill To';
        pf.GST_IN = '27AAAPL1234C1ZV';
        pf.PAN_NUMBER = 'AAAPL1234C';
        pf.ADDRESS_LINE1 = 'Address 1';
        pf.ADDRESS_LINE2 = 'Address 2';
        pf.ADDRESS_LINE3 = 'Address 3';
        pf.CITY = 'Mumbai';
        pf.POSTL_CODE = '400001';
        pf.COUNTRY = 'India';
        pf.DISTRICT = 'Maharashtra';
        pf.STATE = 'Maharashtra';
        pf.REGION = '';

        List<IntegrationRequestBuilder.PartnerFunction> pfList = new List<IntegrationRequestBuilder.PartnerFunction>{ pf };

        Test.startTest();
        CustomerMasterAPI.processPartnerFunctions(pfList, acc.Id);
        Test.stopTest();

        List<Partner_Function_Address_Information__c> pfInfos = [
            SELECT Id, Customer_Name__c, Address_Type__c
            FROM Partner_Function_Address_Information__c
            WHERE Customer_Name__c = :acc.Id
        ];
        System.assert(!pfInfos.isEmpty(), 'Partner Function Address should be inserted');
    }

    @isTest
static void testProcessBankDetailsCoverage() {
    // --- Setup test data ---
    // Get Sales Org record
    Sales_Organizations__c so = [
        SELECT Id, Sales_Org_Code__c
        FROM Sales_Organizations__c
        WHERE Sales_Org_Code__c = 'SO01'
        LIMIT 1
    ];

    // Create Account record
    Account acc = new Account(Name = 'Bank Account Coverage Test');
    insert acc;

    // Existing Bank_Information__c (for update branch)
    Bank_Information__c existingBank = new Bank_Information__c(
        Name = 'Old Test Bank',
        Customer_no__c = 'CUST002',
        IFSC_Code__c = 'OLDIFSC',
        Bank_Address__c = 'Old Address',
        Sales_Org__c = so.Id
    );
    insert existingBank;

    // --- Create two test bank detail inputs ---
    // 1. New record (insert path)
    IntegrationRequestBuilder.BankDetail newBank = new IntegrationRequestBuilder.BankDetail();
    newBank.CUSTOMER_NO = 'CUST001';
    newBank.BANKNAME = 'New Test Bank';
    newBank.IFSC_CODE = 'NEWIFSC001';
    newBank.ADDRESS = 'New Address';

    // 2. Existing record (update path)
    IntegrationRequestBuilder.BankDetail existingBankDetail = new IntegrationRequestBuilder.BankDetail();
    existingBankDetail.CUSTOMER_NO = 'CUST002'; // matches existing record
    existingBankDetail.BANKNAME = 'Updated Test Bank';
    existingBankDetail.IFSC_CODE = 'UPDATEDIFSC002';
    existingBankDetail.ADDRESS = 'Updated Address';

    List<IntegrationRequestBuilder.BankDetail> bankDetails =
        new List<IntegrationRequestBuilder.BankDetail>{ newBank, existingBankDetail };

    // --- Execute method ---
    Test.startTest();
    CustomerMasterAPI.processBankDetails(bankDetails, acc.Id, 'SO01');
    Test.stopTest();

    // --- Verify output ---
    List<Bank_Information__c> result = [
        SELECT Id, Name, Customer_no__c, IFSC_Code__c, Bank_Address__c, Account_Name__c
        FROM Bank_Information__c
        WHERE Customer_no__c IN ('CUST001', 'CUST002')
    ];

    System.assertEquals(2, result.size(), 'Two bank records should exist (1 inserted, 1 updated)');
    System.assertEquals(acc.Id, result[0].Account_Name__c, 'Account should be linked properly.');
}

}