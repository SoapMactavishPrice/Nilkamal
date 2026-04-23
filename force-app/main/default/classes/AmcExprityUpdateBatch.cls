public with sharing class AmcExprityUpdateBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Date today = System.today();
        List<Date> startDates = new List<Date>{
            today,
            today.addDays(-1),
            today.addDays(-2),
            today.addDays(-3)
        };

        return Database.getQueryLocator([
            SELECT Id, AMC_Start_Date__c, AMC_End_Date__c, AMC_Period_In_Months__c, Asset_AMC_PO_Status__c
            FROM Asset_AMC__c
            WHERE AMC_Start_Date__c IN :startDates OR AMC_End_Date__c = :System.today().addDays(-1)
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Asset_AMC__c> scope) {
        Date today = System.today();

        List<Asset_AMC__c> updateList = new List<Asset_AMC__c>();

        for (Asset_AMC__c amc : scope) {
            if (amc.AMC_End_Date__c == today.addDays(-1)) {
                amc.Asset_AMC_PO_Status__c = 'Expired';
                updateList.add(amc);
                continue;
            }

            if (amc.AMC_Start_Date__c != null && amc.AMC_Period_In_Months__c != null) {
                try {
                    Integer amcPeriod = amc.AMC_Period_In_Months__c.intValue();
                    Date tempDate = amc.AMC_Start_Date__c.addDays(-1).addMonths(amcPeriod);
                    Integer lastDay = Date.daysInMonth(tempDate.year(), tempDate.month());
                    Date calculatedEndDate = Date.newInstance(tempDate.year(), tempDate.month(), lastDay);
                    amc.AMC_End_Date__c = calculatedEndDate;

                    if (today < amc.AMC_Start_Date__c) {
                        if(amc.Asset_AMC_PO_Status__c != 'Planned') {
                            amc.Asset_AMC_PO_Status__c = 'Planned';
                            updateList.add(amc);
                        }
                    } else if (amc.AMC_Start_Date__c <= today && today <= calculatedEndDate) {
                        if(amc.Asset_AMC_PO_Status__c != 'Active') {
                            amc.Asset_AMC_PO_Status__c = 'Active';
                            updateList.add(amc);
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error calculating AMC End Date for AMC Id: ' + amc.Id + ', Error: ' + e.getMessage());
                }
            }
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
    }

    public void finish(Database.BatchableContext BC) {

    }
}