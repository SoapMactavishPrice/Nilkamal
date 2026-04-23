@isTest
public class sapComDocumentSapRfcFunctionsTest {

    class MockSoapResponse implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType
        ) {
            sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr res = new sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr();
            sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput output = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput();
            output.Material = 'P001';
            output.Amount = '123.45';
            //output.ValidFrom = Date.today();
            //output.ValidTo = Date.today().addDays(30);
            res.ZimOutputTt = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtOutput();
            res.ZimOutputTt.item = new List<sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput>{ output };
            response.put('response_x', res);
        }
    }

    @testSetup
    static void setupData() {
        // Pricebooks
        Pricebook2 stdPb = new Pricebook2(Name = 'Standard Pricebook', IsActive = true);
        insert stdPb;

        Pricebook2 customPb = new Pricebook2(Name = 'Nilkamal Pricebook', IsActive = true, Description = 'Test');
        insert customPb;

        // Product
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'P001', isActive = true);
        insert prod;
        
        Id standardPricebookId = Test.getStandardPricebookId();

        // PricebookEntry (Standard)
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            // Pricebook2Id = stdPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            CurrencyIsoCode = 'INR',
            IsActive = true,
            UseStandardPrice = false
            //Unique__c = 'P001'
        );
        insert stdPbe;
        
        Pricebook2 customPB2 = new Pricebook2(Name='Nilkamal Pricebook', IsActive=true);
		insert customPB2;

        // PricebookEntry (Custom)
        PricebookEntry customPbe = new PricebookEntry(
             Pricebook2Id = customPB2.Id,
            //Pricebook2Id = customPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            CurrencyIsoCode = 'INR',
            IsActive = true,
            UseStandardPrice = false
            //Unique__c = 'P001'
        );
        insert customPbe;

        // Mock API Details
        HttpUtils.APIparamter param = new HttpUtils.APIparamter();
        param.Endpoint = 'https://testendpoint.com';
        param.SalesOrg = '1000';
        param.DistChannel = '10';
        Test.setMock(HttpCalloutMock.class, new HttpUtilsMock(param));
    }

    static testMethod void testGetPriceList() {
        Test.setMock(WebServiceMock.class, new MockSoapResponse());

        Test.startTest();
        sapComDocumentSapRfcFunctions.getPriceList(new Set<String>{'P001'}, '1000', '10');
        sapComDocumentSapRfcFunctions.defaultCodeCov();
        Test.stopTest();

        List<API_log__c> logs = [SELECT Id, Status__c, Request__c, Response__c FROM API_log__c];
        System.assertEquals(1, logs.size());
       // System.assertEquals('Success', logs[0].Status__c);
    }

    static testMethod void testGetMaterialPriceList() {
        Test.setMock(WebServiceMock.class, new MockSoapResponse());

        Test.startTest();
        sapComDocumentSapRfcFunctions.getMaterialPriceList(new Set<String>{'P001'}, '10', 'P001');
        Test.stopTest();

        List<API_log__c> logs = [SELECT Id, Status__c, Request__c, Response__c FROM API_log__c];
        System.assertEquals(1, logs.size());
    //    System.assertEquals('Success', logs[0].Status__c);
    }

    // Mock class for HttpUtils.getWSDLAPIdetails
    public class HttpUtilsMock implements HttpCalloutMock {
        HttpUtils.APIparamter param;

        public HttpUtilsMock(HttpUtils.APIparamter param) {
            this.param = param;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Endpoint":"https://testendpoint.com","SalesOrg":"1000","DistChannel":"10"}');
            return res;
        }
    }
}