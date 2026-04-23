@isTest
public class ServiceResourcePincodeTriggerTest {
    
    @isTest
    public static void test1() {
        Service_Resource__c sr = new Service_Resource__c();
        sr.User__c = UserInfo.getUserId();
        insert sr;
        
        Pin_Code_Master__c pin = new Pin_Code_Master__c();
        pin.Name = '123456';
        insert pin;
        
        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c();
        srp.Pin_Code_Master__c = pin.Id;
        srp.Service_Resource__c = sr.Id;
        insert srp;
    }
    
}