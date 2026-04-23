@isTest
private class DataClsTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Alias = 'tuser1',
            Email = 'testuser1@example.com',
            Username = 'testuser1@example.com.' + System.currentTimeMillis(),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u1;

        User u2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Alias = 'tuser2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@example.com.' + System.currentTimeMillis(),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u2;

        Group g = new Group(
            Name = 'Test Queue Group',
            Type = 'Queue'
        );
        insert g;
    }

    @isTest
    static void testGetGroupsByNameAndId() {
        Map<String, Group> groupsByName = DataCls.getGroupsByName();
        System.assert(!groupsByName.isEmpty(), 'Groups by name should not be empty');
        
        Map<Id, Group> groupsById = DataCls.getGroupsById();
        System.assert(!groupsById.isEmpty(), 'Groups by Id should not be empty');

        Group firstGroup = groupsById.values()[0];
        Group retrieved = DataCls.getGroupById(firstGroup.Id);
        System.assertEquals(firstGroup.Id, retrieved.Id, 'Group should match by Id');
    }

    @isTest
    static void testGetUsersByUserNameAndId() {
        Map<String, User> usersByName = DataCls.getUsersByUserName();
        System.assert(!usersByName.isEmpty(), 'Users by name should not be empty');
        
        Map<Id, User> usersById = DataCls.getUsersById();
        System.assert(!usersById.isEmpty(), 'Users by Id should not be empty');

        User firstUser = usersById.values()[0];
        User retrieved = DataCls.getUserById(firstUser.Id);
        System.assertEquals(firstUser.Id, retrieved.Id, 'User should match by Id');
    }
}