@isTest
public class ProductMasterRetryBatchTest {

    @isTest
    public static void test1() {
        API_log__c log = new API_log__c(
            Status__c = 'Failed',
            Log_Name__c = 'Product_Master',
            Request__c = '[{"ITEM_NUMBER":"JR53300BJNBDBL","ITEM_DESCRIPTION":"NILKAMAL CRATE JR-53300 BJNB Dark Blue","ITEM_GROUP":"JR53300BJ","BASE_UOM":"NOS","OLD_MATERIAL_CODE":"","SALES_ORGANISATION":"1000","DISTRIBUTION_CHANNEL":"10","DIVISION":"01","SALES_UOM":"","PLANT_CODE":"1455","GENITEMCATGROUP":"NORM","SIZE_DIMENSIONS":"OD.537X353X299 ID.504X323X280MM","ITEM_TYPE":"FERT","MATERIAL_GROUP_2":"C01","MATERIAL_GROUP_2_C":"STANDARD CRATE","MATERIAL_GROUP_3":"C01","MATERIAL_GROUP_3_C":"FAST MOVING CRATE","MATERIAL_GROUP_4":"C02","MATERIAL_GROUP_4_C":"COMPETITIVE","MATERIAL_GROUP_5":"C12","MATERIAL_GROUP_5_C":"Season starts DECEMBER","MATERIAL_GROUP_6":"","MATERIAL_GROUP_6_C":"MHE-HYDR-SEALS / GASKETS","LIST_PRICE_MRP_PRICE":0,"HSN_CODE":"","LeadTime":" 0","MPN":"NPL CRATES","PRODUCT_STATUS": "Active","PRODUCT_IMAGE_NAME":"JR53300BJNBDBL","PRODUCT_IMAGE_BASE64":""}]',
            Exception_Description__c = 'Test Exception'
        );
        insert log;

        Test.startTest();
        ProductMasterRetryBatch batch = new ProductMasterRetryBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
    }

}