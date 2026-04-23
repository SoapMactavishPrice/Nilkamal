@IsTest
public class FieldServiceItemsToApproveControllerTest {
    
    @TestSetup
    static void setupData() {
        Sequence_Master__c seq = new Sequence_Master__c(
            format__c = '00000',
            Starting_Number__c = 1,
            Current_Sequence_No__c = 0
        );
        insert seq;

        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOpp;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User approverUser = new User(
            FirstName = 'Approver',
            LastName = 'User',
            Email = 'approver' + DateTime.now().getTime() + '@test.com',
            Username = 'approver' + DateTime.now().getTime() + '@test.com',
            Alias = 'apprv',
            CommunityNickname = 'apprv' + DateTime.now().getTime(),  // required
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert approverUser;
        
        Profile pb= [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

User delegatedUser = new User(
    FirstName = 'Delegate',
    LastName = 'User',
    Email = 'delegate' + DateTime.now().getTime() + '@test.com',
    Username = 'delegate' + DateTime.now().getTime() + '@test.com',
    Alias = 'delg',
    CommunityNickname = 'delg' + DateTime.now().getTime(),
    ProfileId = pb.Id,
    TimeZoneSidKey = 'Asia/Kolkata',
    LocaleSidKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LanguageLocaleKey = 'en_US',
    DelegatedApproverId = UserInfo.getUserId()
);
insert delegatedUser;


        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Status = 'Draft',
            Approver__c = approverUser.Id   
        );
        insert q;
        
    }
    
    @IsTest
    static void testGetItemsToApprove() {
        Test.startTest();
        Object result = FieldServiceItemsToApproveController.getItemsToApprove(0, 10, 'CreatedDate', 'DESC');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }
}