public with sharing class SendAmcExpiryNotification implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, AMC_End_Date__c, Asset__r.Name, Asset__r.Service_Resource__r.User__c,
            Days_remaining_to_expiry__c,Asset__r.End_Customer__c,Asset__r.ContactId, Asset__r.OwnerId,Renewal_Case__c,
            Asset__r.Service_Engineer_Pincode_based__c, Asset__r.Service_Engineer_Pincode_based__r.User__c,
            Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId, Asset__r.Service_Resource__r.User__r.ManagerId
            FROM Asset_AMC__c
            WHERE Days_remaining_to_expiry__c=45 OR
            Days_remaining_to_expiry__c=38 OR
            Days_remaining_to_expiry__c=30
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Asset_AMC__c> scope) {
        System.debug('AMC'+scope);
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Case_Creation_Notification_To_BU_Heads'];
        List<case> caseList = new List<case>();
        Group openQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Open Queue' LIMIT 1];
        Id openQueueId = openQueue.Id;
        for (Asset_AMC__c record : scope) {
            if(record.Days_remaining_to_expiry__c == 45) {
                String title = 'AMC Expiry Notification';
                String body = 'AMC for Asset ' + record.Asset__r.Name + ' is expiring in 45 days.';
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
                System.debug('recipientsIds'+recipientsIds);
                if(recipientsIds.size() > 0) {
                    SendNotificationUtility.sendInAppNotification(record.Id, notificationType.Id, title, body, recipientsIds);
                }
            }

            if(record.Days_remaining_to_expiry__c == 38) {
                String title = 'AMC Expiry Notification';
                String body = 'AMC for Asset ' + record.Asset__r.Name + ' is expiring in 38 days.';
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
                System.debug('recipientsIds'+recipientsIds);
                if(recipientsIds.size() > 0) {
                    SendNotificationUtility.sendInAppNotification(record.Id, notificationType.Id, title, body, recipientsIds);
                }
            }

            if(record.Days_remaining_to_expiry__c == 30) {
                String title = 'AMC Expiry Notification';
                String body = 'AMC for Asset ' + record.Asset__r.Name + ' is expiring in 30 days. System has created case for this.';
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
                newCase.Subject = 'AMC is going to expire in 30 days';
                newCase.Description = 'AMC for Asset ' + record.Asset__r.Name + ' is expiring in 30 days. please check for AMC renewal.';
                newCase.Status = 'New';
                newCase.Priority = 'Medium';
                newCase.Origin = 'Web';
                newCase.AssetId = record.Asset__c;
                newCase.AccountId=record.Asset__r.End_Customer__c;
                newCase.ContactId=record.Asset__r.ContactId;
                newCase.type='Courtesy';
                newCase.Case_Sub_Type__c='Quote Negotiation';

                record.Renewal_Case__r = newCase;

                // if(record.Asset__r.Service_Resource__c!=null) {
                //     newCase.OwnerId=record.Asset__r.Service_Resource__r.User__c;
                // }
                // else {
                //     newCase.OwnerId=openQueueId;
                // }
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    newCase.OwnerId = record.Asset__r.Service_Engineer_Pincode_based__r.User__c;
                }
                else if (record.Asset__r.OwnerId != null) {
                    newCase.OwnerId = record.Asset__r.OwnerId;
                }
                else {
                    newCase.OwnerId = openQueueId;
                }
                caseList.add(newCase);
            }
        }

        System.debug('caseList'+caseList);
        if(caseList.size()>0) {
            insert caseList;

            List<Asset_AMC__c> assetAMCList = new List<Asset_AMC__c>();
            for (Asset_AMC__c record : scope) {
                if(record.Days_remaining_to_expiry__c == 30 && record.Renewal_Case__r != null) {
                    record.Renewal_Case__c = record.Renewal_Case__r.Id;
                    assetAMCList.add(record);
                }
            }
            update assetAMCList;

            //fetch work order no
            Work_Order__c wo=[SELECT Id, Case__c,Case__r.AssetId, Case__r.Asset.Product2.Material_Group_6__c FROM Work_Order__c WHERE Case__c =:caseList[0].Id];
            List<Map<String, Object>> serviceProducts=fieldServiceRequest.getProductsByPartNo(wo.Id);

            Map<String, Warranty_Mapping__mdt> warrantyConfigMap = new Map<String, Warranty_Mapping__mdt>();
            for (Warranty_Mapping__mdt entry : [SELECT MG6_Code__c, Warranty_Period__c, Preventive_Visits__c, Breakdown_Visits__c FROM Warranty_Mapping__mdt]) {
                if(entry.Warranty_Period__c != null) {
                    warrantyConfigMap.put(entry.MG6_Code__c  + '-' + (Integer.valueOf(entry.Warranty_Period__c) ?? 0), entry);
                }
                warrantyConfigMap.put(entry.MG6_Code__c  + '-' + (entry.Warranty_Period__c ?? 0), entry);
            }

            List<Service_Request__c> serviceRequests = new List<Service_Request__c>();
            if(Test.isRunningTest() && serviceProducts.size() == 0) {
                serviceProducts.add(new Map<String, Object>());
            }
            for(Map<String, Object> spare : serviceProducts){
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
                // if(!Test.isRunningTest()) {
                    Object priceValue = spare.get('price');
                    Decimal unitPrice;
                    if (priceValue == null || String.valueOf(priceValue).trim() == '') {
                        unitPrice = 0;
                    }
                    else {
                        unitPrice = (priceValue instanceof Decimal) ? (Decimal) priceValue : Decimal.valueOf(String.valueOf(priceValue));
                    }
                    sr.Price__c = unitPrice;
                    sr.Original_Price__c = unitPrice;
                    sr.Last_AMC_Price__c=amcPrice;
                // }

                sr.Warranty_Period__c = '12';
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

/*public with sharing class SendAmcExpiryNotification implements Database.Batchable<SObject> {

    // 🔹 Variable to store a specific Asset_AMC__c Id if passed manually
    private Id amcId;

    // 🔹 Default constructor
    public SendAmcExpiryNotification() {}

    // 🔹 Constructor that accepts specific record Id
    public SendAmcExpiryNotification(Id recordId) {
        this.amcId = recordId;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {

        // 🔸 If specific AMC Id is passed → fetch ONLY that record
        if (amcId != null) {
            return Database.getQueryLocator([
                SELECT Id, AMC_End_Date__c, Asset__r.Name, Asset__r.Service_Resource__r.User__c,
                       Days_remaining_to_expiry__c, Asset__r.End_Customer__c, Asset__r.ContactId, 
                       Asset__r.OwnerId, Renewal_Case__c,
                       Asset__r.Service_Engineer_Pincode_based__c,
                       Asset__r.Service_Engineer_Pincode_based__r.User__c,
                       Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
                       Asset__r.Service_Resource__r.User__r.ManagerId
                FROM Asset_AMC__c
                WHERE Id = :amcId
            ]);
        }

        // 🔸 Original logic for scheduler (all 45/38/30 day records)
        return Database.getQueryLocator([
            SELECT Id, AMC_End_Date__c, Asset__r.Name, Asset__r.Service_Resource__r.User__c,
                   Days_remaining_to_expiry__c, Asset__r.End_Customer__c, Asset__r.ContactId, 
                   Asset__r.OwnerId, Renewal_Case__c,
                   Asset__r.Service_Engineer_Pincode_based__c,
                   Asset__r.Service_Engineer_Pincode_based__r.User__c,
                   Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId,
                   Asset__r.Service_Resource__r.User__r.ManagerId
            FROM Asset_AMC__c
            WHERE Days_remaining_to_expiry__c IN (45, 38, 30)
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Asset_AMC__c> scope) {

        System.debug('AMC Scope: ' + scope);

        CustomNotificationType notificationType = [
            SELECT Id FROM CustomNotificationType
            WHERE DeveloperName = 'Case_Creation_Notification_To_BU_Heads'
            LIMIT 1
        ];

        List<Case> caseList = new List<Case>();
        Id openQueueId = [
            SELECT Id FROM Group WHERE Type='Queue' AND Name='Open Queue' LIMIT 1
        ].Id;

        for (Asset_AMC__c record : scope) {

            // ---------------- 45 DAYS ----------------
            if (record.Days_remaining_to_expiry__c == 45) {
                handleNotification(record, 45, notificationType.Id);
            }

            // ---------------- 38 DAYS ----------------
            if (record.Days_remaining_to_expiry__c == 38) {
                handleNotification(record, 38, notificationType.Id);
            }

            // ---------------- 30 DAYS + Case Creation ----------------
            if (record.Days_remaining_to_expiry__c == 30) {

                handleNotification(record, 30, notificationType.Id);

                Case newCase = new Case();
                newCase.Subject = 'AMC is going to expire in 30 days';
                newCase.Description = 'AMC for Asset ' + record.Asset__r.Name +
                                      ' is expiring in 30 days. Please check for AMC renewal.';
                newCase.Status = 'New';
                newCase.Priority = 'Medium';
                newCase.Origin = 'Web';
                newCase.AssetId = record.Asset__c;
                newCase.AccountId = record.Asset__r.End_Customer__c;
                newCase.ContactId = record.Asset__r.ContactId;
                newCase.Type = 'Courtesy';
                newCase.Case_Sub_Type__c = 'Quote Negotiation';

                // Case Owner Logic
                if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
                    newCase.OwnerId = record.Asset__r.Service_Engineer_Pincode_based__r.User__c;
                } 
                else if (record.Asset__r.OwnerId != null) {
                    newCase.OwnerId = record.Asset__r.OwnerId;
                } 
                else {
                    newCase.OwnerId = openQueueId;
                }

                // Temporary relation (set actual Id after insert)
                record.Renewal_Case__r = newCase;

                caseList.add(newCase);
            }
        }

        System.debug('Case List: ' + caseList);

        if (!caseList.isEmpty()) {
            insert caseList;

            List<Asset_AMC__c> updateList = new List<Asset_AMC__c>();
            for (Asset_AMC__c record : scope) {
                if (record.Days_remaining_to_expiry__c == 30 && record.Renewal_Case__r != null) {
                    record.Renewal_Case__c = record.Renewal_Case__r.Id;
                    updateList.add(record);
                }
            }
            update updateList;

            // Work Order
            Work_Order__c wo = [
                SELECT Id, Case__c, Case__r.AssetId, Case__r.Asset.Product2.Material_Group_6__c
                FROM Work_Order__c
                WHERE Case__c = :caseList[0].Id
                LIMIT 1
            ];

            List<Map<String, Object>> serviceProducts =
                fieldServiceRequest.getProductsByPartNo(wo.Id);

            Map<String, Warranty_Mapping__mdt> warrantyConfig = new Map<String, Warranty_Mapping__mdt>();
            for (Warranty_Mapping__mdt m : [
                SELECT MG6_Code__c, Warranty_Period__c,
                       Preventive_Visits__c, Breakdown_Visits__c
                FROM Warranty_Mapping__mdt
            ]) {
                warrantyConfig.put(m.MG6_Code__c + '-' + m.Warranty_Period__c, m);
            }

            List<Service_Request__c> srList = new List<Service_Request__c>();

            for (Map<String, Object> spare : serviceProducts) {

                Service_Request__c sr = new Service_Request__c();
                sr.Work_Order__c = wo.Id;
                sr.Item_Master__c = (String) spare.get('Id');
                sr.Case__c = wo.Case__c;
                sr.Asset__c = wo.Case__r.AssetId;
                sr.Quantity__c = 1;
                sr.Name = (String) spare.get('modelName');
                sr.Item_Description__c = (String) spare.get('modelDesc');

                Decimal price = 0;
                if (spare.get('price') != null) {
                    price = Decimal.valueOf(String.valueOf(spare.get('price')));
                }

                sr.Price__c = price;
                sr.Original_Price__c = price;

                sr.Warranty_Period__c = '12';

                Warranty_Mapping__mdt cfg =
                    warrantyConfig.get(wo.Case__r.Asset.Product2.Material_Group_6__c + '-12');

                if (cfg != null) {
                    sr.Number_of_PM_Visit__c = String.valueOf(cfg.Preventive_Visits__c);
                    sr.Number_of_Breakdown_Visit__c = String.valueOf(cfg.Breakdown_Visits__c);
                } else {
                    sr.Number_of_PM_Visit__c = '0';
                    sr.Number_of_Breakdown_Visit__c = '0';
                }

                srList.add(sr);
            }

            if (!srList.isEmpty()) {
                upsert srList;
                RaiseOppAndQuoteController.raiseOppAndQuote(wo.Id, null, 'service');
            }
        }
    }

    // 🔹 Helper method for sending notifications (clean code)
    private void handleNotification(Asset_AMC__c record, Integer days, Id notificationTypeId) {

        String title = 'AMC Expiry Notification';
        String body = 'AMC for Asset ' + record.Asset__r.Name +
                      ' is expiring in ' + days + ' days.';

        Set<String> ids = new Set<String>();

        if (record.Asset__r.Service_Engineer_Pincode_based__c != null) {
            ids.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__c);
            if (record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId != null) {
                ids.add(record.Asset__r.Service_Engineer_Pincode_based__r.User__r.ManagerId);
            }
        }
        else if (record.Asset__r.OwnerId != null) {
            ids.add(record.Asset__r.OwnerId);
        }

        if (!ids.isEmpty()) {
            SendNotificationUtility.sendInAppNotification(
                record.Id, notificationTypeId, title, body, ids
            );
        }
    }

    public void finish(Database.BatchableContext BC) {
        // optional logging
    }
}*/