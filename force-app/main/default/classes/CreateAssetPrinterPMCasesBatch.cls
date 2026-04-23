// global class CreateAssetPrinterPMCasesBatch implements System.Schedulable, Database.Batchable<sObject>, Database.Stateful {

//     Date targetDate;
//     Integer daysInterval = 90;

//     @TestVisible
//     private List<FailedAsset> failedAssets = new List<FailedAsset>();

//     global CreateAssetPrinterPMCasesBatch() {
//         this.targetDate = System.today();
//     }

//     global CreateAssetPrinterPMCasesBatch(Date targetDate) {
//         this.targetDate = targetDate;
//     }

//     global CreateAssetPrinterPMCasesBatch(Date targetDate, Integer daysInterval) {
//         this.targetDate = targetDate;
//         this.daysInterval = daysInterval;
//     }

//     global void execute(SchedulableContext sc) {
//         Database.executeBatch(this, 10);
//     }

//     global Database.QueryLocator start(Database.BatchableContext bc) {
//         String query = 'SELECT Id, Name, AccountId, ContactId, Business_Vertical__c, ' +
//             'Pin_Code_Master__c, InstallDate, Invoice__r.Billing_Date__c, ' +
//             'Status, Product2.Manufacturing_Part_No1__r.Name ' +
//             'FROM Asset ' +
//             'WHERE Status != \'Expired\' ' +
//             'AND (InstallDate != null OR Invoice__r.Billing_Date__c != null) ' ;
//             // 'AND Product2.Manufacturing_Part_No1__r.Name != \'MHE SIMPLE\' ';

//         return Database.getQueryLocator(query);
//     }

//     global void execute(Database.BatchableContext bc, List<Asset> scope) {
//         System.debug('Processing ' + scope.size() + ' assets');
//         if (scope == null || scope.isEmpty()) return;

//         List<Case> casesToInsert = new List<Case>();
//         Map<Integer, Asset> idxToAsset = new Map<Integer, Asset>();

//         Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'Open_Queue' LIMIT 1].Id;

//         Integer idx = 0;
//         for (Asset assetRecord : scope) {
//             try {
//                 Date baseDate = assetRecord.InstallDate != null ? 
//                               assetRecord.InstallDate : 
//                               assetRecord.Invoice__r.Billing_Date__c;

//                 if (baseDate == null) {
//                     idx++;
//                     continue;
//                 }

//                 // Calculate if today is a PM due date (every 90 days from base date)
//                 Integer daysSinceBase = baseDate.daysBetween(targetDate);

//                 //Boolean isDueDate = (daysSinceBase > 0 && Math.mod(daysSinceBase, daysInterval) == 0);
//                 Boolean isDueForPM = (daysSinceBase >= daysInterval);


//         //         if (isDueDate) {
//         //             Integer intervalCount = daysSinceBase / daysInterval;
//         //             String dateSource = assetRecord.InstallDate != null ? 'Installation Date' : 'Invoice Billing Date';
                    
//         //             Case newCase = new Case(
//         //                 AssetId         = assetRecord.Id,
//         //                 AccountId       = assetRecord.AccountId,
//         //                 ContactId       = assetRecord.ContactId,
//         //                 Case_Pincode__c = assetRecord.Pin_Code_Master__c,
//         //                 Division__c     = assetRecord.Business_Vertical__c,
//         //                 Case_Sub_Type__c= 'Health Checkup',
//         //                 Description     = 'Preventive Maintenance is due for Asset ' + assetRecord.Name + 
//         //                                  ' (' + dateSource + ': ' + baseDate + ', ' + 
//         //                                  (intervalCount * daysInterval) + ' days interval) on ' + targetDate,
//         //                 Origin          = 'System',
//         //                 OwnerId         = queueId,
//         //                 Priority        = 'Medium',
//         //                 Status          = 'New',
//         //                 Type            = 'Preventive Maintenance'
//         //             );
//         //             casesToInsert.add(newCase);
//         //             idxToAsset.put(idx, assetRecord);
                    
