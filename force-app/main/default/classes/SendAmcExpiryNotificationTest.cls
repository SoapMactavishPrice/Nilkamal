@isTest
public class SendAmcExpiryNotificationTest {

    @isTest
    public static void testBatchExecution() {
        // ✅ Get a profile to assign to test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // ✅ Create test Manager User
        User manager = new User(
            Alias = 'mgr',
            Email = 'manager@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'manageruser' + DateTime.now().getTime() + '@test.com'
        );
        insert manager;

        // ✅ Create test Service User with manager assigned
        User serviceUser = new User(
            Alias = 'srv',
            Email = 'service@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Service',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            Username = 'serviceuser' + DateTime.now().getTime() + '@test.com',
            ManagerId = manager.Id
        );
        insert serviceUser;

        Sequence_Master__c sm = new Sequence_Master__c(
            Starting_Number__c = 1,
            format__c = '000000'
        );
        insert sm;

        Division__c div01 = new Division__c(Name = '01', Division_Code__c = '01');
        Division__c div03 = new Division__c(Name = '03', Division_Code__c = '03');
        insert new List<Division__c>{div01, div03};

        Distribution_Channel__c distChannel01 = new Distribution_Channel__c(Name = '10', Distribution_Code__c = '10');
        insert distChannel01;

        Sales_Organizations__c salesOrg01 = new Sales_Organizations__c(Name = '1000', Sales_Org_Code__c = '1000');
        insert salesOrg01;

        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        update standardPricebook;

        Pricebook2 testPricebook = new Pricebook2(Name = 'Nilkamal', IsActive = true);
        insert testPricebook;

        Account acc = new Account(Name = 'Test Account', Pricelist__c = testPricebook.Id);
        insert acc;

        Asset asset = new Asset(Name='Test Asset', AccountId = acc.Id, Business_Vertical__c = 'MHE', End_Customer__c = acc.Id);
        insert asset;

        HSN_Master__c hm = new HSN_Master__c(Name = '998717', IGST__c = 18, SGST__c = 9, CGST__c = 9);
        insert hm;

        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'MHEAMCSER',
            IsActive = true,
            Category__c = 'SERVICE',
            Business_Vertical__c = 'MHE',
            HSN_Code__c = hm.Id,
            Material_Group_6__c = 'B66'
        );
        insert prod;

        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        insert customPbe;

        Contact contact = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
        insert contact;

        Asset asset38 = new Asset(Name = 'Test Asset 21 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        Asset asset30 = new Asset(Name = 'Test Asset 30 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        Asset asset45 = new Asset(Name = 'Test Asset 45 Days', AccountId = acc.Id, End_Customer__c = acc.Id, ContactId = contact.Id, Business_Vertical__c = 'MHE');
        insert new List<Asset>{asset38, asset30, asset45};

        Case cs = new Case(AccountId = acc.Id, Type = 'Breakdown', Case_Sub_Type__c = 'Chargeable Service', Division__c = 'MHE',AssetId = asset.Id);
        insert cs;

        Work_Order__c wo = new Work_Order__c(Case__c = cs.Id, CurrencyIsoCode = 'INR');
        insert wo;

        Service_Pricing__c sp = new Service_Pricing__c(Price__c = 200, Service_Material_Code__c = prod.Id);
        insert sp;

        Service_Request__c sr = new Service_Request__c(
            Work_Order__c = wo.Id,
            Item_Master__c = prod.Id,
            Price__c = 150,
            Original_Price__c = 180,
            Quantity__c = 2,
            Warranty_Period__c = '12 Months',
            Number_of_PM_Visit__c = '1',
            Number_of_Breakdown_Visit__c = '1',
            Is_Cloned__c = false,
            Clone_Id__c = null
        );
        insert sr;

        Service_Resource__c serviceResource = new Service_Resource__c(User__c = serviceUser.Id);
        insert serviceResource;

        asset38.Service_Resource__c = serviceResource.Id;
        asset30.Service_Resource__c = serviceResource.Id;
        asset45.Service_Resource__c = serviceResource.Id;
        update new List<Asset>{asset38, asset30, asset45};

        Asset_AMC__c amcRecord38 = new Asset_AMC__c(Asset__c = asset38.Id,AMC_Start_Date__c = Date.today(), AMC_End_Date__c = Date.today().addDays(38), Asset_AMC_PO_Status__c = 'Active',Product_Category_Type__c = 'AMC',AMC_Period_In_Months__c = 12);
        Asset_AMC__c amcRecord30 = new Asset_AMC__c(Asset__c = asset30.Id,AMC_Start_Date__c = Date.today(), AMC_End_Date__c = Date.today().addDays(30), Asset_AMC_PO_Status__c = 'Active',Product_Category_Type__c = 'AMC',AMC_Period_In_Months__c = 12);
        Asset_AMC__c amcRecord45 = new Asset_AMC__c(Asset__c = asset45.Id,AMC_Start_Date__c = Date.today(), AMC_End_Date__c = Date.today().addDays(45), Asset_AMC_PO_Status__c = 'Active',Product_Category_Type__c = 'AMC',AMC_Period_In_Months__c = 12);
        insert new List<Asset_AMC__c>{amcRecord38, amcRecord30, amcRecord45};

        Test.startTest();
        List<Asset_AMC__c> amcRecords = [
            SELECT Id, AMC_End_Date__c, Asset__r.Name, Asset__r.Service_Resource__r.User__c, Asset__r.Service_Resource__r.User__r.ManagerId,
            Days_remaining_to_expiry__c,Asset__r.End_Customer__c,Asset__r.ContactId, Asset__r.OwnerId, Renewal_Case__c,
            Asset__r.Service_Engineer_Pincode_based__c, Asset__r.Service_Engineer_Pincode_based__r.User__c, Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId
            FROM Asset_AMC__c
        ];

        amcRecords[0].AMC_End_Date__c = Date.today().addDays(30);
        amcRecords[1].AMC_End_Date__c = Date.today().addDays(38);
        amcRecords[2].AMC_End_Date__c = Date.today().addDays(45);

        Formula.recalculateFormulas(amcRecords);

        for(Asset_AMC__c amc : amcRecords) {
            System.debug('AMC Record: ' + amc.Id + ' - AMC_End_Date__c: ' + amc.AMC_End_Date__c + ' - Days_remaining_to_expiry__c: ' + amc.Days_remaining_to_expiry__c);
        }

        new SendAmcExpiryNotification().execute(null, amcRecords);

        Database.executeBatch(new SendAmcExpiryNotification(), 3);
        Test.stopTest();
    }

}