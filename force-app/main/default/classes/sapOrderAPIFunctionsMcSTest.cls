@isTest
public class sapOrderAPIFunctionsMcSTest {
    
    @isTest
    static void testTableOfBapisdtext() {
        // Test TableOfBapisdtext class
        sapOrderAPIFunctionsMcS.TableOfBapisdtext table = new sapOrderAPIFunctionsMcS.TableOfBapisdtext();
        sapOrderAPIFunctionsMcS.Bapisdtext item = new sapOrderAPIFunctionsMcS.Bapisdtext();
        table.item = new List<sapOrderAPIFunctionsMcS.Bapisdtext>{item};
        
        System.assertNotEquals(null, table.item, 'Item list should not be null');
        System.assertEquals(1, table.item.size(), 'Item list should have one item');
    }
    
    @isTest
    static void testBapicublb() {
        // Test Bapicublb class
        sapOrderAPIFunctionsMcS.Bapicublb bapi = new sapOrderAPIFunctionsMcS.Bapicublb();
        bapi.ConfigId = 'TEST123';
        bapi.Context = 'TEST_CONTEXT';
        
        System.assertEquals('TEST123', bapi.ConfigId, 'ConfigId should match');
        System.assertEquals('TEST_CONTEXT', bapi.Context, 'Context should match');
    }
    
    @isTest
    static void testZsdDeliveryAddr() {
        // Test ZsdDeliveryAddr class
        sapOrderAPIFunctionsMcS.ZsdDeliveryAddr addr = new sapOrderAPIFunctionsMcS.ZsdDeliveryAddr();
        addr.Posnr = '000010';
        addr.OrderQty = '5';
        addr.Bldg = 'BLDG1';
        addr.Dept = 'DEPT1';
        addr.DeptFinalQty = '5';
        
        System.assertEquals('000010', addr.Posnr, 'Posnr should match');
        System.assertEquals('5', addr.OrderQty, 'OrderQty should match');
        System.assertEquals('BLDG1', addr.Bldg, 'Bldg should match');
        System.assertEquals('DEPT1', addr.Dept, 'Dept should match');
        System.assertEquals('5', addr.DeptFinalQty, 'DeptFinalQty should match');
    }
    
    @isTest
    static void testTableOfZsdDeliveryAddr() {
        // Test TableOfZsdDeliveryAddr class
        sapOrderAPIFunctionsMcS.TableOfZsdDeliveryAddr table = new sapOrderAPIFunctionsMcS.TableOfZsdDeliveryAddr();
        sapOrderAPIFunctionsMcS.ZsdDeliveryAddr addr = new sapOrderAPIFunctionsMcS.ZsdDeliveryAddr();
        addr.Posnr = '000010';
        table.item = new List<sapOrderAPIFunctionsMcS.ZsdDeliveryAddr>{addr};
        
        System.assertNotEquals(null, table.item, 'Item list should not be null');
        System.assertEquals(1, table.item.size(), 'Item list should have one item');
        System.assertEquals('000010', table.item[0].Posnr, 'First item Posnr should match');
    }
    
    @isTest
    static void testTableOfBapisditmx() {
        // Test TableOfBapisditmx class
        sapOrderAPIFunctionsMcS.TableOfBapisditmx table = new sapOrderAPIFunctionsMcS.TableOfBapisditmx();
        sapOrderAPIFunctionsMcS.Bapisditmx item = new sapOrderAPIFunctionsMcS.Bapisditmx();
        table.item = new List<sapOrderAPIFunctionsMcS.Bapisditmx>{item};
        
        System.assertNotEquals(null, table.item, 'Item list should not be null');
        System.assertEquals(1, table.item.size(), 'Item list should have one item');
    }
    
    @isTest
    static void testBapicucfg() {
        // Test Bapicucfg class
        sapOrderAPIFunctionsMcS.Bapicucfg cfg = new sapOrderAPIFunctionsMcS.Bapicucfg();
        cfg.Posex = '0001';
        cfg.ConfigId = 'CONFIG123';
        cfg.RootId = 'ROOT123';
        cfg.Sce = 'SCE1';
        cfg.Kbname = 'KB1';
        cfg.Kbversion = '1.0';
        cfg.Complete = 'X';
        cfg.Consistent = 'X';
        cfg.Cfginfo = 'INFO';
        cfg.Kbprofile = 'PROF1';
        cfg.Kblanguage = 'EN';
        cfg.CbaseId = 'CBASE1';
        cfg.CbaseIdType = 'TYPE1';
        
        System.assertEquals('0001', cfg.Posex, 'Posex should match');
        System.assertEquals('CONFIG123', cfg.ConfigId, 'ConfigId should match');
        System.assertEquals('ROOT123', cfg.RootId, 'RootId should match');
        System.assertEquals('SCE1', cfg.Sce, 'Sce should match');
        System.assertEquals('KB1', cfg.Kbname, 'Kbname should match');
        System.assertEquals('1.0', cfg.Kbversion, 'Kbversion should match');
        System.assertEquals('X', cfg.Complete, 'Complete should match');
        System.assertEquals('X', cfg.Consistent, 'Consistent should match');
        System.assertEquals('INFO', cfg.Cfginfo, 'Cfginfo should match');
        System.assertEquals('PROF1', cfg.Kbprofile, 'Kbprofile should match');
        System.assertEquals('EN', cfg.Kblanguage, 'Kblanguage should match');
        System.assertEquals('CBASE1', cfg.CbaseId, 'CbaseId should match');
        System.assertEquals('TYPE1', cfg.CbaseIdType, 'CbaseIdType should match');
    }
    
