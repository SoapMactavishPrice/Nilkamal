@RestResource(urlMapping='/StockAPI/*')
    global class StockAPI {
        @HttpPost
        global static void doPost() {
            API_log__c apiLog = new API_log__c();
            try {
                // Parse the JSON request
                RestRequest req = RestContext.request;
                String jsonBody = req.requestBody.toString();
                String message = 'Successfully Synced to SF';
                
                apiLog.Log_Name__c = 'Stock API';
                
                List<IntegrationRequestBuilder.StockWrapper> stockList = IntegrationRequestBuilder.StockParse(jsonBody);
                apiLog.Request__c = 'Total Size = ' + stockList.size();
                
                Set<String> productCodes = new Set<String>();
                Set<String> plantCodes = new Set<String>();
                Set<String> mfgParts = new Set<String>();
                
                for (IntegrationRequestBuilder.StockWrapper stock : stockList) {
                    if (!String.isBlank(stock.Material)) productCodes.add(stock.Material);
                    if (!String.isBlank(stock.Plant_Code)) plantCodes.add(stock.Plant_Code);
                    if (!String.isBlank(stock.Manufacturing_Part_No)) mfgParts.add(stock.Manufacturing_Part_No);
                }
                
                // Product2 Map
                Map<String, Product2> productMap = new Map<String, Product2>();
                for (Product2 product : [
                SELECT Id, ProductCode, Category__c, Business_Vertical__c 
                FROM Product2 
                WHERE ProductCode IN :productCodes
            ]) {
                    productMap.put(product.ProductCode, product);
                }
                
                // Plant_Master__c Map
                Map<String, Plant_Master__c> plantMap = new Map<String, Plant_Master__c>();
                for (Plant_Master__c plant : [
                SELECT Id, Plant_Code__c 
                FROM Plant_Master__c 
                WHERE Plant_Code__c IN :plantCodes
            ]) {
                    plantMap.put(plant.Plant_Code__c, plant);
                }
                
                // Manufacturing_Part_No__c Map
                Map<String, Manufacturing_Part_No__c> mfgMap = new Map<String, Manufacturing_Part_No__c>();
                for (Manufacturing_Part_No__c mfg : [
                SELECT Id, Name 
                FROM Manufacturing_Part_No__c 
                WHERE Name IN :mfgParts
            ]) {
                    mfgMap.put(mfg.Name, mfg);
                }
                
                // Create or update inventory records
                List<Inventory__c> stocksToUpsert = new List<Inventory__c>();
                for (IntegrationRequestBuilder.StockWrapper stock : stockList) {
                    Inventory__c inv = new Inventory__c();
                    if (!String.isBlank(stock.Material)) {
                        if (productMap.containsKey(stock.Material)) {
                            inv.Material__c = productMap.get(stock.Material).Id;
                        } else {
                            // throw new CustomException('Material is not present in the system.');
                        }
                    }
                    
                    if (!String.isBlank(stock.Plant_Code) && plantMap.containsKey(stock.Plant_Code)) {
                        inv.Plant_Master__c = plantMap.get(stock.Plant_Code).Id;
                    }
                    
                    if (!String.isBlank(stock.Manufacturing_Part_No) && mfgMap.containsKey(stock.Manufacturing_Part_No)) {
                        inv.Manufacturing_Part_No__c = mfgMap.get(stock.Manufacturing_Part_No).Id;
                    }
                    
                    inv.Material_Description__c = stock.Material_Description;
                    inv.MG6__c = stock.Material_Group6;
                    inv.MG6_Description__c = stock.MG6_Description;
                    inv.Plant_Name__c = stock.Plant_Name;
                    inv.Quantity__c = Decimal.valueOf(stock.Quantity);
                    inv.External_Key__c = stock.Material + '_' + stock.Plant_Code;
                    inv.Name = stock.Material + '_' + stock.Plant_Code;
                    
                    stocksToUpsert.add(inv);
                }
                
                if (!stocksToUpsert.isEmpty()) {
                    upsert stocksToUpsert External_Key__c;
                }
                
                // Response
                apiLog.Status__c = 'Success';
                Map<String, Object> responseMap = new Map<String, Object>();
                responseMap.put('Status', 'success');
                responseMap.put('msg', message);
                
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseMap));
                
                apiLog.Response__c = JSON.serialize(responseMap);
                apiLog.Response_Code__c = '200';
            } catch (Exception e) {
                RestContext.response.statusCode = 500;
                apiLog.Status__c = 'Failed';
                apiLog.Exception_Description__c = e.getMessage() + ' : ' + String.valueOf(e.getStackTraceString());
                
                RestContext.response.responseBody = Blob.valueOf(
            '{"error": "' + e.getMessage() + ' at line ' + e.getLineNumber() + '"}'
            );
        } finally {
            insert apiLog;
        }
    }
}