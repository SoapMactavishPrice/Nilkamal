@isTest
public class PendingOrderSapSoapFunctionsMcS_Test {
    
    @isTest
    static void testZbapiPendOrderInstantiation() {
        PendingOrderSapSoapFunctionsMcS.ZbapiPendOrder order = new PendingOrderSapSoapFunctionsMcS.ZbapiPendOrder();

        order.Vbeln = '10000001';
        order.Audat = '2025-05-01';
        order.Kunnr = 'CUST001';
        order.Name1 = 'Test Customer';
        order.Ort01 = 'Mumbai';
        order.Regio = 'MH';
        order.Bstnk = 'PO12345';
        order.Posnr = '10';
        order.Matnr = 'MAT001';
        order.Arktx = 'Sample Material';
        order.Werks = 'PL01';
        order.Matkl = 'MATKL';
        order.Mvgr1 = 'Group1';
        order.Mvgr2 = 'Group2';
        order.Mvgr5 = 'Group5';
        order.Kwmeng = '100';
        order.Lfsta = 'C';
        order.Lfimg = '50';
        order.Balqty = '50';
        order.Bezei = 'Zone A';
        order.Salesman = 'John Doe';
        order.Salesgrp = 'SG01';
        order.Vkbur = 'VB01';
        order.SoText = 'Urgent';
        order.Vdatu = '2025-05-15';
        order.Ernam = 'admin';
        order.Ntgew = '10';
        order.Brgew = '12';
        order.Ntgep = 'Gross';
        order.Price = '500';
        order.Pricp = '100';
        order.Abgru = 'Reason1';
        order.Auart = 'OR';
        order.Kzwi5 = 'Disc';
        order.RAuart = 'ZOR';
        order.Vgbel = 'VB1234';
        order.Kunn2 = 'CUST002';
        order.Adrs = 'Billing Addr';
        order.Mfrpn = 'MPN001';
        order.Vrkme = 'EA';
        order.Usnam = 'SAPUSER';
        order.Delno = 'DN001';
        order.Pgino = 'PG001';
        order.Invno = 'INV001';
        order.Abrvw = 'View1';
        order.Usagedis = '10';
        order.Edatu = '2025-06-01';
        order.Itemtext = 'Item Note';
        order.Itemtext1 = 'Item Description';
        order.Holds = 'H1';
        order.Holdsp = 'ReasonHold';
        order.Vkorg = '1000';
        order.Vtweg = '10';
        order.Spart = '01';
        order.VsnmrV = 'SN123';
        order.Valdt = '2025-12-31';
        order.Labst = 'Available';
        order.Trame = 'Transport';
        order.J1ipanno = 'PAN123';
        order.Ihrez = 'IR001';
        order.Desplant = 'DP01';
        order.Lifsk = 'Z1';
        order.Bstdk = '2025-04-30';
        order.Stcd1 = 'TAX1';
        order.Stcd3 = 'TAX3';
        order.Stcd5 = 'TAX5';
        order.Steuc = 'EU1';
        order.Tval = 'TVAL';
        order.Coord = 'COORD1';
        order.Fabchk = 'YES';
        order.Scrprint = 'NO';
        order.LblHold = 'HOLD';
        order.Bklas = 'BK1';
        order.Bkbez = 'BK Desc';
        order.Gbstk = 'Status';
        order.OpenPo = 'YES';
        order.Ordcat = 'Cat1';
        order.Saleco = 'Sale Co';
        order.Bstkd = 'KD001';
        order.Gewei = 'KG';
        order.Meins = 'EA';
        order.SplStk = 'None';
        order.Cuname = 'Customer Unit';
        order.Inco1 = 'FOB';
        order.Inco2 = 'Mumbai';
        order.Status = 'Active';
        order.Fitbox = 'Yes';
        order.Kvgr1 = 'Key1';
        order.Kvgr2 = 'Key2';
        order.Kvgr3 = 'Key3';
        order.Kvgr4 = 'Key4';
        order.Kvgr5 = 'Key5';
        order.Zinstallation = 'INST001';
        order.ZinstallationSta = '2025-01-01';
        order.ZinstallationEnd = '2025-01-31';
        order.ZprojectCompl = 'Yes';
        order.ZuniqueProjectNo = 'PRJ001';

        System.assertEquals('10000001', order.Vbeln);
        System.assertEquals('PRJ001', order.ZuniqueProjectNo);
    }

    @isTest
    static void testZcrmSdPendOrderElement() {
        PendingOrderSapSoapFunctionsMcS.ZcrmSdPendOrder_element element =
            new PendingOrderSapSoapFunctionsMcS.ZcrmSdPendOrder_element();

        System.assertNotEquals(null, element);
    }   
}