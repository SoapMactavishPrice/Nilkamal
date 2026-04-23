public class UpdateQuoteTriggerHandler {

    public static void updateQuoteAddress(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        Set<Id> accountIds = new Set<Id>();

        if (oldQuoteMap == null) {
            oldQuoteMap = new Map<Id, Quote>();
        }

        for (Quote q : newQuotes) {
            if(Trigger.isInsert) {
                if(q.Bill_to_Party__c != null) {
                    accountIds.add(q.Bill_to_Party__c);
                }
                if(q.Ship_to_Party__c != null) {
                    accountIds.add(q.Ship_to_Party__c);
                }
            } else {
                Quote oldQ = oldQuoteMap.get(q.Id);
                if(q.Bill_to_Party__c != oldQ.Bill_to_Party__c && q.Bill_to_Party__c != null) {
                    accountIds.add(q.Bill_to_Party__c);
                }
                if (q.Ship_to_Party__c != oldQ.Ship_to_Party__c && q.Ship_to_Party__c != null) {
                    accountIds.add(q.Ship_to_Party__c);
                }
            }
        }

        System.debug('accountIds: ' + accountIds);

        if (!accountIds.isEmpty()) {

            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id,SAP_Customer_code__c, Mobile_Number__c,State__c ,Street1__c, Street2__c, City__c, Street_House_Number__c, Postal_code__c,Country__c
                FROM Account
                WHERE Id IN :accountIds
            ]);

            for (Quote q : newQuotes) {
                Quote oldQ = new Quote();
                if(oldQuoteMap.containsKey(q.Id)) {
                    oldQ = oldQuoteMap.get(q.Id);
                }

                if(Trigger.isInsert || (q.Bill_to_Party__c != oldQ.Bill_to_Party__c && q.Bill_to_Party__c != null)) {
                    Account acc = accountMap.get(q.Bill_to_Party__c);
                    if (acc != null) {
                        q.Street1_Bill_To__c = acc.Street1__c;
                        q.Street2_Bill_To__c = acc.Street2__c;
                        q.Street_House_Number_Bill_To__c = acc.Street_House_Number__c;
                        q.City_Bill_To__c = acc.City__c;
                        q.Postal_code_Bill_To__c = acc.Postal_code__c;
                        q.Country_Bill_To__c = acc.Country__c;
                        q.Bill_To_Mobile__c = acc.Mobile_Number__c;
                        q.Bill_to_Region__c=acc.State__c;
                        q.Bill_to_Customer_Code__c=acc.SAP_Customer_code__c;

                    }
                }
                if (Trigger.isInsert || (q.Ship_to_Party__c != oldQ.Ship_to_Party__c && q.Ship_to_Party__c != null)) {
                    Account acc = accountMap.get(q.Ship_to_Party__c);
                    if (acc != null) {
                        q.Street1__c = acc.Street1__c;
                        q.Street2__c = acc.Street2__c;
                        q.Street_House_Number__c = acc.Street_House_Number__c;
                        q.City__c = acc.City__c;
                        q.Postal_code__c = acc.Postal_code__c;
                        q.Country__c = acc.Country__c;
                        q.Ship_to_Mobile__c=acc.Mobile_Number__c;
                        q.Ship_to_Region__c=acc.State__c;
                        q.Ship_to_Customer_Code__c=acc.SAP_Customer_code__c;
                    }
                }
            }
        }
    }

    public static void UpdateDefaultValues(List<Quote> quotes) {
        List<Plant_Master__c> plantMasters = [SELECT Id, Name, Plant_Code__c FROM Plant_Master__c];
        Map<String, Plant_Master__c> plantMap = new Map<String, Plant_Master__c>();
        for(Plant_Master__c pm : plantMasters) {
            plantMap.put(pm.Plant_Code__c, pm);
        }
        for(Quote q : quotes) {
            if(q.Business_Vertical__c == 'MHE') {
                if(plantMap.containsKey('1455')) {
                    q.Delivery_Plant__c=plantMap.get('1455').Id; //Default Bhiwandi for MHE
                }
                q.Inco_Terms__c='NK2';
            }
            q.Quote_Probability__c='10';

            if(q.Quote_Document_Type__c == 'AMC' || q.Quote_Document_Type__c == 'Chargeable Service') {
                q.Customer_Scope__c = 'Hydra, Crane, Civil, Transportation for Material Movement and any Fabrication';
            }

        }
    }

    public static void handleFOCPaymentTerms(List<Quote> newQuotes, Map<Id, Quote> oldQuoteMap) {
        for (Quote q : newQuotes) {
            if (q.Billing_Type__c == 'FOC and Non-Returnable' || q.Billing_Type__c == 'FOC and Returnable') {
                q.Payment_Terms__c = 'NFOC';
            }
        }
    }

}