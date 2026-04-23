global class CreatePMCasesBatch implements System.Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
    Date targetDate;
    
    @TestVisible
    private List<FailedVisit> failedVisits = new List<FailedVisit>();
    
    
    
    global CreatePMCasesBatch() {
        this.targetDate = System.today().addDays(30);
    }
    
    global CreatePMCasesBatch(Date targetDate) {
        this.targetDate = targetDate;
    }
    
    global void execute(SchedulableContext sc) {
        // CreatePMCasesBatch b = new CreatePMCasesBatch();
        Database.executeBatch(this, 10);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date target;
        if (targetDate == null) {
            target = System.today().addDays(30);
        }
        else{
            target=targetDate;
        }
        
        String query = 'SELECT Id, Name, Planned_Visit_Date__c, Asset_Warranty__c, Asset_Warranty__r.Asset_Warranty_PO_Status__c, ' +
            'Asset_Serial_No__c, Asset_Serial_No__r.Name, ' +
            'Asset_Serial_No__r.AccountId, Asset_Serial_No__r.ContactId, Asset_Serial_No__r.Business_Vertical__c, Asset_Serial_No__r.Pin_Code_Master__c, ' +
            'Asset_AMC__r.Product_Category_Type__c ' +
            'FROM Asset_Visits__c ' +
            'WHERE Planned_Visit_Date__c =:target AND Case__c = null AND Asset_Serial_No__r.Product2.Manufacturing_Part_No1__r.Name != \'MHE SIMPLE\' ' +
            'AND Asset_Serial_No__r.Type__c IN (\'Within AMC\', \'Within CAMC\', \'Within Warranty\')';
        //  'AND Asset_Warranty__r.Asset_Warranty_PO_Status__c = \'Active\''; // Moved this condition to execute() modified by sanket mahale
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Asset_Visits__c> scope) {
        System.debug('scope '+scope);
        if (scope == null || scope.isEmpty()) return;
        
        List<Case> casesToInsert = new List<Case>();
        // map index -> visit to map results back after partial insert
        Map<Integer, Asset_Visits__c> idxToVisit = new Map<Integer, Asset_Visits__c>();
        
        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'Open_Queue' LIMIT 1].Id;
        
        
        Integer idx = 0;
        for (Asset_Visits__c visit : (List<Asset_Visits__c>) scope) {
            String caseSubType;
            
            if (visit.Asset_Warranty__c != null) {
                /*added by sanket mahale on 2/3/2026*/
                if (visit.Asset_Warranty__r?.Asset_Warranty_PO_Status__c != 'Active') {
                    continue;
                }
                /*ended by sanket mahale on 2/3/2026*/
                caseSubType = 'Warranty PM';
            }
            else if (visit.Asset_AMC__r?.Product_Category_Type__c == 'AMC') {
                caseSubType = 'AMC PM';
            }
            else if (visit.Asset_AMC__r?.Product_Category_Type__c == 'CAMC') {
                caseSubType = 'CAMC PM';
            }
            else {
                idx++;
                continue;
            }
            
            Case newCase = new Case(
                AssetId         = visit.Asset_Serial_No__c,
            AccountId       = visit.Asset_Serial_No__r.AccountId,
            ContactId       = visit.Asset_Serial_No__r.ContactId,
            Case_Pincode__c = visit.Asset_Serial_No__r.Pin_Code_Master__c,
            Division__c     = visit.Asset_Serial_No__r.Business_Vertical__c,
            Asset_Visit__c  = visit.Id,
            Case_Sub_Type__c= caseSubType,
            Description     = 'Preventive Maintenance is due for Asset ' + visit.Asset_Serial_No__r.Name + ' on or before ' + visit.Planned_Visit_Date__c,
            Origin          = 'System',
            OwnerId         = queueId,
            Priority        = 'Low',
            Status          = 'New',
            Type            = 'Preventive Maintenance'
                );
            casesToInsert.add(newCase);
            idxToVisit.put(idx, visit);
            idx++;
        }
        
        if (casesToInsert.isEmpty()) return;
        
        Database.SaveResult[] results = Database.insert(casesToInsert, false);
        
        List<Asset_Visits__c> visitsToUpdate = new List<Asset_Visits__c>();
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i];
            Asset_Visits__c relatedVisit = idxToVisit.get(i);
            
            if (sr.isSuccess()) {
                // Successful insert: set Case__c on the related visit
                Case insertedCase = casesToInsert[i];
                // use the Asset_Visit__c we set earlier to update the visit record
                Id visitIdToUpdate = insertedCase.Asset_Visit__c == null ? (relatedVisit == null ? null : relatedVisit.Id) : insertedCase.Asset_Visit__c;
                if (visitIdToUpdate != null) {
                    visitsToUpdate.add(new Asset_Visits__c(
                        Id = visitIdToUpdate,
                    Case__c = insertedCase.Id
                        ));
                }
            }
            else {
                String assetName = relatedVisit == null ? null : relatedVisit.Asset_Serial_No__r?.Name;
                Date plannedDate = relatedVisit == null ? null : relatedVisit.Planned_Visit_Date__c;
                
                // Record failure details for finish() email
                String errorMsg = '';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getStatusCode() + ' - ' + err.getMessage() + '; ';
                }
                // Trim trailing separator
                if (errorMsg.endsWith('; ')) errorMsg = errorMsg.substring(0, errorMsg.length()-2);
                
                failedVisits.add(new FailedVisit(
                    relatedVisit == null ? null : relatedVisit.Id,
                assetName,
                plannedDate,
                errorMsg
                    ));
                
                System.debug('Failed to insert case for Asset_Visit ' + (relatedVisit == null ? 'null' : relatedVisit.Id) + ' : ' + errorMsg);
            }
        }
        
        if (!visitsToUpdate.isEmpty()) {
            try {
                update visitsToUpdate;
            }
            catch (DmlException ex) {
                // If updating visits fails, capture those errors too
                System.debug('Error updating Asset_Visits__c after case creation: ' + ex.getMessage());
                for (Asset_Visits__c v : visitsToUpdate) {
                    failedVisits.add(new FailedVisit(v.Id, null, null, 'Failed to update Asset_Visits__c: ' + ex.getMessage()));
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Nothing to do if no failures
        if (failedVisits == null || failedVisits.isEmpty()) {
            System.debug('No failed PM case creations. No email sent.');
            return;
        }
        
        // ----------------------------
        // Build HTML email body
        // ----------------------------
        String html = '';
        html += '<h3>Batch PM Case Creation - Failed Assets</h3>';
        html += '<p>The following Asset Visits failed while creating PM cases on ' + String.valueOf(targetDate) + ':</p>';
        html += '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">';
        html += '<tr><th>Asset Visit Id</th><th>Asset Name</th><th>Planned Visit Date</th><th>Error</th></tr>';
        
        for (FailedVisit fv : failedVisits) {
            html += '<tr>';
            html += '<td>' + (fv.visitId == null ? '' : String.valueOf(fv.visitId)) + '</td>';
            html += '<td>' + (fv.assetName == null ? '' : fv.assetName) + '</td>';
            html += '<td>' + (fv.plannedDate == null ? '' : String.valueOf(fv.plannedDate)) + '</td>';
            html += '<td>' + (fv.reason == null ? '' : fv.reason) + '</td>';
            html += '</tr>';
        }
        html += '</table>';
        html += '<p>Please investigate the above failures.</p>';
        
        // ----------------------------
        // Collect recipient emails
        // ----------------------------
        Set<String> toEmails = new Set<String>();
        
        // 1) Always include System Administrators
        try {
            for (User u : [
                SELECT Id, Email
                FROM User
                WHERE Profile.Name = 'System Administrator'
                AND IsActive = true
                AND Email != null
            ]) {
                System.debug('Found System Administrator: ' + u.Email);
                if (u.Email != null) {
                    toEmails.add(u.Email);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying System Administrators: ' + e.getMessage());
        }
        
        // 2) Resolve recipients by Custom Permission: CreatePMCasesBatch_Failure_Recipient
        try {
            // Find custom permission record
            CustomPermission cp = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'CreatePMCasesBatch_Failure_Recipient' LIMIT 1];
            
            if (cp != null) {
                // Find PermissionSet parents that include this CustomPermission
                List<SetupEntityAccess> seaList = [
                    SELECT ParentId, SetupEntityId
                    FROM SetupEntityAccess
                    WHERE SetupEntityId = :cp.Id
                ];
                
                if (!seaList.isEmpty()) {
                    Set<Id> permSetIds = new Set<Id>();
                    for (SetupEntityAccess sea : seaList) permSetIds.add(sea.ParentId);
                    
                    // Classify permission sets: profile-owned (-> ProfileId) vs normal PermissionSet Ids
                    Set<Id> normalPermSetIds = new Set<Id>();
                    
                    for (PermissionSet ps : [
                        SELECT Id, IsOwnedByProfile, ProfileId
                        FROM PermissionSet
                        WHERE Id IN :permSetIds
                    ]) {
                        normalPermSetIds.add(ps.Id);
                    }
                    
                    // 2.a) Users assigned normal permission sets (direct or via group)
                    if (!normalPermSetIds.isEmpty()) {
                        // Get PermissionSetAssignment rows (AssigneeId can be User or Group)
                        List<PermissionSetAssignment> psaList = [
                            SELECT AssigneeId, PermissionSetId
                            FROM PermissionSetAssignment
                            WHERE PermissionSetId IN :normalPermSetIds
                        ];
                        
                        Set<Id> assigneeIds = new Set<Id>();
                        for (PermissionSetAssignment psa : psaList) assigneeIds.add(psa.AssigneeId);
                        
                        Set<Id> directUserAssigneeIds = new Set<Id>();
                        
                        for (Id aId : assigneeIds) {
                            String prefix = String.valueOf(aId).substring(0,3);
                            if (prefix == '005') {
                                directUserAssigneeIds.add(aId);
                            }
                        }
                        
                        // Add direct user assignees
                        if (!directUserAssigneeIds.isEmpty()) {
                            for (User u : [
                                SELECT Id, Email
                                FROM User
                                WHERE Id IN :directUserAssigneeIds
                                AND IsActive = true
                                AND Email != null
                            ]) {
                                System.debug('Found user: ' + u.Email);
                                toEmails.add(u.Email);
                            }
                        }
                    }
                }
            }
        }
        catch (QueryException qx) {
            System.debug('CustomPermission lookup/query error: ' + qx.getMessage());
        }
        catch (Exception ex) {
            System.debug('Unexpected error while resolving custom-permission recipients: ' + ex.getMessage());
        }
        
        System.debug('Resolved recipients: ' + JSON.serialize(new List<String>(toEmails)));
        // ----------------------------
        // Final fallback: ensure at least current user gets the email
        // ----------------------------
        if (toEmails.isEmpty()) {
            System.debug('No recipients found, adding current user: ' + UserInfo.getUserEmail());
            toEmails.add(UserInfo.getUserEmail());
        }
        
        // ----------------------------
        // Send the email
        // ----------------------------
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>(toEmails));
            mail.setSubject('PM Case Creation Failures for ' + String.valueOf(targetDate));
            mail.setHtmlBody(html);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            System.debug('Failure notification email sent to: ' + JSON.serialize(new List<String>(toEmails)));
        }
        catch (Exception e) {
            System.debug('Failed to send failure notification email: ' + e.getMessage());
        }
    }
    
    
    
    @TestVisible
    private class FailedVisit {
        Id visitId;
        String assetName;
        Date plannedDate;
        String reason;
        
        @TestVisible
        FailedVisit(Id vId, String aName, Date pDate, String r) {
            visitId = vId; assetName = aName; plannedDate = pDate; reason = r;
        }
    }
    
}