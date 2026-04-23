@RestResource(urlMapping='/HSN')
global class HSNMasterAPI {
@HttpPost
    global static void doPost() {
        API_log__c apiLog = new API_log__c();
        try {
            // Parse the JSON request
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
			String Message='Successfully Sync to SF';
            apiLog.Log_Name__c = 'HSNAPI';
            apiLog.Request__c = 'Total Size = ' + jsonBody;
            List<IntegrationRequestBuilder.HSNWrapper> dataList = IntegrationRequestBuilder.HSNParse(jsonBody);
            
            Set<String> hsnCode=new Set<String>();
            for(IntegrationRequestBuilder.HSNWrapper hsn:dataList){
                hsnCode.add(hsn.HSNCode);
            }
            
            List<HSN_Master__c> hsnList=new List<HSN_Master__c>();
            hsnList=[SELECT Id,Name FROM HSN_Master__c WHERE Name IN:hsnCode];
            
            Map<String,String> mphsnCode=new Map<String,String>();
            for(HSN_Master__c row :hsnList){
                mphsnCode.put(row.Name,row.Id);
            }
            
            List<HSN_Master__c> newHSNList=new List<HSN_Master__c>();
            for(IntegrationRequestBuilder.HSNWrapper hsn:dataList){
                HSN_Master__c hsnData=new HSN_Master__c();
                if(mphsnCode.get(hsn.HSNCode)!=null){
                    hsnData.Id=mphsnCode.get(hsn.HSNCode);
                }
                hsnData.Name=hsn.HSNCode;
                hsnData.Code__c=hsn.HSNCode;
                hsnData.Description__c=hsn.Description;
                if(hsn.GST!=0){
                    hsnData.CGST__c=Decimal.valueOf(hsn.GST)/2;
                    hsnData.SGST__c=Decimal.valueOf(hsn.GST)/2;
                    hsnData.IGST__c=Decimal.valueOf(hsn.GST);
                }
                hsnData.Active__c=Boolean.valueOf(hsn.Active);
                newHSNList.add(hsnData);
            }
            
            if(newHSNList.size()>0){
               UPSERT newHSNList;
            }
            
            apiLog.Status__c = 'Success';
            Map<String,Object> mpResponse=new Map<String,Object>();
            mpResponse.put('Status','success');
            mpResponse.put('msg',Message);
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(mpResponse));
        }catch (Exception e) {
            RestContext.response.statusCode = 500;
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
            RestContext.response.responseBody = Blob.valueOf('{"error": "' + e.getMessage()+e.getLineNumber()+ + '"}');
        } finally {
            insert apiLog;
        }
    }
}