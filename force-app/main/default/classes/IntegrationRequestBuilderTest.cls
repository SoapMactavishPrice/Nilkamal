@isTest
private class IntegrationRequestBuilderTest {
    
    @isTest
    static void testItemMasterParse() {
        String productJson = '[{' +
            '"ITEM_NUMBER": "000000000400009166",' +
            '"ITEM_DESCRIPTION": "KYROS STNSL 80DA-210LT HD BL",' +
            '"ITEM_GROUP": "FG3000",' +
            '"ITEM_TYPE": "FERT",' +
            '"BASE_UOM": "L",' +
            '"OLD_MATERIAL_CODE": "KSL40401PM551",' +
            '"SALES_ORGANISATION": "",' +
            '"DISTRIBUTION_CHANNEL": "10",' +
            '"DIVISION": "28",' +
            '"SALES_UOM": "NOS",' +
            '"PLANT_CODE": "1000",' +
            '"GENITEMCATGROUP": "NORM",' +
            '"SIZE_DIMENSIONS": "210 LT",' +
            '"ITEM_TYPE_C": "Fertigerzeugnis",' +
            '"MATERIAL_GROUP_1": "AD",' +
            '"MATERIAL_GROUP_1_C": "SBU-4",' +
            '"MATERIAL_GROUP_2": "AO",' +
            '"MATERIAL_GROUP_2_C": "Kyros",' +
            '"MATERIAL_GROUP_3": "AS",' +
            '"MATERIAL_GROUP_3_C": "Solvent",' +
            '"MATERIAL_GROUP_4": "CL",' +
            '"MATERIAL_GROUP_4_C": "Solvents",' +
            '"MATERIAL_GROUP_5": "CM",' +
            '"MATERIAL_GROUP_5_C": "Commodity",' +
            '"MATERIAL_GROUP_6": "CM",' +
            '"MATERIAL_GROUP_6_C": "CM",' +
            '"LIST_PRICE_MRP_PRICE": "",' +
            '"HSN_CODE": "27101990",' +
            '"MPN": "0",' +
            '"PRODUCT_STATUS": "KCVEDALQBGZX",' +
            '"PRODUCT_IMAGE_BASE64": "KCVEDALQBGZX",' +
            '"PRODUCT_IMAGE_NAME": "KCVEDALQBGZX",' +
            '"Warranty": "KCVEDALQBGZX",' +
            '"LeadTime": "KCVEDALQBGZX"' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.ProductMasterJson> products = 
            IntegrationRequestBuilder.itemMasterParse(productJson);
        Test.stopTest();
        
        System.assertEquals(1, products.size(), 'Should parse one product');
        System.assertEquals('000000000400009166', products[0].ITEM_NUMBER, 'Item number should match');
        System.assertEquals('KYROS STNSL 80DA-210LT HD BL', products[0].ITEM_DESCRIPTION, 'Description should match');
    }
    
