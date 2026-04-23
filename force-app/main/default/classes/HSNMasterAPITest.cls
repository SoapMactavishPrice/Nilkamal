@isTest
private class HSNMasterAPITest {

    public class HSNWrapper {
        public String HSNCode;
        public String Description;
        public Decimal GST;
        public Boolean Active;

        public HSNWrapper(String HSNCode, String Description, Decimal GST, Boolean Active) {
            this.HSNCode = HSNCode;
            this.Description = Description;
            this.GST = GST;
            this.Active = Active;
        }
    }

    public class IntegrationRequestBuilder {
        public List<HSNWrapper> HSNParse(String jsonBody) {
            return (List<HSNWrapper>) JSON.deserialize(jsonBody, List<HSNWrapper>.class);
        }
    }

    @isTest
    static void testDoPost_Success() {
        List<HSNWrapper> hsnList = new List<HSNWrapper>{
            new HSNWrapper('1234', 'Description 1', 18, true),
            new HSNWrapper('5678', 'Description 2', 12, false)
        };

        String requestBody = JSON.serialize(hsnList);

        insert new HSN_Master__c(Name = '1234', Code__c = '1234', Description__c = 'Old Desc');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/HSN';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        HSNMasterAPI.doPost();
        Test.stopTest();

        List<API_log__c> logs = [SELECT Status__c FROM API_log__c WHERE Log_Name__c = 'HSNAPI'];
        System.assertEquals('Success', logs[0].Status__c);

        List<HSN_Master__c> results = [SELECT Name, Description__c FROM HSN_Master__c WHERE Name IN ('1234', '5678')];
        System.assertEquals(2, results.size());
    }

    @isTest
    static void testDoPost_Error() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/HSN';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Not valid JSON');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        HSNMasterAPI.doPost();
        Test.stopTest();

        List<API_log__c> logs = [SELECT Status__c, Exception_Description__c FROM API_log__c WHERE Status__c = 'Failed'];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].Exception_Description__c != null);
    }
}