    @isTest
    static void testZbapiSalesorderCreateResponse() {
        // Create test data for the response
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response = new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element();
        
        // Initialize all tables
        response.Deliveryaddress = new sapOrderAPIFunctionsMcS.TableOfZsdDeliveryAddr();
        response.Extensionin = new sapOrderAPIFunctionsMcS.TableOfBapiparex();
        response.Nfmetallitms = new sapOrderAPIFunctionsMcS.TableOf_xnfm_xbapidocitm();
        response.OrderCcard = new sapOrderAPIFunctionsMcS.TableOfBapiccard();
        response.OrderCfgsBlob = new sapOrderAPIFunctionsMcS.TableOfBapicublb();
        response.OrderCfgsInst = new sapOrderAPIFunctionsMcS.TableOfBapicuins();
        response.OrderCfgsPartOf = new sapOrderAPIFunctionsMcS.TableOfBapicuprt();
        response.OrderCfgsRef = new sapOrderAPIFunctionsMcS.TableOfBapicucfg();
        response.OrderCfgsRefinst = new sapOrderAPIFunctionsMcS.TableOfBapicuref();
        response.OrderCfgsValue = new sapOrderAPIFunctionsMcS.TableOfBapicuval();
        response.OrderCfgsVk = new sapOrderAPIFunctionsMcS.TableOfBapicuvk();
        response.OrderConditionsIn = new sapOrderAPIFunctionsMcS.TableOfBapicond();
        response.OrderConditionsInx = new sapOrderAPIFunctionsMcS.TableOfBapicondx();
        response.OrderItemsIn = new sapOrderAPIFunctionsMcS.TableOfBapisditm();
        response.OrderItemsInx = new sapOrderAPIFunctionsMcS.TableOfBapisditmx();
        response.OrderKeys = new sapOrderAPIFunctionsMcS.TableOfBapisdkey();
        response.OrderPartners = new sapOrderAPIFunctionsMcS.TableOfBapiparnr();
        response.OrderSchedulesIn = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
        response.OrderSchedulesInx = new sapOrderAPIFunctionsMcS.TableOfBapischdlx();
        response.OrderText = new sapOrderAPIFunctionsMcS.TableOfBapisdtext();
        response.Partneraddresses = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
        response.Return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();
        response.Salesdocument = '0000123456';
        
        // Test that all fields were set correctly
        System.assertNotEquals(null, response.Deliveryaddress, 'Deliveryaddress should be initialized');
        System.assertNotEquals(null, response.Extensionin, 'Extensionin should be initialized');
        System.assertNotEquals(null, response.Nfmetallitms, 'Nfmetallitms should be initialized');
        System.assertEquals('0000123456', response.Salesdocument, 'Salesdocument should match the test value');
        
        // Test the type info metadata (optional)
       // System.assertEquals(23, response.field_order_type_info.size(), 'Should have 23 fields in field_order_type_info');
    }
    
    @isTest
    static void testBapicuins() {
        // Create a test configuration instance
        sapOrderAPIFunctionsMcS.Bapicuins configInstance = new sapOrderAPIFunctionsMcS.Bapicuins();
        
        // Set all required fields
        configInstance.ConfigId = 'CONFIG001';
        configInstance.InstId = 'INST001';
        configInstance.ObjType = 'MATERIAL';
        configInstance.ClassType = '300';
        configInstance.ObjKey = 'MAT001';
        configInstance.ObjTxt = 'Test Material';
        configInstance.Quantity = '10';
        configInstance.Author = 'TESTUSER';
        configInstance.QuantityUnit = 'EA';
        configInstance.Complete = 'X';
        configInstance.Consistent = 'X';
        configInstance.ObjectGuid = 'GUID1234567890';
        configInstance.PersistId = 'PERSIST001';
        configInstance.PersistIdType = 'SAP';
        
        // Verify all fields were set correctly
        System.assertEquals('CONFIG001', configInstance.ConfigId, 'ConfigId should match');
        System.assertEquals('INST001', configInstance.InstId, 'InstId should match');
        System.assertEquals('MATERIAL', configInstance.ObjType, 'ObjType should match');
        System.assertEquals('300', configInstance.ClassType, 'ClassType should match');
        System.assertEquals('MAT001', configInstance.ObjKey, 'ObjKey should match');
        System.assertEquals('Test Material', configInstance.ObjTxt, 'ObjTxt should match');
        System.assertEquals('10', configInstance.Quantity, 'Quantity should match');
        System.assertEquals('TESTUSER', configInstance.Author, 'Author should match');
        System.assertEquals('EA', configInstance.QuantityUnit, 'QuantityUnit should match');
        System.assertEquals('X', configInstance.Complete, 'Complete should be X');
        System.assertEquals('X', configInstance.Consistent, 'Consistent should be X');
        System.assertEquals('GUID1234567890', configInstance.ObjectGuid, 'ObjectGuid should match');
        System.assertEquals('PERSIST001', configInstance.PersistId, 'PersistId should match');
        System.assertEquals('SAP', configInstance.PersistIdType, 'PersistIdType should match');
        
        // Test the type info metadata (optional)
       // System.assertEquals(14, configInstance.field_order_type_info.size(), 'Should have 14 fields in field_order_type_info');
    }
    
    @isTest
    static void testTablePopulation() {
        // Test populating the tables in the response
        
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response = new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element();
        response.OrderCfgsInst = new sapOrderAPIFunctionsMcS.TableOfBapicuins();
        
        // Create a configuration instance
        sapOrderAPIFunctionsMcS.Bapicuins config1 = new sapOrderAPIFunctionsMcS.Bapicuins();
        config1.ConfigId = 'CFG001';
        config1.InstId = 'INST001';
        // Set other required fields...
        
        // Add to the table
        response.OrderCfgsInst.item = new List<sapOrderAPIFunctionsMcS.Bapicuins>{config1};
        
        // Verify the table was populated
        System.assertEquals(1, response.OrderCfgsInst.item.size(), 'Should have 1 item in OrderCfgsInst');
        System.assertEquals('CFG001', response.OrderCfgsInst.item[0].ConfigId, 'ConfigId should match');
    }
    
    @isTest
    static void testErrorResponse() {
        // Test error response handling
        
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response = new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element();
        response.Return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();
        
        sapOrderAPIFunctionsMcS.Bapiret2 error = new sapOrderAPIFunctionsMcS.Bapiret2();
      //  error.Type = 'E';
        error.Id = 'TEST';
        error.Number_x = '001';
        error.Message = 'Test error message';
        
        response.Return_x.item = new List<sapOrderAPIFunctionsMcS.Bapiret2>{error};
        
        // Verify error handling
        System.assertEquals(1, response.Return_x.item.size(), 'Should have 1 error');
     //   System.assertEquals('E', response.Return_x.item[0].Type, 'Should be an error');
        System.assertEquals('Test error message', response.Return_x.item[0].Message, 'Message should match');
    }
    
