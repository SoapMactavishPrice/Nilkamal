public class HttpUtils {

    public static String getAllFields(String ObjectName,String SoId) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        // String query  = 'SELECT Account.SAP_Customer_Code__c, Sales_Organisation__r.Name,'+String.join(fields, ',')+' FROM '+ObjectName+' WHERE Id =: SoId';
        String query  = 'SELECT ';
        // // System.debug('==> query '+query);
        query= query+String.join(fields, ',')+' FROM '+ObjectName+' WHERE Id =:SoId';
        return query;
    }

    public static String getAllListFields(String ObjectName,List<Id> SoId) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        // String query  = 'SELECT Account.SAP_Customer_Code__c, Sales_Organisation__r.Name,'+String.join(fields, ',')+' FROM '+ObjectName+' WHERE Id =: SoId';
        String query  = 'SELECT ';
        // // System.debug('==> query '+query);
        query= query+String.join(fields, ',')+' FROM '+ObjectName+' WHERE Id IN:SoId';
        return query;
    }

    public static String getOneLevelLineItemRecords(String ObjectName,String pranetObjectName,String parentRecId) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query  = 'SELECT ';
        query= query+String.join(fields, ',')+' FROM '+ObjectName+' WHERE '+pranetObjectName+' =:parentRecId';
        return query;
    }

    public static String getTwoLevelLineItemRecords(String ObjectName,String pranetObjectName,String parentOfParentObejct ,String parentOfParentObejctRecId,Set<Id> ItemIds) {
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(ObjectName).getDescribe().fields.getMap().keySet());
        String query  = 'SELECT ';
        if(ObjectName=='Proforma_Invoice_Condition__c'){
            query=query+'Proforma_Invoice_Line_Item__r.Quote_Line_Item__c, ';
        }
        query= query+String.join(fields, ',')+' FROM '+ObjectName+' WHERE '+parentOfParentObejct+' =:parentOfParentObejctRecId AND '+pranetObjectName+' IN: ItemIds';
        return query;
    }

    /*public static APIparamter getAPIdetails(String apiName){
        WebService_Setting__mdt wbs=[SELECT Id,Endpoint__c,Method__c,Access_Token__c FROM WebService_Setting__mdt WHERE DeveloperName =:apiName];
        APIparamter apiparam=new APIparamter();
        apiparam.endpoint=wbs.Endpoint__c;
        apiparam.method=wbs.Method__c;
        apiparam.accessToken = wbs.Access_Token__c;
        return apiparam;
    }*/

    public static APIparamter getWSDLAPIdetails(String apiName){
        WebService_Setting__mdt wbs=[SELECT Id,Endpoint__c,SalesOrg__c,DistChannel__c FROM WebService_Setting__mdt WHERE DeveloperName =:apiName];
        APIparamter apiparam=new APIparamter();
        apiparam.Endpoint=wbs.Endpoint__c;
        apiparam.SalesOrg=wbs.SalesOrg__c;
        apiparam.DistChannel=wbs.DistChannel__c;
        return apiparam;
    }

    // Method for making an HTTP GET request with Basic Authentication
    public static HttpResponse doGetWithBasicAuth(String endpoint, Map<String, String> queryParams, String username, String password) {
        // Construct the full URL with query parameters
        String fullEndpoint = endpoint;
        if (queryParams != null && !queryParams.isEmpty()) {
            fullEndpoint += '?';

            for (String key : queryParams.keySet()) {
                String value = queryParams.get(key);
                fullEndpoint += key + '=' + EncodingUtil.urlEncode(value, 'UTF-8') + '&';
            }

            // Remove the trailing '&' character
            fullEndpoint = fullEndpoint.removeEnd('&');
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(fullEndpoint);
        request.setMethod('GET');
        request.setTimeOut(120000);

        // Create the Basic Authentication header
        if (String.isNotBlank(username) && String.isNotBlank(password)) {
            String authHeader = createBasicAuthHeader(username, password);
            request.setHeader('Authorization', authHeader);

        }


        Http http = new Http();
        HttpResponse response = http.send(request);

        return response;
    }


    // Method for making an HTTP POST request with Basic Authentication
    /*public static HttpResponse doPostWithBasicAuth(String apiName, String requestBody, String username, String password) {
        APIparamter apiparam=HttpUtils.getAPIdetails(apiName);

        HttpRequest request = new HttpRequest();
        if(apiName =='ExchangeRate' || apiName =='CreditLimitExposure' ||  apiName =='FD32' || apiName == 'Invoice' || apiName == 'OutstandingReport' || apiName =='CreditControl' || apiName == 'CustomerAgeing'){
            System.debug('ExchangeRate == > '+apiparam.endpoint+''+requestBody);
            request.setEndpoint(apiparam.endpoint+''+requestBody);
        }
        else{
            request.setEndpoint(apiparam.endpoint);
        }
        request.setMethod(apiparam.method);
        request.setHeader('Content-Type', 'application/json'); // Adjust content type as needed
        if(apiName!='ExchangeRate' && apiName!='FD32' && apiName!='CreditLimitExposure' && apiName!='Invoice' && apiName!='OutstandingReport' && apiName!='CreditControl' && apiName!='CustomerAgeing'){
            request.setBody(requestBody);
        }
        request.setTimeOut(120000);


        // Create the Basic Authentication header
        if (String.isNotBlank(username) && String.isNotBlank(password)) {
            String authHeader = createBasicAuthHeader(username, password);
            request.setHeader('Authorization', authHeader);

        }

        Http http = new Http();
        HttpResponse response = http.send(request);

        return response;
    }*/




    // Helper method to create Basic Authentication header
    public static String createBasicAuthHeader(String username, String password) {
        String auth = username + ':' + password;
        Blob authBlob = Blob.valueOf(auth);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(authBlob);
        return authHeader;
    }

    public static String replacer(Object obj){
        if(obj == null){
            return '';
        }else{
            return String.valueOf(obj);
        }
    }



    // Method for making an HTTP POST request with OAuth 2.0 authorization
    public static HttpResponse doPostWithOAuth(String endpoint, String requestBody, String oAuthToken) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json'); // Adjust content type as needed

        // Set the OAuth token in the request header
        request.setHeader('Authorization', 'OAuth ' + oAuthToken);

        request.setBody(requestBody);
        request.setTimeOut(120000);

        Http http = new Http();
        HttpResponse response = http.send(request);

        return response;
    }

    public class APIparamter{
        public string Endpoint;
        public string SalesOrg;
        public string DistChannel;
    }
}