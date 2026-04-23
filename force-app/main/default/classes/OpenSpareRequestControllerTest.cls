@isTest
public class OpenSpareRequestControllerTest {

    @isTest
    static void testGetQuoteRecords() {
        // Insert required Sequence_Master__c record to support Quote trigger
        Sequence_Master__c sequence = new Sequence_Master__c(
            //Name = 'Quote Sequence',
            Format__c = 'Q-{0000}', 
            Starting_Number__c = 1000, 
            Current_Sequence_No__c = 1000
        );
        insert sequence;

        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create test Opportunity (required for Quote)
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // Create test Quotes linked to Opportunity
        List<Quote> quotes = new List<Quote>{
            new Quote(Name = 'Quote 1', OpportunityId = opp.Id, Status = 'Draft', ExpirationDate = Date.today().addDays(10)),
            new Quote(Name = 'Quote 2', OpportunityId = opp.Id, Status = 'Approved', ExpirationDate = Date.today().addDays(15)),
            new Quote(Name = 'Quote 3', OpportunityId = opp.Id, Status = 'Presented', ExpirationDate = Date.today().addDays(20))
        };
        insert quotes;

        Test.startTest();
        String resultJson = OpenSpareRequestController.getQuoteRecords();
        Test.stopTest();

        System.debug('Result JSON: ' + resultJson);
        System.assertNotEquals(null, resultJson, 'Result JSON should not be null');
        System.assert(resultJson.contains('Quote 1'), 'Result should contain Quote 1');
        System.assert(resultJson.contains('Quote 2'), 'Result should contain Quote 2');
        System.assert(resultJson.contains('Quote 3'), 'Result should contain Quote 3');
    }
}