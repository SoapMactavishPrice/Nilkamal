@isTest
public  class CustomerRetryBatchTest {

    @isTest
    public static void test1() {
        API_log__c log = new API_log__c(
            Status__c = 'Failed',
            Log_Name__c = 'Customer Master',
            Request__c = 'Total Size = [{"PARENT_ACCOUNT":"","CUSTOMER_NO":"0000132231","COMPANY_CODE":"NPL","ACCOUNT_GROUP":"0001","CUST_NAME":"La-Arte","MOBILE_NUMBER":"","EMAIL_ID":"","PHONE1":"","PHONE2":"","STREET":"Abdul sattar auto guarage cmpd. sho","STREET1":"Behind khailashprabhat hsg soc.","STREET2":"","POST_CODE":"400098","CITY":"CST Road Santacruze East.","COUNTRY":"IN","CURRENCY_SF":"INR","GST_NUMBER":"","PAN_NUMBER":"AAFFP4552M","INCOTERMS1":"","INCOTERMS2":"","TCS_APPLICABLE":"TCS Applicable","TERMS_OF_PAYMENT":"N1","CLASSIFICATION":"","INDUSTRY":"","SUB_INDUSTRY":"","SUB_INDUSTRY2":"","SALES_DISTRICT":"","DISTRIBUTION_CHANNEL":"10","DIVISION":"08","SALES_OFF":"","SALES_GRP":"","SALES_ORG":"1000","VIRTUAL_ACCOUNT_NUMBER":"","PARTNERFUNCTION_LIST": [],"BANK_DETAILS": [{"CUSTOMER_NO":"0000132231","BANKNAME":"","BANKBRANCH":"","IFSC_CODE":"","ADDRESS":""}]}]',
            Exception_Description__c = 'Test Exception'
        );
        insert log;

        Test.startTest();
        CustomerRetryBatch batch = new CustomerRetryBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

}