    @isTest
    static void testCustomerMasterParse() {
        // Test data for CustomerWrapper
        String customerJson = '[{' +
            '"PARENT_ACCOUNT": "PARENT01",' +
            '"CUSTOMER_NO": "CUST001",' +
            '"CUST_NAME": "Test Customer",' +
            '"COMPANY_CODE": "COMP01",' +
            '"ACCOUNT_GROUP": "AG01",' +
            '"MOBILE_NUMBER": "1234567890",' +
            '"EMAIL_ID": "test@example.com",' +
            '"PHONE1": "9876543210",' +
            '"PHONE2": "9876543211",' +
            '"STREET": "Test Street",' +
            '"STREET1": "Test Street 1",' +
            '"STREET2": "Test Street 2",' +
            '"CITY": "Test City",' +
            '"POST_CODE": "123456",' +
            '"COUNTRY": "Test Country",' +
            '"CURRENCY_SF": "USD",' +
            '"GST_NUMBER": "GST123",' +
            '"PAN_NUMBER": "PAN123",' +
            '"INCOTERMS1": "EXW",' +
            '"INCOTERMS2": "Test Incoterms",' +
            '"TCS_APPLICABLE": "Y",' +
            '"TERMS_OF_PAYMENT": "NET30",' +
            '"CLASSIFICATION": "A",' +
            '"SUB_INDUSTRY": "SUB1",' +
            '"SUB_INDUSTRY2": "SUB2",' +
            '"INDUSTRY": "Manufacturing",' +
            '"SALES_DISTRICT": "DIST01",' +
            '"DISTRIBUTION_CHANNEL": "DCH01",' +
            '"DIVISION": "DIV01",' +
            '"SALES_OFF": "OFF01",' +
            '"SALES_GRP": "GRP01",' +
            '"SALES_ORG": "SORG01",' +
            '"VIRTUAL_ACCOUNT_NUMBER": "VAC001",' +
            '"PARTNERFUNCTION_LIST": [{' +
                '"CUSTOMER_NO": "CUST001",' +
                '"ADDRESS_TYPE": "SHIP_TO",' +
                '"ADDRESS_LINE1": "Addr Line 1",' +
                '"ADDRESS_LINE2": "Addr Line 2",' +
                '"ADDRESS_LINE3": "Addr Line 3",' +
                '"CITY": "Partner City",' +
                '"POSTL_CODE": "654321",' +
                '"DISTRICT": "Partner District",' +
                '"STATE": "Partner State",' +
                '"REGION": "Partner Region",' +
                '"GST_IN": "GST456",' +
                '"COUNTRY": "Partner Country",' +
                '"PAN_NUMBER": "PAN456"' +
            '}],' +
            '"BANK_DETAILS": [{' +
                '"CUSTOMER_NO": "CUST001",' +
                '"BANKNAME": "Test Bank",' +
                '"IFSC_CODE": "IFSC001",' +
                '"ADDRESS": "Bank Address"' +
            '}]' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.CustomerWrapper> customers = 
            IntegrationRequestBuilder.customerMasterParse(customerJson);
        Test.stopTest();
        
        System.assertEquals(1, customers.size(), 'Should parse one customer');
        System.assertEquals('CUST001', customers[0].CUSTOMER_NO, 'Customer number should match');
        System.assertEquals(1, customers[0].PARTNERFUNCTION_LIST.size(), 'Should have one partner function');
        System.assertEquals(1, customers[0].BANK_DETAILS.size(), 'Should have one bank detail');
    }
    
