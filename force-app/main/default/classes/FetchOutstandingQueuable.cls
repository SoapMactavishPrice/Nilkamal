global class FetchOutstandingQueuable implements Queueable, Database.AllowsCallouts {
    
    Integer offset;
    public FetchOutstandingQueuable(Integer offset) {
        this.offset = offset;
    }
    
    public void execute(QueueableContext context) {
        API_log__c apiLog=new API_log__c();
        apiLog.Log_Name__c ='CustomerOutStandingAPI';
        try{
            HttpUtils.APIparamter util = HttpUtils.getWSDLAPIdetails('OutstandingAPI');
            
            String endpoint = util.Endpoint;
            String requestBody = '<?xml version="1.0" encoding="UTF-8"?>'
                + '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">'
                + '   <soapenv:Header/>'
                + '   <soapenv:Body>'
                + '      <urn:ZcrmSdCustomerOutstanding>'
                + '<Customer></Customer>'
                + '      </urn:ZcrmSdCustomerOutstanding>'
                + '   </soapenv:Body>'
                + '</soapenv:Envelope>';
            List<Map<String, String>> records = new List<Map<String, String>>();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
            req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZcrmSdCustomerOutstanding');
            req.setBody(requestBody);
            req.setTimeout(120000);
            
            Http http = new Http();
            System.debug('===> '+JSON.serialize(req.getBody()));
            System.debug('===> '+req.getBody());
            
            
            HttpResponse res = http.send(req);
            System.debug('===> '+res.getBody());
            if(res.getStatusCode()==200){
                Dom.Document doc = new Dom.Document();
                doc.load(res.getBody());
                Dom.XMLNode root = doc.getRootElement();
                Dom.XMLNode body = root.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XMLNode response = body.getChildElement('ZcrmSdCustomerOutstandingResponse', 'urn:sap-com:document:sap:soap:functions:mc-style');
                Dom.XMLNode emCustomerOutstanding = response.getChildElement('EmCustomerOutstanding', null);
                String responseTotal=response.getChildElement('EmAddnData', null).getText();
                Integer total = responseTotal != null &&  responseTotal != '' ? Integer.valueOf(responseTotal.trim()) : 0;
                System.debug('total '+total);
                
                Set<Integer> custids=new Set<Integer>();
                Set<String> divList = new Set<String>();
                Set<String> slorgList = new Set<String>();
                for (Dom.XMLNode item : emCustomerOutstanding.getChildElements()) {
                    for (Dom.XMLNode field : item.getChildElements()) {
                        String customer=item.getChildElement('Kunnr', null)?.getText();
                        if( customer!=null && customer!='') {
                            custids.add(Integer.valueOf(customer));
                        }
                        String saleorg=item.getChildElement('Vkorg', null)?.getText();
                        if(saleorg!=null && saleorg!='') {
                            slorgList.add(saleorg);
                        }
                        
                        String div=item.getChildElement('Spart', null)?.getText();
                        if(div!=null && div!='') {
                            divList.add(div);
                        }
                    }
                }
                
                Map<String, Account> accMap=new Map<String, Account>();
                for(Account ac:[Select id,Name,Customer_Code_Backend__c,SAP_Customer_code__c from Account where Customer_Code_Backend__c IN :custids]){
                    accMap.put(String.valueOf(ac.Customer_Code_Backend__c),ac);
                }
                
                List<Sales_Organizations__c> soList= new List<Sales_Organizations__c>();
                soList = [SELECT ID,Name FROM Sales_Organizations__c WHERE Name IN : slorgList];
                
                Map<String,Sales_Organizations__c> soMap = new  Map<String,Sales_Organizations__c>();
                for (Sales_Organizations__c va : soList) {
                    soMap.put(va.Name,va);
                }
                
                List<Division__c> diList= new List<Division__c>();
                diList = [SELECT ID,Division_Code__c FROM Division__c WHERE Division_Code__c IN : divList];
                
                Map<String,Division__c> diMap = new  Map<String,Division__c>();
                for (Division__c va : diList) {
                    diMap.put(va.Division_Code__c,va);
                }
                
                List<User> ulist= new List<User>();
                ulist = [SELECT Id,UID__c,IsActive from User];
                User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
                
                Map<String,String> uMap = new  Map<String,String>();
                Map<String,Boolean> uActiveMap = new Map<String,Boolean>();
                for (User va : ulist) {
                    uMap.put(va.UID__c,va.Id);
                    uActiveMap.put(va.UID__c, va.IsActive);
                }
                
                List<Customer_Outstanding__c> custOutstandingList = new List<Customer_Outstanding__c>();
                for (Dom.XMLNode item : emCustomerOutstanding.getChildElements()) {
                    System.debug('item.getChildElement '+item.getChildElement('Kunnr', null)?.getText());
                    // Map<String, String> record = new Map<String, String>();
                    // for (Dom.XMLNode field : item.getChildElements()) {
                        // record.put(field.getName(), field.getText());
                        Customer_Outstanding__c custOutstanding = new Customer_Outstanding__c();
                        String customer= item.getChildElement('Kunnr', null)?.getText();
                        if(accMap.containsKey(customer)) {
                            custOutstanding.Account__c = accMap.get(customer).Id;
                            custOutstanding.Account_Name__c=accMap.get(customer).Id;
                        }
                        custOutstanding.Customer_Name__c= item.getChildElement('Text4', null)?.getText();
                        custOutstanding.Accounting_Document_Number__c = item.getChildElement('Belnr', null)?.getText();
                        custOutstanding.Document_Date_in_Document__c = Date.valueOf(item.getChildElement('Bldat', null)?.getText());
                        custOutstanding.Outstanding_days__c = parseDecimal(item.getChildElement('Noday', null)?.getText());
                        custOutstanding.Amount_in_Local_Currency__c = parseDecimal(item.getChildElement('Dmbtr', null)?.getText());
                        custOutstanding.On_account_amount__c = parseDecimal(item.getChildElement('Colum6', null)?.getText());
                        custOutstanding.Net_Outstanding__c = parseDecimal(item.getChildElement('Colum7', null)?.getText());
                        custOutstanding.Sales_Office__c = item.getChildElement('Vkbur', null)?.getText();
                        custOutstanding.Sales_Office_Name__c = item.getChildElement('Text1', null)?.getText();
                        custOutstanding.Sales_Group__c = item.getChildElement('Vkgrp', null)?.getText();
                        custOutstanding.Sales_Office_Desc__c = item.getChildElement('Text2', null)?.getText();
                        custOutstanding.Customer_City__c = item.getChildElement('Ort01', null)?.getText();
                        custOutstanding.Cash_Discount_Days_1__c = parseDecimal(item.getChildElement('Zbd1t', null)?.getText());
                        custOutstanding.Customer_PO_Number__c = item.getChildElement('Bstkd', null)?.getText();
                        String poDate = item.getChildElement('Bstdk', null)?.getText();
                        if (String.isNotBlank(poDate) && poDate != '0000-00-00') {
                            // custOutstanding.Customer_PO_date__c = poDate;
                        }
                        custOutstanding.Company_Code__c = item.getChildElement('Bukrs', null)?.getText();
                        custOutstanding.MG2_NEW__c = item.getChildElement('Text10', null)?.getText();
                        custOutstanding.Customer_Number__c = item.getChildElement('Kunnr1', null)?.getText();
                        String uid=item.getChildElement('Kunnr1', null)?.getText();
                        if(uMap.containsKey(uid)){
                            Boolean isActive = uActiveMap.get(uid);
                            if(isActive){
                                custOutstanding.OwnerId = uMap.get(uid);
                            } else {
                                custOutstanding.OwnerId = adminUser.Id;
                            }
                        } else {
                            custOutstanding.OwnerId = adminUser.Id;
                        }
                        
                        String saleorg=item.getChildElement('Vkorg', null)?.getText();
                        if(saleorg!=null && saleorg!=''){
                            slorgList.add(saleorg);
                        }
                        
                        String div=item.getChildElement('Spart', null)?.getText();
                        if(div!=null && div!=''){
                            divList.add(div);
                        }
                        
                        custOutstanding.Sales_Organization_Lookup__c = soMap.get(saleorg)!=null?soMap.get(saleorg).Id:null;
                        custOutstanding.Division_Lookup__c = diMap.get(div)!=null?diMap.get(div).Id:null;
                        custOutstandingList.add(custOutstanding);
                        
                    }
                    if (!custOutstandingList.isEmpty()) {
                        insert custOutstandingList;
                    }
                    
                    
                    if (total > offset) {
                        System.enqueueJob(new FetchOutstandingQueuable(offset + 1));
                    }
                    //  apiLog.Response__c = res.getBody();
                    apiLog.Status__c='Success';
                }
            }
            
            catch (Exception e) {
                System.debug('Error Parsing SOAP Response: ' + e.getMessage() + e.getLineNumber());
                apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
                apiLog.Status__c='Failed';
            }
            Insert apiLog;
        }
        
        
        private Decimal parseDecimal(String value) {
            try {
                return Decimal.valueOf(value.trim());
            } catch (Exception e) {
                return null;
            }
        }
    }