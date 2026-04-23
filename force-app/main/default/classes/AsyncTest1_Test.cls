@isTest
global class AsyncTest1_Test {

    // Mock implementation of HttpCalloutMock
    class CustomerSamplesCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'text/xml');
            res.setBody(
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
                                  'xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
                    '<soapenv:Body>' +
                        '<urn:ZbapiCustomersamplesResponse>' +
                            // Include realistic fields expected by your Apex class
                            '</urn:ZbapiCustomersamplesResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>'
            );
            return res;
        }
    }

    @isTest
    static void testBeginZbapiCustomersamples() {
        Test.setMock(HttpCalloutMock.class, new CustomerSamplesCalloutMock());

        // Create the input parameters
        test1.TableOfZbapiCustomersamples sampleTable = new test1.TableOfZbapiCustomersamples();
        // Optionally add rows to the table: sampleTable.add(...);

        // Set up a dummy continuation
        Continuation cont = new Continuation(60);
        cont.continuationMethod = 'handleResponse'; // Dummy method name

        AsyncTest1.AsyncZBAPI_CUSTOMERSAMPLES4 ws = new AsyncTest1.AsyncZBAPI_CUSTOMERSAMPLES4();

        Test.startTest();
        AsyncTest1.ZbapiCustomersamplesResponse_elementFuture futureResponse = ws.beginZbapiCustomersamples(
            cont,
            sampleTable,
            'Foc001',     // SFoc
            'Kunnr001',   // SKunnr
            'Mat001',     // SMatnr
            'Ord123',     // SOrdnum
            'Spart001',   // SSpart
            'Vkorg001',   // SVkorg
            'Vtweg001',   // SVtweg
            'Werks001'    // SWerks1
        );
        Test.stopTest();

        System.assertNotEquals(null, futureResponse, 'Future response should not be null.');
    }
}