/**
* @File Name : IntegrationHandler.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : December 17, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | December 17, 2024 |   | Initial Version
**/

public class IntegrationHandler {

    public static void getPriceList(String prodCode, String saleOrg, String dist){
        sapComDocumentSapRfcFunctions.getPriceList(new Set<String>{prodCode}, saleOrg, dist);
    }

    public static void getMaterialPriceList(String saleOrg, String dist,String materialgroup){
        sapComDocumentSapRfcFunctions.getMaterialPriceList(new Set<String>{materialgroup},saleOrg,dist);
    }

    /*
    public static void getReturnableSample(){
        try {
            // Instantiate the web service class
            ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS service = new ReturnableSample.ZCRM_RETURNABLE_SAMPLES_WS();

            // Call the API method
            ReturnableSample.ZcrmRsamplesOutput response = service.ZcrmReturnableSamples('');

            // Check if response contains data
            if (response != null && response.item != null) {
                for (ReturnableSample.ZcrmCustomerSampleOutStr sample : response.item) {
                    System.debug('Sample Data: ' + sample);
                }
            } else {
                System.debug('No data returned from the API.');
            }
        } catch (Exception e) {
            System.debug('Error calling API: ' + e.getMessage());
        }
    }
    */

    public static void sendOrder(String quoteId){
        // Query the Quote and its related Line Items
        Quote quoteRecord = [
            SELECT Id, Name, OpportunityId
            FROM Quote
            WHERE Id = :quoteId
        ];

        List<QuoteLineItem> quoteLineItems = [
            SELECT Id, QuoteId, Product2Id, Product2.Name, Quantity, UnitPrice, TotalPrice,
            Discount, PricebookEntry.Product2Id
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId];


        // Instantiate the main request object
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreate_element request = new sapOrderAPIFunctionsMcS.ZbapiSalesorderCreate_element();

        // Set Order Header from Quote record
        sapOrderAPIFunctionsMcS.Bapisdhd1 orderHeader = new sapOrderAPIFunctionsMcS.Bapisdhd1();
        orderHeader.DocType = 'ZDOR';  // Hardcoded - Can be fetched if required
        orderHeader.SalesOrg = '1000'; // Example: Replace with your org-specific data
        orderHeader.DistrChan = '10';
        orderHeader.Division = '01';
        orderHeader.PurchDate = '2024-07-31'; // Using today's date
        orderHeader.Incoterms1 = 'NK2';
        orderHeader.Incoterms2 = 'FREIGHT PAID'; // Modify as per your logic
        orderHeader.Pmnttrms = 'NO';
        orderHeader.PurchNoC = 'BAP/24-25/PO/15';

        // Assign order header to request
        request.OrderHeaderIn = orderHeader;

        // Create Order Items from Quote Line Items
        sapOrderAPIFunctionsMcS.TableOfBapisditm orderItems = new sapOrderAPIFunctionsMcS.TableOfBapisditm();
        orderItems.item = new List<sapOrderAPIFunctionsMcS.Bapisditm>();

        sapOrderAPIFunctionsMcS.TableOfBapisditmx orderItems_x = new sapOrderAPIFunctionsMcS.TableOfBapisditmx();
        orderItems_x.item = new List<sapOrderAPIFunctionsMcS.Bapisditmx>();

        sapOrderAPIFunctionsMcS.TableOfBapischdl schItem = new sapOrderAPIFunctionsMcS.TableOfBapischdl();
        schItem.item = new List<sapOrderAPIFunctionsMcS.Bapischdl>();

        sapOrderAPIFunctionsMcS.TableOfBapischdlx schItem_x = new sapOrderAPIFunctionsMcS.TableOfBapischdlx();
        schItem_x.item = new List<sapOrderAPIFunctionsMcS.Bapischdlx>();

        Integer itemNumber = 10;
        Integer schNum = 1;
        for (QuoteLineItem qli : quoteLineItems) {
            sapOrderAPIFunctionsMcS.Bapisditm orderItem = new sapOrderAPIFunctionsMcS.Bapisditm();
            orderItem.ItmNumber = String.valueOf(itemNumber);
            orderItem.Material = qli.Product2.Name;
            orderItem.Plant = '1406'; // Modify if the plant is dynamically set
            orderItem.TargetQty = String.valueOf(qli.Quantity);

            orderItems.item.add(orderItem);

            sapOrderAPIFunctionsMcS.Bapisditmx orderItemx = new sapOrderAPIFunctionsMcS.Bapisditmx();
            orderItemx.ItmNumber = String.valueOf(itemNumber);
            orderItemx.Material = '';
            orderItemx.Plant = ''; // Modify if the plant is dynamically set
            orderItemx.TargetQty = '';
            orderItemx.Updateflag='I';
            orderItems_x.item.add(orderItemx);


            sapOrderAPIFunctionsMcS.Bapischdl scheItem= new sapOrderAPIFunctionsMcS.Bapischdl();
            scheItem.ItmNumber = String.valueOf(itemNumber);
            scheItem.SchedLine = String.valueOf(schNum);
            scheItem.ReqQty = String.valueOf(qli.Quantity);

            sapOrderAPIFunctionsMcS.Bapischdlx scheItem_x= new sapOrderAPIFunctionsMcS.Bapischdlx();
            scheItem_x.ItmNumber = String.valueOf(itemNumber);
            scheItem_x.SchedLine = String.valueOf(schNum);
            scheItem_x.ReqQty = '';
            scheItem_x.Updateflag='I';


            schItem.item.add(scheItem);
            schItem_x.item.add(scheItem_x);
            itemNumber += 10; // Increment item number for each item
            schNum+=1;
        }

        // Assign order items to request
        request.OrderItemsIn = orderItems;
        request.OrderItemsInx = orderItems_x;

        request.OrderSchedulesIn = schItem;
        request.OrderSchedulesInx = schItem_x;

        // Create Order Conditions from Quote Line Items (pricing data)
        sapOrderAPIFunctionsMcS.TableOfBapicond orderConditions = new sapOrderAPIFunctionsMcS.TableOfBapicond();
        orderConditions.item = new List<sapOrderAPIFunctionsMcS.Bapicond>();

        // Create Order Conditions from Quote Line Items (pricing data)
        sapOrderAPIFunctionsMcS.TableOfBapicondx orderConditions_x = new sapOrderAPIFunctionsMcS.TableOfBapicondx();
        orderConditions_x.item = new List<sapOrderAPIFunctionsMcS.Bapicondx>();

        itemNumber = 10;
        for (QuoteLineItem qli : quoteLineItems) {
            sapOrderAPIFunctionsMcS.Bapicond condition = new sapOrderAPIFunctionsMcS.Bapicond();
            condition.ItmNumber = String.valueOf(itemNumber);
            condition.CondStNo = '010';
            condition.CondCount = '01';
            condition.CondType = 'ZPR1';
            condition.CondValue = String.valueOf(qli.UnitPrice);

            orderConditions.item.add(condition);

            sapOrderAPIFunctionsMcS.Bapicondx conditionx = new sapOrderAPIFunctionsMcS.Bapicondx();
            conditionx.ItmNumber = String.valueOf(itemNumber);
            conditionx.CondStNo = '010';
            conditionx.CondCount = '01';
            conditionx.CondType = 'ZPR1';
            conditionx.Updateflag = 'U';
            conditionx.CondValue = '';

            orderConditions_x.item.add(conditionx);

            itemNumber += 10;
        }

        // Assign order conditions to request
        request.OrderConditionsIn = orderConditions;
        request.OrderConditionsInx = orderConditions_x;

        // Create Order Partners
        sapOrderAPIFunctionsMcS.TableOfBapiparnr orderPartners = new sapOrderAPIFunctionsMcS.TableOfBapiparnr();
        orderPartners.item = new List<sapOrderAPIFunctionsMcS.Bapiparnr>();

        sapOrderAPIFunctionsMcS.Bapiparnr partner = new sapOrderAPIFunctionsMcS.Bapiparnr();
        partner.PartnRole = 'AG';  // Example role - Modify as per your requirement
        partner.PartnNumb = '0000405039'; // Example partner number
        partner.Telephone2 = '9766121163'; // Example telephone
        partner.Telebox = 'MR. ABHIJIT BAR'; // Use Billing Name from Quote

        orderPartners.item.add(partner);

        // Assign partners to request
        request.OrderPartners = orderPartners;


        // Create partener address
        sapOrderAPIFunctionsMcS.TableOfBapiaddr1 PartAddre = new sapOrderAPIFunctionsMcS.TableOfBapiaddr1();
        PartAddre.item = new List<sapOrderAPIFunctionsMcS.Bapiaddr1>();

        sapOrderAPIFunctionsMcS.Bapiaddr1 partneradd = new sapOrderAPIFunctionsMcS.Bapiaddr1();
        partneradd.EMail='sales@baravkarautop.in';

        PartAddre.item.add(partneradd);
        request.Partneraddresses=PartAddre;

        // Set Sender
        sapOrderAPIFunctionsMcS.Sender sender = new sapOrderAPIFunctionsMcS.Sender();
        sender.LogSystem = 'SAPLOGSYS';
        request.Sender = sender;

        // Set User Information
        request.UserName = 'ahmedabad.ro@nilkamal.com';

        sapOrderAPIFunctionsMcS.TableOfBapiret2 return_x = new sapOrderAPIFunctionsMcS.TableOfBapiret2();

        // Create an instance of the API class
        sapOrderAPIFunctionsMcS.ZBAPI_SALESORDER_CREATE_V6 apiInstance = new sapOrderAPIFunctionsMcS.ZBAPI_SALESORDER_CREATE_V6();

        // Call the method correctly
        sapOrderAPIFunctionsMcS.ZbapiSalesorderCreateResponse_element response =
            apiInstance.ZbapiSalesorderCreate(
                orderConditions, orderConditions_x, orderHeader, orderItems, orderItems_x,
                orderPartners, schItem, schItem_x, PartAddre, quoteRecord.Name, 'Urgent',
                return_x, sender, 'ahmedabad.ro@nilkamal.com'
            );

        // Process Response
        if (response != null && response.Salesdocument != null) {
            System.debug('Order Created Successfully: ' + response.Salesdocument);
        } else {
            System.debug('Order Creation Failed: ' + response.Return_x);
        }





    }

