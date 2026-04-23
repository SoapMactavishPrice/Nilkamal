@isTest
public with sharing class PricebookTriggerHandlerTest {

    @isTest
    static void test1() {
        Test.startTest();
        Pricebook2 pb = new Pricebook2(Name = 'Test Pricebook', Is_ARC_Pricebook__c = true);
        insert pb;
        Test.stopTest();
    }

}