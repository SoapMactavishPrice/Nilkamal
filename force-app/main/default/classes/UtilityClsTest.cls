@isTest
private class UtilityClsTest {

    @isTest
    public static void testGetAllFields() {
        Map<String, String> result1 = UtilityCls.getAllFields('Account');
        Map<String, String> result2 = UtilityCls.getAllFields('InvalidObject');
    }

    @isTest
    public static void testGetPickList() {
        Map<String,String> result = UtilityCls.getPickList('Account', 'Type');
    }

    @isTest
    public static void testGetFilterValues() {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Object result1 = UtilityCls.getFilterValues('Account', new List<String>{'OwnerId', 'Type', 'CreatedDate', 'Name', 'Parent.Type'}, '');

        Object result2 = UtilityCls.getFilterValues('Checklist_Master__c', new List<String>{'isActive__c'}, 'WHERE Name = \'Test Account\'');

        try {
            Object result3 = UtilityCls.getFilterValues('Account', new List<String>{'InvalidField'}, '');
        }
        catch (Exception e) { }

        try {
            Object result4 = UtilityCls.getFilterValues('Account', new List<String>{'Parent.InvalidField'}, '');
        }
        catch (Exception e) { }

        try {
            Object result5 = UtilityCls.getFilterValues('Account', new List<String>{'InvalidRelationship.InvalidField'}, '');
        }
        catch (Exception e) { }
    }

    @isTest
    public static void testGetUserIdsReportingToMe() {
        User user = new User();
        user.FirstName = 'Test';
        user.LastName = 'User';
        user.Alias = 'test';
        user.TimeZoneSidKey = 'Asia/Kolkata';
        user.LocaleSidKey = 'en_IN';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.Username = 'test' + Math.random() + '@gmail.com';
        user.Email = 'test' + Math.random() + '@gmail.com';
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'RSM'].Id;
        user.ManagerId = UserInfo.getUserId();
        insert user;

        Set<Id> result = UtilityCls.getUserIdsReportingToMe();
    }

    @isTest
    public static void testGetCurrentFYDetails() {
        Map<String, Object> result = UtilityCls.getCurrentFYDetails();
    }

    @isTest
    public static void testGetStartEndDateFromFYName() {
        Map<String, Object> result1 = UtilityCls.getCurrentFYDetails();
        Map<String, Date> result2 = UtilityCls.getStartEndDateFromFYName(String.valueOf(result1.get('fyName')));
    }

    @isTest
    public static void testGetPincodeListAssignedToMe() {
        Service_Resource__c sr = new Service_Resource__c();
        sr.User__c = UserInfo.getUserId();
        sr.Role__c = 'Service Engineer';
        sr.IsActive__c = true;
        insert sr;

        Pin_Code_Master__c pin = new Pin_Code_Master__c();
        pin.Name = '400001';
        insert pin;

        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c();
        srp.Service_Resource__c = sr.Id;
        srp.Pin_Code_Master__c = pin.Id;
        insert srp;

        Set<Id> result = UtilityCls.getPincodeListAssignedToMe();
    }

    @isTest
    public static void testGetRSMWisePincodeList() {
        User user = new User();
        user.FirstName = 'Test';
        user.LastName = 'User';
        user.Alias = 'test';
        user.TimeZoneSidKey = 'Asia/Kolkata';
        user.LocaleSidKey = 'en_IN';
        user.EmailEncodingKey = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';
        user.Username = 'test' + Math.random() + '@gmail.com';
        user.Email = 'test' + Math.random() + '@gmail.com';
        user.ProfileId = [SELECT Id FROM Profile WHERE Name = 'RSM'].Id;
        user.ManagerId = UserInfo.getUserId();
        insert user;

        Service_Resource__c sr = new Service_Resource__c();
        sr.User__c = UserInfo.getUserId();
        sr.Role__c = 'Service Engineer';
        sr.IsActive__c = true;
        insert sr;

        Pin_Code_Master__c pin = new Pin_Code_Master__c();
        pin.Name = '400001';
        insert pin;

        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c();
        srp.Service_Resource__c = sr.Id;
        srp.Pin_Code_Master__c = pin.Id;
        insert srp;

        Map<Id, Set<Id>> result = UtilityCls.getRSMWisePincodeList();
    }

    @isTest
    public static void testGetUserDetails() {
        User result = UtilityCls.getUserDetails();
    }

    @isTest
    public static void testGetNumberToWordsINR() {
        String result = UtilityCls.getNumberToWordsINR(123456789);
    }

    @isTest
    public static void testGetNumberToWordsLongNumberINR() {
        String result = UtilityCls.getNumberToWordsLongNumberINR(12345678901234510.0);
    }

}