    @AuraEnabled
    public static String sendSalesOrderRequest(String quoteId) {
        // Query the Quote and its related Line Items
        Quote quoteRecord = [
            SELECT Id, Contact.Name, Phone,Contact.FirstName,Contact.LastName,
            Document_No_1__c,Billing_Type__c,
            Expected_Close_Date__c,Quote_Document_Type__c,ContactId,Contact.Email, SAP_Order_No__c,SAP_Response_Message__c,Bill_to_Party__c,Bill_to_Party__r.SAP_Customer_code__c,Ship_to_Party__c,Ship_to_Party__r.SAP_Customer_code__c,Name,Document_No__c,Customer_PO_Number__c,Customer_PO_Date__c,OpportunityId,Sales_Organizations__r.Sales_Org_Code__c,
            Distribution_Channel__r.Distribution_Code__c,Division__r.Division_Code__c,Inco_Terms__c,Inco_Remark__c,Payment_Terms__c,Delivery_Plant__c,Delivery_Plant__r.Plant_Code__c
            FROM Quote WHERE Id = :quoteId
        ];

        Boolean isDiff=false;
        if(quoteRecord.Bill_to_Party__c!=quoteRecord.Ship_to_Party__c){
            isDiff=true;
        }

        List<QuoteLineItem> quoteLineItems = [
            SELECT Id, QuoteId,Discount_In_Value__c, Product2Id, Product2.Name,Product2.ProductCode,Product2.Plant_Master__r.Plant_Code__c,Quantity, UnitPrice, TotalPrice,
            Discount, PricebookEntry.Product2Id,Warranty_Months__c
            FROM QuoteLineItem WHERE QuoteId = :quoteId
        ];
        String Dlvschduse='';
        List<Quote_Service_Line_Item__c> quoteServLineItems =new List<Quote_Service_Line_Item__c>();
        if(quoteRecord.Quote_Document_Type__c!='Spares'){
            quoteServLineItems= [
                SELECT Id,Discounted_Basic_Unit_Price__c, Quote__c,Service_Amount__c, Item_Master__c, Item_Master__r.Name,Item_Master__r.ProductCode,Item_Master__r.Plant_Master__r.Plant_Code__c,Quantity__c
                FROM Quote_Service_Line_Item__c WHERE Quote__c = :quoteId
            ];
            if(quoteServLineItems.size()>0){
                 if(quoteServLineItems[0].Item_Master__r.ProductCode =='MHEAMCSER' || quoteServLineItems[0].Item_Master__r.ProductCode =='MHECAMCSER'){
                    Dlvschduse ='11';
                }else{
                    Dlvschduse='15';
                }
            }
           
        }


        Date poDate=quoteRecord.Customer_PO_Date__c;
        String poformattedDate = DateTime.newInstance(poDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
        // Remove all non-alphanumeric characters except spaces, hyphen, underscore
        String sanitizedPONumber = (quoteRecord.Customer_PO_Number__c != null) ? quoteRecord.Customer_PO_Number__c.replaceAll('[^a-zA-Z0-9\\s-_]', '') : '';

        API_log__c apiLog=new API_log__c();
        apiLog.Log_Name__c ='Order API';
        HttpUtils.APIparamter util=HttpUtils.getWSDLAPIdetails('OrderAPI');

        String endpoint = util.Endpoint;
        String requestBody = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">'
            + '   <soapenv:Header/>'
            + '   <soapenv:Body>'
            + '      <urn:ZbapiSalesorderCreate>'
            + '         <OrderConditionsIn>';
                Integer conitemNumber = 10;
                if(quoteRecord.Quote_Document_Type__c=='Spares'){
                    for (QuoteLineItem qli : quoteLineItems) {
                        requestBody += '<item>'
                            + '<ItmNumber>0000' + String.valueOf(conitemNumber) + '</ItmNumber>'
                            + '<CondStNo>010</CondStNo>'
                            + '<CondCount>01</CondCount>';
                            if(quoteRecord.Quote_Document_Type__c=='Spares' && quoteRecord.Billing_Type__c=='FOC and Non-Returnable'){
                                requestBody+='<CondType>ZPRF</CondType>';
                            }else{
                                requestBody+='<CondType>ZPR1</CondType>';
                            }
                            requestBody+= '<CondValue>' + String.valueOf(qli.Discount_In_Value__c) + '</CondValue>'
                            + '<Currency>INR</Currency>'
                            + '</item>';
                        conitemNumber += 10;
                    }
                }else{
                    for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                        requestBody += '<item>'
                            + '<ItmNumber>0000' + String.valueOf(conitemNumber) + '</ItmNumber>'
                            + '<CondStNo>010</CondStNo>'
                            + '<CondCount>01</CondCount>';
                            if(quoteRecord.Quote_Document_Type__c=='AMC' || quoteRecord.Quote_Document_Type__c=='Chargeable Service'){
                                requestBody+='<CondType>ZS00</CondType>';
                            }else{
                                requestBody+='<CondType>ZPR1</CondType>';
                            }
                            requestBody+= '<CondValue>' + String.valueOf(qli.Discounted_Basic_Unit_Price__c) + '</CondValue>'
                            + '<Currency>INR</Currency>'
                            + '</item>';
                        conitemNumber += 10;
                    }
                }
                requestBody += '         </OrderConditionsIn>'
                    + '<OrderConditionsInx>';
                Integer conitemNumberx = 10;
                if(quoteRecord.Quote_Document_Type__c=='Spares'){
                    for (QuoteLineItem qli : quoteLineItems) {
                        requestBody += '<item>'
                            + '<ItmNumber>0000' + String.valueOf(conitemNumberx) + '</ItmNumber>'
                            + '<CondStNo>010</CondStNo>'
                            + '<CondCount>01</CondCount>';
                            if(quoteRecord.Quote_Document_Type__c=='Spares' && quoteRecord.Billing_Type__c=='FOC and Non-Returnable'){
                                requestBody+='<CondType>ZPRF</CondType>';
                            }else{
                                requestBody+='<CondType>ZPR1</CondType>';
                            }
                            requestBody+= '<Updateflag>U</Updateflag>'
                            + '<CondValue>X</CondValue>'
                            + '<Currency>X</Currency>'
                            + '</item>';
                        conitemNumberx += 10;
                    }
                }else{
                    for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                        requestBody += '<item>'
                            + '<ItmNumber>0000' + String.valueOf(conitemNumberx) + '</ItmNumber>'
                            + '<CondStNo>010</CondStNo>'
                            + '<CondCount>01</CondCount>';
                            if(quoteRecord.Quote_Document_Type__c=='AMC' || quoteRecord.Quote_Document_Type__c=='Chargeable Service'){
                                requestBody+='<CondType>ZS00</CondType>';
                            }else{
                                requestBody+='<CondType>ZPR1</CondType>';
                            }
                            requestBody+= '<Updateflag>U</Updateflag>'
                            + '<CondValue>X</CondValue>'
                            + '<Currency>X</Currency>'
                            + '</item>';
                        conitemNumberx += 10;
                    }
                }
                requestBody += '</OrderConditionsInx>'
            + '<OrderHeaderIn>';
            if(quoteRecord.Quote_Document_Type__c=='Spares'){
                if(quoteRecord.Billing_Type__c=='FOC and Returnable'){
                    requestBody+='<DocType>ZSOA</DocType>';
                }
                if(quoteRecord.Billing_Type__c=='FOC and Non-Returnable'){
                    requestBody+='<DocType>ZEFO</DocType>';
                }
                if(quoteRecord.Billing_Type__c=='Chargeable'){
                    requestBody+='<DocType>ZDOR</DocType>';
                }
            }else if(quoteRecord.Quote_Document_Type__c=='AMC' || quoteRecord.Quote_Document_Type__c=='Chargeable Service'){
                requestBody+='<DocType>ZSER</DocType>';
            }

