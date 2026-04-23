public with sharing class OpenSpareRequestController {
    @AuraEnabled
    public static String getQuoteRecords() {
        List<Quote> quoteList = new List<Quote>();

        try {
            System.debug('Fetching Quote records...');

            quoteList = [
                SELECT Id, Name, Account.Name, TotalPrice, Status, ExpirationDate,Total_Basic_Unit_Price__c
                FROM Quote
                WHERE Status IN ('Draft', 'In Review', 'Approved', 'Rejected', 'Presented', 'Negotiation')
                ORDER BY CreatedDate DESC
            ];

            System.debug('Quotes retrieved: ' + quoteList);

        } catch (Exception e) {System.debug('An error occurred: ' + e.getMessage());throw new AuraHandledException('An error occurred while fetching quote records.');
        }

        return JSON.serialize(quoteList);
    }

}