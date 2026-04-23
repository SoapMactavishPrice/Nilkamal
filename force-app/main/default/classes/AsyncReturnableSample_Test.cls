@isTest
global class AsyncReturnableSample_Test {

    class ReturnableSampleMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');
            res.setBody(
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                    'xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<soapenv:Body>' +
                        '<urn:ZcrmReturnableSamplesResponse>' +
                            '<EmReturnableSamples>' +
                                '<item>' +
                                    '<SAMPLEID>RS001</SAMPLEID>' +
                                    '<PRODUCT>Product A</PRODUCT>' +
                                    '<STATUS>Available</STATUS>' +
                                '</item>' +
                            '</EmReturnableSamples>' +
                        '</urn:ZcrmReturnableSamplesResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testBeginZcrmReturnableSamples() {
        Test.setMock(HttpCalloutMock.class, new ReturnableSampleMock());

        Continuation cont = new Continuation(40);
        cont.continuationMethod = 'handleResponse';

        AsyncReturnableSample.AsyncZCRM_RETURNABLE_SAMPLES_WS ws =
            new AsyncReturnableSample.AsyncZCRM_RETURNABLE_SAMPLES_WS();

        Test.startTest();
        AsyncReturnableSample.ZcrmReturnableSamplesResponse_elementFuture future =
            ws.beginZcrmReturnableSamples(cont, 'FOC123');
        Test.stopTest();

        System.assertNotEquals(null, future);
    }
}