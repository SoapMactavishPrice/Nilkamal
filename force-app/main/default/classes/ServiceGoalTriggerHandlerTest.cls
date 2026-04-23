@isTest
public class ServiceGoalTriggerHandlerTest {

    @isTest
    static void testUpdateStartAndEndDate_InsertScenario() {
        Service_Goal__c sg = new Service_Goal__c(
            Financial_Year__c = 'FY 2024-2025'
        );

        insert sg;

        List<Service_Goal__c> newRecords = [SELECT Id, Financial_Year__c, Start_Date__c, End_Date__c FROM Service_Goal__c WHERE Id = :sg.Id];

        Test.startTest();
        ServiceGoalTriggerHandler.updateStartAndEndDate(newRecords, null);
        Test.stopTest();

        System.assertNotEquals(null, newRecords[0].Start_Date__c, 'Start date should be populated');
        System.assertNotEquals(null, newRecords[0].End_Date__c, 'End date should be populated');
    }

    @isTest
    static void testUpdateStartAndEndDate_UpdateScenario() {
        Service_Goal__c sg = new Service_Goal__c(
            Financial_Year__c = 'FY 2024-2025',
            Start_Date__c = null,
            End_Date__c = null
        );
        insert sg;

        Map<Id, Service_Goal__c> oldMap = new Map<Id, Service_Goal__c>{
            sg.Id => sg
        };

        sg.Financial_Year__c = 'FY 2024-2025';
        update sg;

        List<Service_Goal__c> updatedList = [SELECT Id, Financial_Year__c, Start_Date__c, End_Date__c FROM Service_Goal__c WHERE Id = :sg.Id];

        Test.startTest();
        ServiceGoalTriggerHandler.updateStartAndEndDate(updatedList, oldMap);
        Test.stopTest();

        System.assertNotEquals(null, updatedList[0].Start_Date__c, 'Start date should be updated');
        System.assertNotEquals(null, updatedList[0].End_Date__c, 'End date should be updated');
    }

   @isTest
static void testServiceGoalTrigger_InsertAndUpdate_WithSharing() {
    User u = new User(
        Username = 'testuse' +  Math.floor(Math.random() * 1000000) + '@example.com',
        Alias = 'testuser',
        Email = 'testuser@example.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'User',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
        TimeZoneSidKey = 'Asia/Kolkata'
    );
    insert u;

    Service_Resource__c sr = new Service_Resource__c(User__c = u.Id);
    insert sr;

    Service_Goal__c sg = new Service_Goal__c(
        Financial_Year__c = 'FY 2024-2025',
        Service_Resource__c = sr.Id
    );

    Test.startTest();
    insert sg;

    sg.Financial_Year__c = 'FY 2025-2026';
    update sg;
    Test.stopTest();

    List<Service_Goal__Share> shares = [
        SELECT Id, UserOrGroupId, ParentId
        FROM Service_Goal__Share
        WHERE ParentId = :sg.Id
    ];
    
}

}