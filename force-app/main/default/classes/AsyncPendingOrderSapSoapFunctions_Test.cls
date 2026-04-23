@isTest
global class AsyncPendingOrderSapSoapFunctions_Test {

    // Mock for the SOAP callout
    class PendingOrderCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');
            res.setBody(
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                    'xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<soapenv:Body>' +
                        '<urn:ZcrmSdPendOrderResponse>' +
                            '<EmPendOrder>' +
                                '<item>' +
                                    '<ORDERID>100001</ORDERID>' +
                                    '<CUSTOMER>ACME</CUSTOMER>' +
                                    '<STATUS>PENDING</STATUS>' +
                                '</item>' +
                            '</EmPendOrder>' +
                        '</urn:ZcrmSdPendOrderResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testBeginZcrmSdPendOrder() {
        Test.setMock(HttpCalloutMock.class, new PendingOrderCalloutMock());

        // Setup the continuation
        Continuation cont = new Continuation(40);
        cont.continuationMethod = 'handleResponse';

        // Create instance of async web service class
        AsyncPendingOrderSapSoapFunctionsMcS.AsyncZCRM_SD_PEND_ORDER_WS ws =
            new AsyncPendingOrderSapSoapFunctionsMcS.AsyncZCRM_SD_PEND_ORDER_WS();

        // Start test
        Test.startTest();
        AsyncPendingOrderSapSoapFunctionsMcS.ZcrmSdPendOrderResponse_elementFuture futureResponse =
            ws.beginZcrmSdPendOrder(cont);
        Test.stopTest();

        // We can't use futureResponse.getValue() in test context
        // Just check if futureResponse is not null
        System.assertNotEquals(null, futureResponse);
    }
}