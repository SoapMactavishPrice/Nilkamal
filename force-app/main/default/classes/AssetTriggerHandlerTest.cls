@isTest
public class AssetTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Id serviceEngineerProfileId;
        Id rsmProfileId;
        Id coordProfileId;
        Id serviceHeadProfileId;

        for(Profile p : [SELECT Id, Name FROM Profile WHERE Name IN ('Service Engineer', 'RSM', 'Coordinator', 'Service Head')]) {
            if(p.Name == 'Service Engineer') {
                serviceEngineerProfileId = p.Id;
            }
            else if(p.Name == 'RSM') {
                rsmProfileId = p.Id;
            }
            else if(p.Name == 'Coordinator') {
                coordProfileId = p.Id;
            }
            else if(p.Name == 'Service Head') {
                serviceHeadProfileId = p.Id;
            }
        }

        Id serviceEngineerRoleId;
        Id rsmRoleId;
        Id coordRoleId;
        Id serviceHeadRoleId;

        for(UserRole ur : [SELECT Id, Name FROM UserRole WHERE Name IN ('Service Engineer MHE 1', 'RSM MHE 1', 'Coordinator MHE 1', 'Service Head MHE')]) {
            if(ur.Name == 'Service Engineer MHE 1') {
                serviceEngineerRoleId = ur.Id;
            }
            else if(ur.Name == 'RSM MHE 1') {
                rsmRoleId = ur.Id;
            }
            else if(ur.Name == 'Coordinator MHE 1') {
                coordRoleId = ur.Id;
            }
            else if(ur.Name == 'Service Head MHE') {
                serviceHeadRoleId = ur.Id;
            }
        }

        User serviceEngineerUser = new User(
            FirstName = 'Engineer',
            LastName = 'Old',
            Email = 'engineer.old@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'eold',
            ProfileId = serviceEngineerProfileId,
            UserRoleId = serviceEngineerRoleId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        User rsmUser = new User(
            FirstName = 'RSM',
            LastName = 'Old',
            Email = 'rsm.old@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'rold',
            ProfileId = rsmProfileId,
            UserRoleId = rsmRoleId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        User coordUser = new User(
            FirstName = 'Coordinator',
            LastName = 'Old',
            Email = 'coord.old@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'coold',
            ProfileId = coordProfileId,
            UserRoleId = coordRoleId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        User serviceHeadUser = new User(
            FirstName = 'Service Head',
            LastName = 'Old',
            Email = 'serviceHead.old@example.com',
            Username = 'test' + Math.random() + '@gmail.com',
            Alias = 'shold',
            ProfileId = serviceHeadProfileId,
            UserRoleId = serviceHeadRoleId,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{ serviceEngineerUser, rsmUser, coordUser, serviceHeadUser };
    }


    @isTest
    static void testUpdateSerialNumber() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Product2 p = new Product2(Name = 'Test Product', isActive = true);
        insert p;

        Asset asset = new Asset(
            Name = 'OldSerial',
            AccountId = acc.Id,
            Product2Id = p.Id,
            Status = 'Purchased',
            //AssetLevel = 'Level 1',
            Type__c = 'Within Warranty'
        );
        insert asset;

        Case cs = new Case(
            AccountId = acc.Id,
            AssetId = asset.Id,
            Status = 'New'
        );
        insert cs;

        Map<Id, Asset> oldMap = new Map<Id, Asset>([SELECT Id, Name, SerialNumber, Type__c FROM Asset WHERE Id = :asset.Id]);

        asset.Name = 'NewSerial';
        asset.Type__c = 'Scraped';

        Test.startTest();
        try {
            update asset;
            System.assert(false, 'Expected validation error due to open case was not thrown');
        }
        catch (DmlException e) {
            System.assert(e.getMessage().contains('Case is open you can not make it as Scraped'), 'Expected validation error not found');
        }
        Test.stopTest();
    }


    @isTest
    static void testUpdateBusinessVertical() {
        Pin_Code_Master__c pinCode = new Pin_Code_Master__c(Name = '123456');
        insert pinCode;

        Account acc = new Account(Name = 'Test Account', Business_Vertical__c = 'MHE', Pin_Code__c = pinCode.Id);
        insert acc;
        system.debug('acc'+acc);

        Product2 product = new Product2(Name = 'Test Product', Business_Vertical__c = 'MHE',Material_Group_6__c = 'B35');
        insert product;

        Asset asset = new Asset(Name = 'Test Asset', Product2Id = product.Id);
        insert asset;

        AssetTriggerHandler.updateAssetBusinessVertical(new List<Asset>{ asset });

        Asset updatedAsset = [SELECT Business_Vertical__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals('MHE', updatedAsset.Business_Vertical__c);
    }


    @isTest
    static void testCreateCase() {
        Pin_Code_Master__c custPin = new Pin_Code_Master__c(Name = '111111', Region__c='North');
        insert custPin;

        Account acc = new Account(
            Name = 'Customer Account',
            Pin_Code__c = custPin.Id,
            Business_Vertical__c = 'MHE'
        );
        insert acc;

        Account endCus = new Account(
            Name = 'Customer Account2'
        );
        insert endCus;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'testcontact@test.com'
        );
        insert con;

        Product2 prod = new Product2(
            Name = 'Test Product',
            Installation_Required__c = 'Yes',
            Business_Vertical__c = 'MHE',
            Material_Group_6__c = 'B35'
        );
        insert prod;

        MG6_Mapping__mdt mapping = [
            SELECT Id, DeveloperName, MG6_Type__c, Installation_Required__c
            FROM MG6_Mapping__mdt
            WHERE MG6_Type__c = 'B35'
        ];

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        system.debug('pppp'+p);

        User engUser = new User(
            Username = 'enguser' + System.currentTimeMillis() + '@test.com',
            Alias = 'engusr',
            Email = 'enguser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'Engineer',
            FirstName = 'Test',
            isActive = true
        );
        insert engUser;

        User rsmUser = new User(
            Username = 'rsmuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'rsmusr',
            Email = 'rsmuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'RSM',
            FirstName = 'Test',
            isActive = true
        );
        insert rsmUser;

        Service_Resource__c sr = new Service_Resource__c(
            Name = 'Engineer SR',
            Business_Vertical__c = 'MHE',
            isActive__c = true,
            User__c = engUser.Id,
            RSM__c = rsmUser.Id,
            Role__c = 'Service Engineer'
        );
        insert sr;

        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c(
            Pin_Code_Master__c = custPin.Id,
            Service_Resource__c = sr.Id,
            Is_Active__c = true
        );
        insert srp;

        Group openQueue = new Group(Name = 'Open Queue', Type = 'Queue');
        insert openQueue;

        Asset asset1 = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            End_Customer__c = endCus.Id,
            ContactId = con.Id,
            Product2Id = prod.Id,
            Type__c = 'Within AMC',
            Business_Vertical__c = 'MHE',
            Pin_Code_Master__c = custPin.Id,
            PurchaseDate = Date.today().addDays(1), // > cutoff
            Status = 'Purchased',
            CurrencyIsoCode = 'INR'
            //Territory_Master__c = 'North' // required custom field
        );
        insert asset1;

        system.debug('asset'+asset1);

        Case c = new Case(
            Status = 'New',
            Subject = 'Test Case',
            AccountId = acc.Id ,
            AssetId = asset1.Id
        );
        insert c;

        c.Status = 'Closed';
        c.IsClosingFromCustomUI__c = true;
        update c;

        Test.startTest();
        AssetTriggerHandler.createCase(new List<Asset>{ asset1 });
        Test.stopTest();

        List<Case> cases = [SELECT Id, Status, OwnerId, Type FROM Case WHERE AssetId = :asset1.Id];
        System.assert(cases.size() > 0, 'Case should be created for Asset');
    }


    @isTest
    static void testCreateCaseWithShipToPinAndServiceResources() {
        Pin_Code_Master__c shipToPin = new Pin_Code_Master__c(Name = '999999', Region__c = 'North');
        insert shipToPin;

        Account acc = new Account(Name = 'Customer Account 2');
        insert acc;

        Product2 prod = new Product2(Name = 'Product A', Installation_Required__c = 'Yes', Business_Vertical__c = 'MHE', Material_Group_6__c = 'B35');
        insert prod;

        MG6_Mapping__mdt mapping = [
            SELECT Id, DeveloperName, MG6_Type__c, Installation_Required__c
            FROM MG6_Mapping__mdt
            WHERE MG6_Type__c = 'B35'
        ];

        User engUser = new User(
            Username = 'engineeruser@test.com',
            Alias = 'engusr',
            Email = 'enguser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'Engineer',
            isActive = true
        );
        insert engUser;

        User rsmUser = new User(
            Username = 'rsmuser@test.com',
            Alias = 'rsmusr',
            Email = 'rsmuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'RSM',
            isActive = true
        );
        insert rsmUser;

        Service_Resource__c serviceResource = new Service_Resource__c(
            Name = 'Engineer SR',
            Business_Vertical__c = 'MHE',
            isActive__c = true,
            User__c = engUser.Id,
            RSM__c = rsmUser.Id,
            Role__c = 'Service Engineer'
        );
        insert serviceResource;

        Service_Resource_Pincode__c srp = new Service_Resource_Pincode__c(
            Pin_Code_Master__c = shipToPin.Id,
            Service_Resource__c = serviceResource.Id,
            Is_Active__c = true
        );
        insert srp;

        Asset asset = new Asset(
            Name = 'Asset A',
            AccountId = acc.Id,
            Product2Id = prod.Id,
            Type__c = 'Within AMC',
            Business_Vertical__c = 'MHE',
            Pin_Code_Master__c = shipToPin.Id,
            Status = 'Purchased'
        );
        try {
        insert asset;
        }
        catch(Exception e) { }


        Case cs = new Case(AccountId = acc.Id, AssetId = asset.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id);
        insert wo;

        Group openQueue = new Group(Name = 'Open Queue', Type = 'Queue');
        insert openQueue;

        Test.startTest();
        AssetTriggerHandler.createCase(new List<Asset>{ asset });
        Test.stopTest();
    }


    @isTest
    static void testUpdateShipToPinCode() {
        Pin_Code_Master__c pin = new Pin_Code_Master__c(Name = '999999', Region__c = 'TestRegion');
        insert pin;

        Account acc = new Account(Name = 'Test Account', Pin_Code__c = pin.Id);
        insert acc;

        Product2 product = new Product2(Name = 'Test Product', Business_Vertical__c = 'MHE');
        insert product;

        Asset asset = new Asset(
            Name = 'Test Asset'
        );
        insert asset;

        Map<Id, Asset> oldMap = new Map<Id, Asset>{ asset.Id => asset.clone(false, true) };

        asset.Ship_to_Pin__c = '999999';
        asset.SerialNumber = 'NK000000';
        asset.Unique_Key__c = 'Test';

        update asset;

        AssetTriggerHandler.updateShipToPinCode(new List<Asset>{ asset }, oldMap);

        Asset updatedAsset = [SELECT Pin_Code_Master__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(pin.Id, updatedAsset.Pin_Code_Master__c, 'Pin_Code_Master__c should be set to matching Pin Code record');
    }


    @isTest
    static void testHandleAssetSharing() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Service Engineer' LIMIT 1];

        User serviceEngUser = new User(
            Username = 'se' + System.currentTimeMillis() + '@test.com',
            Alias = 'seusr',
            Email = 'se@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'SEUser'
        );
        insert serviceEngUser;

        User rsmUser = new User(
            Username = 'rsm' + System.currentTimeMillis() + '@test.com',
            Alias = 'rsmusr',
            Email = 'rsm@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'RSMUser'
        );
        insert rsmUser;

        User coordUser = new User(
            Username = 'coord' + System.currentTimeMillis() + '@test.com',
            Alias = 'coo',
            Email = 'coord@test.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            LastName = 'CoordUser'
        );
        insert coordUser;

        Service_Resource__c srEng = new Service_Resource__c(Name = 'Engineer', User__c = serviceEngUser.Id);
        Service_Resource__c srRsm = new Service_Resource__c(Name = 'RSM', User__c = rsmUser.Id);
        Service_Resource__c srCoord = new Service_Resource__c(Name = 'Coordinator', User__c = coordUser.Id);
        insert new List<Service_Resource__c>{ srEng, srRsm, srCoord };

        Account acc = new Account(Name = 'Customer Account 2');
        insert acc;

        Asset testAsset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            Status = 'Purchased'
        );
        insert testAsset;

        Asset oldAsset = testAsset.clone(false, true, false, false);
        oldAsset.Service_Engineer_Pincode_based__c = null;
        oldAsset.RSM_Pincode_based__c = null;
        oldAsset.Coordinator_Pincode_based__c = null;

        testAsset.Service_Engineer_Pincode_based__c = srEng.Id;
        testAsset.RSM_Pincode_based__c = srRsm.Id;
        testAsset.Coordinator_Pincode_based__c = srCoord.Id;

        Test.startTest();
        AssetTriggerHandler.handleAssetSharing(new List<Asset>{ testAsset }, new Map<Id, Asset>{ testAsset.Id => oldAsset });
        Test.stopTest();
    }


    @isTest
    public static void testOwnerChange() {
        User serviceEngineerUser;
        User rsmUser;
        User coordUser;
        User serviceHeadUser;

        for(User u : [SELECT Id, Profile.Name, IsActive FROM User WHERE Profile.Name IN ('Service Engineer', 'RSM', 'Coordinator', 'Service Head') AND Email LIKE '%example%']) {
            if(u.Profile.Name == 'Service Engineer') {
                serviceEngineerUser = u;
            }
            else if(u.Profile.Name == 'RSM') {
                rsmUser = u;
            }
            else if(u.Profile.Name == 'Coordinator') {
                coordUser = u;
            }
            else if(u.Profile.Name == 'Service Head') {
                serviceHeadUser = u;
            }
        }

        Service_Resource__c srEng = new Service_Resource__c(Name = 'Engineer', User__c = serviceEngineerUser.Id, RSM__c = rsmUser.Id, Coordinator__c = coordUser.Id, Role__c = 'Service Engineer');
        Service_Resource__c srRsm = new Service_Resource__c(Name = 'RSM', User__c = rsmUser.Id, Coordinator__c = coordUser.Id, Role__c = 'RSM');
        Service_Resource__c srCoord = new Service_Resource__c(Name = 'Coordinator', User__c = coordUser.Id, Role__c = 'Coordinator');
        Service_Resource__c srSh = new Service_Resource__c(Name = 'Service Head', User__c = serviceHeadUser.Id, Role__c = 'Service Head');
        insert new List<Service_Resource__c>{ srEng, srRsm, srCoord, srSh };


        Account acc = new Account(Name = 'Customer Account 2');
        insert acc;

        Asset asset = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id,
            Status = 'Purchased'
        );
        insert asset;

        Asset_Warranty__c aw = new Asset_Warranty__c(Asset__c = asset.Id, Warranty_Start_Date__c = System.today(), Warranty_Period__c = 12);
        insert aw;

        Asset_AMC__c amc = new Asset_AMC__c(Asset__c = asset.Id, AMC_Start_Date__c = System.today(), AMC_Period_In_Months__c = 12, Product_Category_Type__c = 'AMC');
        insert amc;


        Test.startTest();

        asset.OwnerId = serviceEngineerUser.Id;
        update asset;

        asset = [SELECT OwnerId, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c FROM Asset WHERE Id = :asset.Id];
        System.debug(JSON.serialize(asset));
        Assert.areEqual(srEng.Id, asset.Service_Engineer_Pincode_based__c);
        Assert.areEqual(srRsm.Id, asset.RSM_Pincode_based__c);
        Assert.areEqual(srCoord.Id, asset.Coordinator_Pincode_based__c);


        asset.OwnerId = rsmUser.Id;
        update asset;

        asset = [SELECT OwnerId, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c FROM Asset WHERE Id = :asset.Id];
        System.debug(JSON.serialize(asset));
        Assert.isNull(asset.Service_Engineer_Pincode_based__c);
        Assert.areEqual(srRsm.Id, asset.RSM_Pincode_based__c);
        Assert.areEqual(srCoord.Id, asset.Coordinator_Pincode_based__c);


        asset.OwnerId = coordUser.Id;
        update asset;

        asset = [SELECT OwnerId, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c FROM Asset WHERE Id = :asset.Id];
        System.debug(JSON.serialize(asset));
        Assert.isNull(asset.Service_Engineer_Pincode_based__c);
        Assert.isNull(asset.RSM_Pincode_based__c);
        Assert.areEqual(srCoord.Id, asset.Coordinator_Pincode_based__c);


        asset.OwnerId = serviceHeadUser.Id;
        update asset;

        asset = [SELECT OwnerId, Service_Engineer_Pincode_based__c, RSM_Pincode_based__c, Coordinator_Pincode_based__c FROM Asset WHERE Id = :asset.Id];
        System.debug(JSON.serialize(asset));
        Assert.isNull(asset.Service_Engineer_Pincode_based__c);
        Assert.isNull(asset.RSM_Pincode_based__c);
        Assert.isNull(asset.Coordinator_Pincode_based__c);

        Test.stopTest();
    }


    @isTest
    public static void testAssetTransfer() {
        Account acc1 = new Account(Name = 'Customer Account 1');
        Account acc2 = new Account(Name = 'Customer Account 2');
        Account acc3 = new Account(Name = 'Customer Account 3');
        Account acc4 = new Account(Name = 'Customer Account 4');
        insert new List<Account>{ acc1, acc2, acc3, acc4 };

        Contact con1 = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc1.Id, Email = 'testcontact@test.com');
        Contact con3 = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc3.Id, Email = 'testcontact@test.com');
        insert new List<Contact>{ con1, con3 };

        Asset asset = new Asset(Name = 'Test Asset', AccountId = acc1.Id, End_Customer__c = acc2.Id, ContactId = con1.Id);
        insert asset;

        asset.AccountId = acc3.Id;
        asset.End_Customer__c = acc4.Id;
        asset.ContactId = con3.Id;
        update asset;

        Case case1 = new Case(AssetId = asset.Id, AccountId = acc1.Id, ContactId = con1.Id, Type = 'Breakdown', Case_Sub_Type__c = 'AMC Breakdown');
        insert case1;

        asset.AccountId = acc1.Id;
        asset.End_Customer__c = acc2.Id;
        asset.ContactId = con1.Id;
        try {
            update asset;
        }
        catch(Exception e) {
            Assert.isInstanceOfType(e, DMLException.class);
        }
    }

}