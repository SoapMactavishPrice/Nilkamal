public with sharing class UpdateServiceGoal implements System.Schedulable, Database.Batchable<SObject> {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 1);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Name, Business_Verticals__c, Start_Date__c, End_Date__c, Sales_Office__c, Service_Resource__c, Service_Resource__r.User__c, Service_Resource__r.User__r.UID__c,
            Sales_Goal__c, Sales_Achievement__c, Service_Goal__c, Service_Achievement__c, Total_Goal__c, Total_Achievement__c,
            Sales_Achievement_Percentage__c, Service_Achievement_Percentage__c, Total_Achievement_Percentage__c
            FROM Service_Goal__c
            WHERE Financial_Year__c IN (:getFinancialYearFormat(System.today()), :getFinancialYearFormat(System.today().addDays(-1))) AND Service_Resource__r.User__r.UID__c != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Service_Goal__c> scope) {
        System.debug('Scope: ' + scope);
        for(Service_Goal__c goal : scope) {
            Decimal spareGoal = 0;
            Decimal serviceGoal = 0;
            List<Invoice__c> invoicesToUpdate = new List<Invoice__c>();

            for(Invoice__c invoice : [
                SELECT Id, Net_Invoice_Amount__c, Line_Item_Net_Value__c, Item_Master__c, Item_Master__r.Category__c, Service_Goal__c
                FROM Invoice__c
                WHERE Billing_Date__c >= :goal.Start_Date__c AND Billing_Date__c <= :goal.End_Date__c AND Sales_Employee_Code__c = :goal.Service_Resource__r.User__r.UID__c AND Billing_Type__c = 'F2' AND Item_Master__r.Category__c IN ('Spare', 'Service') AND Sales_Office_Code__c = :goal.Sales_Office__c AND
                Sales_Employee_Code__c != null AND Sales_Employee_Code__c != '' AND Line_Item_Net_Value__c != null
            ]) {
                if(invoice.Item_Master__r.Category__c == 'Spare') {
                    spareGoal += invoice.Line_Item_Net_Value__c;
                }
                else if (invoice.Item_Master__r.Category__c == 'Service') {
                    serviceGoal += invoice.Line_Item_Net_Value__c;
                }
                if(invoice.Service_Goal__c != goal.Id) {
                    invoice.Service_Goal__c = goal.Id;
                    invoicesToUpdate.add(invoice);
                }
            }

            if(!invoicesToUpdate.isEmpty()) {
                Database.update(invoicesToUpdate, true, AccessLevel.SYSTEM_MODE);
            }

            Boolean isGoalChanged = false;
            if(goal.Sales_Achievement__c != spareGoal) {
                goal.Sales_Achievement__c = spareGoal;
                isGoalChanged = true;
            }
            if(goal.Service_Achievement__c != serviceGoal) {
                goal.Service_Achievement__c = serviceGoal;
                isGoalChanged = true;
            }

            if(isGoalChanged) {
                System.debug('Result: ' + Database.update(goal, true, AccessLevel.SYSTEM_MODE));
            }
        }
    }

    public void finish(Database.BatchableContext BC) {}



    public static String getFinancialYearFormat(Date billed_date) {
        if (billed_date == null) {
            return null;
        }

        Integer year = billed_date.year();
        Integer month = billed_date.month();
        Integer fyStartYear;
        Integer fyEndYear;

        if (month >= 4) {
            // April to December
            fyStartYear = year;
            fyEndYear = year + 1;
        } else {
            // January to March
            fyStartYear = year - 1;
            fyEndYear = year;
        }

        return 'FY ' + fyStartYear + '-' + fyEndYear.toString().substring(2);
    }

}