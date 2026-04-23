@isTest
private class StockAPITest {
    
    @isTest
    static void testDoPostSuccess() {
        Product2 product = new Product2(Name = 'Test Product', ProductCode = 'MAT001');
        insert product;

        Plant_Master__c plant = new Plant_Master__c(
            Name = 'Test Plant', 
            Plant_Code__c = 'PLT001',
            GST_No__c = '22AAAAA0000A1Z5' 
        );
        insert plant;

        Manufacturing_Part_No__c mfg = new Manufacturing_Part_No__c(Name = 'MPN001');
        insert mfg;

        String jsonPayload = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                'Material' => 'MAT001',
                'Plant_Code' => 'PLT001',
                'Manufacturing_Part_No' => 'MPN001',
                'Material_Description' => 'Test Description',
                'Material_Group6' => 'MG6',
                'MG6_Description' => 'MG6 Desc',
                'Plant_Name' => 'Test Plant',
                'Quantity' => 100
            }
        });

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/StockAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        RestContext.response = res;

        StockAPI.doPost();
        Test.stopTest();

        List<Inventory__c> inventoryRecords = [SELECT Id, Name FROM Inventory__c WHERE Name = 'MAT001_PLT001'];
        System.assertEquals(1, inventoryRecords.size());

        List<API_log__c> logs = [SELECT Id, Status__c, Response_Code__c FROM API_log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Success', logs[0].Status__c);
        System.assertEquals('200', logs[0].Response_Code__c);
    }

    @isTest
    static void testDoPostWithException() {
        String invalidJson = '{"bad json": }';

        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/StockAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(invalidJson);
        RestContext.request = req;
        RestContext.response = res;

        StockAPI.doPost();
        Test.stopTest();

        List<API_log__c> logs = [SELECT Id, Status__c, Exception_Description__c FROM API_log__c ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Failed', logs[0].Status__c);

        System.assert(!String.isBlank(logs[0].Exception_Description__c));
    }
}