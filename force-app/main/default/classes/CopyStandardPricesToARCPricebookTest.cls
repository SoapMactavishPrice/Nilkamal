@isTest
public with sharing class CopyStandardPricesToARCPricebookTest {

    @isTest
    public static void test1() {
        Manufacturing_Part_No__c mpn = new Manufacturing_Part_No__c(Name = 'MHE SPARES & SERVICES');
        insert mpn;

        Pricebook2 standardPB = new Pricebook2(Id = Test.getStandardPricebookId());
        update standardPB;

        Pricebook2 arcPB1 = new Pricebook2(Name = 'ARC PB 1', IsActive = true, Is_ARC_Pricebook__c = true);
        Pricebook2 arcPB2 = new Pricebook2(Name = 'ARC PB 2', IsActive = true, Is_ARC_Pricebook__c = true);
        insert new List<Pricebook2>{arcPB1, arcPB2};

        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 100; i++) {
            products.add(new Product2(Name = 'Test Product ' + i, IsActive = true, Manufacturing_Part_No1__c = mpn.Id));
        }
        insert products;

        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for (Product2 p : products) {
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPB.Id,
                Product2Id = p.Id,
                UnitPrice = 100,
                UseStandardPrice = false,
                IsActive = true
            ));
        }
        insert standardEntries;

        PricebookEntry arcEntry = new PricebookEntry(
            Pricebook2Id = arcPB1.Id,
            Product2Id = products[0].Id,
            UnitPrice = 100,
            UseStandardPrice = false,
            IsActive = true
        );
        insert arcEntry;

        for(PricebookEntry pe : [SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode,
            Pricebook2.Name, Pricebook2.IsStandard, Product2.Name
            FROM PricebookEntry
        ]) {
            System.debug(pe.Id + ' ' + pe.Product2Id + ' ' + pe.UnitPrice + ' ' + pe.CurrencyIsoCode + ' ' + pe.Pricebook2.Name + ' ' + pe.Pricebook2.IsStandard + ' ' + pe.Product2.Name);
        }

        System.debug([SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode,
            Pricebook2.Name, Product2.Name
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = true AND Product2.Manufacturing_Part_No1__r.Name = 'MHE SPARES & SERVICES']);

        Test.startTest();
        CopyStandardPricesToARCPricebook batch = new CopyStandardPricesToARCPricebook(new Set<Id>{arcPB1.Id, arcPB2.Id});
        batch = new CopyStandardPricesToARCPricebook();
        Database.executeBatch(batch);
        Test.stopTest();
    }

}