            requestBody+=' <SalesOrg>' + String.valueOf(quoteRecord.Sales_Organizations__r.Sales_Org_Code__c!=null?quoteRecord.Sales_Organizations__r.Sales_Org_Code__c:'') + '</SalesOrg>'
            + '            <DistrChan>' + String.valueOf(quoteRecord.Distribution_Channel__r.Distribution_Code__c!=null?quoteRecord.Distribution_Channel__r.Distribution_Code__c:'') + '</DistrChan>'
            + '            <Division>' + String.valueOf(quoteRecord.Division__r.Division_Code__c!=null?quoteRecord.Division__r.Division_Code__c:'') + '</Division>'
            + '            <PurchDate>' + poformattedDate + '</PurchDate>'
            + '            <Incoterms1>' + quoteRecord.Inco_Terms__c + '</Incoterms1>';
            if(quoteRecord.Inco_Terms__c=='NK2'){
                requestBody+= '<Incoterms2>Freight Paid</Incoterms2>';
            }
            if(quoteRecord.Quote_Document_Type__c!='Spares'){
                requestBody+= '<Dlvschduse>' + Dlvschduse + '</Dlvschduse>';
            }
            requestBody+= '<Pmnttrms>' + quoteRecord.Payment_Terms__c + '</Pmnttrms>'
            + '            <PurchNoC>' + sanitizedPONumber + '</PurchNoC>'
            + '         </OrderHeaderIn>'
            + '         <OrderHeaderInx>'
            + '            <Updateflag>I</Updateflag>'
            + '            <DocType>X</DocType>'
            + '            <SalesOrg>X</SalesOrg>'
            + '            <DistrChan>X</DistrChan>'
            + '            <Division>X</Division>'
            + '            <PurchDate>X</PurchDate>'
            + '            <Incoterms1>X</Incoterms1>'
            + '            <Incoterms2>X</Incoterms2>';
            if(quoteRecord.Quote_Document_Type__c!='Spares'){
                requestBody+= '<Dlvschduse>X</Dlvschduse>';
            }
            requestBody+= '            <Pmnttrms>X</Pmnttrms>'
            + '            <PurchNoC>X</PurchNoC>'
            + '         </OrderHeaderInx>'
            + '         <OrderItemsIn>';