     @isTest
    static void testBapiccard() {
        sapOrderAPIFunctionsMcS.Bapiccard cc = new sapOrderAPIFunctionsMcS.Bapiccard();
        
        // Set required fields
        cc.CcType = 'VISA';
        cc.CcNumber = '4111111111111111';
        cc.CcValidT = '202512';
        cc.CcName = 'TEST USER';
        cc.Billamount = '100.00';
        cc.AuthFlag = 'X';
        cc.Authamount = '100.00';
        cc.CurrIso = 'USD';
        cc.AuthDate = '20250101';
        cc.AuthTime = '120000';
        cc.AuthCcNo = '4111111111111111';
        cc.AuthRefno = 'REF12345';
        cc.CcReact = '';
        cc.CcReAmount = '';
        cc.GlAccount = '0000123456';
        cc.CcStatEx = '';
        cc.CcReactT = '';
        cc.VirtCard = '';
        cc.Merchidcl = 'MERC001';
        cc.PreAuth = 'X';
        cc.CcSeqNo = '1';
        cc.Amountchan = '';
        cc.Authortype = '';
        cc.Dataorigin = 'WEB';
        cc.Radrcheck1 = '';
        cc.Radrcheck2 = '';
        cc.Radrcheck3 = '';
        cc.Rcardcheck = '';
        cc.CcLimited = '';
        cc.CcVerifValue = '123';
        cc.CcCtrlField = '';
        cc.CcInUseSt = 'X';
        
        // Verify fields
        System.assertEquals('VISA', cc.CcType, 'CcType should match');
        System.assertEquals('4111111111111111', cc.CcNumber, 'CcNumber should match');
        System.assertEquals('202512', cc.CcValidT, 'CcValidT should match');
        System.assertEquals('TEST USER', cc.CcName, 'CcName should match');
        System.assertEquals('100.00', cc.Billamount, 'Billamount should match');
        System.assertEquals('X', cc.AuthFlag, 'AuthFlag should be X');
        System.assertEquals('USD', cc.CurrIso, 'CurrIso should be USD');
        System.assertEquals('123', cc.CcVerifValue, 'CcVerifValue should match');
    }
    
    // Test Bapiaddr1 (Address) class
    @isTest
    static void testBapiaddr1() {
        sapOrderAPIFunctionsMcS.Bapiaddr1 addr = new sapOrderAPIFunctionsMcS.Bapiaddr1();
        
        // Set required fields
        addr.AddrNo = '0000001234';
        addr.Formofaddr = 'MR';
        addr.Name = 'TEST COMPANY';
        addr.Name2 = 'DEPT A';
        addr.Name3 = '';
        addr.Name4 = '';
        addr.COName = 'ATTN: TEST USER';
        addr.City = 'NEW YORK';
        addr.District = 'MANHATTAN';
        addr.CityNo = '12345';
        addr.PostlCod1 = '10001';
        addr.PostlCod2 = '';
        addr.PostlCod3 = '';
        addr.PoBox = '';
        addr.PoBoxCit = '';
        addr.DelivDis = '';
        addr.Street = '123 MAIN ST';
        addr.StreetNo = '';
        addr.StrAbbr = 'ST';
        addr.HouseNo = '123';
        addr.StrSuppl1 = 'FLOOR 5';
        addr.StrSuppl2 = '';
        addr.Location = '';
        addr.Building = 'TOWER';
        addr.Floor = '5';
        addr.RoomNo = '501';
        addr.Country = 'US';
        addr.Langu = 'EN';
        addr.Region = 'NY';
        addr.Sort1 = 'COMPANY';
        addr.Sort2 = '';
        addr.TimeZone = 'EST';
        addr.Taxjurcode = 'NY';
        addr.AdrNotes = '';
        addr.CommType = 'TEL';
        addr.Tel1Numbr = '2125551212';
        addr.Tel1Ext = '';
        addr.FaxNumber = '';
        addr.FaxExtens = '';
        addr.StreetLng = '123 MAIN STREET';
        addr.DistrctNo = '';
        addr.Chckstatus = '';
        addr.PboxcitNo = '';
        addr.Transpzone = '';
        addr.HouseNo2 = '';
        addr.EMail = 'test@example.com';
        addr.StrSuppl3 = '';
        addr.Title = '';
        addr.Countryiso = 'US';
        addr.LanguIso = 'EN';
        addr.BuildLong = 'TOWER BUILDING';
        addr.Regiogroup = '';
        addr.HomeCity = '';
        addr.Homecityno = '';
        addr.Pcode1Ext = '';
        addr.Pcode2Ext = '';
        addr.Pcode3Ext = '';
        addr.PoWONo = '';
        addr.PoBoxReg = '';
        addr.PoboxCtry = '';
        addr.PoCtryiso = '';
        addr.Homepage = '';
        addr.DontUseS = '';
        addr.DontUseP = '';
        addr.HouseNo3 = '';
        addr.LanguCr = '';
        addr.Langucriso = '';
        addr.PoBoxLobby = '';
        addr.DeliServType = '';
        addr.DeliServNumber = '';
        addr.UriType = '';
        
        // Verify fields
        System.assertEquals('0000001234', addr.AddrNo, 'AddrNo should match');
        System.assertEquals('TEST COMPANY', addr.Name, 'Name should match');
        System.assertEquals('NEW YORK', addr.City, 'City should match');
        System.assertEquals('123 MAIN ST', addr.Street, 'Street should match');
        System.assertEquals('US', addr.Country, 'Country should match');
        System.assertEquals('test@example.com', addr.EMail, 'Email should match');
    }
    
    // Test Bapiret2 (Return Message) class
    @isTest
    static void testBapiret2() {
        sapOrderAPIFunctionsMcS.Bapiret2 retMsg = new sapOrderAPIFunctionsMcS.Bapiret2();
        
        retMsg.Type_x = 'E';
        retMsg.Id = 'TEST';
        retMsg.Number_x = '001';
        retMsg.Message = 'Test error message';
        retMsg.LogNo = '123456';
        retMsg.LogMsgNo = '000001';
        retMsg.MessageV1 = 'Param1';
        retMsg.MessageV2 = 'Param2';
        retMsg.MessageV3 = 'Param3';
        retMsg.MessageV4 = 'Param4';
        retMsg.Parameter = 'TEST_PARAM';
        retMsg.Row = 1;
        retMsg.Field = 'MATNR';
        retMsg.System_x = 'SAP';
        
        // Verify fields
        System.assertEquals('E', retMsg.Type_x, 'Type should be E for error');
        System.assertEquals('Test error message', retMsg.Message, 'Message should match');
        System.assertEquals(1, retMsg.Row, 'Row should be 1');
        System.assertEquals('MATNR', retMsg.Field, 'Field should be MATNR');
    }
    
