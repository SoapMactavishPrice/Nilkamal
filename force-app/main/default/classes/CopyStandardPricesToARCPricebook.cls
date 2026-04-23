global with sharing class CopyStandardPricesToARCPricebook implements Schedulable, Database.Batchable<SObject>, Database.Stateful {

    Set<Id> arcPricebookIds;

    global CopyStandardPricesToARCPricebook() {
        Decimal standardPricebookEntryCount = [SELECT COUNT() FROM PricebookEntry WHERE Pricebook2.IsStandard = true AND
        Product2.Manufacturing_Part_No1__r.Name IN ('MHE SPARES & SERVICES', 'SERVICE')
        //(Product2.Manufacturing_Part_No1__r.Name = 'MHE SPARES & SERVICES' OR Product2.Manufacturing_Part_No1__r.Name = 'SERVICES')
        ];


        List<Pricebook2> arcPricebookRecords = [SELECT Id FROM Pricebook2 WHERE IsStandard = false AND IsActive = true AND Is_ARC_Pricebook__c = true];
        this.arcPricebookIds = new Set<Id>();
        for (Pricebook2 pb : arcPricebookRecords) {
            this.arcPricebookIds.add(pb.Id);
        }

        for(AggregateResult ar : [
            SELECT Pricebook2Id, COUNT(Id)
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = false AND Pricebook2.IsActive = true AND Pricebook2.Is_ARC_Pricebook__c = true
            AND Product2.Manufacturing_Part_No1__r.Name IN ('MHE SPARES & SERVICES', 'SERVICE')
            // Product2.Manufacturing_Part_No1__r.Name = 'MHE SPARES & SERVICES'
            GROUP BY Pricebook2Id]
        ) {
            if(Integer.valueOf(ar.get('expr0')) == standardPricebookEntryCount) {
                this.arcPricebookIds.remove((Id)ar.get('Pricebook2Id'));
            }
        }
    }

    global CopyStandardPricesToARCPricebook(Id arcPricebookId) {
        this.arcPricebookIds = new Set<Id>{arcPricebookId};
    }

    global CopyStandardPricesToARCPricebook(Set<Id> arcPricebookIds) {
        this.arcPricebookIds = arcPricebookIds;
    }





    global void execute(SchedulableContext sc) {
        CopyStandardPricesToARCPricebook batch = new CopyStandardPricesToARCPricebook();
        Database.executeBatch(batch);
    }



    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode,
            Pricebook2.Name, Product2.Name
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = true AND Product2.Manufacturing_Part_No1__r.Name IN ('MHE SPARES & SERVICES', 'SERVICE')
            // Product2.Manufacturing_Part_No1__r.Name = 'MHE SPARES & SERVICES'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<PricebookEntry> scope) {
        // Get product Ids from current chunk
        Set<Id> productIds = new Set<Id>();
        for (PricebookEntry pe : scope) {
            productIds.add(pe.Product2Id);
        }

        // Query existing entries in ARC pricebook for these products
        Map<String, PricebookEntry> existingMap = new Map<String, PricebookEntry>();
        for(PricebookEntry pe : [SELECT Id, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Pricebook2Id IN :arcPricebookIds AND Product2Id IN :productIds]) {
            existingMap.put(pe.Pricebook2Id + '-' + pe.Product2Id, pe);
        }


        Map<Id, Pricebook2> arcPricebookMap = new Map<Id, Pricebook2>([SELECT Id, Name FROM Pricebook2 WHERE Id IN :arcPricebookIds]);


        List<PricebookEntry> newEntries = new List<PricebookEntry>();

        for (PricebookEntry pe : scope) {
            for(Id arcPricebookId : arcPricebookIds) {
                String key = arcPricebookId + '-' + pe.Product2Id;
                if (!existingMap.containsKey(key)) {
                    newEntries.add(new PricebookEntry(
                        Pricebook2Id        =       arcPricebookId,
                        Product2Id          =       pe.Product2Id,
                        UnitPrice           =       pe.UnitPrice,
                        UseStandardPrice    =       true,
                        CurrencyIsoCode     =       pe.CurrencyIsoCode,
                        IsActive            =       true,
                        External_Id__c      =       arcPricebookMap.get(arcPricebookId).Name + ' - ' + pe.Product2.Name
                    ));
                }
            }
        }

        if (!newEntries.isEmpty()) {
            insert newEntries;
        }
    }

    global void finish(Database.BatchableContext bc) {

    }

}