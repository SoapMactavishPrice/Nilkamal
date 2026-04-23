public with sharing class DeepCloneQuoteController {

    @AuraEnabled
    public static Id deepCloneQuote(Id quoteId) {
        try {
            if (quoteId == null) {
                throw new AuraHandledException('Quote ID cannot be null.');
            }

            Quote originalQuote = [SELECT Id, Status FROM Quote WHERE Id = :quoteId];
            if(originalQuote.Status != 'Amended' || originalQuote.Status != 'Rejected' || originalQuote.Status != 'Denied') {
                originalQuote.Status = 'Amended';
                update originalQuote;
            }


            String query1 = 'SELECT ' + UtilityCls.getAllFields('Quote').get('Quote') + ' FROM Quote WHERE Id = :quoteId';
            String query2 = 'SELECT ' + UtilityCls.getAllFields('QuoteLineItem').get('QuoteLineItem') + ' FROM QuoteLineItem WHERE QuoteId = :quoteId';
            String query3 = 'SELECT ' + UtilityCls.getAllFields('Quote_Service_Line_Item__c').get('Quote_Service_Line_Item__c') + ' FROM Quote_Service_Line_Item__c WHERE Quote__c = :quoteId';

            System.debug('Query 1: ' + query1);
            System.debug('Query 2: ' + query2);
            System.debug('Query 3: ' + query3);

            Quote sourceQuote = Database.query(query1);
            List<QuoteLineItem> sourceQuoteLineItems = Database.query(query2);
            List<Quote_Service_Line_Item__c> sourceQuoteServiceLineItems = Database.query(query3);


            Quote clonedQuote = sourceQuote.clone(false, true, false);
            clonedQuote.Status = 'Draft';
            insert clonedQuote;


            List<QuoteLineItem> clonedQuoteLineItems = new List<QuoteLineItem>();
            for (QuoteLineItem lineItem : sourceQuoteLineItems) {
                QuoteLineItem clonedLineItem = lineItem.clone(false, true, false);
                clonedLineItem.QuoteId = clonedQuote.Id;
                clonedQuoteLineItems.add(clonedLineItem);
            }
            if (!clonedQuoteLineItems.isEmpty()) {
                insert clonedQuoteLineItems;
            }


            List<Quote_Service_Line_Item__c> clonedQuoteServiceLineItems = new List<Quote_Service_Line_Item__c>();
            for (Quote_Service_Line_Item__c serviceLineItem : sourceQuoteServiceLineItems) {
                Quote_Service_Line_Item__c clonedServiceLineItem = serviceLineItem.clone(false, true, false);
                clonedServiceLineItem.Quote__c = clonedQuote.Id;
                clonedQuoteServiceLineItems.add(clonedServiceLineItem);
            }
            if (!clonedQuoteServiceLineItems.isEmpty()) {
                insert clonedQuoteServiceLineItems;
            }


            return clonedQuote.Id;
        }
        catch (Exception e) {
            System.debug('Error during quote cloning: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

}