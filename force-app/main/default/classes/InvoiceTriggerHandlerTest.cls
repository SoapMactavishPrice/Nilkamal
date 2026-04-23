@isTest
private class InvoiceTriggerHandlerTest {

    @testSetup
    static void setupData() {
        // User u = new User(Id = UserInfo.getUserId(), UID__c = 'UID001');
        // update u;

        User u = new User(Id = UserInfo.getUserId(), UID__c = 'UID001');
        update u;

        Service_Resource__c sr = new Service_Resource__c(User__c = UserInfo.getUserId(), Role__c = 'Service Engineer');
        insert sr;

        Pricebook2 pb = new Pricebook2(Name = 'Nilkamal Pricebook', IsActive = true);
        insert pb;

        Manufacturing_Part_No__c mpnMHEComplex = new Manufacturing_Part_No__c(Name = 'MHE COMPLEX');
        Manufacturing_Part_No__c mpn = new Manufacturing_Part_No__c(Name = 'MHE SPARES & SERVICES');
        Manufacturing_Part_No__c mpnService = new Manufacturing_Part_No__c(Name = 'SERVICE');
        insert new List<Manufacturing_Part_No__c>{mpnMHEComplex, mpnService};

        Product2 complexEquipment = new Product2(Name = 'MHE COMPLEX', Category__c = 'Equipment', Description = '', Business_Vertical__c = 'MHE', Manufacturing_Part_No1__c = mpnMHEComplex.Id);
        Product2 spare = new Product2(Name = 'NK25-SPARE', Category__c = 'Spare', Description = '', Business_Vertical__c = 'MHE', Manufacturing_Part_No1__c = mpn.Id);
        Product2 service = new Product2(Name = 'MHE_OW_SER', Category__c = 'Service', Description = '', Business_Vertical__c = 'MHE', Manufacturing_Part_No1__c = mpnService.Id);
        insert new List<Product2>{complexEquipment, spare, service};

        Account acc = new Account(Name = 'Test Account 5409');
        insert acc;

        Contact con = new Contact(FirstName = 'Test 334', LastName = 'Contact', AccountId = acc.Id, Email = 'test@example.com');
        insert con;

        Sequence_Master__c seq = new Sequence_Master__c(Starting_Number__c = 100, Current_Sequence_No__c = 105, format__c = '000000');
        insert seq;

        Opportunity opp = new Opportunity(Name = 'Test Opp 443', AccountId = acc.Id, StageName = 'New', CloseDate = Date.today().addDays(30));
        insert opp;

        Quote qt = new Quote(Name = 'Test Quote 32', SAP_Order_No__c = 'ORD001', OpportunityId = opp.Id);
        insert qt;

        Pin_Code_Master__c pin = new Pin_Code_Master__c(Name = '123456');
        insert pin;

        // String fy = InvoiceTriggerHandler.getFinancialYearFormat(System.today());
        // Service_Goal__c sg = new Service_Goal__c(
        //     Service_Resource__c = sr.Id,
        //     Sales_Achievement__c = 1000,
        //     Financial_Year__c = fy
        // );
        // insert sg;
    }

    @isTest
    static void testInvoiceOfEquipment() {
        Test.startTest();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Invoice__c inv = new Invoice__c(
            Name = 'INV001-' + System.currentTimeMillis(),
            Item_Master__c = [SELECT Id FROM Product2 WHERE Category__c = 'Equipment' LIMIT 1].Id,
            Billing_Qty__c = 1,
            SAPOrderNo__c = 'ORD001',
            Ship_to_Pin__c = '123456',
            Sold_To_Party_1__c = acc.Id,
            Ship_To_Party_1__c = acc.Id,
            Contact__c = null,
            Ship_to_Address__c = 'Ship Address',
            Ship_to_City__c = 'Ship City',
            Ship_to_Region__c = 'Ship Region',
            Ship_to_Country__c = 'Ship Country',
            PO_Number__c = 'PO123',
            Billing_Date__c = Date.today(),
            Net_Invoice_Amount__c = 1000,
            Sold_to_Address__c = 'Bill Addr',
            Sold_to_City__c = 'Bill City',
            Sold_to_Pin__c = '654321',
            Sold_to_Region__c = 'Bill Region',
            Sold_to_Country__c = 'Bill Country',
            Sold_To_Party_Number__c = 'CUST001',
            Ship_To_Party_Number__c = 'SHIP001',
            Warrenty_Periods__c = '12',
            Serial_No__c = '123456',
            PO_Date__c = Date.today(),
            Sales_Employee_code__c = 'UID001',
            Billing_Type__c = 'F2',
            Sales_Person_Name__c = UserInfo.getUserId()
        );
        insert inv;

        inv.Net_Invoice_Amount__c = 2000;
        update inv;

        delete [SELECT Id FROM Asset_Visits__c WHERE Asset_Serial_No__r.Invoice__c = :inv.Id];

        delete [SELECT Id FROM Asset_Warranty__c WHERE Asset__r.Invoice__c = :inv.Id];

        delete [SELECT Id FROM Asset WHERE Invoice__c = :inv.Id];

        delete inv;

        undelete inv;

        Test.stopTest();
    }