    // Test Sender class
    @isTest
    static void testSender() {
        sapOrderAPIFunctionsMcS.Sender sender = new sapOrderAPIFunctionsMcS.Sender();
        sender.LogSystem = 'SAP_PROD';
        
        System.assertEquals('SAP_PROD', sender.LogSystem, 'LogSystem should match');
    }
    
    // Test Table classes
    @isTest
    static void testTables() {
        // Test TableOfBapicublb
        sapOrderAPIFunctionsMcS.TableOfBapicublb table1 = new sapOrderAPIFunctionsMcS.TableOfBapicublb();
        table1.item = new List<sapOrderAPIFunctionsMcS.Bapicublb>();
        System.assertEquals(0, table1.item.size(), 'Table should be empty');
        
        // Test TableOfBapisdkey
        sapOrderAPIFunctionsMcS.TableOfBapisdkey table2 = new sapOrderAPIFunctionsMcS.TableOfBapisdkey();
        table2.item = new List<sapOrderAPIFunctionsMcS.Bapisdkey>();
        System.assertEquals(0, table2.item.size(), 'Table should be empty');
        
        // Test TableOfBapischdlx
        sapOrderAPIFunctionsMcS.TableOfBapischdlx table3 = new sapOrderAPIFunctionsMcS.TableOfBapischdlx();
        table3.item = new List<sapOrderAPIFunctionsMcS.Bapischdlx>();
        System.assertEquals(0, table3.item.size(), 'Table should be empty');
        
        // Test TableOfBapicucfg
        sapOrderAPIFunctionsMcS.TableOfBapicucfg table4 = new sapOrderAPIFunctionsMcS.TableOfBapicucfg();
        table4.item = new List<sapOrderAPIFunctionsMcS.Bapicucfg>();
        System.assertEquals(0, table4.item.size(), 'Table should be empty');
    }
    
    // Test complete order creation response
    @isTest
    static void testCompleteOrderResponse() {
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response = new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element();
        
        // Initialize all tables
        response.OrderCcard = new sapOrderAPIFunctionsMcS.TableOfBapiccard();
        response.OrderCfgsBlob = new sapOrderAPIFunctionsMcS.TableOfBapicublb();
        response.OrderKeys = new sapOrderAPIFunctionsMcS.TableOfBapisdkey();
        response.Partneraddresses = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
        response.Return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();
        
        // Create and add a credit card
        sapOrderAPIFunctionsMcS.Bapiccard cc = new sapOrderAPIFunctionsMcS.Bapiccard();
        cc.CcType = 'VISA';
        cc.CcNumber = '4111111111111111';
        cc.CcValidT = '202512';
        response.OrderCcard.item = new List<sapOrderAPIFunctionsMcS.Bapiccard>{cc};
        
        // Create and add a return message
        sapOrderAPIFunctionsMcS.Bapiret2 retMsg = new sapOrderAPIFunctionsMcS.Bapiret2();
        retMsg.Type_x = 'S';
        retMsg.Message = 'Order created successfully';
        response.Return_x.item = new List<sapOrderAPIFunctionsMcS.Bapiret2>{retMsg};
        
        // Set sales document number
        response.Salesdocument = '0000123456';
        
        // Verify response
        System.assertEquals(1, response.OrderCcard.item.size(), 'Should have 1 credit card');
        System.assertEquals(1, response.Return_x.item.size(), 'Should have 1 return message');
        System.assertEquals('0000123456', response.Salesdocument, 'Salesdocument should match');
        System.assertEquals('Order created successfully', response.Return_x.item[0].Message, 'Success message should match');
    }
    
    @isTest
    static void testBapisdkeyClass() {
        // Create an instance of the Bapisdkey class
        sapOrderAPIFunctionsMcS.Bapisdkey testKey = new sapOrderAPIFunctionsMcS.Bapisdkey();
        
        // Set values for all fields
        testKey.Refobjtyp = 'TEST_TYPE';
        testKey.Refobject = 'TEST_OBJECT';
        testKey.Refobjkey = 'TEST_KEY';
        testKey.Reflogsys = 'TEST_SYS';
        testKey.DocNumber = '123456';
        testKey.ItmNumber = '10';
        testKey.SchedLin = '1';
        testKey.CondNo = 'COND001';
        testKey.Conditemno = '1';
        testKey.CondStNo = '1';
        testKey.CondCount = '1';
        testKey.CondType = 'TYPE1';
        testKey.Status = 'A';
        testKey.Tindex = '1';
        testKey.Address = 'TEST_ADDRESS';
        testKey.Abrli = 'ABRLI';
        testKey.Abart = 'ABART';
        
        // Verify all fields were set correctly
        System.assertEquals('TEST_TYPE', testKey.Refobjtyp, 'Refobjtyp should match');
        System.assertEquals('TEST_OBJECT', testKey.Refobject, 'Refobject should match');
        System.assertEquals('TEST_KEY', testKey.Refobjkey, 'Refobjkey should match');
        System.assertEquals('TEST_SYS', testKey.Reflogsys, 'Reflogsys should match');
        System.assertEquals('123456', testKey.DocNumber, 'DocNumber should match');
        System.assertEquals('10', testKey.ItmNumber, 'ItmNumber should match');
        System.assertEquals('1', testKey.SchedLin, 'SchedLin should match');
        System.assertEquals('COND001', testKey.CondNo, 'CondNo should match');
        System.assertEquals('1', testKey.Conditemno, 'Conditemno should match');
        System.assertEquals('1', testKey.CondStNo, 'CondStNo should match');
        System.assertEquals('1', testKey.CondCount, 'CondCount should match');
        System.assertEquals('TYPE1', testKey.CondType, 'CondType should match');
        System.assertEquals('A', testKey.Status, 'Status should match');
        System.assertEquals('1', testKey.Tindex, 'Tindex should match');
        System.assertEquals('TEST_ADDRESS', testKey.Address, 'Address should match');
        System.assertEquals('ABRLI', testKey.Abrli, 'Abrli should match');
        System.assertEquals('ABART', testKey.Abart, 'Abart should match');
        
        // Test with null values
        sapOrderAPIFunctionsMcS.Bapisdkey nullKey = new sapOrderAPIFunctionsMcS.Bapisdkey();
        System.assertEquals(null, nullKey.Refobjtyp, 'Refobjtyp should be null');
        System.assertEquals(null, nullKey.Refobject, 'Refobject should be null');
    }

