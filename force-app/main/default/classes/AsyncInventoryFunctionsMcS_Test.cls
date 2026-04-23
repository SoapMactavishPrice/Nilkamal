@isTest
private class AsyncInventoryFunctionsMcS_Test {

    private class MockInventoryCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(200);

            res.setBody(
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                'xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
              '<soapenv:Body>' +
                '<urn:ZbapiOrderstockResponse>' +
                  '<Output>' +
                    '<item>' +
                      '<MATNR>123456</MATNR>' +
                      '<WERKS>1000</WERKS>' +
                      '<LABST>50</LABST>' +
                    '</item>' +
                  '</Output>' +
                '</urn:ZbapiOrderstockResponse>' +
              '</soapenv:Body>' +
            '</soapenv:Envelope>'
        	);
            return res;
        }
    }

    @isTest
    static void testBeginZbapiOrderstock() {
        Test.setMock(HttpCalloutMock.class, new MockInventoryCallout());

        // Prepare dummy data
        inventoryFunctionsMcS.TableOfZbapiOrdstk output = new inventoryFunctionsMcS.TableOfZbapiOrdstk();

        Continuation cont = new Continuation(60);
        cont.continuationMethod = 'handleCallback';

        AsyncInventoryFunctionsMcS.AsyncZBAPI_ORDERSTOCK1 asyncInstance =
            new AsyncInventoryFunctionsMcS.AsyncZBAPI_ORDERSTOCK1();

        AsyncInventoryFunctionsMcS.ZbapiOrderstockResponse_elementFuture future =
            asyncInstance.beginZbapiOrderstock(cont, '123456', output, '1000');

        // We're not calling getValue() directly, just verifying that it runs
        Test.startTest();
        // let the async call complete
        Test.stopTest();

        System.assertNotEquals(null, future);
    }
}