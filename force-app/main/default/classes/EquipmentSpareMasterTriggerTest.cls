@isTest
public class EquipmentSpareMasterTriggerTest {

    @isTest
    public static void test1() {
        Product2 prod1 = new Product2(Name = 'Test Product1', isActive = true);

        Product2 prod2 = new Product2(Name = 'Test Product2', isActive = true);

        insert new List<Product2>{prod1, prod2};

        Test.startTest();
        Equipment_Spare_Master__c esm = new Equipment_Spare_Master__c(SAP_Nilkamal_Model_Code_Equipment__c = prod1.Id, SAP_Material_Code_Spare__c = prod2.Id);
        insert esm;
        Test.stopTest();
    }

}