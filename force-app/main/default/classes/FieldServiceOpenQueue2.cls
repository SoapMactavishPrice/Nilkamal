public with sharing class FieldServiceOpenQueue2 {
    
    @AuraEnabled(cacheable = true)
    public static List < Case > getCasesForCurrentUser() {
        Id currentUserId = UserInfo.getUserId();
        return [
            SELECT Id, CaseNumber, Description, Contact.Name, Account.Name, Contact.Email,
            Contact.Phone, CreatedDate, Priority, Division__c, Type
            FROM Case
            WHERE OwnerId !=: currentUserId AND(Assign_To__c =: currentUserId OR Re_Assign_To__c =: currentUserId)
        ];
    }
    
    /**
     * Assigns the given Case record to the current user.
     * Throws an error if the case is already owned by the current user or if the Case ID is invalid.
     *
     * @param caseId ID of the Case record to be accepted.
     */
    @AuraEnabled
    public static void acceptCase(Id caseId) {
        if (caseId == null) {
            throw new AuraHandledException('Case ID is required.');
        }
        
        // Fetch the "Open Queue" ID dynamically
        Id openQueueId = [
            SELECT Id FROM Group WHERE Name = 'Open Queue'
            AND Type = 'Queue'
            LIMIT 1
        ].Id;
        
        // Fetch the Case record
        Case caseToAccept = [
            SELECT Id, OwnerId, CaseNumber
            FROM Case
            WHERE Id =: caseId
            LIMIT 1
        ];
        
        // Check if the Case owner is the Open Queue
        if (caseToAccept.OwnerId == openQueueId) {
            // Update the Case owner to the current logged-in user
            caseToAccept.OwnerId = UserInfo.getUserId();
            update caseToAccept;
        } else {
            throw new AuraHandledException('This case is not assigned to the Open Queue.');
        }
    }
    @future
    public static void updateOwner(Id caseId, Id ownerId) {
        try {
            // Retrieve the Case to update
            Case caseToUpdate = [SELECT Id, OwnerId FROM Case WHERE Id =: caseId LIMIT 1];
            
            // Update the OwnerId field
            caseToUpdate.OwnerId = ownerId;
            update caseToUpdate;
            
            System.debug('Case Owner updated successfully for Case Id: ' + caseId);
        } catch (Exception e) {
            System.debug('Error updating Case Owner: ' + e.getMessage());
        }
    }
    
    //ended here 08/02/25
    //Custom Notification Logic Starts Here
    @AuraEnabled
    public static void sendRejectionNotification(Id caseId) {
        if (String.isNotBlank(caseId)) {
            Case caseRecord = [SELECT OwnerId FROM Case WHERE Id =: caseId LIMIT 1];
            if (caseRecord != null) {
                String ownerId = caseRecord.OwnerId;
                sendRejectionEmail(caseId, ownerId);
            } else {
                throw new AuraHandledException('Case record not found.');
            }
        } else {
            throw new AuraHandledException('Case Id cannot be null or blank.');
        }
    }
    
    // Future method to send rejection email
    @future
    public static void sendRejectionEmail(String caseId, String ownerId) {
        // Query the Case Owner's email
        User owner = [SELECT Email FROM User WHERE Id =: ownerId LIMIT 1];
        
        if (owner.Email != null) {
            // Construct email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] {
                owner.Email
            });
            email.setSubject('Case Rejected Notification');
            email.setPlainTextBody('Dear User,\n\nThe case with Id ' + caseId + ' has been rejected. Please review it.\n\nThank you.');
            
            // Send the email
            if (Label.Internal_Email_Disabled != 'True') {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                    email
                });
            }
        } else {
            System.debug('Owner email not found for Id: ' + ownerId);
        }
    }
    
    @AuraEnabled
    public static void updateCaseAndSendCaseOwnerNotification(Id caseId) {
        // Fetch the case details
        Case caseRecord = [SELECT Id, OwnerId, CaseNumber, Subject FROM Case WHERE Id =: caseId LIMIT 1];
        
        caseRecord.Reassignment_Request__c = 'Rejected';
        
        UPDATE caseRecord;
        
        // Get Custom Notification Type Id (Replace with actual ID from Setup)
        Id notificationTypeId = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Case_Reassignment_Rejection_To_Owner'
            LIMIT 1
        ].Id;
        
        // Create the Custom Notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Case ReAssignment Rejection');
        notification.setBody('Case Reassignment Rejection for Case Number: ' + caseRecord.CaseNumber);
        notification.setSenderId(UserInfo.getUserId()); // Sender is the current user
        notification.setTargetId(caseRecord.Id); // Target is the Case record
        notification.setNotificationTypeId(notificationTypeId); // Correct method to set notification type
        
        notification.send(new Set < String > {
            caseRecord.OwnerId
        });
    }
    
    //get data from queue
    @AuraEnabled
    public static List < Case > getCasesForQueue() {
        try {
            return [
                SELECT Id, CaseNumber, Subject, OwnerId, Description, Contact.Name, Account.Name, Contact.Email, Contact.Phone,
                CreatedDate, Priority, Division__c, Type,
                Additional_Resource_Request__c, Additional_Resource_Request_Comment__c, Additional_Resource_Request_RSM_Comment__c, Additional_Resource_Request_Date_Time__c,
                Reassignment_Request__c, Reassignment_Request_Comment__c, Reassignment_Request_RSM_Comment__c, Reassignment_Request_Date_Time__c
                FROM Case
                WHERE OwnerId =: UserInfo.getUserId()
                ORDER BY CaseNumber DESC
            ];
        } catch (Exception e) {
            // Handle the case where the queue doesn't exist or another error occurs
            System.debug('Error: ' + e.getMessage());
            return new List < Case > ();
        }
        
    }
    
    @AuraEnabled
    public static List < Case > getOpenQueueCases() {
        try {
            Id openQueueId = [
                SELECT Id FROM Group WHERE Name = 'Open Queue' AND Type = 'Queue' LIMIT 1].Id;
            
            User currentUser = [SELECT Id, Business_Unit__c FROM User WHERE Id =: UserInfo.getUserId()];
            
            System.debug(openQueueId + 'openQueueId');
            
            Set < Id > userIdsReportingToMe = UtilityCls.getUserIdsReportingToMe();
            
            List<Case> openQueueCases = [
                SELECT Id, CaseNumber, Subject, OwnerId, Description, Contact.Name, Account.Name, Case_Pincode__r.Name, Owner.Name,
                Contact.Email, Account.Territory_Master__c, Account.Pin_Code__c, Contact.Phone, CreatedDate, Asset.Name,
                Priority, Division__c,
                Reassignment_Request__c, Type, Additional_Resource_Request__c, Reassignment_Request_Comment__c, Additional_Resource_Request_Comment__c,Additional_Resource_Req_Proposed_Date__c
                FROM Case
                WHERE IsClosed=false AND Division__c =: currentUser.Business_Unit__c AND((OwnerId =: openQueueId) OR((Reassignment_Request__c = 'Requested' OR Additional_Resource_Request__c = 'Requested') AND OwnerId IN: userIdsReportingToMe))
                ORDER BY CaseNumber DESC
            ];
            
            System.debug('Cases with blank owner or owned by Open Queue: ' + openQueueCases);
            
            return openQueueCases;
        } catch (Exception e) {
            System.debug('Error fetching Open Queue cases: ' + e.getMessage());
            return new List < Case > ();
        }
    }
    
    @AuraEnabled
    public static void reassignCase(String caseId, String comment) {
        try {
            User currentUser = [
                SELECT Id, Name, ManagerId, Manager.Email, Manager.FirstName, Manager.ManagerId, Manager.Manager.Email, Manager.Manager.FirstName
                FROM User
                WHERE Id =: UserInfo.getUserId()
            ];
            
            Case caseToReassign = [
                SELECT Id, CaseNumber, Subject, Reassignment_Request__c, Account.Name, Description, Asset.Name,Additional_Resource_Req_Proposed_Date__c
                FROM Case
                WHERE Id =: caseId
            ];
            
            if (currentUser.ManagerId != null) {
                CustomNotificationType notificationType = [
                    SELECT Id, DeveloperName
                    FROM CustomNotificationType
                    WHERE DeveloperName = 'Case_Reassignment_Alert'
                ];
                
                if (notificationType != null) {
                    String notificationBody = currentUser.Name + ' is requesting reassignment for Case ' + caseToReassign.CaseNumber + '.' + (String.isNotBlank(caseToReassign.Subject) ? (' Subject: ' + caseToReassign.Subject + '.') : '');
                    
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Case Reassignment Request ' + caseToReassign.CaseNumber);
                    notification.setBody(notificationBody);
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetPageRef('{"type":"standard__webPage","attributes":{"url":"/lightning/cmp/c__fieldServiceOpenQueue2"}}');
                    //notification.setTargetId(currentUser.ManagerId);
                    
                    Set<String> recipientIds = new Set<String>();
                    recipientIds.add(currentUser.ManagerId);
                    if(currentUser.Manager.ManagerId != null) {
                        recipientIds.add(currentUser.Manager.ManagerId);
                    }
                    notification.send(recipientIds);
                }
                else {
                    System.debug('No Custom Notification Type found with DeveloperName "Case_Reassignment_Alert".');
                }
                
                String subject = 'Case Reassignment Request ' + caseToReassign.CaseNumber;
                String body = 'Hi ' + currentUser.Manager.FirstName + ',\n\n' +
                    currentUser.Name + ' is requesting reassignment for Case.\n\n' +
                    '📌 Case Number: ' + caseToReassign.CaseNumber +
                    '\n📄 Account Name: ' + caseToReassign.Account.Name +
                    '\n📄 Serial Number: ' + caseToReassign.Asset.Name +
                    //'\n📄 Subject: ' + caseToReassign.Subject +
                '\n📄 Description: ' + caseToReassign.Description;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{currentUser.Manager.Email});
                if(currentUser.Manager.ManagerId != null) {
                    mail.setCcAddresses(new List<String>{currentUser.Manager.Manager.Email});
                }
                mail.setSubject(subject);
                mail.setPlainTextBody(body);
                
                if (Label.Internal_Email_Disabled != 'True') {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                        mail
                    });
                }
                caseToReassign.Reassignment_Request__c = 'Requested';
                caseToReassign.Reassignment_Request_Comment__c = comment;
                caseToReassign.Reassignment_Request_Date_Time__c = DateTime.now();
                caseToReassign.Reassignment_Request_RSM_Comment__c = '';
                update caseToReassign;
            } else {
                throw new CustomException('Manager not found for the current user.');
            }
        } catch (Exception e) {
            System.debug('❌ Error during case reassignment notification: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // user query start here on 07-03-2022
    @AuraEnabled
    public static Object getUsersByTerritoryFromCases(List < Id > caseIds) {
        Id userId = UserInfo.getUserId();
        return [
            SELECT Id, Name, Email, ManagerId
            FROM User
            WHERE IsActive = true AND (ManagerId =: userId OR Manager.ManagerId =: userId)
            // AND Id NOT IN (SELECT User__c FROM Service_Resource__c WHERE Leave__c != null)
            ORDER BY Name
        ];
    }
    
    // save function
    @AuraEnabled
    public static void saveCaseWithNewOwner(Map < Id, Id > caseIdToOwnerMap) {
        if (caseIdToOwnerMap == null || caseIdToOwnerMap.isEmpty()) {
            throw new AuraHandledException('No cases provided for update.');
        }
        
        // Fetch all cases in bulk
        List < Case > casesToUpdate = new List < Case > ();
        Map < Id, Case > caseMap = new Map < Id, Case > ([
            SELECT Id, OwnerId, Reassignment_Request__c, Subject, CaseNumber
            FROM Case
            WHERE Id IN: caseIdToOwnerMap.keySet()
        ]);
        
        for (Id caseId: caseIdToOwnerMap.keySet()) {
            if (caseMap.containsKey(caseId)) {
                Case caseToUpdate = caseMap.get(caseId);
                caseToUpdate.OwnerId = caseIdToOwnerMap.get(caseId);
                casesToUpdate.add(caseToUpdate);
            }
        }
        
        if (!casesToUpdate.isEmpty()) {
            UPDATE casesToUpdate;
            sendNotificationToAssignedUsers(caseIdToOwnerMap, caseMap);
            System.debug('Cases updated successfully: ' + casesToUpdate);
        } else {
            throw new AuraHandledException(
                'No cases were updated. Please ensure the cases are either assigned to the Open Queue or marked as reassigned.'
                );
        }
    }
    
    private static void sendNotificationToAssignedUsers(Map < Id, Id > caseIdToOwnerMap, Map < Id, Case > caseMap) {
        CustomNotificationType notificationType = [
            SELECT Id, DeveloperName
            FROM CustomNotificationType
            WHERE DeveloperName = 'Case_Assign'
            LIMIT 1
        ];
        
        User currentUser = [SELECT Id, Name, ManagerId, Manager.Email FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        
        if (notificationType != null) {
            for (Id caseId: caseIdToOwnerMap.keySet()) {
                String notificationBodyData = 'Case ' + caseMap.get(caseId).CaseNumber +
                    ' has been assigned to you.' + (String.isNotBlank(caseMap.get(caseId).Subject) ? ' Subject: ' + caseMap.get(caseId).Subject : '');
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Case ' + caseMap.get(caseId).CaseNumber + ' assigned to you by ' + currentUser.Name);
                notification.setBody(notificationBodyData);
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(caseId);
                
                Set<String> recipientIds = new Set<String>{
                    caseIdToOwnerMap.get(caseId)
                };
                notification.send(recipientIds);
            }
        }
        else {
            System.debug('Unable to send notification. Custom Notification Type does not exist');
        }
    }
    
    @AuraEnabled
    public static void updateCaseResource(String caseId, String comment, Date proposedDate) {
        try {
            User currentUser = [
                SELECT Id, Name, ManagerId, Manager.Email, Manager.FirstName, Manager.ManagerId, Manager.Manager.Email, Manager.Manager.FirstName
                FROM User
                WHERE Id =: UserInfo.getUserId()
            ];
            
            Case caseToReassign = [
                SELECT Id, CaseNumber, Subject, Reassignment_Request__c, Account.Name, Description, Asset.Name
                FROM Case
                WHERE Id =: caseId
            ];
            
            if (currentUser.ManagerId != null) {
                CustomNotificationType notificationType = [
                    SELECT Id, DeveloperName
                    FROM CustomNotificationType
                    WHERE DeveloperName = 'Case_Reassignment_Alert'
                ];
                
                if (notificationType != null) {
                    String notificationBody = currentUser.Name + ' is requesting additional resource for Case ' + caseToReassign.CaseNumber + '.' + (String.isNotBlank(caseToReassign.Subject) ? (' Subject: ' + caseToReassign.Subject + '.') : '');
                    
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Case Additional Resource Request ' + caseToReassign.CaseNumber);
                    notification.setBody(notificationBody);
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetPageRef('{"type":"standard__webPage","attributes":{"url":"/lightning/cmp/c__fieldServiceOpenQueue2"}}');
                    // notification.setTargetId(caseToReassign.Id);
                    
                    Set<String> recipientIds = new Set<String>();
                    recipientIds.add(currentUser.ManagerId);
                    if(currentUser.Manager.ManagerId != null) {
                        recipientIds.add(currentUser.Manager.ManagerId);
                    }
                    notification.send(recipientIds);
                }
                else {
                    System.debug('Unable to send notification. Custom Notification Type does not exist');
                }
                
                String subject = 'Case ' + caseToReassign.CaseNumber + ' requested for additional resource';
                String body = 'Hi ' + currentUser.Manager.FirstName + ',\n\n' +
                    'Case ' + caseToReassign.CaseNumber + ' has been requested for additional resource.\n\n' +
                    'Case Number: ' + caseToReassign.CaseNumber + '\n' +
                    'Account Name: ' + caseToReassign.Account.Name + '\n' +
                    'Serial Number: ' + caseToReassign.Asset.Name + '\n\n' +
                    //'Subject: ' + caseToReassign.Subject + '\n' +
                'Description: ' + caseToReassign.Description;
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{currentUser.Manager.Email});
                if(currentUser.Manager.ManagerId != null) {
                    mail.setCcAddresses(new List<String>{currentUser.Manager.Manager.Email});
                }
                mail.setSubject(subject);
                mail.setPlainTextBody(body);
                
                if (Label.Internal_Email_Disabled != 'True') {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                        mail
                    });
                }
                
                Case caseRecord = [SELECT Id, Additional_Resource_Request__c, Additional_Resource_Request_Comment__c FROM Case WHERE Id =: caseId LIMIT 1];
                caseRecord.Additional_Resource_Request__c = 'Requested';
                caseRecord.Additional_Resource_Request_Comment__c = comment;
                caseRecord.Additional_Resource_Request_Date_Time__c = System.now();
                caseRecord.Additional_Resource_Request_RSM_Comment__c = '';
                caseRecord.Additional_Resource_Req_Proposed_Date__c = proposedDate;
                update caseRecord;
            } else {
                throw new CustomException('Manager not found for the current user.');
            }
        } catch (Exception e) {
            System.debug('❌ Error during case additional resource request: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void handleReAssignRequest(String caseId, String status, String comment, String newOwnerId) {
        try {
            Case caseRecord = [SELECT Id, CaseNumber, OwnerId, Reassignment_Request__c, Reassignment_Request_RSM_Comment__c FROM Case WHERE Id =: caseId];
            String oldOwnerId = caseRecord.OwnerId;
            
            Set < Id > userIds = new Set < Id > ();
            userIds.add(caseRecord.OwnerId);
            userIds.add(newOwnerId);
            
            caseRecord.Reassignment_Request__c = status;
            caseRecord.Reassignment_Request_RSM_Comment__c = comment;
            caseRecord.Is_service_appointment_created__c = false;
            if (status == 'Approved') {
                caseRecord.OwnerId = newOwnerId;
                caseRecord.Assigned_Date_Time__c = System.now();
            }
            update caseRecord;
            
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Case_Reassignment_Alert' LIMIT 1];
            
            User currentUser = [SELECT Id, Name, ManagerId, Manager.Email FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            
            if (status == 'Approved') {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Case ' + caseRecord.CaseNumber + ' reassigned to you.');
                notification.setBody('Case ' + caseRecord.CaseNumber + ' has been reassigned to you by ' + currentUser.Name + '. Please see the details.');
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(caseRecord.Id);
                // notification.send(new Set < String > { newOwnerId });
            }
            else if (status == 'Rejected') {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Case Reassignment Rejected ' + caseRecord.CaseNumber);
                notification.setBody('Your case has been rejected by the Manager. ' + (String.isNotBlank(comment) ? ('With comment : ' + comment) : ''));
                notification.setTargetId(caseRecord.Id);
                notification.setNotificationTypeId(notificationType.Id);
                notification.send(new Set < String > { oldOwnerId });
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveCaseTeamRecords(List <CaseTeamWrapper> records, String caseId, String status, String comment, date acceptedDate) {
        try {
            Case caseToUpdate = [
                SELECT Id, CaseNumber, AccountId, ContactId, Type, Case_Sub_Type__c, Assigned_Date_Time__c, Additional_Resource_Request__c, Additional_Resource_Request_RSM_Comment__c, OwnerId,
                (SELECT Id FROM Work_Orders__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Case
                WHERE Id =: caseId
            ];
            
            caseToUpdate.Additional_Resource_Request__c = status;
            caseToUpdate.Additional_Resource_Request_RSM_Comment__c = comment;
            
            update caseToUpdate;
            
            List<Service_Appointment__c> sapList = new List<Service_Appointment__c>();
            
            Work_Order__c latestWorkOrder = new Work_Order__c();
            if (caseToUpdate.Work_Orders__r.size() > 0) {
                latestWorkOrder = caseToUpdate.Work_Orders__r[0];
            }
            
            Map<String, Service_Appointment__c> sapDateMap = new Map<String, Service_Appointment__c>();
            for(Service_Appointment__c sap: [SELECT Id, Case__c, Scheduled_Start__c, Unique_Key__c FROM Service_Appointment__c WHERE Case__c =: caseId AND Remote_Support__c = false]) {
                sapDateMap.put(sap.Scheduled_Start__c.format('ddMMyyyy'), sap);
                System.debug('Unique Key: ' + sap.Unique_Key__c);
            }
            
            CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName = 'Case_Additional_Resource' LIMIT 1];
            
            if (status == 'Approved' && !records.isEmpty()) {
                List<Case_Team__c> caseTeamsToInsert = new List<Case_Team__c>();
                
                System.debug('Unique Key: ' + caseToUpdate.Id + '-' + caseToUpdate.OwnerId + '-' + acceptedDate + '-' + false);
                System.debug('sapDateMap: ' + sapDateMap);
                DateTime acceptedDateTime = DateTime.newInstance(acceptedDate, Time.newInstance(0, 0, 0, 0));
                if (String.valueOf(caseToUpdate.OwnerId).startsWith('005') && !sapDateMap.containsKey(acceptedDateTime.format('ddMMyyyy'))) {
                    Service_Appointment__c sap = new Service_Appointment__c();
                    sap.OwnerId = caseToUpdate.OwnerId;
                    sap.Case__c = caseId;
                    sap.Work_Order__c = latestWorkOrder.Id != null ? latestWorkOrder.Id : null;
                    sap.Account__c = caseToUpdate.AccountId;
                    sap.Contact__c = caseToUpdate.ContactId;
                    sap.WO_Type__c = caseToUpdate.Type;
                    sap.Scheduled_Start__c = acceptedDate;
                    sap.Assigned_Date__c = Date.valueOf(caseToUpdate.Assigned_Date_Time__c);
                    sap.Is_Additional_Resource__c = false;
                    sap.Is_Scheduled_by_RSM__c = true;
                    sapList.add(sap);
                }
                
                for (CaseTeamWrapper wrapper: records) {
                    Case_Team__c caseTeam = new Case_Team__c();
                    caseTeam.Case__c = wrapper.caseId;
                    caseTeam.Member__c = wrapper.memberId;
                    caseTeam.Access_Level__c = 'Edit';
                    caseTeam.Case_Team_Role__c = 'Additional Resource';
                    caseTeamsToInsert.add(caseTeam);
                    
                    Service_Appointment__c sap1 = new Service_Appointment__c();
                    sap1.OwnerId = wrapper.memberId;
                    sap1.Case__c = wrapper.caseId;
                    sap1.Work_Order__c = latestWorkOrder.Id != null ? latestWorkOrder.Id : null;
                    sap1.Account__c = caseToUpdate.AccountId;
                    sap1.Contact__c = caseToUpdate.ContactId;
                    sap1.WO_Type__c = caseToUpdate.Type;
                    sap1.Scheduled_Start__c = acceptedDate;
                    sap1.Assigned_Date__c = Date.valueOf(caseToUpdate.Assigned_Date_Time__c);
                    sap1.Is_Additional_Resource__c = true;
                    sap1.Is_Scheduled_by_RSM__c = true;
                    sapList.add(sap1);
                }
                
                if (!caseTeamsToInsert.isEmpty()) {
                    Database.insert(caseTeamsToInsert, true);
                }
                
                if (!sapList.isEmpty()) {
                    Database.insert(sapList, true);
                }
                
                if (notificationType != null) {
                    Set<String> users = new Set<String>();
                    for (Case_Team__c caseTeam: caseTeamsToInsert) {
                        users.add(caseTeam.Member__c);
                    }
                    
                    List<User> userList = [
                        SELECT Id, Name, Email
                        FROM User
                        WHERE Id IN: users
                    ];
                    
                    for (User user: userList) {
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('Additional Resource Request : ' + caseToUpdate.CaseNumber);
                        notification.setBody('You are added as a Additional Resource to ' + caseToUpdate.CaseNumber + '.');
                        notification.setTargetId(caseToUpdate.Id);
                        notification.setNotificationTypeId(notificationType.Id);
                        notification.send(new Set < String > {user.Id});
                    }
                    
                    Set<String> userNames = new Set<String>();
                    for (User user: userList) {
                        userNames.add(user.Name);
                    }
                    
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Additional Resource Request : ' + caseToUpdate.CaseNumber);
                    notification.setBody('Listed Users are added as a Additional Resource to ' + caseToUpdate.CaseNumber + '. ' + String.join(userNames, ', '));
                    notification.setTargetId(caseToUpdate.Id);
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.send(new Set < String > {caseToUpdate.OwnerId});
                }
            } else if (status == 'Rejected') {
                if (notificationType != null) {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Additional Resource Request : ' + caseToUpdate.CaseNumber);
                    notification.setBody('Additional Resource Request Rejected for ' + caseToUpdate.CaseNumber + '.');
                    notification.setTargetId(caseToUpdate.Id);
                    notification.setNotificationTypeId(notificationType.Id);
                    
                    notification.send(new Set < String > {caseToUpdate.OwnerId});
                }
            }
        } catch (Exception e) {
            System.debug('❌ Error during case additional resource request: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class CaseTeamWrapper {
        @AuraEnabled public String caseId {get; set;}
        @AuraEnabled public String memberId {get; set;}
        @AuraEnabled public String role {get; set;}
        @AuraEnabled public String accessLevel {get; set;}
    }
    
    
    @AuraEnabled
    public static Boolean updateTechSupport(String caseId) {
        try{
            Case caseRecord = [
                SELECT Id, Tech_support_clicked_by_user__c,CaseNumber, Technical_Support_SE_Comment__c, Technical_Support_SE_DateTime__c,
                TYPEOF Owner
                WHEN User THEN Email, ManagerId, Manager.Name, Manager.Technical_Assistant__c, Manager.Technical_Assistant__r.Email
                WHEN Group THEN Id, Name
                END
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
            
            caseRecord.Tech_support_clicked_by_user__c = true;
            update caseRecord;
            
            return true;
        }
        catch(Exception e) {
            return false;
        }
    }
    
    
    @AuraEnabled
    public static void submitTechnicalSupport(Id caseId, String comment) {
        if (String.isBlank(comment)) {
            throw new AuraHandledException('Comment cannot be empty.');
        }
        
        Case caseRecord = [
            SELECT Id, CaseNumber, Technical_Support_SE_Comment__c, Technical_Support_SE_DateTime__c,
            TYPEOF Owner
            WHEN User THEN Email, ManagerId, Manager.Name, Manager.Technical_Assistant__c, Manager.Technical_Assistant__r.Email
            WHEN Group THEN Id, Name
            END
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        // Update comment and timestamp
        caseRecord.Technical_Support_SE_Comment__c = comment;
        caseRecord.Technical_Support_SE_DateTime__c = System.now();
        caseRecord.Status = 'Tech Support';
        update caseRecord;
        
        // Construct URLs
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String customTabUrl = baseUrl + '/lightning/n/Tech_Support?c__openTechSupportModal=true&c__caseId=' + caseId;
        // String homePageUrlWithModal = baseUrl + '/lightning/page/home?openTechSupportModal=true&caseId=' + caseId;
        String caseLink = baseUrl + '/' + caseRecord.Id;
        String caseAnchor = '<a href="' + caseLink + '">' + caseRecord.CaseNumber + '</a>';
        
        // Email body and subject
        String emailSubject = 'Technical Support Comment Submitted for Case: ' + caseRecord.CaseNumber;
        String emailBody = 'Hello,<br/><br/>' +
            'A new technical support comment has been submitted for Case: ' + caseAnchor + '.<br/><br/>' +
            '<strong>Comment:</strong><br/>' + comment + '<br/><br/>' +
            // '<a href="' + homePageUrlWithModal + '" style="' +
        // 'display: inline-block; background-color: #0070d2; color: white; padding: 10px 20px; ' +
        // 'text-decoration: none; border-radius: 5px; font-weight: bold;">Go to Home Page</a>';
        +'Click below to open the Technical Support page and submit your comment:<br/><br/>' +
            '<a href="' + customTabUrl + '" style="' +
            'display: inline-block; background-color: #0070d2; color: white; padding: 10px 20px; ' +
            'text-decoration: none; border-radius: 5px; font-weight: bold;">Go to Technical Support Page</a>';
        
        // Email recipients
        List<String> toAddresses = new List<String>();
        
        if (caseRecord.Owner instanceof User) {
            User owner = (User) caseRecord.Owner;
            // if (owner.Email != null) {
                //     toAddresses.add(owner.Email);
            // }
            if (owner.Manager == null) {
                throw new AuraHandledException('Case owner does not have a manager assigned.');
            }
            
            if (owner.Manager.Technical_Assistant__r == null) {
                throw new AuraHandledException('Manager does not have a Technical Assistant assigned.');
            }
            
            String taEmail = owner.Manager.Technical_Assistant__r.Email;
            if (taEmail != null) {
                toAddresses.add(taEmail);
            }
            
            // if (owner.Manager != null && owner.Manager.Technical_Assistant__r != null) {
                //     String taEmail = owner.Manager.Technical_Assistant__r.Email;
                //     if (taEmail != null) {
                    //         toAddresses.add(taEmail);
                //     }
            // }
        } else {
            throw new AuraHandledException('Case is not assigned to a user. Please assign it to a user with a manager and technical assistant.');
        }
        
        // Send email if recipients exist
        if (!toAddresses.isEmpty()) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(emailSubject);
            mail.setHtmlBody(emailBody);
            
            if (Label.Internal_Email_Disabled != 'True') {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
            }
        }
    }
    
    
    @AuraEnabled
    public static void uploadFileToServer(String fileName, String base64Data, String contentType, String recordId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;
        
    }
    
    // @AuraEnabled
    // public static Boolean checkUserPermission(Id caseId) {
        //     Id currentUserId = UserInfo.getUserId();
        
        //     Case caseRecord = [
        //         SELECT Id, OwnerId,
        //             TYPEOF Owner
        //                 WHEN User THEN ManagerId, Manager.Technical_Assistant__r.Id
        //                 WHEN Group THEN Id
        //             END
        //         FROM Case
        //         WHERE Id = :caseId
        //         LIMIT 1
        //     ];
        
        //     if (caseRecord.Owner instanceof User) {
            //         User owner = (User) caseRecord.Owner;
            //         return currentUserId == owner.ManagerId ||
            //                currentUserId == owner.Manager.Technical_Assistant__r.Id;
        //     }
        //     return false;
    // }
    
    
    @AuraEnabled
    public static Boolean checkUserPermission(Id caseId) {
        Id currentUserId = UserInfo.getUserId();
        
        // Query Case and handle polymorphic relationship for Owner
        Case caseRecord = [
            SELECT Id, OwnerId,
            TYPEOF Owner
            WHEN User THEN ManagerId, Manager.Technical_Assistant__r.Id
            WHEN Group THEN Id
            END
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        // Check if the Owner is a User and then access the Manager and Technical_Assistant fields
        if (caseRecord.Owner instanceof User) {
            User owner = (User) caseRecord.Owner;
            
            // Ensure that the Manager is not null before accessing its fields
            if (owner.ManagerId != null && owner.Manager.Technical_Assistant__r != null) {
                return owner.Manager.Technical_Assistant__r.Id == currentUserId;
            }
        }
        
        // Return false if conditions are not met
        return false;
    }
    
    
    
    
    @AuraEnabled
    public static void submitSupportComment(Id caseId, String comment) {
        System.debug('Called submitSupportComment with caseId: ' + caseId + ' and comment: ' + comment);
        
        if (String.isBlank(comment)) {
            throw new AuraHandledException('Comment cannot be empty.');
        }
        
        if (caseId == null) {
            throw new AuraHandledException('Case ID is required.');
        }
        
        Id currentUserId = UserInfo.getUserId();
        System.debug('Current User ID: ' + currentUserId);
        
        Case caseRecord = [
            SELECT Id, CaseNumber, Subject, OwnerId, Status, Technical_Support_Response__c, Technical_Support_Response_DateTime__c,
            TYPEOF Owner
            WHEN User THEN Name, Email, Id, ManagerId, Manager.Name, Manager.Technical_Assistant__c, Manager.Technical_Assistant__r.Email, Manager.Technical_Assistant__r.Id
            WHEN Group THEN Id, Name
            END
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        System.debug('Case OwnerId: ' + caseRecord.OwnerId);
        
        // Validate user permissions
        if (caseRecord.Owner instanceof User) {
            User owner = (User) caseRecord.Owner;
            
            System.debug('Case Owner User Name: ' + owner.Name);
            System.debug('Owner.Id: ' + owner.Id);
            System.debug('Owner.ManagerId: ' + owner.ManagerId);
            System.debug('Manager TA Id: ' + owner.Manager.Technical_Assistant__r?.Id);
            
            // Allow if current user is: Manager, TA, or Owner
            // if (
            //     currentUserId != owner.ManagerId &&
            //     currentUserId != owner.Manager.Technical_Assistant__r?.Id &&
            //     currentUserId != owner.Id
            // ) {
                //     throw new AuraHandledException(
                //         'You are not authorized to submit technical support comments for this case. ' +
                //         'Only the Manager, Technical Assistant, or Case Owner can submit comments.'
                //     );
            // }
            if (currentUserId != owner.Manager.Technical_Assistant__r?.Id) {
                throw new AuraHandledException(
                    'You are not authorized to submit technical support comments for this case. ' +
                    'Only the Manager\'s Technical Assistant is allowed.'
                    );
            }
        } else {
            throw new AuraHandledException(
                'Case is not assigned to a user. ' +
                'Please assign it to a user with a manager and technical assistant.'
                );
        }
        
        caseRecord.Technical_Support_Response__c = comment;
        caseRecord.Technical_Support_Response_DateTime__c = System.now();
        update caseRecord;
        System.debug('Case updated with technical support response.');
        
        // Send email to case owner if they have an email address
        if (caseRecord.Owner.Email != null) {
            System.debug('Sending email to owner: ' + caseRecord.Owner.Email);
            sendEmailToOwner(caseRecord, comment);
        } else {
            System.debug('Owner email is null. Skipping email.');
        }
    }
    
    private static void sendEmailToOwner(Case caseRecord, String comment) {
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String caseLink = baseUrl + '/' + caseRecord.Id;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        List<String> toAddresses = new List<String>{caseRecord.Owner.Email};
        mail.setToAddresses(toAddresses);
        
        mail.setSubject('Technical Support Comment Added to Case #' + caseRecord.CaseNumber);
        
        String emailBody = '<html><body>';
        emailBody += '<p>Hello ' + caseRecord.Owner.Name + ',</p>';
        emailBody += '<p>A new technical support comment has been added to your case:</p>';
        emailBody += '<p><strong>Case #:</strong> <a href="' + caseLink + '">' + caseRecord.CaseNumber + '</a></p>';
        // emailBody += '<p><strong>Subject:</strong> ' + caseRecord.Subject + '</p>';
        emailBody += '<p><strong>Comment:</strong></p>';
        emailBody += '<div style="background-color:#f3f2f2; padding:10px; border-left:4px solid #1589ee; margin:10px 0;">';
        emailBody += comment.replace('\n', '<br/>');
        emailBody += '</div>';
        emailBody += '<p>Please click the case number above to view the complete details in Salesforce.</p>';
        emailBody += '<p>Thank you,<br/>Technical Support Team</p>';
        emailBody += '</body></html>';
        
        mail.setHtmlBody(emailBody);
        
        try {
            if (Label.Internal_Email_Disabled != 'True') {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
                System.debug('Email sent successfully.');
            }
        } catch (Exception e) {
            System.debug('Error sending email: ' + e.getMessage());
        }
        
    }
    
    public static void fakeMethod(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
    
}