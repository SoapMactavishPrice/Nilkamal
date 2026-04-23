@isTest

public class CaseHistoryTest {
/*
   @isTest static void testGetAssetDetails() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

       Asset asset = new Asset(Name='Test Asset');
        insert asset;
        

        Asset_AMC__c amc = new Asset_AMC__c(
            Name = 'AMC 1',
            Asset__c = asset.Id
        );
        insert amc;

        Asset_Warranty__c warranty = new Asset_Warranty__c(
            Name = 'Warranty 1',
            Asset__c = asset.Id
           
        );
        insert warranty;

        Case cs = new Case(
            AssetId = asset.Id,
            Status = 'New',
            Origin = 'Phone',
            Priority = 'Medium',
            Subject = 'Test Case'
        );
        insert cs;
        
         Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
    insert wo;

        Service_Appointment__c sa = new Service_Appointment__c(
        Case__c = cs.Id,
        Work_Order__c = wo.Id 
    );
    insert sa;

        Task task = new Task(
            Subject = 'Task 1',
            WhatId = sa.Id,
            OwnerId = u.Id
        );
        insert task;

        Test.startTest();
        //List<Map<String, Object>> result = CaseHistory.getAssetDetails(cs.Id);
        Test.stopTest();

        //System.assertNotEquals(null, result);
        //System.assertEquals(1, result.size());

        //Map<String, Object> assetData = result[0];
        //System.assertEquals(asset.Id, assetData.get('Id'));
        //System.assertEquals(asset.Name, assetData.get('Name'));
       
        List<Map<String, Object>> amcsResult = (List<Map<String, Object>>)assetData.get('AMCs');
        System.assert(amcsResult.size() > 0);

        List<Map<String, Object>> warrantiesResult = (List<Map<String, Object>>)assetData.get('Warranties');
        System.assert(warrantiesResult.size() > 0);

        List<Map<String, Object>> casesResult = (List<Map<String, Object>>)assetData.get('Cases');
        System.assert(casesResult.size() > 0);

        List<Map<String, Object>> tasksResult = (List<Map<String, Object>>)assetData.get('Tasks');
        System.assert(tasksResult.size() > 0);
}*/

}