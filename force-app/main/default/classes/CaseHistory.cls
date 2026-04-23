public with sharing class CaseHistory {
    // @AuraEnabled(cacheable=true)
    // public static List<Map<String, Object>> getAssetData(String caseId) {
    //     List<Asset> assets = [
    //         SELECT Id, Name,
    //             (SELECT Id, Name FROM Asset_AMCs__r),
    //             (SELECT Id, Name FROM Asset_Warrantys__r),
    //             (SELECT Id FROM Cases)
    //         FROM Asset
    //         WHERE Id IN (SELECT AssetId FROM Case WHERE Id = :caseId)
    //     ];

    //     // Prepare the result as a list of maps for structured data
    //     List<Map<String, Object>> result = new List<Map<String, Object>>();
    //     for (Asset asset : assets) {
    //         Map<String, Object> assetData = new Map<String, Object>();
    //         assetData.put('assetId', asset.Id);
    //         assetData.put('assetName', asset.Name);

    //         List<Map<String, String>> amcs = new List<Map<String, String>>();
    //         if (asset.Asset_AMCs__r != null) {
    //             for (Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                 amcs.add(new Map<String, String>{ 'id' => amc.Id, 'name' => amc.Name });
    //             }
    //         }
    //         assetData.put('amcs', amcs);

    //         List<Map<String, String>> warranties = new List<Map<String, String>>();
    //         if (asset.Asset_Warrantys__r != null) {
    //             for (Asset_Warranty__c warranty : asset.Asset_Warrantys__r) {
    //                 warranties.add(new Map<String, String>{ 'id' => warranty.Id, 'name' => warranty.Name });
    //             }
    //         }
    //         assetData.put('warranties', warranties);

    //         List<String> cases = new List<String>();
    //         if (asset.Cases != null) {
    //             for (Case caseRecord : asset.Cases) {
    //                 cases.add(caseRecord.Id);
    //             }
    //         }
    //         assetData.put('cases', cases);

    //         result.add(assetData);
    //     }

    //     return result;
    // }



    // @AuraEnabled(cacheable=true)
    // public static List<Map<String, Object>> getAssetDetails(String caseId) {
    //     Case cs = [SELECT AssetId FROM Case WHERE Id = :caseId];
    //     List<Asset> assets = [
    //         SELECT Id, Name,OwnerId,Owner.Name, SerialNumber, Invoice_Number__c, Contract_No__c, Contract_Name__c, Type__c,
    //         (
    //             SELECT Id, Name, Sales_Order_No__c, Sales_Order_Date__c, Invoice_No__c, Invoice_Date__c, Payment_Term__c, Year__c, Date_of_Activation__c,
    //             AMC_Start_Date__c, Invoice_Term__c, AMC_End_Date__c, Asset_Type__c
    //             FROM Asset_AMCs__r
    //         ),
    //         (
    //             SELECT Id, Name, Engineer_Name__c, Sales_Order_No__c, Sales_Order_Date__c, Delivery_Order_No__c, Delivery_Order_Date__c, Invoice_No__c,
    //             Invoice_Date__c, Year__c, Date_of_Commissioning__c, Warranty_Start_Date__c, Warranty_End_Date__c, Asset_Type__c, Warranty_Visit__c
    //             FROM Asset_Warranty__r
    //         ),
    //         (
    //             SELECT Id, CaseNumber, AssetId, Assign_To__c, Re_Assign_To__c, Case_Raise_By_Engineer__c, Division__c, CurrencyIsoCode, Type,
    //             Status, Reason, CreatedDate, Origin, Priority, Description
    //             FROM Cases
    //         )
    //         FROM Asset
    //         WHERE Id = :cs.AssetId
    //     ];

    //     System.debug('Assets: ' + assets);

    //     List<Map<String, Object>> result = new List<Map<String, Object>>();
    //     for (Asset asset : assets) {
    //         Map<String, Object> assetData = new Map<String, Object>();
    //         assetData.put('Id', asset.Id);
    //         assetData.put('Name', asset.Name);
    //         assetData.put('OwnerName', asset.Owner.Name);
    //         assetData.put('SerialNumber', asset.SerialNumber);
    //         assetData.put('InvoiceNumber', asset.Invoice_Number__c);
    //         assetData.put('ContractNo', asset.Contract_No__c);
    //         assetData.put('ContractName', asset.Contract_Name__c);
    //         // assetData.put('ServiceResource', asset.Service_Resource__c);
    //         assetData.put('Type', asset.Type__c);

    //         List<Map<String, Object>> amcs = new List<Map<String, Object>>();
    //         // if (asset.Asset_AMCs__r != null) {
    //             for (Asset_AMC__c amc : asset.Asset_AMCs__r) {
    //                 amcs.add(new Map<String, Object>{
    //                     'Id' => amc.Id,
    //                     'Name' => amc.Name,
    //                     'SalesOrderNo' => amc.Sales_Order_No__c,
    //                     'SalesOrderDate' => amc.Sales_Order_Date__c,
    //                     'InvoiceNo' => amc.Invoice_No__c,
    //                     'InvoiceDate' => amc.Invoice_Date__c,
    //                     'PaymentTerm' => amc.Payment_Term__c,
    //                     'Year' => amc.Year__c,
    //                     'DateOfActivation' => amc.Date_of_Activation__c,
    //                     'AMCStartDate' => amc.AMC_Start_Date__c,
    //                     'InvoiceTerm' => amc.Invoice_Term__c,
    //                     'AMCEndDate' => amc.AMC_End_Date__c,
    //                     'AssetType' => amc.Asset_Type__c
    //                 });
    //             }
    //         // }
    //         System.debug('AMCs for Asset ' + asset.Id + ': ' + amcs);
    //         assetData.put('AMCs', amcs);

    //         List<Map<String, Object>> warranties = new List<Map<String, Object>>();
    //         // if (asset.Asset_Warrantys__r != null) {
    //             for (Asset_Warranty__c warranty : asset.Asset_Warranty__r) {
    //                 warranties.add(new Map<String, Object>{
    //                     'Id' => warranty.Id,
    //                     'Name' => warranty.Name,
    //                     //'Product' => warranty.Product__c,
    //                     'EngineerName' => warranty.Engineer_Name__c,
    //                     'SalesOrderNo' => warranty.Sales_Order_No__c,
    //                     'SalesOrderDate' => warranty.Sales_Order_Date__c,
    //                     'DeliveryOrderNo' => warranty.Delivery_Order_No__c,
    //                     'DeliveryOrderDate' => warranty.Delivery_Order_Date__c,
    //                     'InvoiceNo' => warranty.Invoice_No__c,
    //                     'InvoiceDate' => warranty.Invoice_Date__c,
    //                     'Year' => warranty.Year__c,
    //                     'DateOfCommissioning' => warranty.Date_of_Commissioning__c,
    //                     'WarrantyStartDate' => warranty.Warranty_Start_Date__c,
    //                     'WarrantyEndDate' => warranty.Warranty_End_Date__c,
    //                     // 'Location' => warranty.Location__c,
    //                     'AssetType' => warranty.Asset_Type__c,
    //                     'WarrantyVisit' => warranty.Warranty_Visit__c
    //                 });
    //             }
    //         // }
    //         System.debug('Warranties for Asset ' + asset.Id + ': ' + warranties);
    //         assetData.put('Warranties', warranties);

    //         List<Map<String, Object>> cases = new List<Map<String, Object>>();
    //         // if (asset.Cases != null) {
    //             for (Case caseRecord : asset.Cases) {
    //                 cases.add(new Map<String, Object>{
    //                     'Id' => caseRecord.Id,
    //                     'CaseNumber' => caseRecord.CaseNumber,
    //                     'AssetId' => caseRecord.AssetId,
    //                    // 'CasePincode' => caseRecord.Case_Pincode_del__c,
    //                     'AssignTo' => caseRecord.Assign_To__c,
    //                     'ReAssignTo' => caseRecord.Re_Assign_To__c,
    //                     'CaseRaiseByEngineer' => caseRecord.Case_Raise_By_Engineer__c,
    //                     'Division' => caseRecord.Division__c,
    //                     //'CasePincodeText' => caseRecord.Case_Pincode_Text__c,
    //                     'CurrencyIsoCode' => caseRecord.CurrencyIsoCode,
    //                     'Type' => caseRecord.Type,
    //                     'Status' => caseRecord.Status,
    //                     'Reason' => caseRecord.Reason,
    //                     'CreatedDate' => caseRecord.CreatedDate,
    //                     'Origin' => caseRecord.Origin,
    //                     'Priority' => caseRecord.Priority,
    //                     'Description' => caseRecord.Description
    //                 });
    //             }
    //         // }
    //         System.debug('Cases for Asset ' + asset.Id + ': ' + cases);
    //         assetData.put('Cases', cases);

    //         //
    //         // Add the Task records related to the Asset (via Service_Appointment__c and Case__r.AssetId)
    //         List<Map<String, Object>> tasks = new List<Map<String, Object>>();
    //         List<Task> taskRecords = [
    //             SELECT Id, Subject, WhoId, Who.Name,WhatId,What.Name,Description,ActivityDate,Owner.Name
    //             FROM Task
    //             WHERE WhatId IN (
    //                 SELECT Id
    //                 FROM Service_Appointment__c
    //                 WHERE Case__r.AssetId = :asset.Id
    //             )
    //         ];

    //         for (Task task : taskRecords) {
    //             tasks.add(new Map<String, Object> {
    //                 'Id' => task.Id,
    //                 'Subject' => task.Subject,
    //                 'WhoId' => task.WhoId,
    //                 'WhoName' => task.Who.Name,
    //                 'WhatId' => task.WhatId,
    //                 'WhatName' => task.What.Name,
    //                 'Description' => task.Description,
    //                 'ActivityDate' => task.ActivityDate,
    //                 'OwnerName' => task.Owner.Name
    //             });
    //         }
    //         System.debug('Tasks for Asset ' + asset.Id + ': ' + tasks);
    //         assetData.put('Tasks', tasks);

    //         result.add(assetData);
    //     }

    //         //

    //     //     result.add(assetData);
    //     // }
    //     System.debug('Final Result: ' + result);
    //     return result;
    // }
}