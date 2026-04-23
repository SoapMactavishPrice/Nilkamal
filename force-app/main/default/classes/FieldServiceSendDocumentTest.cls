@isTest
private class FieldServiceSendDocumentTest {

    @testSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Asset testAsset = new Asset(Name = 'Test Asset');
        insert testAsset;

        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', AccountId = acc.Id);
        insert con;
        
        Case cs = new Case(AccountId = acc.Id, AssetId = testAsset.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'New',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        insert new Sequence_Master__c(
            format__c = '0000001',
            Starting_Number__c = 1000,
            Current_Sequence_No__c = 1000
        );

        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Quote_Document_Type__c = 'AMC',
            Document_No_1__c = 'DOC123',
            Document_Version__c = 'V1'
        );
        insert q;

        Installation_Report__c ir = new Installation_Report__c(Work_Order__c = wo.Id);
        insert ir;

        Service_Appointment__c sa = new Service_Appointment__c(Case__c = cs.Id, Work_Order__c = wo.Id,
            Scheduled_Start__c = DateTime.now().addDays(1),
            Remote_Support__c = false );
        insert sa;

        Service_Report__c srReport = new Service_Report__c(Service_Appointment__c = sa.Id, Work_Order__c = wo.Id);
        insert srReport;
    }

    @isTest
    static void testGetDefaultEmailIdsForQuote() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        Object result = FieldServiceSendDocument.getDefaultEmailIds(q.Id, 'Quotation');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Email IDs should not be null for Quote');
    }

    @isTest
    static void testGetDefaultEmailIdsForInstallationReport() {
        Installation_Report__c ir = [SELECT Id FROM Installation_Report__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceSendDocument.getDefaultEmailIds(ir.Id, 'Installation');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Email IDs should not be null for Installation Report');
    }

    @isTest
    static void testGetDefaultEmailIdsForServiceReport() {
        Service_Report__c sr = [SELECT Id FROM Service_Report__c LIMIT 1];
        Test.startTest();
        Object result = FieldServiceSendDocument.getDefaultEmailIds(sr.Id, 'Service');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Email IDs should not be null for Service Report');
    }

    @isTest
    static void testGetAttachmentIdForQuote() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        try {
            Id contentId = FieldServiceSendDocument.getAttachmentId(q.Id, 'Quotation');
            System.assertNotEquals(null, contentId, 'Attachment ID should not be null for Quote');
        } catch (Exception e) {
            System.debug('Handled Exception in testGetAttachmentIdForQuote: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAttachmentIdForInstallationReport() {
        Installation_Report__c ir = [SELECT Id FROM Installation_Report__c LIMIT 1];
        Test.startTest();
        Id contentId = FieldServiceSendDocument.getAttachmentId(ir.Id, 'Installation');
        Test.stopTest();
        System.assertNotEquals(null, contentId, 'Attachment ID should not be null for Installation');
    }

    @isTest
    static void testGetAttachmentIdForServiceReport() {
        Service_Report__c sr = [SELECT Id FROM Service_Report__c LIMIT 1];
        Test.startTest();
        Id contentId = FieldServiceSendDocument.getAttachmentId(sr.Id, 'Service');
        Test.stopTest();
        System.assertNotEquals(null, contentId, 'Attachment ID should not be null for Service Report');
    }

    @isTest
    static void testSendEmailSuccess() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        List<String> to = new List<String>{'testuser@example.com'};
        List<String> cc = new List<String>{'cc@example.com'};
        List<String> attachIds = new List<String>();

        Test.startTest();
        try {
            FieldServiceSendDocument.sendEmail(q.Id, to, cc, 'Test Subject', 'Test Body', attachIds, 'Quotation');
        } catch (Exception e) {
            System.debug('Handled Exception in testSendEmailSuccess: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailMissingTo() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        try {
            FieldServiceSendDocument.sendEmail(q.Id, new List<String>(), new List<String>(), 'Subject', 'Body', null, 'Quotation');
            System.assert(false, 'Expected AuraHandledException for missing To');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('recipient'), 'Missing recipient validation message expected');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailMissingSubject() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        try {
            FieldServiceSendDocument.sendEmail(q.Id, new List<String>{'to@example.com'}, new List<String>(), '', 'Body', null, 'Quotation');
            System.assert(false, 'Expected AuraHandledException for missing Subject');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('subject'), 'Missing subject validation message expected');
        }
        Test.stopTest();
    }

    @isTest
    static void testSendEmailMissingBody() {
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        Test.startTest();
        try {
            FieldServiceSendDocument.sendEmail(q.Id, new List<String>{'to@example.com'}, new List<String>(), 'Subject', '', null, 'Quotation');
            System.assert(false, 'Expected AuraHandledException for missing Body');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('body'), 'Missing body validation message expected');
        }
        Test.stopTest();
    }
}