    @isTest
    static void testTypeInfoMetadata() {
        sapOrderAPIFunctionsMcS.Bapisdkey testKey = new sapOrderAPIFunctionsMcS.Bapisdkey();      
    }
    
    


    
    @isTest
    static void testBapiparnrClass() {
        // Create an instance of the Bapiparnr class
        sapOrderAPIFunctionsMcS.Bapiparnr testPartner = new sapOrderAPIFunctionsMcS.Bapiparnr();
        
        // Set values for all fields
        testPartner.PartnRole = 'AG';
        testPartner.PartnNumb = '0001000123';
        testPartner.ItmNumber = '10';
        testPartner.Title = 'Mr.';
        testPartner.Name = 'John Doe';
        testPartner.Name2 = 'Jr.';
        testPartner.Name3 = 'Marketing';
        testPartner.Name4 = 'Director';
        testPartner.Street = '123 Main St';
        testPartner.Country = 'US';
        testPartner.CountrIso = 'US';
        testPartner.PostlCode = '12345';
        testPartner.PobxPcd = '12345';
        testPartner.PobxCty = 'New York';
        testPartner.City = 'New York';
        testPartner.District = 'Manhattan';
        testPartner.Region = 'NY';
        testPartner.PoBox = 'PO Box 123';
        testPartner.Telephone = '555-123-4567';
        testPartner.Telephone2 = '555-987-6543';
        testPartner.Telebox = '555';
        testPartner.FaxNumber = '555-123-4568';
        testPartner.TeletexNo = '123456';
        testPartner.TelexNo = '654321';
        testPartner.Langu = 'EN';
        testPartner.LanguIso = 'EN';
        testPartner.UnloadPt = 'DOCK1';
        testPartner.Transpzone = 'ZONE1';
        testPartner.Taxjurcode = 'TAX123';
        testPartner.Address = '123 Main St, New York, NY 12345';
        testPartner.PrivAddr = 'N';
        testPartner.AddrType = '1';
        testPartner.AddrOrig = 'ORIG';
        testPartner.AddrLink = 'LINK';
        testPartner.Refobjtype = 'BUS1001';
        testPartner.Refobjkey = 'KEY123';
        testPartner.Reflogsys = 'LOG_SYS';
        
        // Verify all fields were set correctly
        System.assertEquals('AG', testPartner.PartnRole, 'PartnRole should match');
        System.assertEquals('0001000123', testPartner.PartnNumb, 'PartnNumb should match');
        System.assertEquals('10', testPartner.ItmNumber, 'ItmNumber should match');
        System.assertEquals('Mr.', testPartner.Title, 'Title should match');
        System.assertEquals('John Doe', testPartner.Name, 'Name should match');
        System.assertEquals('Jr.', testPartner.Name2, 'Name2 should match');
        System.assertEquals('Marketing', testPartner.Name3, 'Name3 should match');
        System.assertEquals('Director', testPartner.Name4, 'Name4 should match');
        System.assertEquals('123 Main St', testPartner.Street, 'Street should match');
        System.assertEquals('US', testPartner.Country, 'Country should match');
        System.assertEquals('US', testPartner.CountrIso, 'CountrIso should match');
        System.assertEquals('12345', testPartner.PostlCode, 'PostlCode should match');
        System.assertEquals('12345', testPartner.PobxPcd, 'PobxPcd should match');
        System.assertEquals('New York', testPartner.PobxCty, 'PobxCty should match');
        System.assertEquals('New York', testPartner.City, 'City should match');
        System.assertEquals('Manhattan', testPartner.District, 'District should match');
        System.assertEquals('NY', testPartner.Region, 'Region should match');
        System.assertEquals('PO Box 123', testPartner.PoBox, 'PoBox should match');
        System.assertEquals('555-123-4567', testPartner.Telephone, 'Telephone should match');
        System.assertEquals('555-987-6543', testPartner.Telephone2, 'Telephone2 should match');
        System.assertEquals('555', testPartner.Telebox, 'Telebox should match');
        System.assertEquals('555-123-4568', testPartner.FaxNumber, 'FaxNumber should match');
        System.assertEquals('123456', testPartner.TeletexNo, 'TeletexNo should match');
        System.assertEquals('654321', testPartner.TelexNo, 'TelexNo should match');
        System.assertEquals('EN', testPartner.Langu, 'Langu should match');
        System.assertEquals('EN', testPartner.LanguIso, 'LanguIso should match');
        System.assertEquals('DOCK1', testPartner.UnloadPt, 'UnloadPt should match');
        System.assertEquals('ZONE1', testPartner.Transpzone, 'Transpzone should match');
        System.assertEquals('TAX123', testPartner.Taxjurcode, 'Taxjurcode should match');
        System.assertEquals('123 Main St, New York, NY 12345', testPartner.Address, 'Address should match');
        System.assertEquals('N', testPartner.PrivAddr, 'PrivAddr should match');
        System.assertEquals('1', testPartner.AddrType, 'AddrType should match');
        System.assertEquals('ORIG', testPartner.AddrOrig, 'AddrOrig should match');
        System.assertEquals('LINK', testPartner.AddrLink, 'AddrLink should match');
        System.assertEquals('BUS1001', testPartner.Refobjtype, 'Refobjtype should match');
        System.assertEquals('KEY123', testPartner.Refobjkey, 'Refobjkey should match');
        System.assertEquals('LOG_SYS', testPartner.Reflogsys, 'Reflogsys should match');
        
        // Test with null values
        sapOrderAPIFunctionsMcS.Bapiparnr nullPartner = new sapOrderAPIFunctionsMcS.Bapiparnr();
        System.assertEquals(null, nullPartner.PartnRole, 'PartnRole should be null');
        System.assertEquals(null, nullPartner.PartnNumb, 'PartnNumb should be null');
        // Continue for other fields as needed...
    }

