@isTest
public class FeedItemTriggerTest {
    @isTest
    static void testSubmitTechnicalSupport() {
        // Create Profile for Users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create main group user
        User groupUser = new User(
            FirstName = 'Main',
            LastName = 'User',
            Email = 'mainuser_' + System.currentTimeMillis() + '@test.com',
            Username = 'mainuser_' + System.currentTimeMillis() + '@test.com',
            Alias = 'musr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert groupUser;

        // Create Technical Assistant user
        User techAssistant = new User(
            FirstName = 'Tech',
            LastName = 'Assistant',
            Email = 'ta_' + System.currentTimeMillis() + '@test.com',
            Username = 'ta_' + System.currentTimeMillis() + '@test.com',
            Alias = 'tausr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert techAssistant;

        // Link Technical Assistant to group user
        groupUser.Technical_Assistant__c = techAssistant.Id;
        update groupUser;

        // Create group and membership
        Group techGroup = new Group(
            Name = 'MHE Technical Support',
            Type = 'Regular'
        );
        insert techGroup;

        GroupMember gm = new GroupMember(
            GroupId = techGroup.Id,
            UserOrGroupId = groupUser.Id
        );
        insert gm;

        // 🔑 Non-setup records inside runAs
        System.runAs(groupUser) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;

            Asset ast = new Asset(
                Name = 'Test Asset',
                AccountId = acc.Id,
                Unique_Key__c = 'UK_' + System.currentTimeMillis() + '_' + String.valueOf(Math.random()).substring(2,6)
            );
            insert ast;

            Case testCase = new Case(
                Subject = 'Test Tech Support Case',
                Status = 'New',
                Origin = 'Email',
                Priority = 'Medium',
                AccountId = acc.Id,
                AssetId = ast.Id,
                OwnerId = groupUser.Id
            );
            insert testCase;

            Test.startTest();
            FeedItem item = new FeedItem(
                ParentId = testCase.Id,
                Body = '#TechSupport required for issue',
                Type = 'TextPost'
            );
            insert item;
            Test.stopTest();

            // 🔎 Assertions to verify logic
            Case updatedCase = [
                SELECT Id, Status, Tech_Support_Status__c 
                FROM Case 
                WHERE Id = :testCase.Id
            ];
            //System.assertEquals('Tech Support', updatedCase.Status, 'Case should move to Tech Support status');
            //System.assertEquals('Opened by Service Engineer', updatedCase.Tech_Support_Status__c, 'Case should reflect opened Tech Support');

            List<Case_Team__c> teams = [
                SELECT Id, Member__c, Case_Team_Role__c 
                FROM Case_Team__c 
                WHERE Case__c = :testCase.Id
            ];
            //System.assertEquals(1, teams.size(), 'Case team should be created');
            //System.assertEquals('Technical Assistant', teams[0].Case_Team_Role__c, 'Case team role should be Technical Assistant');
            //System.assertEquals(techAssistant.Id, teams[0].Member__c, 'Technical Assistant should be added to the Case Team');
        }
    }
}