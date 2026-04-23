/**
 * @description
 * @author Aditya Zagade
 * @since 7 Feb 2025
 * @Created the class and added the logic for getting data of groups and users
 * @group Utility
 */
public with sharing class DataCls {

    private static List<Group> groups;
    private static List<User> users;



    /**
     * @description Method to get groups by Name
     * @return  `Map<String, Group>`
     * @example
     * Map<String, Group> groups = DataCls.getGroupsByName();
     */
    public static Map<String, Group> getGroupsByName() {
        initializeGroups();
        Map<String, Group> groupsByName = new Map<String, Group>();
        for(Group q : groups) {
            groupsByName.put(q.Name, q);
        }
        return groupsByName;
    }

    /**
     * @description Method to get groups by Id
     * @return  `Map<Id, Group>`
     * @example
     * Map<Id, Group> groups = DataCls.getGroupsById();
     */
    public static Map<Id, Group> getGroupsById() {
        initializeGroups();
        Map<Id, Group> groupsById = new Map<Id, Group>();
        for(Group q : groups) {
            groupsById.put(q.Id, q);
        }
        return groupsById;
    }

    /**
     * @description Method to get single group by Id
     * @param groupId
     * @return  `Group`
     * @example
     * Group group = DataCls.getGroupById('00G0Z00000WwBmE');
     */
    public static Group getGroupById(String groupId) {
        Map<Id, Group> groupMap = getGroupsById();
        return groupMap.get(groupId);
    }


    /**
     * @description Method to get users by UserName
     * @return  `Map<String, User>`
     * @example
     * Map<String, User> users = DataCls.getUsersByUserName();
     */
    public static Map<String, User> getUsersByUserName() {
        initializeUsers();
        Map<String, User> usersByName = new Map<String, User>();
        for(User u : users) {
            usersByName.put(u.Name, u);
        }
        return usersByName;
    }

    /**
     * @description Method to get users by Id
     * @return  `Map<Id, User>`
     * @example
     * Map<Id, User> users = DataCls.getUsersById();
     */
    public static Map<Id, User> getUsersById() {
        initializeUsers();
        Map<Id, User> usersById = new Map<Id, User>();
        for(User u : users) {
            usersById.put(u.Id, u);
        }
        return usersById;
    }

    /**
     * @description Method to get single user by Id
     * @param userId
     * @return  `User`
     * @example
     * User user = DataCls.getUserById('0050Z00000WwBmE');
     */
    public static User getUserById(String userId) {
        Map<Id, User> userMap = getUsersById();
        return userMap.get(userId);
    }
















    /**
     * @description Method to initialize groups
     * @return null
     * @example
     * DataCls.initializeGroups();
     */
    private static void initializeGroups() {
        if(groups == null) {
            groups = [SELECT Id, Name FROM Group WHERE Type = 'Queue'];
        }
    }

    /**
     * @description Method to initialize users
     * @return null
     * @example
     * DataCls.initializeUsers();
     */
    private static void initializeUsers() {
        if(users == null) {
            users = [
                SELECT Id, Name, FirstName, LastName, Username, Email, ProfileId, Profile.Name, UserRoleId, UserRole.Name, ManagerId, Sales_Group__c
                FROM User
                WHERE IsActive = true
            ];
        }
    }

}