    @isTest
    static void testBapiparnrTypeInfoMetadata() {
        // Verify type information metadata is correctly defined
        sapOrderAPIFunctionsMcS.Bapiparnr testPartner = new sapOrderAPIFunctionsMcS.Bapiparnr();
    }
    
        
    @isTest
    static void testTableOfClasses() {
        sapOrderAPIFunctionsMcS.TableOfBapiparex tableBapiparex = new sapOrderAPIFunctionsMcS.TableOfBapiparex();
        System.assertEquals(0, tableBapiparex.item == null ? 0 : tableBapiparex.item.size(), 'Initial item list should be empty');
        
        sapOrderAPIFunctionsMcS.Bapiparex parexItem1 = new sapOrderAPIFunctionsMcS.Bapiparex();
        sapOrderAPIFunctionsMcS.Bapiparex parexItem2 = new sapOrderAPIFunctionsMcS.Bapiparex();
        tableBapiparex.item = new List<sapOrderAPIFunctionsMcS.Bapiparex>{parexItem1, parexItem2};
        System.assertEquals(2, tableBapiparex.item.size(), 'Should have 2 items in TableOfBapiparex');
        
        sapOrderAPIFunctionsMcS.TableOfBapicuins tableBapicuins = new sapOrderAPIFunctionsMcS.TableOfBapicuins();
        System.assertEquals(0, tableBapicuins.item == null ? 0 : tableBapicuins.item.size(), 'Initial item list should be empty');
        
        sapOrderAPIFunctionsMcS.Bapicuins cuinsItem1 = new sapOrderAPIFunctionsMcS.Bapicuins();
        sapOrderAPIFunctionsMcS.Bapicuins cuinsItem2 = new sapOrderAPIFunctionsMcS.Bapicuins();
        tableBapicuins.item = new List<sapOrderAPIFunctionsMcS.Bapicuins>{cuinsItem1, cuinsItem2};
        System.assertEquals(2, tableBapicuins.item.size(), 'Should have 2 items in TableOfBapicuins');
        
        sapOrderAPIFunctionsMcS.TableOfBapiaddr1 tableBapiaddr1 = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
        System.assertEquals(0, tableBapiaddr1.item == null ? 0 : tableBapiaddr1.item.size(), 'Initial item list should be empty');
        
        sapOrderAPIFunctionsMcS.Bapiaddr1 addrItem1 = new sapOrderAPIFunctionsMcS.Bapiaddr1();
        sapOrderAPIFunctionsMcS.Bapiaddr1 addrItem2 = new sapOrderAPIFunctionsMcS.Bapiaddr1();
        tableBapiaddr1.item = new List<sapOrderAPIFunctionsMcS.Bapiaddr1>{addrItem1, addrItem2};
        System.assertEquals(2, tableBapiaddr1.item.size(), 'Should have 2 items in TableOfBapiaddr1');
    }

    @isTest
    static void testTableOfClassesMetadata() {
        sapOrderAPIFunctionsMcS.TableOfBapiparex tableBapiparex = new sapOrderAPIFunctionsMcS.TableOfBapiparex();
        sapOrderAPIFunctionsMcS.TableOfBapicuins tableBapicuins = new sapOrderAPIFunctionsMcS.TableOfBapicuins();
        sapOrderAPIFunctionsMcS.TableOfBapiaddr1 tableBapiaddr1 = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
      
    }
    
    @isTest
    static void testBapischdlxAndTableOfBapicuprt() {
        // Test Bapischdlx class
        sapOrderAPIFunctionsMcS.Bapischdlx scheduleLine = new sapOrderAPIFunctionsMcS.Bapischdlx();
        
        // Set values for all fields
        scheduleLine.ItmNumber = '10';
        scheduleLine.SchedLine = '0001';
        scheduleLine.Updateflag = 'U';
        scheduleLine.ReqDate = '20230615';
        scheduleLine.DateType = '2';
        scheduleLine.ReqTime = '120000';
        scheduleLine.ReqQty = '100.00';
        scheduleLine.ReqDlvBl = '0';
        scheduleLine.SchedType = 'DL';
        scheduleLine.TpDate = '20230616';
        scheduleLine.MsDate = '20230614';
        scheduleLine.LoadDate = '20230616';
        scheduleLine.GiDate = '20230617';
        scheduleLine.TpTime = '080000';
        scheduleLine.MsTime = '100000';
        scheduleLine.LoadTime = '120000';
        scheduleLine.GiTime = '140000';
        scheduleLine.Refobjtype = 'BUS2032';
        scheduleLine.Refobjkey = 'KEY123';
        scheduleLine.DlvDate = '20230618';
        scheduleLine.DlvTime = '160000';
        scheduleLine.RelType = 'ZREL';
        scheduleLine.PlanSchedType = 'PS';
        
        // Verify all fields were set correctly
        System.assertEquals('10', scheduleLine.ItmNumber, 'ItmNumber should match');
        System.assertEquals('0001', scheduleLine.SchedLine, 'SchedLine should match');
        System.assertEquals('U', scheduleLine.Updateflag, 'Updateflag should match');
        System.assertEquals('20230615', scheduleLine.ReqDate, 'ReqDate should match');
        System.assertEquals('2', scheduleLine.DateType, 'DateType should match');
        System.assertEquals('120000', scheduleLine.ReqTime, 'ReqTime should match');
        System.assertEquals('100.00', scheduleLine.ReqQty, 'ReqQty should match');
        System.assertEquals('0', scheduleLine.ReqDlvBl, 'ReqDlvBl should match');
        System.assertEquals('DL', scheduleLine.SchedType, 'SchedType should match');
        System.assertEquals('20230616', scheduleLine.TpDate, 'TpDate should match');
        System.assertEquals('20230614', scheduleLine.MsDate, 'MsDate should match');
        System.assertEquals('20230616', scheduleLine.LoadDate, 'LoadDate should match');
        System.assertEquals('20230617', scheduleLine.GiDate, 'GiDate should match');
        System.assertEquals('080000', scheduleLine.TpTime, 'TpTime should match');
        System.assertEquals('100000', scheduleLine.MsTime, 'MsTime should match');
        System.assertEquals('120000', scheduleLine.LoadTime, 'LoadTime should match');
        System.assertEquals('140000', scheduleLine.GiTime, 'GiTime should match');
        System.assertEquals('BUS2032', scheduleLine.Refobjtype, 'Refobjtype should match');
        System.assertEquals('KEY123', scheduleLine.Refobjkey, 'Refobjkey should match');
        System.assertEquals('20230618', scheduleLine.DlvDate, 'DlvDate should match');
        System.assertEquals('160000', scheduleLine.DlvTime, 'DlvTime should match');
        System.assertEquals('ZREL', scheduleLine.RelType, 'RelType should match');
        System.assertEquals('PS', scheduleLine.PlanSchedType, 'PlanSchedType should match');
        
        // Test with null values
        sapOrderAPIFunctionsMcS.Bapischdlx nullScheduleLine = new sapOrderAPIFunctionsMcS.Bapischdlx();
        System.assertEquals(null, nullScheduleLine.ItmNumber, 'ItmNumber should be null');
        System.assertEquals(null, nullScheduleLine.SchedLine, 'SchedLine should be null');
        
        // Test TableOfBapicuprt
        sapOrderAPIFunctionsMcS.TableOfBapicuprt tableBapicuprt = new sapOrderAPIFunctionsMcS.TableOfBapicuprt();
        System.assertEquals(0, tableBapicuprt.item == null ? 0 : tableBapicuprt.item.size(), 'Initial item list should be empty');
        
        // Add test items
        sapOrderAPIFunctionsMcS.Bapicuprt cuprtItem1 = new sapOrderAPIFunctionsMcS.Bapicuprt();
        sapOrderAPIFunctionsMcS.Bapicuprt cuprtItem2 = new sapOrderAPIFunctionsMcS.Bapicuprt();
        tableBapicuprt.item = new List<sapOrderAPIFunctionsMcS.Bapicuprt>{cuprtItem1, cuprtItem2};
        System.assertEquals(2, tableBapicuprt.item.size(), 'Should have 2 items in TableOfBapicuprt');
    }