    @isTest
    static void testInvoiceParse() {
        // Test data for InvoiceWrapper
        String invoiceJson = '[{' +
            '"NilkamalSrno": "NK001",' +
            '"VendorSrno": "V001",' +
            '"WarrantyPeriods": "12",' +
            '"SAPInvoiceNo": "INV001",' +
            '"SAPOrderNo": "ORD001",' +
            '"X2nd_LR_number": "LR002",' +
            '"X2nd_Transporter_name": "Transporter 2",' +
            '"Billing_Date": "2023-01-01",' +
            '"Billing_Document": "DOC001",' +
            '"Billing_Qty": 10,' +
            '"Billing_Type": "Standard",' +
            '"Customer_Mobile": "9876543210",' +
            '"Sales_org": "SORG01",' +
            '"Distribution_Channel": "DCH01",' +
            '"Division": "DIV01",' +
            '"Item_Text": "Test Item",' +
            '"LR_number": "LR001",' +
            '"LR_Date": "2023-01-01",' +
            '"Line_Item": "10",' +
            '"Material": "MAT001",' +
            '"Material_Description": "Test Material",' +
            '"Net_Invoice_Amount": 1000,' +
            '"PO_Date": "2023-01-01",' +
            '"PO_Number": "PO001",' +
            '"Plant_Name": "PLANT01",' +
            '"Sales_Employee_code": "EMP001",' +
            '"Serial_No": "SER001",' +
            '"Ship_to_Address": "Ship Address",' +
            '"Ship_to_City": "Ship City",' +
            '"Ship_to_Country": "Ship Country",' +
            '"Ship_to_Email": "ship@example.com",' +
            '"Ship_to_GST_No": "GST001",' +
            '"Ship_to_Mob": "9876543210",' +
            '"Ship_to_Name": "Ship Name",' +
            '"Ship_to_Pin": "123456",' +
            '"Ship_to_Region": "Ship Region",' +
            '"Ship_to_Tele": "9876543210",' +
            '"Sold_to_Address": "Sold Address",' +
            '"Sold_to_City": "Sold City",' +
            '"Sold_to_Country": "Sold Country",' +
            '"Sold_to_GST_No": "GST002",' +
            '"Sold_to_Party_Name": "Sold Name",' +
            '"Sold_to_Party_No": "SOLD001",' +
            '"Sold_to_Pin": "654321",' +
            '"Sold_to_Email": "sold@example.com",' +
            '"Sold_to_Telephone": "9876543211",' +
            '"Sold_to_Region": "Sold Region",' +
            '"Valuation_Class": "VAL01",' +
            '"Ship_to_Party": "SHIP001",' +
            '"MFG_part_no": "MFR001",' +
            '"Total_document_amount": 1200,' +
            '"Total_tax_amount": 200,' +
            '"Transporter_name": "Transporter 1",' +
            '"Customer_Contact_Name": "Contact Name",' +
            '"Customer_Contact_Email": "contact@example.com",' +
            '"Sales_Group_Code": "GRP01",' +
            '"Sales_Group_Description": "Group 1",' +
            '"Sales_Office_Code": "OFF01",' +
            '"Sales_Office_Description": "Office 1",' +
            '"Material_Group_6": "MG6"' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.InvoiceWrapper> invoices = 
            IntegrationRequestBuilder.InvoiceParse(invoiceJson);
        IntegrationRequestBuilder.InvoiceWrapper invoices1 = new IntegrationRequestBuilder.InvoiceWrapper();
        invoices1.NilkamalSrno='test';
        invoices1.VendorSrno = 'V001';
            invoices1.WarrantyPeriods = '12';
    invoices1.SAPInvoiceNo = 'INV001';
    invoices1.SAPOrderNo = 'ORD001';
    invoices1.X2nd_LR_number = 'LR002';
    invoices1.X2nd_Transporter_name = 'Transporter 2';
    //invoices1.Billing_Date = Date.valueOf('2023-01-01');
    invoices1.Billing_Document = 'DOC001';
    invoices1.Billing_Qty = 10;
    invoices1.Billing_Type = 'Standard';
    invoices1.Customer_Mobile = '9876543210';
    invoices1.Sales_org = 'SORG01';
    invoices1.Distribution_Channel = 'DCH01';
    invoices1.Division = 'DIV01';
    invoices1.Item_Text = 'Test Item';
    invoices1.LR_number = 'LR001';
    //invoices1.LR_Date = Date.valueOf('2023-01-01');
    invoices1.Line_Item = '10';
    invoices1.Material = 'MAT001';
    invoices1.Material_Description = 'Test Material';
    invoices1.Net_Invoice_Amount = 1000;
    //invoices1.PO_Date = Date.valueOf('2023-01-01');
    invoices1.PO_Number = 'PO001';
    invoices1.Plant_Name = 'PLANT01';
    invoices1.Sales_Employee_code = 'EMP001';
    invoices1.Serial_No = 'SER001';
    invoices1.Ship_to_Address = 'Ship Address';
    invoices1.Ship_to_City = 'Ship City';
    invoices1.Ship_to_Country = 'Ship Country';
    invoices1.Ship_to_Email = 'ship@example.com';
    invoices1.Ship_to_GST_No = 'GST001';
    invoices1.Ship_to_Mob = '9876543210';
    invoices1.Ship_to_Name = 'Ship Name';
    invoices1.Ship_to_Pin = '123456';
    invoices1.Ship_to_Region = 'Ship Region';
    invoices1.Ship_to_Tele = '9876543210';
    invoices1.Sold_to_Address = 'Sold Address';
    invoices1.Sold_to_City = 'Sold City';
    invoices1.Sold_to_Country = 'Sold Country';
    invoices1.Sold_to_GST_No = 'GST002';
    invoices1.Sold_to_Party_Name = 'Sold Name';
    invoices1.Sold_to_Party_No = 'SOLD001';
    invoices1.Sold_to_Pin = '654321';
    invoices1.Sold_to_Email = 'sold@example.com';
    invoices1.Sold_to_Telephone = '9876543211';
    invoices1.Sold_to_Region = 'Sold Region';
    invoices1.Valuation_Class = 'VAL01';
    invoices1.Ship_to_Party = 'SHIP001';
    invoices1.MFG_part_no = 'MFR001';
    invoices1.Total_document_amount = 1200;
    invoices1.Total_tax_amount = 200;
    invoices1.Transporter_name = 'Transporter 1';
    invoices1.Customer_Contact_Name = 'Contact Name';
    invoices1.Customer_Contact_Email = 'contact@example.com';
    invoices1.Sales_Group_Code = 'GRP01';
    invoices1.Sales_Group_Description = 'Group 1';
    invoices1.Sales_Office_Code = 'OFF01';
    invoices1.Sales_Office_Description = 'Office 1';
    invoices1.Material_Group_6 = 'MG6';

        Test.stopTest();
        
        System.assertEquals(1, invoices.size(), 'Should parse one invoice');
        System.assertEquals('INV001', invoices[0].SAPInvoiceNo, 'Invoice number should match');
        System.assertEquals(10, invoices[0].Billing_Qty, 'Billing quantity should match');
    }
    
