trigger FeedCommentTrigger on FeedComment(after insert, before delete) {

    if(Trigger.isBefore && Trigger.isDelete) {
        for (FeedComment fc : Trigger.old) {
            fc.addError('Deletion of Chatter comments is not allowed for any user.');
        }
    }


    if(Trigger.isAfter && Trigger.isInsert) {
        Set<Id> feedItemIds = new Set<Id>();

        for (FeedComment fc : Trigger.new) {
            if (fc.FeedItemId != null) {
                feedItemIds.add(fc.FeedItemId);
            }
        }

        Map<Id, FeedItem> feedItems = new Map<Id, FeedItem>(
            [SELECT Id, ParentId FROM FeedItem WHERE Id IN :feedItemIds]
        );

        Map<Id, SObject> parentRecords = new Map<Id, SObject>();
        Set<Id> parentIds = new Set<Id>();

        for (FeedItem fi : feedItems.values()) {
            if (fi.ParentId.getSObjectType() == Case.SObjectType) {
                parentIds.add(fi.ParentId);
            }
        }

        Map<Id, SObject> cases = new Map<Id, SObject>(
            [SELECT Id, OwnerId, CaseNumber, Tech_Support_Status__c FROM Case WHERE Id IN :parentIds]
        );

        for(SObject c : cases.values()) {
            parentRecords.put(c.Id, c);
        }

        User usr = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Boolean isFromTechTeam = usr.Profile.Name == 'Technical Team';


        Map<Id, Case> caseToUpdate = new Map<Id, Case>();

        for (FeedComment fc : Trigger.new) {
            if(parentRecords.get(fc.ParentId) == null) continue;

            FeedItem fi = feedItems.get(fc.FeedItemId);
            if (fi == null) continue;

            SObject parentRecord = cases.get(fi.ParentId);
            if (parentRecord == null) continue;

            Id ownerId = (Id) parentRecord.get('OwnerId');

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            Id customNotifTypeId = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Case_Escalation' LIMIT 1].Id;
            notification.setNotificationTypeId(customNotifTypeId);
            notification.setTitle('New Comment on Case - ' + parentRecord.get('CaseNumber'));
            String plainComment = fc.CommentBody.replaceAll('<[^>]+>', '');
            notification.setBody(usr.Name+' commented: "' + plainComment + '" on "' + parentRecord.get('CaseNumber') + '".');
            notification.setTargetId(fi.ParentId);
            notification.setSenderId(UserInfo.getUserId());

            notification.send(new Set<String> {String.valueOf(parentRecords.get(fi.ParentId).get('OwnerId'))});

            System.debug('isFromTechTeam: ' + isFromTechTeam);
            System.debug('parentRecord.get(Tech_Support_Status__c): ' + parentRecord.get('Tech_Support_Status__c'));

            if(!isFromTechTeam && parentRecord.get('Tech_Support_Status__c') != 'Comment by Service Engineer') {
                Case newCase = new Case(Id = parentRecord.Id, Tech_Support_Status__c = 'Comment by Service Engineer');
                caseToUpdate.put(parentRecord.Id, newCase);
            }
        }

        if(!caseToUpdate.isEmpty()) {
            update caseToUpdate.values();
        }
    }

}