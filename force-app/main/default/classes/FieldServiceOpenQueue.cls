public with sharing class FieldServiceOpenQueue {
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getCasesForCurrentUser() {
        Id currentUserId = UserInfo.getUserId();
        return [
            SELECT Id, CaseNumber, Description, Contact.Name, Account.Name,Contact.Email, Contact.Phone
            FROM Case
            WHERE OwnerId != :currentUserId 
              AND (Assign_To__c = :currentUserId 
                OR Re_Assign_To__c = :currentUserId)
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

        // Fetch the case record to be updated
        Case caseToAccept = [
            SELECT Id, OwnerId,Assign_To__c, Re_Assign_To__c
            FROM Case 
            WHERE Id = :caseId 
            LIMIT 1
        ];
        Id currentUserId = UserInfo.getUserId();
        //Assign the OwnerId to Assign_To__c or Re_Assign_To__c if available
    if (caseToAccept.Assign_To__c != null) {
        updateOwner(caseId, caseToAccept.Assign_To__c);
        //caseToAccept.OwnerId = caseToAccept.Assign_To__c;
    } else if (caseToAccept.Re_Assign_To__c != null) {
        updateOwner(caseId, caseToAccept.Assign_To__c);
        //caseToAccept.OwnerId = caseToAccept.Re_Assign_To__c;
    } else {
        throw new AuraHandledException('No valid Assign_To__c or Re_Assign_To__c found.');
    }

        // Check if the current user is already the owner
        if (caseToAccept.OwnerId == currentUserId) {
            throw new AuraHandledException('You already own this case.');
        }
        else {
            update caseToAccept;
        }

        // Update the OwnerId to the current user
        // caseToAccept.OwnerId = currentUserId;
        // update caseToAccept;
    }
    @future
    public static void updateOwner(Id caseId, Id ownerId) {
        try {
            // Retrieve the Case to update
            Case caseToUpdate = [SELECT Id, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
            
            // Update the OwnerId field
            caseToUpdate.OwnerId = ownerId;
            update caseToUpdate;

            System.debug('Case Owner updated successfully for Case Id: ' + caseId);
        } catch (Exception e) {
            System.debug('Error updating Case Owner: ' + e.getMessage());
        }
    }
//Custom Notification Logic Starts Here
    @AuraEnabled
    public static void sendRejectionNotification(Id caseId) {
        if (String.isNotBlank(caseId)) {
            Case caseRecord = [SELECT OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
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
        User owner = [SELECT Email FROM User WHERE Id = :ownerId LIMIT 1];

        if (owner.Email != null) {
            // Construct email message
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[] { owner.Email });
            email.setSubject('Case Rejected Notification');
            email.setPlainTextBody('Dear User,\n\nThe case with Id ' + caseId + ' has been rejected. Please review it.\n\nThank you.');

            // Send the email
            if (Label.Internal_Email_Disabled != 'True') {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        } else {
            System.debug('Owner email not found for Id: ' + ownerId);
        }
}
//get data from queue
@AuraEnabled
    public static List<Case> getCasesForQueue(String queueName) {
        // Step 1: Get the Queue Id
Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :queueName LIMIT 1];

// Step 2: Get all the members (User and Group Ids) of the Queue
List<GroupMember> groupMembers = [
    SELECT UserOrGroupId 
    FROM GroupMember 
    WHERE GroupId = :queue.Id
];

// Step 3: Collect all User or Group Ids
Set<Id> userOrGroupIds = new Set<Id>();
for (GroupMember gm : groupMembers) {
    userOrGroupIds.add(gm.UserOrGroupId);
}

// Step 4: Query Cases owned by these Users or Groups
List<Case> cases = [
    SELECT Id, CaseNumber, Subject, OwnerId,Description, Contact.Name, Account.Name,Contact.Email, Contact.Phone
    FROM Case 
    WHERE OwnerId IN :userOrGroupIds
];

// Output or process the cases
System.debug('Cases: ' + cases);
 
return cases;
    }
    
}