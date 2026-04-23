public class calloutTest {
    @future(callout=true)
	  public static void sendZcrmSdCustomerOutstanding(String customerNumber) {
        // Endpoint URL
        String endpoint = 'https://nilkamala-limited-cpi-orzjdq25.it-cpi006-rt.cfapps.jp10.hana.ondemand.com/http/SF/ZCRM_CUST_OUTSTD_SRV';
		String username = 'sb-7cffb3b0-3104-4c6c-b288-29d7940b6377!b26902|it-rt-nilkamala-limited-cpi-orzjdq25!b134';
        String password = 'e782edf7-4e26-4a9f-a949-55f69343564b$hh6I65UgRRUzz5YmKJrDvtaqTsa2A-9YIkG5Wvd_j34=';
        String auth = EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
        // SOAP Envelope
        String soapBody = '<root><Customer>' + customerNumber + '</Customer></root>';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZcrmSdCustomerOutstanding');
        req.setHeader('Authorization', 'Basic ' + auth);
        req.setBody(soapBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        // Return the response body (XML)
        system.debug(res.getBody());
    }
    
    @future(callout=true)
	  public static void sendZcrmSdProductprice(Boolean makecall) {
        // Endpoint URL
        String endpoint = 'https://nilkamala-limited-cpi-orzjdq25.it-cpi006-rt.cfapps.jp10.hana.ondemand.com/http/SF/ZCRM_PRDCT_PRICE_SRV';
		String username = 'sb-7cffb3b0-3104-4c6c-b288-29d7940b6377!b26902|it-rt-nilkamala-limited-cpi-orzjdq25!b134';
        String password = 'e782edf7-4e26-4a9f-a949-55f69343564b$hh6I65UgRRUzz5YmKJrDvtaqTsa2A-9YIkG5Wvd_j34=';
        String auth = EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
        // SOAP Envelope
        String soapBody = '<ZcrmSdProductPrice>'
    +'<ConditionType>ZPR2</ConditionType>'
    +'<ZimA079>'
        +'<SalesOrg>NKML</SalesOrg>'
        +'<DistChannel>30</DistChannel>'
        +'<MaterialGroup>01</MaterialGroup>'
    +'</ZimA079>'
    +'<ZimA004>'
        +'<SalesOrg>NKML</SalesOrg>'
        +'<DistChannel>30</DistChannel>'
        +'<Material>NKCDDK20-SLCYKIT</Material>'
    +'</ZimA004>'
        +'<ZimA004>'
        +'<SalesOrg>NKML</SalesOrg>'
        +'<DistChannel>30</DistChannel>'
        +'<Material>PC9155270ORG</Material>'
    +'</ZimA004>'
        +'<ZimA004>'
        +'<SalesOrg>NKML</SalesOrg>'
        +'<DistChannel>30</DistChannel>'
        +'<Material>PC9155270ORGN</Material>'
    +'</ZimA004>'
+'</ZcrmSdProductPrice>';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZCRM_PRDCT_PRICE_SRV');
        req.setHeader('Authorization', 'Basic ' + auth);
        req.setBody(soapBody);

        Http http = new Http();
        HttpResponse res = new HttpResponse();
          if(makecall){
              res = http.send(req);
          }
        
        // Return the response body (XML)
        system.debug(res.getBody());
          system.debug(res.getBody());
    }
    
    @future(callout=true)
	  public static void sendZcrmSdPendingOrder(Boolean makecall) {
        // Endpoint URL
        String endpoint = 'https://nilkamala-limited-cpi-orzjdq25.it-cpi006-rt.cfapps.jp10.hana.ondemand.com/http/SF/ZCRM_SD_PEND_ORDER_SRV';
		String username = 'sb-7cffb3b0-3104-4c6c-b288-29d7940b6377!b26902|it-rt-nilkamala-limited-cpi-orzjdq25!b134';
        String password = 'e782edf7-4e26-4a9f-a949-55f69343564b$hh6I65UgRRUzz5YmKJrDvtaqTsa2A-9YIkG5Wvd_j34=';
        String auth = EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
        // SOAP Envelope
        String soapBody = '';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/xml');
        req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZCRM_SD_PEND_ORDER_SRV');
        req.setHeader('Authorization', 'Basic ' + auth);
        req.setBody(soapBody);

        Http http = new Http();
        HttpResponse res = new HttpResponse();
          if(makecall){
              res = http.send(req);
          }

        // Return the response body (XML)
        system.debug(res.getBody());
          String big = String.valueof(res); // very long
			Integer chunkSize = 5000;

		for(Integer i=0; i<big.length(); i+=chunkSize){
   		  System.debug( big.substring(i, Math.min(i+chunkSize, big.length())) );
		}
    }
}