@isTest
public class SpareEquipmentAPI_Test {

    @isTest
    static void testSparesEquipmentAPI() {
        Product2 spare = new Product2(Name = 'Spare1', ProductCode = 'SP001', IsActive = true);
        Product2 equipment = new Product2(Name = 'Equip1', ProductCode = 'EQ001', IsActive = true);
        insert new List<Product2>{ spare, equipment };

        String testJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'SAPMaterialNumber' => 'SP001',
                'SAPEquipmentCode' => 'EQ001',
                'OEMModel' => 'OEM123',
                'VendorMatCode' => 'VMC999'
            }
        });

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestUri = '/services/apexrest/SparesEquipmentAPI/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(testJson);

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        SpareEquipmentAPI.doPost();
        Test.stopTest();

        List<API_Log__c> logs = [SELECT Id, Status__c, Log_Name__c FROM API_Log__c WHERE Log_Name__c = 'SparesEquipmentAPI'];
        System.assertEquals(1, logs.size(), 'There should be one API log record');
        System.assertEquals('Success', logs[0].Status__c, 'Log should indicate success');

        List<Equipment_Spare_Master__c> spares = [SELECT Id, SAP_Material_Code_Spare__c, SAP_Nilkamal_Model_Code_Equipment__c, OEM_model__c, Vendor_Material_Code_part_code__c FROM Equipment_Spare_Master__c];
        System.assertEquals(1, spares.size(), 'One spare-equipment mapping should be created');
        System.assertEquals('OEM123', spares[0].OEM_model__c);
        System.assertEquals('VMC999', spares[0].Vendor_Material_Code_part_code__c);
    }
}