    @isTest
    static void testInvoiceOfSpare() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Invoice__c inv = new Invoice__c(
            Name = 'INV001-' + System.currentTimeMillis(),
            Item_Master__c = [SELECT Id FROM Product2 WHERE Category__c = 'Spare' LIMIT 1].Id,
            Billing_Qty__c = 2,
            SAPOrderNo__c = 'ORD001',
            Ship_to_Pin__c = '123456',
            Sold_To_Party_1__c = acc.Id,
            Ship_To_Party_1__c = acc.Id,
            Contact__c = null,
            Ship_to_Address__c = 'Ship Address',
            Ship_to_City__c = 'Ship City',
            Ship_to_Region__c = 'Ship Region',
            Ship_to_Country__c = 'Ship Country',
            PO_Number__c = 'PO123',
            Billing_Date__c = Date.today(),
            Net_Invoice_Amount__c = 1000,
            Sold_to_Address__c = 'Bill Addr',
            Sold_to_City__c = 'Bill City',
            Sold_to_Pin__c = '654321',
            Sold_to_Region__c = 'Bill Region',
            Sold_to_Country__c = 'Bill Country',
            Sold_To_Party_Number__c = 'CUST001',
            Ship_To_Party_Number__c = 'SHIP001',
            Warrenty_Periods__c = '12',
            Serial_No__c = null,
            PO_Date__c = Date.today(),
            Sales_Employee_code__c = 'UID001',
            Billing_Type__c = 'F3',
            Sales_Person_Name__c = UserInfo.getUserId()
        );
        insert inv;

        inv.Net_Invoice_Amount__c = 2000;
        update inv;

        delete inv;

        Test.stopTest();
    }


    @isTest
    static void testInvoiceOfService() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        Invoice__c inv = new Invoice__c(
            Name = 'INV002-' + System.currentTimeMillis(),
            Item_Master__c = [SELECT Id FROM Product2 WHERE Category__c = 'Service' LIMIT 1].Id,
            Billing_Qty__c = 1,
            SAPOrderNo__c = 'ORD001',
            Ship_to_Pin__c = '123456',
            Sold_To_Party_1__c = acc.Id,
            Ship_To_Party_1__c = acc.Id,
            Contact__c = null,
            Ship_to_Address__c = 'Ship Address',
            Ship_to_City__c = 'Ship City',
            Ship_to_Region__c = 'Ship Region',
            Ship_to_Country__c = 'Ship Country',
            PO_Number__c = 'PO123',
            Billing_Date__c = Date.today(),
            Net_Invoice_Amount__c = 1000,
            Sold_to_Address__c = 'Bill Addr',
            Sold_to_City__c = 'Bill City',
            Sold_to_Pin__c = '654321',
            Sold_to_Region__c = 'Bill Region',
            Sold_to_Country__c = 'Bill Country',
            Sold_To_Party_Number__c = 'CUST001',
            Ship_To_Party_Number__c = 'SHIP001',
            Warrenty_Periods__c = '12',
            Serial_No__c = null,
            PO_Date__c = Date.today(),
            Sales_Employee_code__c = 'UID001',
            Billing_Type__c = 'F3',
            Sales_Person_Name__c = UserInfo.getUserId(),
            Quote__c = [SELECT Id FROM Quote LIMIT 1].Id
        );
        insert inv;

        inv.Net_Invoice_Amount__c = 2000;
        update inv;

        delete inv;
        Test.stopTest();
    }

}