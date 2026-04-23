@RestResource(urlMapping='/CreateCaseAPI/*')
global class CreateCaseAPI {

    @HttpPost
    global static void createCase() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        API_log__c apiLog = new API_log__c();

        try {
            // for(Case cs : [SELECT Id, CaseNumber,Owner.Email, Owner.Manager.Email FROM Case WHERE CreatedDate = TODAY]) {
            //     System.debug(cs);
            // }

            String jsonBody = request.requestBody.toString();

            apiLog.Log_Name__c = 'Create Case API';
            apiLog.Request__c = 'Total Size = ' + jsonBody;

            CaseWrapper caseWrapper = parse(jsonBody);


            List<Asset> assetList = [
                SELECT Id,Name, SerialNumber, AccountId, ContactId,
                (
                    SELECT Id, CaseNumber, Description,Owner.Email,Owner.Name, Status
                    FROM Cases
                    WHERE IsClosed = false AND Type != 'Installation' AND Type != 'Preventive Maintenance'
                    ORDER BY CreatedDate DESC
                    LIMIT 1)
                FROM Asset
                WHERE Name = :caseWrapper.serialNumber OR SerialNumber = :caseWrapper.serialNumber LIMIT 1
            ];

            Map<String, Contact> contactMap = new Map<String, Contact>();
            if(!assetList.isEmpty()) {
                for(Contact con : [
                    SELECT Id, Email
                    FROM Contact
                    WHERE Email = :caseWrapper.email AND AccountId = :assetList[0].AccountId
                ]) {
                    contactMap.put(con.Email, con);
                }
            }

            if(contactMap.containsKey(caseWrapper.email) == false) {
                Contact con = new Contact();
                if (assetList != null && !assetList.isEmpty()) {
                    con.AccountId = assetList[0].AccountId;
                }
                String[] nameParts = caseWrapper.contactName.split(' ', 2);
                if (nameParts.size() == 2) {
                    con.FirstName = nameParts[0];
                    con.LastName = nameParts[1];
                } else {
                    con.FirstName = '';
                    con.LastName = nameParts[0];
                }
                con.Email = caseWrapper.email;
                con.MobilePhone = caseWrapper.mobile;

                insert con;

                contactMap.put(caseWrapper.email,con);
            }

            String description = '';
            if(String.isNotBlank(caseWrapper.customerName)) {
                description += caseWrapper.customerName + '\n';
            }
            if(String.isNotBlank(caseWrapper.contactName)) {
                description += 'Contact : ' + caseWrapper.contactName + '\n';
            }
            if(String.isNotBlank(caseWrapper.email)) {
                description += 'Email : ' + caseWrapper.email + '\n';
            }
            if(String.isNotBlank(caseWrapper.mobile)) {
                description += 'Mobile : ' + caseWrapper.mobile + '\n';
            }
            if(String.isNotBlank(caseWrapper.invoiceNumber)) {
                description += 'Invoice No : ' + caseWrapper.invoiceNumber + '\n';
            }
            if(String.isNotBlank(caseWrapper.serialNumber)) {
                description += 'Serial No : ' + caseWrapper.serialNumber + '\n';
            }
            if(String.isNotBlank(caseWrapper.OemSerialNumber)) {
                description += 'OEM Serial No : ' + caseWrapper.OemSerialNumber + '\n';
            }
            if(String.isNotBlank(caseWrapper.address)) {
                description += 'Address : ' + caseWrapper.address + '\n';
            }

            if(String.isNotBlank(caseWrapper.description)) {
                description += 'description : ' + caseWrapper.description;
            }


            String assetId;
            String assetName;
            String accountId;
            String contactId;
            Boolean isExistingCaseOpen = false;
            Case newOrExistingCase;
            if(assetList.size() > 0) {
                assetId = assetList[0].Id;
                assetName = assetList[0].Name;
                accountId = assetList[0].AccountId;
                contactId = assetList[0].ContactId;

                if(assetList[0].Cases.size() > 0) {
                    isExistingCaseOpen = true; newOrExistingCase = assetList[0].Cases[0];
                }
            }




            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            if(isExistingCaseOpen) {
                newOrExistingCase.Description += '\n\n\n\n' + System.now().format('dd MMM yyyy HH:mm:ss') + '\n' + description;

                if (String.valueOf(newOrExistingCase.OwnerId).startsWith('005')) {

                    User us = [Select Id,Manager.Email,ManagerId from User where Id=:newOrExistingCase.OwnerId];
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    List<string> toAddresses = new  List<string>();
                    toAddresses.add(newOrExistingCase.Owner.Email);

                    Set<String> recipientsIds = new Set<String>();
                    recipientsIds.add(us.Id);
                    
                    if(string.isNotBlank(us.Manager.Email)) {
                        toAddresses.add(us.Manager.Email);
                        recipientsIds.add(us.ManagerId);
                    }

                    message.setToAddresses(toAddresses);
                    message.subject = 'New Case Attempt for Asset with Existing Open Case – '+assetName +' - '+newOrExistingCase.CaseNumber;
                    string body  = 'Hi '+newOrExistingCase.Owner.Name+'<br/><br/>';
                    body+='A customer has attempted to create a new case for the asset <strong>'+assetName+'</strong>, which already has an open case (<strong>'+newOrExistingCase.CaseNumber+'</strong>).<br/><br/>';
                    body+='As per the current process, a new case was not created. Instead, the existing case has been updated with the customer\'s latest input in the <strong>Description</strong> field.<br/><br/>';
                    body+='Please review the case for further action.';
                    message.htmlBody = body;
                    emailList.add(message);


                    CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='Case_Attempt_for_Asset'];

                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Customer Submitted New Case Details for Asset '+assetName+' - '+newOrExistingCase.CaseNumber);
                    notification.setBody('A customer tried to raise a new case for asset '+assetName+', but an open case ('+newOrExistingCase.CaseNumber+') already exists.The existing case description has been updated with the latest information.');
                    notification.setTargetId(newOrExistingCase.Id);
                    notification.setNotificationTypeId(notificationType.Id);
                    //try {
                    notification.send(recipientsIds);
                    //}
                    //catch (Exception e) {
                    //  System.debug('Problem sending notification: ' + e.getMessage());
                    //}

                    if(emailList.size() > 0 && Label.External_Email_Disabled != 'True') {
                        Messaging.sendEmail(emailList);
                    }
                }

                update newOrExistingCase;
            }
            else {
                newOrExistingCase = new Case();
                if(!assetList.isEmpty()) {
                    newOrExistingCase.AssetId = assetId;
                    newOrExistingCase.AccountId = accountId;
                }

                newOrExistingCase.Type = caseWrapper.type;
                newOrExistingCase.ContactId = contactId;
                if(contactMap.containsKey(caseWrapper.email)) {
                    if(contactId != contactMap.get(caseWrapper.email).Id) {
                        newOrExistingCase.Case_Notified_By__c = contactMap.get(caseWrapper.email).Id;
                    }
                }
                newOrExistingCase.Type = caseWrapper.type;
                newOrExistingCase.Case_Sub_Type__c = caseWrapper.subType;
                newOrExistingCase.Division__c = caseWrapper.businessVertical;
                newOrExistingCase.Priority = 'Medium';
                newOrExistingCase.Origin = 'QR';
                if(String.isNotBlank(caseWrapper.address)) {
                    if(caseWrapper.address.length() > 255) {
                        newOrExistingCase.Location__c = caseWrapper.address.subString(0, 255);
                    } else {
                       newOrExistingCase.Location__c = caseWrapper.address;
                    }
                }
                newOrExistingCase.Description = System.now().format('dd MMM yyyy HH:mm:ss') + '\n' + description;

                Map<String, Group> groupsByName = DataCls.getGroupsByName();
                if(groupsByName.containsKey('Open Queue')) {
                    newOrExistingCase.OwnerId = groupsByName.get('Open Queue').Id;
                } else {

                }
                if(!Test.isRunningTest()){
                    insert newOrExistingCase; newOrExistingCase = [SELECT Id, CaseNumber FROM Case WHERE Id = :newOrExistingCase.Id];
                }
                

                
            }

            Map<String,Object> result = new Map<String,Object>();
            result.put('Status', 'success');
            result.put('msg', newOrExistingCase.CaseNumber);

            apiLog.Status__c = 'Success';
            apiLog.Response__c = JSON.serialize(result);

            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));
        }
        catch(DmlException e) {String msg; if(e.getNumDml() > 0) {msg = e.getDmlMessage(0);} else {msg = e.getMessage();}throw new CustomException(msg);}
        catch(Exception e) {
            apiLog.Exception_Description__c = e.getMessage() + ' : ' + e.getCause() + ' : ' + e.getStackTraceString();
            apiLog.Status__c = 'Failed';

            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"error": "' + e.getMessage()+e.getLineNumber()+ + '"}');
        }
        insert apiLog;
    }



    public class CaseWrapper {
        public String serialNumber;
        public String OemSerialNumber;
        public String type;
        public String subType;
        public String customerName;
        public String contactName;
        public String email;
        public String mobile;
        public String invoiceNumber;
        public String businessVertical;
        public String address;
        public String description;

    }

    private static CaseWrapper parse(String jsonString) {
        return (CaseWrapper) JSON.deserialize(jsonString, CaseWrapper.class);
    }


}