    @isTest
    static void testStockParse() {
        String stockJson = '[{' +
            '"Material": "MAT001",' +
            '"Material_Description": "Test Material",' +
            '"Plant_Name": "PLANT01",' +
            '"Plant_Code": "1000",' +
            '"Quantity": "100",' +
            '"Manufacturing_Part_No": "MFR001",' +
            '"Material_Group6": "MG6",' +
            '"MG6_Description": "Material Group 6"' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.StockWrapper> stockItems = 
            IntegrationRequestBuilder.StockParse(stockJson);
        Test.stopTest();
        
        System.assertEquals(1, stockItems.size(), 'Should parse one stock item');
        System.assertEquals('MAT001', stockItems[0].Material, 'Material should match');
        System.assertEquals('100', stockItems[0].Quantity, 'Quantity should match');
    }
    
    @isTest
    static void testSparesEquipmentParse() {
        String sparesJson = '[{' +
            '"SAPMaterialNumber": "MAT001",' +
            '"VendorMatCode": "V001",' +
            '"SAPEquipmentCode": "EQ001",' +
            '"OEMModel": "MODEL001"' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.SparesEquipmentWrapper> spares = 
            IntegrationRequestBuilder.SparesEquipmentParse(sparesJson);
        Test.stopTest();
        
        System.assertEquals(1, spares.size(), 'Should parse one spare equipment');
        System.assertEquals('MAT001', spares[0].SAPMaterialNumber, 'Material number should match');
        System.assertEquals('EQ001', spares[0].SAPEquipmentCode, 'Equipment code should match');
    }
    
    @isTest
    static void testHSNParse() {
        String hsnJson = '[{' +
            '"HSNCode": "27101990",' +
            '"Description": "Test HSN",' +
            '"GST": 18,' +
            '"Active": "Y"' +
        '}]';
        
        Test.startTest();
        List<IntegrationRequestBuilder.HSNWrapper> hsnCodes = 
            IntegrationRequestBuilder.HSNParse(hsnJson);
        Test.stopTest();
        
        System.assertEquals(1, hsnCodes.size(), 'Should parse one HSN code');
        System.assertEquals('27101990', hsnCodes[0].HSNCode, 'HSN code should match');
        System.assertEquals(18, hsnCodes[0].GST, 'GST rate should match');
    }
    
    @isTest
    static void testParseEmptyJson() {
        Test.startTest();
        List<IntegrationRequestBuilder.ProductMasterJson> emptyProducts = 
            IntegrationRequestBuilder.itemMasterParse('[]');
        List<IntegrationRequestBuilder.CustomerWrapper> emptyCustomers = 
            IntegrationRequestBuilder.customerMasterParse('[]');
        List<IntegrationRequestBuilder.InvoiceWrapper> emptyInvoices = 
            IntegrationRequestBuilder.InvoiceParse('[]');
        List<IntegrationRequestBuilder.StockWrapper> emptyStock = 
            IntegrationRequestBuilder.StockParse('[]');
        List<IntegrationRequestBuilder.SparesEquipmentWrapper> emptySpares = 
            IntegrationRequestBuilder.SparesEquipmentParse('[]');
        List<IntegrationRequestBuilder.HSNWrapper> emptyHSN = 
            IntegrationRequestBuilder.HSNParse('[]');
        Test.stopTest();
        
        System.assertEquals(0, emptyProducts.size(), 'Empty products array');
        System.assertEquals(0, emptyCustomers.size(), 'Empty customers array');
        System.assertEquals(0, emptyInvoices.size(), 'Empty invoices array');
        System.assertEquals(0, emptyStock.size(), 'Empty stock array');
        System.assertEquals(0, emptySpares.size(), 'Empty spares array');
        System.assertEquals(0, emptyHSN.size(), 'Empty HSN array');
    }
    
    @isTest
    static void testParseInvalidJson() {
        Test.startTest();
        try {
            List<IntegrationRequestBuilder.ProductMasterJson> invalidProducts = 
                IntegrationRequestBuilder.itemMasterParse('invalid json');
            System.assert(false, 'Expected exception for invalid JSON');
        } catch (Exception e) {
            System.assert(e instanceof System.JSONException, 'Expected JSONException');
        }
        Test.stopTest();
    }
}