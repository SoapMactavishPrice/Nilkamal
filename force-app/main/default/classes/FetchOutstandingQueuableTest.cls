@isTest
private class FetchOutstandingQueuableTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(200);

            String responseBody = '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">' +
                '   <soapenv:Body>' +
                '      <urn:ZcrmSdCustomerOutstandingResponse>' +
                '         <EmCustomerOutstanding>' +
                '            <item>' +
                '               <Kunnr>12345</Kunnr>' +
                '               <Vkorg>1000</Vkorg>' +
                '               <Spart>01</Spart>' +
                '               <Text4>Customer Name</Text4>' +
                '               <Belnr>Doc123</Belnr>' +
                '               <Bldat>2025-06-01</Bldat>' +
                '               <Noday>10</Noday>' +
                '               <Dmbtr>500.00</Dmbtr>' +
                '               <Colum6>50.00</Colum6>' +
                '               <Colum7>450.00</Colum7>' +
                '               <Vkbur>Office1</Vkbur>' +
                '               <Text1>Office Name</Text1>' +
                '               <Vkgrp>Group1</Vkgrp>' +
                '               <Text2>Office Desc</Text2>' +
                '               <Ort01>CityName</Ort01>' +
                '               <Zbd1t>30</Zbd1t>' +
                '               <Bstkd>PO123</Bstkd>' +
                '               <Bstdk>2025-06-10</Bstdk>' +
                '               <Bukrs>Comp1</Bukrs>' +
                '               <Text10>MG2</Text10>' +
                '               <Kunnr1>CustNum1</Kunnr1>' +
                '            </item>' +
                '         </EmCustomerOutstanding>' +
                '         <EmAddnData>0</EmAddnData>' + // total = 0 so no recursion
                '      </urn:ZcrmSdCustomerOutstandingResponse>' +
                '   </soapenv:Body>' +
                '</soapenv:Envelope>';

            res.setBody(responseBody);
            return res;
        }
    }

    @isTest static void testFetchOutstandingQueuable() {
        Account acc = new Account(Name = 'Test Account', SAP_Customer_code__c = '12345');
        insert acc;

        Sales_Organizations__c salesOrg = new Sales_Organizations__c(Name = '1000');
        insert salesOrg;

        Division__c division = new Division__c(Division_Code__c = '01');
        insert division;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        System.enqueueJob(new FetchOutstandingQueuable(0));

        Test.stopTest();

        List<Customer_Outstanding__c> custOutstandings = [SELECT Id, Account__c FROM Customer_Outstanding__c];
        System.assert(!custOutstandings.isEmpty(), 'Customer Outstanding records should be inserted');
        System.assertEquals(acc.Id, custOutstandings[0].Account__c, 'Account reference should match');

    }
}