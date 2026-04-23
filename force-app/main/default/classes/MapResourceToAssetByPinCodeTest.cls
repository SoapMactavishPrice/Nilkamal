@isTest
public class MapResourceToAssetByPinCodeTest {

    @isTest
    static void testBatchExecution() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1];

        User serHeadUser = new User(
            Alias = 'serhead',
            Email = 'nilesh.patil@nilkamal.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Service Head',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'serheaduser' + DateTime.now().getTime() + '@example.com'
        );
        User seUser = new User(
            Alias = 'tuser1',
            Email = 'tuser1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'tuser1' + DateTime.now().getTime() + '@example.com'
        );
        User rsmUser = new User(
            Alias = 'rsmusr',
            Email = 'rsm@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'RSM',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'rsmuser' + DateTime.now().getTime() + '@example.com'
        );
        User coordUser = new User(
            Alias = 'coord',
            Email = 'coord@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Coordinator',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'coorduser' + DateTime.now().getTime() + '@example.com'
        );

        User integrationUser = new User(
            Alias = 'int',
            Email = 'integration@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Integration',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'integrationuser' + DateTime.now().getTime() + '@example.com'
        );

        insert new List<User>{seUser, rsmUser, coordUser, serHeadUser, integrationUser};


        Pin_Code_Master__c pinCode1 = new Pin_Code_Master__c(Name = '400001');
        Pin_Code_Master__c pinCode2 = new Pin_Code_Master__c(Name = '400002');
        Pin_Code_Master__c pinCode3 = new Pin_Code_Master__c(Name = '400003');
        Pin_Code_Master__c pinCode4 = new Pin_Code_Master__c(Name = '400004');
        insert new List<Pin_Code_Master__c>{pinCode1, pinCode2, pinCode3, pinCode4};


        Service_Resource__c srHead = new Service_Resource__c(
            Name = 'Service Head',
            User__c = serHeadUser.Id,
            isActive__c = true,
            Role__c = 'Service Head'
        );
        Service_Resource__c srCoord = new Service_Resource__c(
            Name = 'Coordinator',
            User__c = coordUser.Id,
            isActive__c = true,
            Role__c = 'Coordinator',
            RSM__c = rsmUser.Id
        );
        Service_Resource__c srRSM = new Service_Resource__c(
            Name = 'RSM',
            User__c = rsmUser.Id,
            isActive__c = true,
            Role__c = 'RSM',
            Coordinator__c = coordUser.Id
        );
        Service_Resource__c srEng = new Service_Resource__c(
            Name = 'Service Engg',
            User__c = seUser.Id,
            isActive__c = true,
            Role__c = 'Service Engineer',
            RSM__c = rsmUser.Id,
            Coordinator__c = coordUser.Id
        );
        insert new List<Service_Resource__c>{srHead, srCoord, srRSM, srEng};


        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c(
            Pin_Code_Master__c = pinCode1.Id,
            Service_Resource__c = srEng.Id,
            Is_Active__c = true
        );
        Service_Resource_Pincode__c srpRSM = new Service_Resource_Pincode__c(
            Pin_Code_Master__c = pinCode2.Id,
            Service_Resource__c = srRSM.Id,
            Is_Active__c = true
        );
        Service_Resource_Pincode__c srpCoord = new Service_Resource_Pincode__c(
            Pin_Code_Master__c = pinCode3.Id,
            Service_Resource__c = srCoord.Id,
            Is_Active__c = true
        );
        insert new List<Service_Resource_Pincode__c>{srp, srpRSM, srpCoord};


        Asset asset = new Asset(
            Name = 'Test Asset',
            Pin_Code_Master__c = pinCode1.Id,
            Business_Vertical__c = 'MHE',
            Service_Engineer_Pincode_based__c = srCoord.Id,
            OwnerId = integrationUser.Id
        );
        Asset asset2 = new Asset(
            Name = 'Test Asset2',
            Pin_Code_Master__c = pinCode2.Id,
            Business_Vertical__c = 'MHE',
            OwnerId = integrationUser.Id
        );
        Asset asset3 = new Asset(
            Name = 'Test Asset3',
            Pin_Code_Master__c = pinCode3.Id,
            Business_Vertical__c = 'MHE',
            OwnerId = integrationUser.Id
        );
        Asset asset4 = new Asset(
            Name = 'Test Asset4',
            Pin_Code_Master__c = pinCode4.Id,
            Business_Vertical__c = 'MHE',
            OwnerId = integrationUser.Id
        );
        Asset asset5 = new Asset(
            Name = 'Test Asset5',
            Pin_Code_Master__c = pinCode4.Id,
            Business_Vertical__c = 'MHE',
            Service_Engineer_Pincode_based__c = srEng.Id,
            RSM_Pincode_based__c = srRSM.Id,
            Coordinator_Pincode_based__c = srCoord.Id,
            OwnerId = integrationUser.Id
        );
        insert new List<Asset>{asset, asset2, asset3, asset4, asset5};


        Asset_Warranty__c aw = new Asset_Warranty__c(
            Asset__c = asset.Id,
            Asset_Warranty_PO_Status__c = 'Active',
            Warranty_Start_Date__c = Date.today(),
            Warranty_End_Date__c = Date.today().addDays(5),
            Warranty_Period__c = 12
        );
        insert aw;
        Asset_AMC__c amc = new Asset_AMC__c(
            Asset__c = asset.Id,
            Asset_AMC_PO_Status__c = 'Active',
            AMC_Start_Date__c = Date.today(),
            AMC_End_Date__c = Date.today().addDays(5),
            AMC_Period_In_Months__c = 12,
            Product_Category_Type__c = 'AMC'
        );
        insert amc;


        Test.startTest();
        String cronExp = '0 0 * * 1-7 ? *';
        String jobId = System.schedule('Test Scheduled Job', cronExp, new MapResourceToAssetByPinCode());
        MapResourceToAssetByPinCode.mapResourcesToAssets(new Set<Id>{asset.Id});
        Test.stopTest();

    }

}