//         //             System.debug('Creating PM case for Asset: ' + assetRecord.Name + 
//         //                         ', Base Date: ' + baseDate + ' (' + dateSource + ')' +
//         //                         ', Days since base: ' + daysSinceBase + 
//         //                         ', Interval: ' + intervalCount);
//         //         }
//         //         idx++;
//         //     } catch (Exception e) {
//         //         // Record failure for this asset
//         //         failedAssets.add(new FailedAsset(
//         //             assetRecord.Id,
//         //             assetRecord.Name,
//         //             assetRecord.Status,
//         //             'Exception in processing: ' + e.getMessage() + ' at line ' + e.getLineNumber()
//         //         ));
//         //         idx++;
//         //     }
//         // }

//          if (isDueForPM) {
//                     // Calculate how many intervals have passed
//                     Integer intervalsPassed = daysSinceBase / daysInterval;
//                     Integer actualDays = intervalsPassed * daysInterval;
//                     String dateSource = assetRecord.InstallDate != null ? 'Installation Date' : 'Invoice Billing Date';
                    
//                     Case newCase = new Case(
//                         AssetId         = assetRecord.Id,
//                         AccountId       = assetRecord.AccountId,
//                         ContactId       = assetRecord.ContactId,
//                         Case_Pincode__c = assetRecord.Pin_Code_Master__c,
//                         Division__c     = assetRecord.Business_Vertical__c,
//                         Case_Sub_Type__c= 'Health Checkup',
//                         Description     = 'Preventive Maintenance is due for Asset ' + assetRecord.Name + 
//                                          ' (' + dateSource + ': ' + baseDate + ', ' + 
//                                          daysSinceBase + ' days have passed, next PM due at ' + actualDays + ' days) on ' + targetDate,
//                         Origin          = 'System',
//                         OwnerId         = queueId,
//                         Priority        = 'Medium',
//                         Status          = 'New',
//                         Type            = 'Preventive Maintenance'
//                     );
//                     casesToInsert.add(newCase);
//                     idxToAsset.put(idx, assetRecord);
                    
//                     System.debug('Creating PM case for Asset: ' + assetRecord.Name + 
//                                 ', Base Date: ' + baseDate + ' (' + dateSource + ')' +
//                                 ', Days since base: ' + daysSinceBase + 
//                                 ', Intervals passed: ' + intervalsPassed);
//                 }
//                 idx++;
//             } catch (Exception e) {
//                 // Record failure for this asset
//                 failedAssets.add(new FailedAsset(
//                     assetRecord.Id,
//                     assetRecord.Name,
//                     assetRecord.Status,
//                     'Exception in processing: ' + e.getMessage() + ' at line ' + e.getLineNumber()
//                 ));
//                 idx++;
//             }
//         }

//         if (casesToInsert.isEmpty()) {
//             System.debug('No PM cases to create for ' + scope.size() + ' assets on ' + targetDate);
//             return;
//         }

//         System.debug('Attempting to insert ' + casesToInsert.size() + ' PM cases');

//         Database.SaveResult[] results = Database.insert(casesToInsert, false);

//         for (Integer i = 0; i < results.size(); i++) {
//             Database.SaveResult sr = results[i];
//             Asset relatedAsset = idxToAsset.get(i);

//             if (!sr.isSuccess()) {
//                 String errorMsg = '';
//                 for (Database.Error err : sr.getErrors()) {
//                     errorMsg += err.getStatusCode() + ' - ' + err.getMessage() + '; ';
//                 }
//                 if (errorMsg.endsWith('; ')) errorMsg = errorMsg.substring(0, errorMsg.length()-2);

//                 failedAssets.add(new FailedAsset(
//                     relatedAsset == null ? null : relatedAsset.Id,
//                     relatedAsset == null ? null : relatedAsset.Name,
//                     relatedAsset == null ? null : relatedAsset.Status,
//                     errorMsg
//                 ));

//                 System.debug('Failed to insert case for Asset ' + (relatedAsset == null ? 'null' : relatedAsset.Id) + ' : ' + errorMsg);
//             } else {
//                 System.debug('Successfully created PM case for Asset: ' + (relatedAsset == null ? 'null' : relatedAsset.Name));
//             }
//         }
//     }

//     global void finish(Database.BatchableContext bc) {
//         if (failedAssets == null || failedAssets.isEmpty()) {
//             System.debug('No failed PM case creations. No email sent.');
//             return;
//         }

//         // ----------------------------
//         // Build HTML email body
//         // ----------------------------
//         String html = '';
//         html += '<h3>Batch Printer PM Case Creation - Failed Assets</h3>';
//         html += '<p>The following Assets failed while creating PM cases on ' + String.valueOf(targetDate) + ':</p>';
//         html += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
//         html += '<tr><th>Asset Id</th><th>Asset Name</th><th>Status</th><th>Error</th></tr>';