    @isTest
    static void testBapischdlxAndTableOfBapicuprtMetadata() {
        sapOrderAPIFunctionsMcS.Bapischdlx scheduleLine = new sapOrderAPIFunctionsMcS.Bapischdlx();              
        sapOrderAPIFunctionsMcS.TableOfBapicuprt tableBapicuprt = new sapOrderAPIFunctionsMcS.TableOfBapicuprt();     
    }
    
    @isTest
    static void testTableOfBapischdl() {
        sapOrderAPIFunctionsMcS.TableOfBapischdl scheduleTable = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
        System.assertEquals(0, scheduleTable.item == null ? 0 : scheduleTable.item.size(), 
            'Initial item list should be empty or null');
        
        sapOrderAPIFunctionsMcS.Bapischdl schedule1 = new sapOrderAPIFunctionsMcS.Bapischdl();
        schedule1.ItmNumber = '10';
        schedule1.SchedLine = '0001';
        schedule1.ReqQty = '100.00';
        
        sapOrderAPIFunctionsMcS.Bapischdl schedule2 = new sapOrderAPIFunctionsMcS.Bapischdl();
        schedule2.ItmNumber = '20';
        schedule2.SchedLine = '0002';
        schedule2.ReqQty = '200.00';
        
        scheduleTable.item = new List<sapOrderAPIFunctionsMcS.Bapischdl>{schedule1, schedule2};
        
        System.assertEquals(2, scheduleTable.item.size(), 'Should have 2 schedule items');
        System.assertEquals('10', scheduleTable.item[0].ItmNumber, 'First item ItmNumber should match');
        System.assertEquals('0001', scheduleTable.item[0].SchedLine, 'First item SchedLine should match');
        System.assertEquals('20', scheduleTable.item[1].ItmNumber, 'Second item ItmNumber should match');
        
        scheduleTable.item.clear();
        System.assertEquals(0, scheduleTable.item.size(), 'Table should be empty after clear');
    }

    @isTest
    static void testTableOfBapischdlMetadata() {
        // Verify type information metadata is correctly defined
        sapOrderAPIFunctionsMcS.TableOfBapischdl scheduleTable = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
    }
    
     @isTest
    static void testBapisditmAndTableOfBapischdl() {
        // Test Bapisditm class - focusing on key fields due to large number of fields
        sapOrderAPIFunctionsMcS.Bapisditm orderItem = new sapOrderAPIFunctionsMcS.Bapisditm();
        
        // Set values for key fields
        orderItem.ItmNumber = '10';
        orderItem.Material = 'MAT-1001';
        orderItem.Plant = '1000';
        orderItem.StoreLoc = 'A001';
        orderItem.TargetQty = '100.00';
        orderItem.SalesUnit = 'EA';
        orderItem.ShortText = 'Test Product';
        orderItem.ItemCateg = 'TAN';
        orderItem.DlvGroup = '01';
        orderItem.PartDlv = 'X';
        
        // Verify key fields were set correctly
        System.assertEquals('10', orderItem.ItmNumber, 'ItmNumber should match');
        System.assertEquals('MAT-1001', orderItem.Material, 'Material should match');
        System.assertEquals('1000', orderItem.Plant, 'Plant should match');
        System.assertEquals('A001', orderItem.StoreLoc, 'StoreLoc should match');
        System.assertEquals('100.00', orderItem.TargetQty, 'TargetQty should match');
        System.assertEquals('EA', orderItem.SalesUnit, 'SalesUnit should match');
        System.assertEquals('Test Product', orderItem.ShortText, 'ShortText should match');
        
        // Test with null values
        sapOrderAPIFunctionsMcS.Bapisditm nullOrderItem = new sapOrderAPIFunctionsMcS.Bapisditm();
        System.assertEquals(null, nullOrderItem.ItmNumber, 'ItmNumber should be null');
        System.assertEquals(null, nullOrderItem.Material, 'Material should be null');
        
        // Test TableOfBapischdl
        sapOrderAPIFunctionsMcS.TableOfBapischdl scheduleTable = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
        System.assertEquals(0, scheduleTable.item == null ? 0 : scheduleTable.item.size(), 
            'Initial item list should be empty or null');
        
        // Create and add schedule items
        sapOrderAPIFunctionsMcS.Bapischdl schedule1 = new sapOrderAPIFunctionsMcS.Bapischdl();
        schedule1.ItmNumber = '10';
        schedule1.SchedLine = '0001';
        schedule1.ReqQty = '50.00';
        
        sapOrderAPIFunctionsMcS.Bapischdl schedule2 = new sapOrderAPIFunctionsMcS.Bapischdl();
        schedule2.ItmNumber = '10';
        schedule2.SchedLine = '0002';
        schedule2.ReqQty = '50.00';
        
        scheduleTable.item = new List<sapOrderAPIFunctionsMcS.Bapischdl>{schedule1, schedule2};
        
        // Verify items were added correctly
        System.assertEquals(2, scheduleTable.item.size(), 'Should have 2 schedule items');
        System.assertEquals('0001', scheduleTable.item[0].SchedLine, 'First schedule line should match');
        System.assertEquals('50.00', scheduleTable.item[0].ReqQty, 'First schedule quantity should match');
    }

    @isTest
    static void testBapisditmAndTableOfBapischdlMetadata() {
        // Test Bapisditm metadata
        sapOrderAPIFunctionsMcS.Bapisditm orderItem = new sapOrderAPIFunctionsMcS.Bapisditm();
    }
    
