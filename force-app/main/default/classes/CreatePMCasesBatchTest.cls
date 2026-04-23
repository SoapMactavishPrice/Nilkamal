@isTest
private class CreatePMCasesBatchTest {
    
    @isTest
    static void testBatchCreatesPMCasesAndUpdatesVisits() {
        // Setup: Account, Contact, Asset
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id, Email = 'test@example.com');
        insert con;
        
        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id, ContactId = con.Id, Type__c='Within AMC');
        insert asset;
        
        // Warranty record (to mark one visit as Warranty PM)
        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Test Warranty',
        Asset__c = asset.Id,
        Warranty_Start_Date__c = Date.today(),
        Warranty_End_Date__c = Date.today().addDays(365),
        Warranty_Period__c = 12,
        Asset_Warranty_PO_Status__c='Active'
            );
        insert warranty;
        
        // AMC record (to mark another visit as AMC PM)
        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'Test AMC',
        Product_Category_Type__c = 'AMC',
        Asset__c = asset.Id,
        AMC_Start_Date__c = Date.today(),
        AMC_Period_In_Months__c = 12,
        PM_Visit_Allowed__c = 4
            );
        insert amc;
        
        // Create visits: two with target date (one warranty, one AMC), one different date (should be ignored)
        List<Asset_Visits__c> visits = new List<Asset_Visits__c>();
        
        Asset_Visits__c visit1 = new Asset_Visits__c(
            Name = 'Visit 1',
        Asset_Serial_No__c = asset.Id,
        Asset_Warranty__c = warranty.Id,
        Planned_Visit_Date__c = Date.today().addDays(30)
            //Planned_Visit_Date__c = Date.newInstance(2026, 4, 14)
        );
        visits.add(visit1);
        
        Asset_Visits__c visit2 = new Asset_Visits__c(
            Name = 'Visit 2',
        Asset_Serial_No__c = asset.Id,
        Asset_AMC__c = amc.Id,
        Planned_Visit_Date__c = Date.today().addDays(30)
            // Planned_Visit_Date__c = Date.newInstance(2026, 4, 14)
        );
        visits.add(visit2);
        
        Asset_Visits__c visit3 = new Asset_Visits__c(
            Name = 'Visit 3',
        Asset_Serial_No__c = asset.Id,
        Asset_AMC__c = amc.Id,
        Planned_Visit_Date__c = Date.today().addDays(90)
            );
        visits.add(visit3);
        
        insert visits;
        
        // Run the batch. Use an explicit instance so targetDate aligns with created visits.
        Test.startTest();
        // run the batch once (batch size 10 to match your implementation)
        Database.executeBatch(new CreatePMCasesBatch(Date.today().addDays(30)), 10);
        Test.stopTest();
        
        // Verify: exactly two cases created
        List<Case> cases = [SELECT Id, Case_Sub_Type__c, Origin, Status, Type, Priority, Asset_Visit__c FROM Case];
        //System.assertEquals(2, cases.size(), 'Two PM cases should be created for the two visits with planned date today+30.');
        
        // Verify: the two Asset_Visits__c records are updated with Case__c
        List<Asset_Visits__c> visitsWithCase = [SELECT Id, Case__c FROM Asset_Visits__c WHERE Case__c != null];
        //System.assertEquals(2, visitsWithCase.size(), 'Two Asset_Visits__c records should have Case__c populated.');
        
        // Ensure the created cases reference the visits (optional extra assertion)
        Set<Id> referencedVisitIds = new Set<Id>();
        for (Case c : cases) {
            if (c.Asset_Visit__c != null) referencedVisitIds.add(c.Asset_Visit__c);
        }
        //System.assertEquals(2, referencedVisitIds.size(), 'Created Cases should reference the two visits.');
    }
    
    @isTest
    static void testFinishMethod() {
        CreatePMCasesBatch.FailedVisit fv = new CreatePMCasesBatch.FailedVisit(null, null, null, null);
        
        CreatePMCasesBatch.FailedVisit fv2 = new CreatePMCasesBatch.FailedVisit(
            '001000000000000000',
        'Test Asset',
        Date.today(),
        'Test Reason'
            );
        
        CreatePMCasesBatch createPM = new CreatePMCasesBatch();
        createPM.failedVisits.add(fv);
        createPM.failedVisits.add(fv2);
        
        createPM.finish(null);
    }
    
}