//         for (FailedAsset fa : failedAssets) {
//             html += '<tr>';
//             html += '<td>' + (fa.assetId == null ? '' : String.valueOf(fa.assetId)) + '</td>';
//             html += '<td>' + (fa.assetName == null ? '' : fa.assetName) + '</td>';
//             html += '<td>' + (fa.assetStatus == null ? '' : fa.assetStatus) + '</td>';
//             html += '<td>' + (fa.reason == null ? '' : fa.reason) + '</td>';
//             html += '</tr>';
//         }
//         html += '</table>';
//         html += '<p>Please investigate the above failures.</p>';

//         Set<String> toEmails = new Set<String>();

//         try {
//             for (User u : [
//                 SELECT Id, Email
//                 FROM User
//                 WHERE Profile.Name = 'System Administrator'
//                 AND IsActive = true
//                 AND Email != null
//             ]) {
//                 System.debug('Found System Administrator: ' + u.Email);
//                 if (u.Email != null) {
//                     toEmails.add(u.Email);
//                 }
//             }
//         } catch (Exception e) {
//             System.debug('Error querying System Administrators: ' + e.getMessage());
//         }

//         try {
//             CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'CreatePMCasesBatch_Failure_Recipient' LIMIT 1];

//             if (cp != null) {
//                 List<SetupEntityAccess> seaList = [
//                     SELECT ParentId, SetupEntityId
//                     FROM SetupEntityAccess
//                     WHERE SetupEntityId = :cp.Id
//                 ];

//                 if (!seaList.isEmpty()) {
//                     Set<Id> permSetIds = new Set<Id>();
//                     for (SetupEntityAccess sea : seaList) permSetIds.add(sea.ParentId);

//                     Set<Id> normalPermSetIds = new Set<Id>();

//                     for (PermissionSet ps : [
//                         SELECT Id, IsOwnedByProfile, ProfileId
//                         FROM PermissionSet
//                         WHERE Id IN :permSetIds
//                     ]) {
//                         normalPermSetIds.add(ps.Id);
//                     }

//                     if (!normalPermSetIds.isEmpty()) {
//                         // Get PermissionSetAssignment rows (AssigneeId can be User or Group)
//                         List<PermissionSetAssignment> psaList = [
//                             SELECT AssigneeId, PermissionSetId
//                             FROM PermissionSetAssignment
//                             WHERE PermissionSetId IN :normalPermSetIds
//                         ];

//                         Set<Id> assigneeIds = new Set<Id>();
//                         for (PermissionSetAssignment psa : psaList) assigneeIds.add(psa.AssigneeId);

//                         Set<Id> directUserAssigneeIds = new Set<Id>();

//                         for (Id aId : assigneeIds) {
//                             String prefix = String.valueOf(aId).substring(0,3);
//                             if (prefix == '005') {
//                                 directUserAssigneeIds.add(aId);
//                             }
//                         }

//                         // Add direct user assignees
//                         if (!directUserAssigneeIds.isEmpty()) {
//                             for (User u : [
//                                 SELECT Id, Email
//                                 FROM User
//                                 WHERE Id IN :directUserAssigneeIds
//                                 AND IsActive = true
//                                 AND Email != null
//                             ]) {
//                                 System.debug('Found user: ' + u.Email);
//                                 toEmails.add(u.Email);
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//         catch (QueryException qx) {
//             System.debug('CustomPermission lookup/query error: ' + qx.getMessage());
//         }
//         catch (Exception ex) {
//             System.debug('Unexpected error while resolving custom-permission recipients: ' + ex.getMessage());
//         }

//         System.debug('Resolved recipients: ' + JSON.serialize(new List<String>(toEmails)));
//         // ----------------------------
//         // Final fallback: ensure at least current user gets the email
//         // ----------------------------
//         if (toEmails.isEmpty()) {
//             System.debug('No recipients found, adding current user: ' + UserInfo.getUserEmail());
//             toEmails.add(UserInfo.getUserEmail());
//         }

//         // ----------------------------
//         // Send the email
//         // ----------------------------
//         try {
//             Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//             mail.setToAddresses(new List<String>(toEmails));
//             mail.setSubject('Printer PM Case Creation Failures for ' + String.valueOf(targetDate));
//             mail.setHtmlBody(html);

