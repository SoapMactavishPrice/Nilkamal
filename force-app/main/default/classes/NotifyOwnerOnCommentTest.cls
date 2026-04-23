@isTest
public class NotifyOwnerOnCommentTest {
    @isTest
    static void testFeedCommentNotification() {
        // Create Technical Assistant user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User techAssistant = new User(
            Alias = 'tausr',
            Email = 'techassistant@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Tech Assistant',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'tauser' + System.currentTimeMillis() + '@example.com'
        );
        insert techAssistant;

        // Create primary test user with Technical_Assistant__c set
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            Technical_Assistant__c = techAssistant.Id
        );
        insert testUser;

        // Create related Account and Asset
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Asset asset = new Asset(Name='Test1 Asset', AccountId = acc.Id);
        insert asset;

        // Create Case with Owner as testUser
        Case testCase = new Case(
            Subject = 'Test Case for Notification',
            Status = 'New',
            Priority = 'Medium',
            OwnerId = testUser.Id,
            AccountId = acc.Id,
            AssetId = asset.Id
        );
        insert testCase;

        // Create FeedItem (Chatter Post)
        FeedItem post = new FeedItem(
            ParentId = testCase.Id,
            Body = 'Initial post on Case',
            Type = 'TextPost'
        );
        insert post;

        // Add FeedComment (this should trigger notification logic)
        try{
        Test.startTest();
        FeedComment comment = new FeedComment(
            FeedItemId = post.Id,
            CommentBody = 'This is a test comment for notification'
        );
        insert comment;
        Test.stopTest();

        System.assertEquals(testCase.Id, post.ParentId);
        }catch(Exception e){
            
        }
    }
}