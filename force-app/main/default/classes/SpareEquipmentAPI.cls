@RestResource(urlMapping='/SparesEquipmentAPI/*')
global class SpareEquipmentAPI {
@HttpPost
    global static void doPost() {
        API_log__c apiLog = new API_log__c();
        try {
            // Parse the JSON request
            RestRequest req = RestContext.request;
            String jsonBody = req.requestBody.toString();
			String Message='Successfully Sync to SF';
            apiLog.Log_Name__c = 'SparesEquipmentAPI';
            apiLog.Request__c = 'Total Size = ' + jsonBody;
            List<IntegrationRequestBuilder.SparesEquipmentWrapper> dataList = IntegrationRequestBuilder.SparesEquipmentParse(jsonBody);
            Set<String> SparesProductCodes = new Set<String>();
            Set<String> equipmentProductCodes = new Set<String>();
             for (IntegrationRequestBuilder.SparesEquipmentWrapper row : dataList) {
                 if (!String.isBlank(row.SAPMaterialNumber)){
                      SparesProductCodes.add(row.SAPMaterialNumber);
                 }
                 if (!String.isBlank(row.SAPEquipmentCode)){
                      equipmentProductCodes.add(row.SAPEquipmentCode);
                 }
             }
            // Product2 Map
            Map<String, Product2> spareProductMap = new Map<String, Product2>();
            for (Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :SparesProductCodes]) {
                spareProductMap.put(product.ProductCode, product);
            }
            
            // Product2 Map
            Map<String, Product2> equipmentProductMap = new Map<String, Product2>();
            for (Product2 product : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :equipmentProductCodes]) {
                equipmentProductMap.put(product.ProductCode, product);
            }
            
            List<Equipment_Spare_Master__c> existit=new List<Equipment_Spare_Master__c>();
            existit=[SELECT Id,SAP_Material_Code_Spare__r.ProductCode,SAP_Nilkamal_Model_Code_Equipment__r.ProductCode FROM Equipment_Spare_Master__c WHERE SAP_Material_Code_Spare__c IN :spareProductMap.keySet() 
                    AND SAP_Nilkamal_Model_Code_Equipment__c IN :equipmentProductMap.keySet()];
            Map<String ,String> mpSpare=new Map<String ,String>();
            for(Equipment_Spare_Master__c mprow:existit){
                mpSpare.put(mprow.SAP_Nilkamal_Model_Code_Equipment__r.ProductCode+'-'+mprow.SAP_Material_Code_Spare__r.ProductCode ,mprow.Id);
            }
           
            List<Equipment_Spare_Master__c> upProductList=new List<Equipment_Spare_Master__c>();
            for (IntegrationRequestBuilder.SparesEquipmentWrapper row : dataList) {
                //fetch spare material code
                if (!String.isBlank(row.SAPMaterialNumber)){
                    if(spareProductMap.get(row.SAPMaterialNumber)!=null){
                        Equipment_Spare_Master__c  prod = new Equipment_Spare_Master__c();
                        if(mpSpare.get(row.SAPEquipmentCode+'-'+row.SAPMaterialNumber)!=null){
                            prod.Id=mpSpare.get(row.SAPEquipmentCode+'-'+row.SAPMaterialNumber);
                        }
                        if(spareProductMap.get(row.SAPMaterialNumber)!=null){
                            prod.SAP_Material_Code_Spare__c=spareProductMap.get(row.SAPMaterialNumber).Id;
                        }
                        if(equipmentProductMap.get(row.SAPEquipmentCode)!=null){
                            prod.SAP_Nilkamal_Model_Code_Equipment__c=equipmentProductMap.get(row.SAPEquipmentCode).Id;
                        }
                        prod.OEM_model__c=row.OEMModel;
                        prod.Vendor_Material_Code_part_code__c=row.VendorMatCode;
                        // prod.AltMat1__c=row.AltMat1;
                        // prod.AltMat2__c=row.AltMat2;
                        // prod.AltMat3__c=row.AltMat3;
                        // prod.AltMat4__c=row.AltMat4;
                        // prod.AltMat5__c=row.AltMat5;
                        // prod.AltMat6__c=row.AltMat6;
                        // prod.AltMat7__c=row.AltMat7;
                        // prod.AltMat8__c=row.AltMat8;
                        // prod.AltMat9__c=row.AltMat9;
                        // prod.AltMat10__c=row.AltMat10;
                        upProductList.add(prod);
                    }
                }
             }
            if(upProductList.size()>0){
                UPSERT upProductList;
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