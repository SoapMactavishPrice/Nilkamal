@isTest
global class AsyncSapComDocumentSapSoapFunctions_Test {

    // Mock callout for your SOAP request
    class ProductPriceCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');
            res.setBody(
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                    'xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<soapenv:Body>' +
                        '<urn:ZcrmSdProductPriceResponse>' +
                            '<EmProductPrice>' +
                                '<PRICE>100.00</PRICE>' +
                                '<CURRENCY>USD</CURRENCY>' +
                            '</EmProductPrice>' +
                        '</urn:ZcrmSdProductPriceResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testBeginZcrmSdProductPrice() {
        // Setup the mock callout
        Test.setMock(HttpCalloutMock.class, new ProductPriceCalloutMock());

        // Setup the continuation context
        Continuation cont = new Continuation(40);
        cont.continuationMethod = 'handleResponse';

        // Instantiate the async webservice client
        AsyncSapComDocumentSapSoapFunctionsMcS.AsyncZCRM_SD_PRODUCT_PRICE_WS ws =
            new AsyncSapComDocumentSapSoapFunctionsMcS.AsyncZCRM_SD_PRODUCT_PRICE_WS();

        // Create sample input for the call
        sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr input = new sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr();
        // populate input fields if needed, e.g.
        // input.PRODUCTID = 'PROD001';

        Test.startTest();
        AsyncSapComDocumentSapSoapFunctionsMcS.ZcrmSdProductPriceResponse_elementFuture futureResponse =
            ws.beginZcrmSdProductPrice(cont, input);
        Test.stopTest();

        // You cannot call futureResponse.getValue() in test context, so just verify futureResponse is not null
        System.assertNotEquals(null, futureResponse);
    }
}