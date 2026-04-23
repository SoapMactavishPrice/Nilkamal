/**
 * @author Aditya Zagade
 * @since 5 Dec 2024 Created
 *
 * @group Field Service
 */
public with sharing class AddProductOnOpportunityController {

    /**
     * @description Method to get the list of pricebook entries
     * @param recordId
     * @param filtersSelected
     * @param offset
     * @param lmt
     * @return  `Object` pricebook entries list
     * @exception Throws an AuraHandledException
     * @example
     * List<Map<String, String>> filtersSelected = new List<Map<String, String>>();
     * filtersSelected.add(new Map<String, String>{'field' => 'Product2.Name', 'value' => 'Test'});
     * Object pricebookEntries = AddProductOnOpportunityController.getProductList(recordId, filtersSelected, 0, 10);
     */
    @AuraEnabled
    public static Object getProductList(String recordId, List<Map<String, String>> filtersSelected, Integer offset, Integer lmt) {
        try {
            Opportunity opportunity = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :recordId];
            String query = 'SELECT Id, UnitPrice, Product2.Name, Product2.Description, Product2.Base_UOM__r.Name, Product2.Sales_UOM__r.Name, Product2.Image__c ' +
                            'FROM PricebookEntry ' +
                            'WHERE Pricebook2Id = \'' + opportunity.Pricebook2Id + '\' ';
            if(filtersSelected != null && filtersSelected.size() > 0) {
                for(Map<String, String> filter : filtersSelected) {
                    query += 'AND ' + filter.get('field') + ' = \'' + filter.get('value') + '\' ';
                }
            }
            query += ' LIMIT ' + lmt + ' OFFSET ' + offset;
            return Database.query(query);
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}