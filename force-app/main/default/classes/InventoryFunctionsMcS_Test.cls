@isTest
private class InventoryFunctionsMcS_Test {

    class ZBAPIOrderStockMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseName,
            String responseNamespace,
            String clientCertName
        ) {
            inventoryFunctionsMcS.ZbapiOrdstk stockItem = new inventoryFunctionsMcS.ZbapiOrdstk();
            stockItem.Material = 'MAT001';
            stockItem.Plant = 'PL01';
            stockItem.PlantName = 'Mumbai Plant';
            stockItem.UnrestrictedStock = '100';
            stockItem.Nm01Stock = '10';
            stockItem.StockInTransit = '20';
            stockItem.TotalStock = '130';
            stockItem.SoCount = '5';
            stockItem.OpenSoQty = '50';
            stockItem.BtrCount = '3';
            stockItem.OpenBtrQtyOut = '30';
            stockItem.TotalOpenOrderQty = '80';
            stockItem.TotalAvailableQty = '50';
            stockItem.OpenBtrQtyIn = '10';
            stockItem.ManufacturingPartNo = 'MPN123';

            inventoryFunctionsMcS.TableOfZbapiOrdstk outputTable = new inventoryFunctionsMcS.TableOfZbapiOrdstk();
            outputTable.item = new List<inventoryFunctionsMcS.ZbapiOrdstk>{ stockItem };

            inventoryFunctionsMcS.ZbapiOrderstockResponse_element responseElement = new inventoryFunctionsMcS.ZbapiOrderstockResponse_element();
            responseElement.Output = outputTable;

            response.put('response_x', responseElement);
        }
    }

    @isTest
    static void testZbapiOrderstock() {
        Test.setMock(WebServiceMock.class, new ZBAPIOrderStockMock());

        Test.startTest();
        inventoryFunctionsMcS.ZBAPI_ORDERSTOCK1 service = new inventoryFunctionsMcS.ZBAPI_ORDERSTOCK1();

        String matnr = 'MAT001';
        inventoryFunctionsMcS.TableOfZbapiOrdstk output = new inventoryFunctionsMcS.TableOfZbapiOrdstk();
        String werks = 'PL01';

        inventoryFunctionsMcS.TableOfZbapiOrdstk result = service.ZbapiOrderstock(matnr, output, werks);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.item);
        System.assertEquals(1, result.item.size());
        System.assertEquals('MAT001', result.item[0].Material);
    }
}