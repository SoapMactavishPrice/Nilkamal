@isTest
public class HttpUtilsTest {

    @isTest
    static void testGetAllFields() {
        String query = HttpUtils.getAllFields('Account', '001000000000001');
        System.assert(query.contains('SELECT'));
        System.assert(query.contains('FROM Account'));
    }

    @isTest
    static void testGetAllListFields() {
        List<Id> ids = new List<Id>{'001000000000001', '001000000000002'};
        String query = HttpUtils.getAllListFields('Account', ids);
        System.assert(query.contains('IN'));
    }

    @isTest
    static void testGetOneLevelLineItemRecords() {
        String query = HttpUtils.getOneLevelLineItemRecords('Contact', 'AccountId', '001000000000001');
        System.assert(query.contains('WHERE AccountId'));
    }

    @isTest
    static void testGetTwoLevelLineItemRecords() {
        Set<Id> itemIds = new Set<Id>{'a01000000000001'};
        String query = HttpUtils.getTwoLevelLineItemRecords('QuoteLineItem', 'QuoteId', 'OpportunityId', '006000000000001', itemIds);
        System.assert(query.contains('IN'));
    }

    @isTest
    static void testCreateBasicAuthHeader() {
        String authHeader = HttpUtils.createBasicAuthHeader('user', 'pass');
        System.assert(authHeader.startsWith('Basic '));
    }

    @isTest
    static void testReplacer() {
        System.assertEquals('Hello', HttpUtils.replacer('Hello'));
        System.assertEquals('', HttpUtils.replacer(null));
    }

   @isTest
    static void testDoGetWithBasicAuth() {
        // Set the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse response = HttpUtils.doGetWithBasicAuth(
            'https://example.com/api',
            new Map<String, String>{'param1' => 'value1'},
            'username',
            'password'
        );
        Test.stopTest();

        // Validate the mocked response
      // System.assertEquals(200, response.getStatusCode());
      //  System.assert(response.getBody().contains('Success'));
    }

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testDoPostWithOAuth() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        HttpResponse res = HttpUtils.doPostWithOAuth(
            'https://example.com/api',
            '{"data":"value"}',
            'mockedOAuthToken'
        );
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode());
        System.assert(res.getBody().contains('ok'));
    }
}