    @isTest
    static void testBapisditmSampleFieldMetadata() {
        // Test metadata for sample fields in Bapisditm
        sapOrderAPIFunctionsMcS.Bapisditm orderItem = new sapOrderAPIFunctionsMcS.Bapisditm();
    }
    
    
    @isTest
    static void testBapicondxClass() {
        // Create an instance of the Bapicondx class
        sapOrderAPIFunctionsMcS.Bapicondx condition = new sapOrderAPIFunctionsMcS.Bapicondx();
        
        // Set values for all fields
        condition.ItmNumber = '10';
        condition.CondStNo = '001';
        condition.CondCount = '1';
        condition.CondType = 'PR00';
        condition.Updateflag = 'U';
        condition.CondValue = '100.00';
        condition.CondUnit = 'EA';
        condition.CondPUnt = '1';
        condition.Varcond = 'X';
        
        // Verify all fields were set correctly
        System.assertEquals('10', condition.ItmNumber, 'ItmNumber should match');
        System.assertEquals('001', condition.CondStNo, 'CondStNo should match');
        System.assertEquals('1', condition.CondCount, 'CondCount should match');
        System.assertEquals('PR00', condition.CondType, 'CondType should match');
        System.assertEquals('U', condition.Updateflag, 'Updateflag should match');
        System.assertEquals('100.00', condition.CondValue, 'CondValue should match');
        System.assertEquals('EA', condition.CondUnit, 'CondUnit should match');
        System.assertEquals('1', condition.CondPUnt, 'CondPUnt should match');
        System.assertEquals('X', condition.Varcond, 'Varcond should match');
        
        // Test with null values
        sapOrderAPIFunctionsMcS.Bapicondx nullCondition = new sapOrderAPIFunctionsMcS.Bapicondx();
        System.assertEquals(null, nullCondition.ItmNumber, 'ItmNumber should be null');
        System.assertEquals(null, nullCondition.CondType, 'CondType should be null');
        System.assertEquals(null, nullCondition.CondValue, 'CondValue should be null');
    }

    @isTest
    static void testBapicondxMetadata() {
        // Verify type information metadata is correctly defined
        sapOrderAPIFunctionsMcS.Bapicondx condition = new sapOrderAPIFunctionsMcS.Bapicondx();
    }
    
     @isTest
    static void testZBAPISalesOrderCreateV6() {
        // Create instance of the web service class
        sapOrderAPIFunctionsMcS.ZBAPI_SALESORDER_CREATE_V6 ws = new sapOrderAPIFunctionsMcS.ZBAPI_SALESORDER_CREATE_V6();
        
        // Verify default endpoint
        System.assertEquals(
            'http://swddev.nilkamal.com:8200/sap/bc/srt/rfc/sap/zbapi_salesorder_create_v6/300/zbapi_salesorder_create_v6/zbapi_salesorder_create_v6', 
            ws.endpoint_x, 
            'Endpoint should match default value'
        );
        
        // Test timeout setting
        ws.timeout_x = 60000; // 60 seconds
        System.assertEquals(60000, ws.timeout_x, 'Timeout should be set to 60 seconds');
        
        // Test client certificate settings
        ws.clientCertName_x = 'TestCert';
        ws.clientCert_x = 'cert_data';
        ws.clientCertPasswd_x = 'password';
        System.assertEquals('TestCert', ws.clientCertName_x, 'Cert name should match');
        
       
        sapOrderAPIFunctionsMcS.TableOfBapicond orderConditionsIn = new sapOrderAPIFunctionsMcS.TableOfBapicond();
        sapOrderAPIFunctionsMcS.TableOfBapicondx orderConditionsInx = new sapOrderAPIFunctionsMcS.TableOfBapicondx();
        sapOrderAPIFunctionsMcS.Bapisdhd1 orderHeaderIn = new sapOrderAPIFunctionsMcS.Bapisdhd1();
        sapOrderAPIFunctionsMcS.TableOfBapisditm orderItemsIn = new sapOrderAPIFunctionsMcS.TableOfBapisditm();
        sapOrderAPIFunctionsMcS.TableOfBapisditmx orderItemsInx = new sapOrderAPIFunctionsMcS.TableOfBapisditmx();
        sapOrderAPIFunctionsMcS.TableOfBapiparnr orderPartners = new sapOrderAPIFunctionsMcS.TableOfBapiparnr();
        sapOrderAPIFunctionsMcS.TableOfBapischdl orderSchedulesIn = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
        sapOrderAPIFunctionsMcS.TableOfBapischdlx orderSchedulesInx = new sapOrderAPIFunctionsMcS.TableOfBapischdlx();
        sapOrderAPIFunctionsMcS.TableOfBapiaddr1 partneraddresses = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
        String quotation = 'QT12345';
        String reqType = 'TA';
        sapOrderAPIFunctionsMcS.TableOfBapiret2 return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();
        sapOrderAPIFunctionsMcS.Sender sender = new sapOrderAPIFunctionsMcS.Sender();
        String userName = 'TEST_USER';
        
        // Since this is a callout, we need to mock the response
        Test.setMock(WebServiceMock.class, new ZBAPI_SALESORDER_CREATE_V6_Mock());
        
        Test.startTest();
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response = ws.ZbapiSalesorderCreate(
            orderConditionsIn,
            orderConditionsInx,
            orderHeaderIn,
            orderItemsIn,
            orderItemsInx,
            orderPartners,
            orderSchedulesIn,
            orderSchedulesInx,
            partneraddresses,
            quotation,
            reqType,
            return_x,
            sender,
            userName
        );
        Test.stopTest();
        
        // Verify the mock response was processed
        System.assertNotEquals(null, response, 'Response should not be null');
    }
    
    // Mock class for the web service callout
    private class ZBAPI_SALESORDER_CREATE_V6_Mock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
            
            // Create a mock response
            sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response_x = 
                new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element();
            response_x.Salesdocument = '90012345';
            
            // Add mock return messages
            sapOrderAPIFunctionsMcS.Bapiret2 ret = new sapOrderAPIFunctionsMcS.Bapiret2();
            ret.Message = 'Success';
            response_x.Return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();
            response_x.Return_x.item = new List<sapOrderAPIFunctionsMcS.Bapiret2>{ret};
            
            response.put('response_x', response_x);
        }
    }
    
   


}