public with sharing class SendWarrantyExpiryNotification implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, Asset_Warranty_PO_Status__c, Warranty_End_Date__c,Asset__r.Service_Resource__r.User__c,Asset__r.Service_Resource__r.User__r.ManagerId,
            Days_remaining_to_expiry__c,Asset__r.End_Customer__c,Asset__r.ContactId,Asset_Warranty__c.Asset__c,Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__c,
            Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__r.User__c,Asset_Warranty__c.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,Asset_Warranty__c.Asset__r.Name,
            Asset__r.OwnerId,Renewal_Case__c
            FROM Asset_Warranty__c
            WHERE Days_remaining_to_expiry__c=45
            OR
            Days_remaining_to_expiry__c=38 OR
            Days_remaining_to_expiry__c=30
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Asset_Warranty__c> scope) {
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Case_Creation_Notification_To_BU_Heads'];
        List<case> caseList = new List<case>();
        Group openQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Open Queue' LIMIT 1];
        Id openQueueId = openQueue.Id;

        for (Asset_Warranty__c record : scope) {
            system.debug('Days_remaining_to_expiry__c'+record.Days_remaining_to_expiry__c);
            system.debug('Warranty_End_Date__c'+record.Warranty_End_Date__c);
            if(record.Days_remaining_to_expiry__c == 45) {
                String title = 'Warranty Expiry Notification';

                String body = 'Warranty for Asset ' + record.Asset__r.Name + ' is expiring in 45 days.';
                Set<String> recipientsIds = new Set<String>();
                // if(record.asset__r.Service_Resource__c != null) {
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__c);
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__r.ManagerId);
                // }
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__c);
                    if (record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId != null) {
                        recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId);
                    }
                } else if (record.Asset__r.OwnerId != null) {
                    recipientsIds.add(record.Asset__r.OwnerId);
                }


                if(recipientsIds.size() > 0) {
                    SendNotificationUtility.sendInAppNotification(record.Id, notificationType.Id, title, body, recipientsIds);
                }
            }
            if(record.Days_remaining_to_expiry__c == 38) {
                String title = 'Warranty Expiry Notification';
                String body = 'Warranty for Asset ' + record.Asset__r.Name + ' is expiring in 38 days.';
                Set<String> recipientsIds = new Set<String>();
                // if(record.asset__r.Service_Resource__c != null) {
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__c);
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__r.ManagerId);
                // }
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__c);
                    if (record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId != null) {
                        recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId);
                    }
                } else if (record.Asset__r.OwnerId != null) {
                    recipientsIds.add(record.Asset__r.OwnerId);
                }
                if(recipientsIds.size() > 0) {
                    SendNotificationUtility.sendInAppNotification(record.Id, notificationType.Id, title, body, recipientsIds);
                }
            }
            if(record.Days_remaining_to_expiry__c == 30) {
                String title = 'Warranty Expiry Notification';
                String body = 'Warranty for Asset ' + record.Asset__r.Name + ' is expiring in 30 days. System has created case for this.';
                Set<String> recipientsIds = new Set<String>();
                // if(record.asset__r.Service_Resource__c != null) {
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__c);
                //     recipientsIds.add(record.Asset__r.Service_Resource__r.User__r.ManagerId);
                // }
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__c);
                    if (record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId != null) {
                        recipientsIds.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId);
                    }
                } else if (record.Asset__r.OwnerId != null) {
                    recipientsIds.add(record.Asset__r.OwnerId);
                }

                if(recipientsIds.size() > 0) {
                    SendNotificationUtility.sendInAppNotification(record.Id, notificationType.Id, title, body, recipientsIds);
                }
                // Create a case for warranty expiry ,Asset, contact,account,case type, subtype, source,pincode, business vertical
                case newCase = new case();
                newCase.Subject = 'Warranty is going to expire in 30 days';
                newCase.Description = 'Warranty for Asset ' + record.Asset__r.Name + ' is expiring in 30 days. please check for AMC renewal.';
                newCase.Status = 'New';
                newCase.Priority = 'Medium';
                newCase.Origin = 'Web';
                newCase.AssetId = record.Asset__c;
                newCase.AccountId=record.Asset__r.End_Customer__c;
                newCase.ContactId=record.Asset__r.ContactId;
                newCase.type='Courtesy';
                newCase.Case_Sub_Type__c='Quote Negotiation';

                record.Renewal_Case__r = newCase;

                // if(record.Asset__r.Service_Resource__c!=null)
                // newCase.OwnerId=record.Asset__r.Service_Resource__r.User__c;
                // else {
                //     newCase.OwnerId=openQueueId;
                // }
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    newCase.OwnerId = record.Asset__r.Service_Engineer_Pincode_based__r.User__c;
                } else if (record.Asset__r.OwnerId != null) {
                    newCase.OwnerId = record.Asset__r.OwnerId;
                } else {
                    newCase.OwnerId = openQueueId;
                }
                caseList.add(newCase);


            }
        }
        if(caseList.size()>0) {
            insert caseList;

            List<Asset_Warranty__c> assetWarrantyList = new List<Asset_Warranty__c>();
            for (Asset_Warranty__c record : scope) {
                if(record.Days_remaining_to_expiry__c == 30 && record.Renewal_Case__r != null) {
                    record.Renewal_Case__c = record.Renewal_Case__r.Id;
                    assetWarrantyList.add(record);
                }
            }
            update assetWarrantyList;

            //fetch work order no
            system.debug('caseList'+caseList);
            Work_Order__c wo=[SELECT Id, Case__c,Case__r.AssetId, Case__r.Asset.Product2.Material_Group_6__c FROM Work_Order__c WHERE Case__c=:caseList[0].Id];
            Case cs=[Select Id,OwnerId FROM Case WHERE Id=:caseList[0].Id];
            List<Map<String, Object>> serviceProducts=fieldServiceRequest.getProductsByPartNo(wo.Id);

            Map<String, Warranty_Mapping__mdt> warrantyConfigMap = new Map<String, Warranty_Mapping__mdt>();
            for (Warranty_Mapping__mdt entry : [SELECT MG6_Code__c, Warranty_Period__c, Preventive_Visits__c, Breakdown_Visits__c FROM Warranty_Mapping__mdt]) {
                if(entry.Warranty_Period__c != null) {
                    warrantyConfigMap.put(entry.MG6_Code__c  + '-' + (Integer.valueOf(entry.Warranty_Period__c) ?? 0), entry);
                }
            }

            List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
            for(Map<String, Object> spare : serviceProducts){
                Object priceValue = spare.get('price');     //140 to 148 line commented and 149 -150 added
                Decimal unitPrice;
                if (priceValue == null || String.valueOf(priceValue).trim() == '') {
                    unitPrice = 0;
                }
                else {
                    unitPrice = (priceValue instanceof Decimal) ? (Decimal) priceValue : Decimal.valueOf(String.valueOf(priceValue));
                }

                Object amcValue = spare.get('AMCprice');
                Decimal amcPrice;
                if (amcValue == null || String.valueOf(amcValue).trim() == '') {
                    amcPrice = 0;
                }
                else {
                    amcPrice = (amcValue instanceof Decimal) ? (Decimal) amcValue : Decimal.valueOf(String.valueOf(amcValue));
                }

                Service_Request__c sr=new Service_Request__c();
                sr.Work_Order__c = wo.Id;
                sr.Item_Master__c=(String) spare.get('Id');
                sr.Case__c = wo.Case__c;
                sr.Asset__c = wo.Case__r.AssetId;
                sr.Quantity__c = 1;
                sr.Name = (String) spare.get('modelName');
                sr.Item_Description__c = (String) spare.get('modelDesc');
                sr.Price__c = unitPrice;
                sr.Original_Price__c = unitPrice;
                sr.Last_AMC_Price__c=amcPrice;
                sr.Warranty_Period__c='12';
                Warranty_Mapping__mdt entry = warrantyConfigMap.get((String) wo.Case__r.Asset.Product2.Material_Group_6__c + '-' + 12);
                if (entry != null) {
                    sr.Number_of_PM_Visit__c= String.valueOf(entry.Preventive_Visits__c);
                    sr.Number_of_Breakdown_Visit__c= String.valueOf(entry.Breakdown_Visits__c);
                } else {
                    sr.Number_of_PM_Visit__c= '0';
                    sr.Number_of_Breakdown_Visit__c= '0';
                }
                serviceRequests.add(sr);
            }

            if (!serviceRequests.isEmpty()) {
                UPSERT serviceRequests;
                RaiseOppAndQuoteController.raiseOppAndQuote(wo.Id,'frombatch', 'service');
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        // Optional: Add logic to send notifications or log completion
    }

}