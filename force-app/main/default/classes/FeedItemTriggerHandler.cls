public class FeedItemTriggerHandler {

    // public static void handleAfterInsert(List<FeedItem> newItems) {
    //     for (FeedItem item : newItems) {
    //         if (item.ParentId != null && item.Type == 'TextPost' && String.isNotBlank(item.Body)) {
    //             if (item.ParentId.getSObjectType() == Case.SObjectType) {
    //                 try {
    //                     submitTechnicalSupport(item, item.ParentId, item.Body, item.Id);
    //                 } catch (Exception ex) {
    //                     System.debug('Error in submitTechnicalSupport: ' + ex.getMessage() + ' - ' + ex.getLineNumber());
    //                     throw new AuraHandledException(ex.getMessage());
    //                 }
    //             }
    //         }
    //     }
    // }
    public static void handleAfterInsert(List<FeedItem> newItems) {

        Set<Id> caseIds = new Set<Id>();
        Map<Id, String> feedBodies = new Map<Id, String>();  

        for (FeedItem item : newItems) {
            if (item.ParentId != null &&
                item.Type == 'TextPost' &&
                String.isNotBlank(item.Body)) {

                if (item.ParentId.getSObjectType() == Case.SObjectType) {

                    try {
                        submitTechnicalSupport(item, item.ParentId, item.Body, item.Id);

                        caseIds.add(item.ParentId);

                        feedBodies.put(item.ParentId, item.Body);

                    } catch (Exception ex) {
                        System.debug('Error in submitTechnicalSupport: ' + ex.getMessage() + ' - Line: ' + ex.getLineNumber());
                        throw new AuraHandledException(ex.getMessage());
                    }
                }
            }
        }
                
        if (!caseIds.isEmpty()) {
            CaseTriggerHandler.updateCaseFromChatter(caseIds,feedBodies);
        }
    }

    public static void handleBeforeDelete(List<FeedItem> oldItems) {
        for (FeedItem fi : oldItems) {
            fi.addError('Deletion of Chatter posts is not allowed for any user.');
        }
    }

    public static void submitTechnicalSupport(FeedItem feedItem, Id caseId, String comment, String feedId) {
        if (String.isBlank(comment)) {
            feedItem.addError('Comment cannot be empty.');
        }

        try {
            Case caseRecord = [
                SELECT Id, Tech_support_clicked_by_user__c, CaseNumber, Status,
                TYPEOF Owner
                    WHEN User THEN Email, ManagerId, Manager.Name, Technical_Assistant__c, Manager.Technical_Assistant__r.Email, Manager.Technical_Assistant__r.Name,Technical_Assistant__r.Name,Technical_Assistant__r.Email
                    WHEN Group THEN Id, Name
                END
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            if (caseRecord.Owner instanceof User) {
                User ownerUser = (User)caseRecord.Owner;
                if (ownerUser.Technical_Assistant__c == null) {
                    feedItem.addError('Technical Assistant is not defined, Please contact your System Administrator');
                    return;
                }

                List<Case_Team__c> existingCaseTeams = [
                    SELECT Id
                    FROM Case_Team__c
                    WHERE Case__c = :caseRecord.Id
                    AND Member__c = :ownerUser.Technical_Assistant__c
                    LIMIT 1
                ];

                if (existingCaseTeams.isEmpty()) {
                    Case_Team__c caseTeam = new Case_Team__c(
                        Case__c = caseRecord.Id,
                        Member__c = ownerUser.Technical_Assistant__c,
                        Access_Level__c = 'Edit',
                        Case_Team_Role__c = 'Technical Assistant'
                    );
                    insert caseTeam;
                }

                String techAssistantEmail = ownerUser.Technical_Assistant__r.Email;
                String techAssistantName = ownerUser.Technical_Assistant__r.Name;

                caseRecord.Status = 'Tech Support';
                caseRecord.Tech_support_clicked_by_user__c = false;
                caseRecord.Tech_Support_Status__c = 'Opened by Service Engineer';
                update caseRecord;

                String baseUrl = URL.getOrgDomainUrl().toExternalForm();
                String customTabUrl = baseUrl + '/lightning/r/' + feedId + '/view';
                String caseAnchor = '<a href="' + customTabUrl + '">' + caseRecord.CaseNumber + '</a>';

                String emailSubject = 'Technical Support Comment Submitted for Case: ' + caseRecord.CaseNumber;
                String emailBody = 'Hello ' + techAssistantName + ',<br/><br/>' +
                    'A new technical support comment has been submitted for Case: ' + caseAnchor + '.<br/><br/>' +
                    '<strong>Comment:</strong><br/>' + comment + '<br/><br/>' +
                    'Click below to open the Technical Support page:<br/><br/>' +
                    '<a href="' + customTabUrl + '" style="' +
                    'display: inline-block; background-color: #0070d2; color: white; padding: 10px 20px; ' +
                    'text-decoration: none; border-radius: 5px; font-weight: bold;">Go to Technical Support Page</a>';

                if (techAssistantEmail != null) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(new List<String>{ techAssistantEmail, 'shital.jadhav@nilkamal.com' });
                    mail.setSubject(emailSubject);
                    mail.setHtmlBody(emailBody);

                    if (Label.Internal_Email_Disabled != 'True') {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    }
                }

                User usr = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                Id customNotifTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Escalation' LIMIT 1].Id;
                notification.setNotificationTypeId(customNotifTypeId);
                notification.setTitle('Technical Support Request');

                String plainComment = comment.replaceAll('<[^>]+>', '');
                if (String.isBlank(plainComment)) {
                    plainComment = 'new comment received';
                }

                notification.setBody(usr.Name + ' requested technical support: "' + plainComment + '" on Case "' + caseRecord.CaseNumber + '".');
                notification.setTargetId(caseRecord.Id);
                notification.setSenderId(UserInfo.getUserId());

                Id UserId = [SELECT Id FROM User WHERE Email = 'aditya.zagade@finessedirect.com' LIMIT 1].Id;


                try {
                    notification.send(new Set<String>{ ownerUser.Technical_Assistant__c,UserId });
                } catch (Exception e) {
                    System.debug('Error in submitTechnicalSupport: ' + e.getMessage() + ' - ' + e.getLineNumber());
                    feedItem.addError('Error submitting technical support: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error in submitTechnicalSupport: ' + e.getMessage() + ' - ' + e.getLineNumber());
            feedItem.addError('Error submitting technical support: ' + e.getMessage());
        }
    }

}