        Integer itemNumber = 10;
        if(quoteRecord.Quote_Document_Type__c=='Spares'){
            for (QuoteLineItem qli : quoteLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(itemNumber) + '</ItmNumber>'
                    + '<Material>' + qli.Product2.ProductCode + '</Material>'
                    //+ '<Plant>1406</Plant>'
                    // + '<Plant>' +qli.Product2.Plant_Master__r.Plant_Code__c+ '</Plant>'
                    + '<Plant>' +String.valueOf(quoteRecord.Delivery_Plant__r.Plant_Code__c!=null?quoteRecord.Delivery_Plant__r.Plant_Code__c:'')+ '</Plant>'
                    + '<TargetQty>' + String.valueOf(qli.Quantity) + '</TargetQty>'
                    + '<ItemCateg></ItemCateg>'
                    + '<WarrentyTerm>' + (qli.Warranty_Months__c != null ? String.valueOf(qli.Warranty_Months__c) : '') + '</WarrentyTerm>'
                    + '<PrcGroup2/>'
                    + '</item>';
                itemNumber += 10;
            }
        }else{
            for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(itemNumber) + '</ItmNumber>'
                    + '<Material>' + qli.Item_Master__r.ProductCode + '</Material>'
                    // + '<Plant>' +qli.Item_Master__r.Plant_Master__r.Plant_Code__c+ '</Plant>'
                    + '<Plant>' +String.valueOf(quoteRecord.Delivery_Plant__r.Plant_Code__c!=null?quoteRecord.Delivery_Plant__r.Plant_Code__c:'')+ '</Plant>'
                    + '<TargetQty>' + String.valueOf(qli.Quantity__c) + '</TargetQty>'
                    + '<ItemCateg></ItemCateg>'
                    + '<WarrentyTerm></WarrentyTerm>'
                    + '<PrcGroup2/>'
                    + '</item>';
                itemNumber += 10;
            }
        }
        requestBody += '         </OrderItemsIn>'
            + '         <OrderItemsInx>';

        Integer itemNumberx = 10;
        if(quoteRecord.Quote_Document_Type__c=='Spares'){
            for (QuoteLineItem qli : quoteLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(itemNumberx) + '</ItmNumber>'
                    + '<Updateflag>I</Updateflag>'
                    + '<Material>X</Material>'
                    + '<Plant>X</Plant>'
                    + '<TargetQty>X</TargetQty>'
                    + '<ItemCateg></ItemCateg>'
                    + '<WarrentyTerm>X</WarrentyTerm>'
                    + '<PrcGroup2/>'
                    + '<Ref1S/>'
                    + '<Campaign/>'
                    + '</item>';
                itemNumberx += 10;
            }
        }else{
            for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(itemNumberx) + '</ItmNumber>'
                    + '<Updateflag>I</Updateflag>'
                    + '<Material>X</Material>'
                    + '<Plant>X</Plant>'
                    + '<TargetQty>X</TargetQty>'
                    + '<ItemCateg></ItemCateg>'
                    + '<WarrentyTerm></WarrentyTerm>'
                    + '<PrcGroup2/>'
                    + '<Ref1S/>'
                    + '<Campaign/>'
                    + '</item>';
                itemNumberx += 10;
            }
        }

        requestBody += '         </OrderItemsInx>';
        String conname = '';
        if (quoteRecord.Contact != null && String.isNotBlank(quoteRecord.Contact.Name)) {
            String fullName = quoteRecord.Contact.LastName + ' ' + quoteRecord.Contact.FirstName;
            conname = (fullName.length() > 15) ? fullName.substring(0, 15) : fullName;
        }
        if(isDiff){
            
            requestBody+=   + '<OrderPartners>'
                +'<item>'
                + '<PartnRole>AG</PartnRole>'
                + '<PartnNumb>' + String.valueOf(quoteRecord.Bill_to_Party__r.SAP_Customer_code__c) + '</PartnNumb>'
                + '<Telephone2>' + String.valueOf(quoteRecord.Phone!=null?quoteRecord.Phone:'') + '</Telephone2>'
                + '<Telebox>' + conname + '</Telebox>'
                + '</item>'
                +'<item>'
                + '<PartnRole>WE</PartnRole>'
                + '<PartnNumb>' + String.valueOf(quoteRecord.Ship_to_Party__r.SAP_Customer_code__c) + '</PartnNumb>'
                + '<Telephone2>' + String.valueOf(quoteRecord.Phone!=null?quoteRecord.Phone:'') + '</Telephone2>'
                + '<Telebox>' + conname + '</Telebox>'
                + '</item>'
            + '</OrderPartners>';
        }else{
            requestBody+=    + '<OrderPartners>'
                +'<item>'
                + '<PartnRole>AG</PartnRole>'
                + '<PartnNumb>' + String.valueOf(quoteRecord.Bill_to_Party__r.SAP_Customer_code__c) + '</PartnNumb>'
                + '<Telephone2>' + String.valueOf(quoteRecord.Phone!=null?quoteRecord.Phone:'') + '</Telephone2>'
                + '<Telebox>' + conname + '</Telebox>'
                + '</item>'
            + '</OrderPartners>';
        }

        requestBody += '         <OrderSchedulesIn>';

        Integer schitemNumber = 10;
        Integer schedLine = 1;
        if(quoteRecord.Quote_Document_Type__c=='Spares'){

            for (QuoteLineItem qli : quoteLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(schitemNumber) + '</ItmNumber>'
                    + '<SchedLine>000' + String.valueOf(schedLine) + '</SchedLine>'
                    + '<ReqQty>' + String.valueOf(qli.Quantity) + '</ReqQty>'
                    + '</item>';
                schedLine++;
                schitemNumber += 10;
            }
        }else{
            for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(schitemNumber) + '</ItmNumber>'
                    + '<SchedLine>000' + String.valueOf(schedLine) + '</SchedLine>'
                    + '<ReqQty>' + String.valueOf(qli.Quantity__c) + '</ReqQty>'
                    + '</item>';
                schedLine++;
                schitemNumber += 10;
            }
        }
        requestBody += '         </OrderSchedulesIn>'
            + '         <OrderSchedulesInx>';

        Integer schitemNumberx = 10;
        Integer schedLinex = 1;
        if(quoteRecord.Quote_Document_Type__c=='Spares'){
            for (QuoteLineItem qli : quoteLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(schitemNumberx) + '</ItmNumber>'
                    + '<SchedLine>000' + String.valueOf(schedLinex) + '</SchedLine>'
                    + '<Updateflag>I</Updateflag>'
                    + '<ReqQty>X</ReqQty>'
                    + '</item>';
                schedLinex++;
                schitemNumberx += 10;
            }
        }else{
            for (Quote_Service_Line_Item__c qli : quoteServLineItems) {
                requestBody += '<item>'
                    + '<ItmNumber>0000' + String.valueOf(schitemNumberx) + '</ItmNumber>'
                    + '<SchedLine>000' + String.valueOf(schedLinex) + '</SchedLine>'
                    + '<Updateflag>I</Updateflag>'
                    + '<ReqQty>X</ReqQty>'
                    + '</item>';
                schedLinex++;
                schitemNumberx += 10;
            }
        }

        requestBody += '         </OrderSchedulesInx>'
            + '<Partneraddresses>'
                +'<item>'
                //+ '<EMail>sales@baravkarautop.in</EMail>'
                + '<EMail>' + String.valueOf(quoteRecord.Contact.Email!=null?quoteRecord.Contact.Email:'') + '</EMail>'
                + '</item>'
            + '</Partneraddresses>'
            + '<Quotation>' + String.valueOf(quoteRecord.Document_No_1__c) + '</Quotation>'
            + '<ReqType>Urgent</ReqType>'
            + '         <Return>'
            + '            <item>'
            + '               <Type/>'
            + '               <Id/>'
            + '               <Number/>'
            + '               <Message/>'
            + '               <LogNo/>'
            + '               <LogMsgNo/>'
            + '               <MessageV1/>'
            + '               <MessageV2/>'
            + '               <MessageV3/>'
            + '               <MessageV4/>'
            + '               <Parameter/>'
            + '               <Row/>'
            + '               <Field/>'
            + '               <System/>'
            + '            </item>'
            + '         </Return>'
            + '<UserName>ahmedabad.ro@nilkamal.com</UserName>'
            + '      </urn:ZbapiSalesorderCreate>'
            + '   </soapenv:Body>'
            + '</soapenv:Envelope>';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZbapiSalesorderCreate');
        req.setBody(requestBody);
        req.setTimeout(120000);

        Http http = new Http();
        // System.debug('===> '+JSON.serialize(req.getBody()));
        // System.debug('===> '+req.getBody());
        String reqBody = req.getBody();
        Integer maxLength = 131072; // RTA field size limit

        if(reqBody != null && reqBody.length() > maxLength){
            createFile('RequestBody.xml', reqBody, quoteRecord.Id);
            apiLog.Request__c = sanitizedPONumber+' Stored in file: RequestBody.xml ';
        }else{
            apiLog.Request__c = reqBody;
        }
        try {
            HttpResponse res = http.send(req);
            // System.debug('===> '+res.getBody());
            String resBody = (res != null) ? res.getBody() : '';
            if(resBody != null && resBody.length() > maxLength){
                createFile('ResponseBody.xml', resBody, quoteRecord.Id);
                apiLog.Response__c = sanitizedPONumber+' Stored in file: ResponseBody.xml';
            }else{
                apiLog.Response__c = resBody;
            }

            if(res.getStatusCode()==200){
                apiLog.Status__c='200';
                upsert apiLog;
                return parseResponse(res.getBody(),quoteRecord);
            }else if(res.getStatusCode()==503){
                apiLog.Status__c='503';
                upsert apiLog;
                return 'Service is down , please check with Admin';
            }else if(res.getStatusCode()==500){
                apiLog.Status__c='500';
                upsert apiLog;
                return res.getBody();
            }else{
                apiLog.Status__c='404';
                upsert apiLog;
                return 'Something went wrong , need to check with Admin ';
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            apiLog.Exception_Description__c=e.getMessage() +' : '+e.getCause()+' : '+e.getStackTraceString();
            apiLog.Status__c='Failed';
            upsert apiLog;
        }

        return '';
    }

    private static void createFile(String fileName, String body, Id quoteId){
        // Create the file (ContentVersion)
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = Blob.valueOf(body);
        insert cv;

        // Get ContentDocumentId from inserted ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id = :cv.Id 
                                LIMIT 1].ContentDocumentId;

        // Relate file to Quote
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = quoteId; // attach to Quote
        cdl.ShareType = 'V'; // Viewer access
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    // public static String parseResponse(String responseBody,Quote quoteRecor) {
    //     Dom.Document doc = new Dom.Document();
    //     doc.load(responseBody);

    //     // Navigate to the response body
    //     Dom.XMLNode responseNode = doc.getRootElement()
    //         .getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/')
    //         .getChildElement('ZbapiSalesorderCreateResponse', 'urn:sap-com:document:sap:soap:functions:mc-style');

    //     System.debug(responseNode);

    //     // Define XPath expression to extract return list
    //     List<Dom.XMLNode> returnItems = doc.getRootElement()
    //         .getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/')
    //         .getChildElement('ZbapiSalesorderCreateResponse', 'urn:sap-com:document:sap:soap:functions:mc-style')
    //         .getChildElement('Return', null)
    //         .getChildElements();

    //      // Extract Sales Document Number
    //     String salesDocumentNo = '';
    //     Dom.XMLNode salesDocumentNode = responseNode.getChildElement('Salesdocument', null);
    //     if (salesDocumentNode != null) {
    //         salesDocumentNo = salesDocumentNode.getText();
    //         if(quoteRecor.SAP_Order_No__c==null){
    //             quoteRecor.SAP_Order_No__c=salesDocumentNo;
    //             quoteRecor.Expected_Close_Date__c=Date.today();
    //             quoteRecor.Status = 'Order Created';
    //         }
    //     }

    //     List<String> messages = new List<String>();

    //     for (Dom.XMLNode itemNode : returnItems) {
    //         String message = itemNode.getChildElement('Message', null).getText();
    //         messages.add(message);
    //     }
    //     System.debug('Extracted Messages: ' + messages);
    //     quoteRecor.SAP_Response_Message__c=String.valueOf(messages);
    //     quoteRecor.SAP_Response_Date__c	= System.now();
    //     if(String.isBlank(quoteRecor.SAP_Order_No__c) && String.isNotBlank(quoteRecor.SAP_Response_Message__c)) {
    //         quoteRecor.Status='Error in Order';
    //     }
    //     update quoteRecor;
    //     if(salesDocumentNo ==''){
    //         return String.valueOf(messages);
    //     }else{
    //         return 'Order is Created successfully '+salesDocumentNo;
    //     }

    // }
    // Change Done In 25-11-2025 for message concatination
    public static String parseResponse(String responseBody, Quote quoteRecor) {
        Dom.Document doc = new Dom.Document();
        doc.load(responseBody);

        // Navigate to the response body
        Dom.XMLNode responseNode = doc.getRootElement()
            .getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/')
            .getChildElement('ZbapiSalesorderCreateResponse', 'urn:sap-com:document:sap:soap:functions:mc-style');

        System.debug(responseNode);

        // Define XPath expression to extract return list
        List<Dom.XMLNode> returnItems = doc.getRootElement()
            .getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/')
            .getChildElement('ZbapiSalesorderCreateResponse', 'urn:sap-com:document:sap:soap:functions:mc-style')
            .getChildElement('Return', null)
            .getChildElements();

        // Extract Sales Document Number
        String salesDocumentNo = '';
        Dom.XMLNode salesDocumentNode = responseNode.getChildElement('Salesdocument', null);
        if (salesDocumentNode != null) {
            salesDocumentNo = salesDocumentNode.getText();
            if(quoteRecor.SAP_Order_No__c == null) {
                quoteRecor.SAP_Order_No__c = salesDocumentNo;
                quoteRecor.Expected_Close_Date__c = Date.today();
                quoteRecor.Status = 'Order Created';
            }
        }

        List<String> messages = new List<String>();

        for (Dom.XMLNode itemNode : returnItems) {
            Dom.XMLNode messageNode = itemNode.getChildElement('Message', null);
            if (messageNode != null) {
                String message = messageNode.getText();
                if (String.isNotBlank(message)) {
                    messages.add(message);
                }
            }
        }
        
        System.debug('Extracted Messages: ' + messages);
        
        // Join all messages with a separator to preserve full content
        String fullMessage = String.join(messages, ', ');
        quoteRecor.SAP_Response_Message__c = fullMessage;
        quoteRecor.SAP_Response_Date__c = System.now();
        
        if(String.isBlank(quoteRecor.SAP_Order_No__c) && String.isNotBlank(quoteRecor.SAP_Response_Message__c)) {
            quoteRecor.Status = 'Error in Order';
        }
        
        update quoteRecor;
        
        if(String.isBlank(salesDocumentNo)) {
            return fullMessage;
        } else {
            return 'Order is Created successfully ' + salesDocumentNo + '. Messages: ' + fullMessage;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getOutStanding(String accId) {
        Account acc=[SELECT id,SAP_Customer_code__c FROM Account WHERE Id=:accId];
        HttpUtils.APIparamter util=HttpUtils.getWSDLAPIdetails('OutstandingAPI');

        String endpoint = util.Endpoint;
        String requestBody = '<?xml version="1.0" encoding="UTF-8"?>'
            + '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">'
            + '   <soapenv:Header/>'
            + '   <soapenv:Body>'
            + '      <urn:ZcrmSdCustomerOutstanding>'
                        + '<Customer>' + String.valueOf(acc.SAP_Customer_code__c) + '</Customer>'
            + '      </urn:ZcrmSdCustomerOutstanding>'
            + '   </soapenv:Body>'
            + '</soapenv:Envelope>';
        List<Map<String, String>> records = new List<Map<String, String>>();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        req.setHeader('SOAPAction', 'urn:sap-com:document:sap:soap:functions:mc-style:ZcrmSdCustomerOutstanding');
        req.setBody(requestBody);
        req.setTimeout(120000);

        Http http = new Http();
        System.debug('===> '+JSON.serialize(req.getBody()));
        System.debug('===> '+req.getBody());

        try {
            HttpResponse res = http.send(req);
            System.debug('===> '+res.getBody());
            if(res.getStatusCode()==200){
                Dom.Document doc = new Dom.Document();
                doc.load(res.getBody());
                Dom.XMLNode root = doc.getRootElement();
                Dom.XMLNode body = root.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');
                Dom.XMLNode response = body.getChildElement('ZcrmSdCustomerOutstandingResponse', 'urn:sap-com:document:sap:soap:functions:mc-style');
                Dom.XMLNode emCustomerOutstanding = response.getChildElement('EmCustomerOutstanding', null);

                for (Dom.XMLNode item : emCustomerOutstanding.getChildElements()) {
                    Map<String, String> record = new Map<String, String>();
                    for (Dom.XMLNode field : item.getChildElements()) {
                        record.put(field.getName(), field.getText());
                    }
                    records.add(record);
                }
            }

        } catch (Exception e) {
            System.debug('Error Parsing SOAP Response: ' + e.getMessage());
        }

        return records;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountNameById(String accId) {
        Account acc = [SELECT Name FROM Account WHERE Id = :accId LIMIT 1];
        return acc.Name;
    }


    @AuraEnabled
    public static Boolean validateQuoteItems(Id quoteId) {
        List<Quote_Service_Line_Item__c > items = [
            SELECT Id, Item_Master__r.Name, AMC_Start_Date__c, AMC_Period_In_Months__c
            FROM Quote_Service_Line_Item__c 
            WHERE Quote__c = :quoteId
        ];

        for (Quote_Service_Line_Item__c  item : items) {
            if (item.Item_Master__r.Name != null &&
                (item.Item_Master__r.Name.containsIgnoreCase('AMC') || item.Item_Master__r.Name.containsIgnoreCase('CAMC'))) {

                if (item.AMC_Start_Date__c == null || item.AMC_Period_In_Months__c == null) {
                    return false;
                }
            }
        }

        return true;
    }




}