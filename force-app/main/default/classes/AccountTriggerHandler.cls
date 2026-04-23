public class AccountTriggerHandler {

    public static void handleTerritoryUpdate(List<Account> accounts, Boolean isInsert, Boolean isUpdate) {
        Set<Id> pincodeIds = new Set<Id>();
        Set<String> shippingPincodeIds = new Set<String>();
        for (Account acc : accounts) {
            if (acc.Pin_Code__c	 != null) {
                pincodeIds.add(acc.Pin_Code__c);
            }
            if(acc.postal_code__c != null){
                shippingPincodeIds.add(acc.postal_code__c);
            }
        }

        if (!pincodeIds.isEmpty()) {
            Map<String, Pin_Code_Master__c> postalCodeMap = new Map<String, Pin_Code_Master__c>();
            List<Pin_Code_Master__c> pincodes = [SELECT Id, Name,state__c FROM Pin_Code_Master__c WHERE name IN :shippingPincodeIds];
            for(Pin_Code_Master__c pincode : pincodes) {
                postalCodeMap.put(pincode.name, pincode);
            }

            List<Territory_Pincode_Mapping__c> pincodeTerritories = [SELECT Pin_Code_Master__c, Territory_Master__c
                                                                    FROM Territory_Pincode_Mapping__c
                                                                    WHERE Pin_Code_Master__c IN :pincodeIds];

            Map<Id, String> pincodeToTerritoryMap = new Map<Id, String>();
            for (Territory_Pincode_Mapping__c tp : pincodeTerritories) {
                pincodeToTerritoryMap.put(tp.Pin_Code_Master__c, tp.Territory_Master__c);
            }

            for (Account acc : accounts) {
                if (acc.Pin_Code__c != null && pincodeToTerritoryMap.containsKey(acc.Pin_Code__c)) {
                    acc.Territory_Master__c = pincodeToTerritoryMap.get(acc.Pin_Code__c);

                }
                if(postalCodeMap.containsKey(acc.postal_code__c)){
                    acc.state__c = postalCodeMap.get(acc.postal_code__c).state__c;
                }
            }
        }
    }

    public static void updatePriceList(List<Account> accounts) {
        try {
            Pricebook2 Pricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Nilkamal Pricebook' LIMIT 1];
            for (Account acc : accounts) {
                acc.Pricelist__c = Pricebook.Id;
            }
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
    }

    public static void updatePinCode(List<Account> accounts, Map<Id, Account> oldMap) {
        Set<Id> pinCodeIds = new Set<Id>();
        Set<String> pinCodes = new Set<String>();
        for (Account acc : accounts) {
            if(acc.Pin_Code__c != null) {
                pinCodeIds.add(acc.Pin_Code__c);
            }
            if(String.isNotBlank(acc.Postal_code__c)) {
                pinCodes.add(acc.Postal_code__c);
            }
        }

        Map<String, Pin_Code_Master__c> pincodeMap = new Map<String, Pin_Code_Master__c>();
        for (Pin_Code_Master__c pincode : [SELECT Id, Name, Region__c FROM Pin_Code_Master__c WHERE Id IN :pinCodeIds OR Name IN :pinCodes]) {
            pincodeMap.put(pincode.Name, pincode);
        }

        for(Account acc : accounts) {
            if(acc.Postal_Code__c != null) {
                String oldPinCode = pincodeMap.containsKey(acc.Postal_Code__c) ? pincodeMap.get(acc.Postal_Code__c).Name : null;
                if(acc.Pin_Code__c == null) {
                    if(pincodeMap.containsKey(acc.Postal_code__c)) {
                        acc.Pin_Code__c = pincodeMap.get(acc.Postal_code__c).Id;
                    }
                }
                else if(acc.Postal_code__c != oldPinCode) {
                    if(pincodeMap.containsKey(acc.Postal_code__c)) {
                        acc.Pin_Code__c = pincodeMap.get(acc.Postal_code__c).Id;
                    }
                }
            } else {
                acc.Pin_Code__c = null;
            }
        }
    }

}