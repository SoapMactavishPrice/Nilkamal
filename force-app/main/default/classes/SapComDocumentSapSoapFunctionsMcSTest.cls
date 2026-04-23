@isTest
private class SapComDocumentSapSoapFunctionsMcSTest {
    
    @isTest
    static void testZcrmSOutput() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput output = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput();
        
        output.SalesOrg = '1000';
        output.DistChannel = '10';
        output.MaterialGroup = 'FG3000';
        output.Material = 'MAT001';
        output.MaterialDesc = 'Test Material';
        output.Division = '00';
        output.MaterialType = 'FERT';
        output.Uom = 'EA';
        output.Amount = '100.00';
        output.ValidFrom = '20230101';
        output.ValidTo = '20231231';
        output.ConditionType = 'PR00';
        output.Message = 'Success';
        
        System.assertEquals('1000', output.SalesOrg);
        System.assertEquals('10', output.DistChannel);
        System.assertEquals('FG3000', output.MaterialGroup);
        System.assertEquals('MAT001', output.Material);
        System.assertEquals('Test Material', output.MaterialDesc);
        System.assertEquals('00', output.Division);
        System.assertEquals('FERT', output.MaterialType);
        System.assertEquals('EA', output.Uom);
        System.assertEquals('100.00', output.Amount);
        System.assertEquals('20230101', output.ValidFrom);
        System.assertEquals('20231231', output.ValidTo);
        System.assertEquals('PR00', output.ConditionType);
        System.assertEquals('Success', output.Message);
    }
    
    @isTest
    static void testZcrmSA079() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA079 a079 = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA079();
        
        a079.SalesOrg = '1000';
        a079.DistChannel = '10';
        a079.MaterialGroup = 'FG3000';
        
        System.assertEquals('1000', a079.SalesOrg);
        System.assertEquals('10', a079.DistChannel);
        System.assertEquals('FG3000', a079.MaterialGroup);
    }
    
    @isTest
    static void testZcrmSA004() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA004 a004 = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA004();
        
        a004.SalesOrg = '1000';
        a004.DistChannel = '10';
        a004.Material = 'MAT001';
        
        System.assertEquals('1000', a004.SalesOrg);
        System.assertEquals('10', a004.DistChannel);
        System.assertEquals('MAT001', a004.Material);
    }
    
    @isTest
    static void testZcrmInputStr() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr input = new sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr();
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA079 a079Item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA079();
        a079Item.SalesOrg = '1000';
        a079Item.DistChannel = '10';
        a079Item.MaterialGroup = 'FG3000';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtA079 a079Table = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtA079();
        a079Table.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA079[]{a079Item};
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA004 a004Item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA004();
        a004Item.SalesOrg = '1000';
        a004Item.DistChannel = '10';
        a004Item.Material = 'MAT001';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtA004 a004Table = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtA004();
        a004Table.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA004[]{a004Item};
        
        input.ConditionType = 'PR00';
        input.ZimA079 = a079Table;
        input.ZimA004 = a004Table;
        
        System.assertEquals('PR00', input.ConditionType);
        System.assertEquals(1, input.ZimA079.item.size());
        System.assertEquals(1, input.ZimA004.item.size());
        System.assertEquals('1000', input.ZimA079.item[0].SalesOrg);
        System.assertEquals('MAT001', input.ZimA004.item[0].Material);
    }
    
    @isTest
    static void testZcrmOutputStr() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr output = new sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr();
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput outputItem = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput();
        outputItem.SalesOrg = '1000';
        outputItem.Material = 'MAT001';
        outputItem.Amount = '100.00';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtOutput outputTable = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtOutput();
        outputTable.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput[]{outputItem};
        
        output.ZimOutputTt = outputTable;
        
        System.assertEquals(1, output.ZimOutputTt.item.size());
        System.assertEquals('1000', output.ZimOutputTt.item[0].SalesOrg);
        System.assertEquals('MAT001', output.ZimOutputTt.item[0].Material);
        System.assertEquals('100.00', output.ZimOutputTt.item[0].Amount);
    }
    
    @isTest
    static void testZcrmSdProductPrice() {
        sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput outputItem = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput();
        outputItem.SalesOrg = '1000';
        outputItem.DistChannel = '10';
        outputItem.Material = 'MAT001';
        outputItem.Amount = '100.00';
        outputItem.Message = 'Success';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtOutput outputTable = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtOutput();
        outputTable.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSOutput[]{outputItem};
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr mockResponse = new sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr();
        mockResponse.ZimOutputTt = outputTable;
        
        sapComDocumentSapSoapFunctionsMcS.ZCRM_SD_PRODUCT_PRICE_WS ws = new sapComDocumentSapSoapFunctionsMcS.ZCRM_SD_PRODUCT_PRICE_WS();
        
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl(mockResponse));
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr input = new sapComDocumentSapSoapFunctionsMcS.ZcrmInputStr();
        input.ConditionType = 'PR00';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA079 a079Item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA079();
        a079Item.SalesOrg = '1000';
        a079Item.DistChannel = '10';
        a079Item.MaterialGroup = 'FG3000';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtA079 a079Table = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtA079();
        a079Table.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA079[]{a079Item};
        input.ZimA079 = a079Table;
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmSA004 a004Item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA004();
        a004Item.SalesOrg = '1000';
        a004Item.DistChannel = '10';
        a004Item.Material = 'MAT001';
        
        sapComDocumentSapSoapFunctionsMcS.ZcrmTtA004 a004Table = new sapComDocumentSapSoapFunctionsMcS.ZcrmTtA004();
        a004Table.item = new sapComDocumentSapSoapFunctionsMcS.ZcrmSA004[]{a004Item};
        input.ZimA004 = a004Table;
        
        Test.startTest();
        sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr response = ws.ZcrmSdProductPrice(input);
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertNotEquals(null, response.ZimOutputTt);
        System.assertEquals(1, response.ZimOutputTt.item.size());
        System.assertEquals('MAT001', response.ZimOutputTt.item[0].Material);
        System.assertEquals('100.00', response.ZimOutputTt.item[0].Amount);
    }
    
    private class WebServiceMockImpl implements WebServiceMock {
        private sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr mockResponse;
        
        public WebServiceMockImpl(sapComDocumentSapSoapFunctionsMcS.ZcrmOutputStr response) {
            this.mockResponse = response;
        }
        
        public void doInvoke(
            Object stub, Object request, Map<String, Object> response,
            String endpoint, String soapAction, String requestName,
            String responseNS, String responseName, String responseType) {
            response.put('response_x', new sapComDocumentSapSoapFunctionsMcS.ZcrmSdProductPriceResponse_element());
            ((sapComDocumentSapSoapFunctionsMcS.ZcrmSdProductPriceResponse_element)response.get('response_x')).EmProductPrice = mockResponse;
        }
    }
}