//             Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
//             System.debug('Failure notification email sent to: ' + JSON.serialize(new List<String>(toEmails)));
//         }
//         catch (Exception e) {
//             System.debug('Failed to send failure notification email: ' + e.getMessage());
//         }
//     }

//     @TestVisible
//     private class FailedAsset {
//         Id assetId;
//         String assetName;
//         String assetStatus;
//         String reason;

//         @TestVisible
//         FailedAsset(Id aId, String aName, String aStatus, String r) {
//             assetId = aId; 
//             assetName = aName; 
//             assetStatus = aStatus; 
//             reason = r;
//         }
//     }
// }


global class CreateAssetPrinterPMCasesBatch implements System.Schedulable, Database.Batchable<sObject>, Database.Stateful {

    @TestVisible
    private List<FailedAsset> failedAssets = new List<FailedAsset>();

    global CreateAssetPrinterPMCasesBatch() {}

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 10);
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, AccountId, ContactId, Business_Vertical__c, ' +
            'Pin_Code_Master__c, InstallDate, Invoice__r.Billing_Date__c, ' +
            'Status, Printer_PM_Cycle__c ' +
            'FROM Asset ' +
            'WHERE Status != \'Expired\' ' +
            'AND Business_Vertical__c = \'Printer\' ' +
            'AND Type__c = \'Rental\' ' +
            'AND Printer_PM_Cycle__c = 0';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Asset> scope) {
        System.debug('Processing ' + scope.size() + ' assets');
        if (scope == null || scope.isEmpty()) return;

        List<Case> casesToInsert = new List<Case>();
        Map<Integer, Asset> idxToAsset = new Map<Integer, Asset>();

        Id queueId;
        try {
            queueId = [SELECT Id FROM Group WHERE DeveloperName = 'Open_Queue' LIMIT 1].Id;
        } catch (Exception e) {
            System.debug('Error getting queue ID: ' + e.getMessage());
            return;
        }

        Integer idx = 0;
        for (Asset assetRecord : scope) {
            try {
                // if (assetRecord.Printer_PM_Cycle__c == 0) {
                    Case newCase = new Case(
                        AssetId         = assetRecord.Id,
                        AccountId       = assetRecord.AccountId,
                        ContactId       = assetRecord.ContactId,
                        Case_Pincode__c = assetRecord.Pin_Code_Master__c,
                        Division__c     = assetRecord.Business_Vertical__c,
                        Case_Sub_Type__c= 'Health Checkup',
                        Description     = 'Preventive Maintenance is due for Asset ' + assetRecord.Name + 
                                         ' (PM Cycle: Exact 90-day interval)',
                        Origin          = 'System',
                        OwnerId         = queueId,
                        Priority        = 'Medium',
                        Status          = 'New',
                        Type            = 'Preventive Maintenance'
                    );
                    casesToInsert.add(newCase);
                    idxToAsset.put(idx, assetRecord);
                    
                    System.debug('Creating PM case for Asset: ' + assetRecord.Name);
                // }
                idx++;
            } catch (Exception e) {
                failedAssets.add(new FailedAsset(
                    assetRecord.Id,
                    assetRecord.Name,
                    assetRecord.Status,
                    'Exception: ' + e.getMessage()
                ));
                idx++;
            }
        }

        if (casesToInsert.isEmpty()) {
            System.debug('No cases to insert');
            return;
        }

        try {
            Database.SaveResult[] results = Database.insert(casesToInsert, false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                Asset relatedAsset = idxToAsset.get(i);

                if (!sr.isSuccess()) {
                    String errorMsg = '';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getStatusCode() + ' - ' + err.getMessage() + '; ';
                    }
                    if (errorMsg.endsWith('; ')) {
                        errorMsg = errorMsg.substring(0, errorMsg.length()-2);
                    }

                    failedAssets.add(new FailedAsset(
                        relatedAsset != null ? relatedAsset.Id : null,
                        relatedAsset != null ? relatedAsset.Name : null,
                        relatedAsset != null ? relatedAsset.Status : null,
                        errorMsg
                    ));

                    System.debug('Failed to insert case: ' + errorMsg);
                } else {
                    System.debug('Successfully created PM case for Asset: ' + (relatedAsset != null ? relatedAsset.Name : 'Unknown'));
                }
            }
        } catch (Exception e) {
            System.debug('Error during case insertion: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        if (failedAssets == null || failedAssets.isEmpty()) {
            System.debug('Batch completed successfully with no failures');
            return;
        }

        // Build HTML email body
        String html = '';
        html += '<h3>Batch Printer PM Case Creation - Failed Assets</h3>';
        html += '<p>The following Assets failed while creating PM cases:</p>';
        html += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
        html += '<tr><th>Asset Id</th><th>Asset Name</th><th>Status</th><th>Error</th></tr>';

        for (FailedAsset fa : failedAssets) {
            html += '<tr>';
            html += '<td>' + (fa.assetId == null ? '' : String.valueOf(fa.assetId)) + '</td>';
            html += '<td>' + (fa.assetName == null ? '' : fa.assetName) + '</td>';
            html += '<td>' + (fa.assetStatus == null ? '' : fa.assetStatus) + '</td>';
            html += '<td>' + (fa.reason == null ? '' : fa.reason) + '</td>';
            html += '</tr>';
        }
        html += '</table>';
        html += '<p>Please investigate the above failures.</p>';

        // Collect recipient emails
        Set<String> toEmails = new Set<String>();

        // System Administrators
        try {
            for (User u : [
                SELECT Id, Email
                FROM User
                WHERE Profile.Name = 'System Administrator'
                AND IsActive = true
                AND Email != null
            ]) {
                toEmails.add(u.Email);
            }
        } catch (Exception e) {
            System.debug('Error querying System Administrators: ' + e.getMessage());
        }

        // Custom Permission recipients
        try {
            CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'CreatePMCasesBatch_Failure_Recipient' LIMIT 1];

            if (cp != null) {
                List<SetupEntityAccess> seaList = [
                    SELECT ParentId, SetupEntityId
                    FROM SetupEntityAccess
                    WHERE SetupEntityId = :cp.Id
                ];

                if (!seaList.isEmpty()) {
                    Set<Id> permSetIds = new Set<Id>();
                    for (SetupEntityAccess sea : seaList) {
                        permSetIds.add(sea.ParentId);
                    }

                    Set<Id> normalPermSetIds = new Set<Id>();
                    for (PermissionSet ps : [
                        SELECT Id, IsOwnedByProfile, ProfileId
                        FROM PermissionSet
                        WHERE Id IN :permSetIds
                    ]) {
                        normalPermSetIds.add(ps.Id);
                    }

                    if (!normalPermSetIds.isEmpty()) {
                        List<PermissionSetAssignment> psaList = [
                            SELECT AssigneeId, PermissionSetId
                            FROM PermissionSetAssignment
                            WHERE PermissionSetId IN :normalPermSetIds
                        ];

                        Set<Id> assigneeIds = new Set<Id>();
                        for (PermissionSetAssignment psa : psaList) {
                            assigneeIds.add(psa.AssigneeId);
                        }

                        Set<Id> directUserAssigneeIds = new Set<Id>();
                        for (Id aId : assigneeIds) {
                            String prefix = String.valueOf(aId).substring(0,3);
                            if (prefix == '005') {
                                directUserAssigneeIds.add(aId);
                            }
                        }

                        if (!directUserAssigneeIds.isEmpty()) {
                            for (User u : [
                                SELECT Id, Email
                                FROM User
                                WHERE Id IN :directUserAssigneeIds
                                AND IsActive = true
                                AND Email != null
                            ]) {
                                toEmails.add(u.Email);
                            }
                        }
                    }
                }
            }
        } catch (Exception ex) {
            System.debug('Error resolving custom-permission recipients: ' + ex.getMessage());
        }

        // Final fallback
        if (toEmails.isEmpty()) {
            toEmails.add(UserInfo.getUserEmail());
        }

        // Send the email
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(toEmails));
            mail.setSubject('Printer PM Case Creation Failures');
            mail.setHtmlBody(html);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            System.debug('Failure notification email sent to ' + toEmails.size() + ' recipients');
        } catch (Exception e) {
            System.debug('Failed to send failure notification email: ' + e.getMessage());
        }
    }

    @TestVisible
    private class FailedAsset {
        Id assetId;
        String assetName;
        String assetStatus;
        String reason;

        FailedAsset(Id aId, String aName, String aStatus, String r) {
            assetId = aId; 
            assetName = aName; 
            assetStatus = aStatus; 
            reason = r;
        }
    }
}