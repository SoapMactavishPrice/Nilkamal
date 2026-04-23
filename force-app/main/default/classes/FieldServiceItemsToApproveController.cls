public with sharing class FieldServiceItemsToApproveController {

    @AuraEnabled
    public static Object getItemsToApprove(Integer offset, Integer lmt, String sortBy, String sortDirection) {
        try {
            Id currentUserId = UserInfo.getUserId();

            List<Id> delegateApproverIds = new List<Id>();
            for(User u : [SELECT Id FROM User WHERE delegatedApproverId = :currentUserId]) {
                delegateApproverIds.add(u.Id);
            }

            String query = 'SELECT Id, ProcessInstanceId, OriginalActorId, OriginalActor.Name, ActorId, Actor.Name, CreatedDate, ' +
                'ProcessInstance.LastActorId, ProcessInstance.LastActor.Name, ProcessInstance.TargetObjectId, ProcessInstance.TargetObject.Name ' +
                'FROM ProcessInstanceWorkitem ' +
                'WHERE OriginalActorId = \'' + currentUserId + '\' ';
            if(!delegateApproverIds.isEmpty()) {
                query += ' OR OriginalActorId IN (\'' + String.join(delegateApproverIds, '\', \'') + '\') ';
            }
            // query += 'ORDER BY ' + sortBy + ' ' + sortDirection + ' LIMIT ' + lmt + ' OFFSET ' + offset;

            // query += 'LIMIT ' + lmt + ' OFFSET ' + offset;

            System.debug('query: ' + query);

            List<ProcessInstanceWorkitem> recordList = Database.query(query);
            // recordList.addAll((List<ProcessInstanceWorkitem>)Database.query(query));
            // recordList.addAll((List<ProcessInstanceWorkitem>)Database.query(query));
            // recordList.addAll((List<ProcessInstanceWorkitem>)Database.query(query));
            // recordList.addAll((List<ProcessInstanceWorkitem>)Database.query(query));

            Set<String> targetObjectIdPrefixes = new Set<String>();
            Set<Id> targetObjectIds = new Set<Id>();
            Set<Id> processInstanceIds = new Set<Id>();
            for(ProcessInstanceWorkitem item : recordList) {
                String prefix = String.valueOf(item.ProcessInstance.TargetObjectId).subString(0, 3);
                 targetObjectIdPrefixes.add(prefix);
                if (prefix == Quote.SObjectType.getDescribe().getKeyPrefix()) {
             targetObjectIds.add(item.ProcessInstance.TargetObjectId);
           }

                       //comment by keshav
               // if(!targetObjectIdPrefixes.contains(prefix)) {
                   // targetObjectIdPrefixes.add(prefix);
                    //targetObjectIds.add(item.ProcessInstance.TargetObjectId);
               // }
                processInstanceIds.add(item.ProcessInstanceId);
            }

            System.debug('processInstanceIds: ' + processInstanceIds);

            Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance>([
                SELECT Id,
                (
                    SELECT ActorId, Actor.Name FROM Steps ORDER BY CreatedDate DESC LIMIT 1
                )
                FROM ProcessInstance
                WHERE Id IN :processInstanceIds
            ]);

            System.debug('targetObjectIds: ' + targetObjectIds);

            Map<Id, Quote> quoteMap = new Map<Id, Quote>([
                SELECT Id, Status, Quote_Document_Type__c, Billing_Type__c
                FROM Quote
                WHERE Id IN :targetObjectIds
            ]);

            Map<String, String> targetObjectLabelMap = new Map<String, String>();
            for(Schema.SObjectType sObjectType : Schema.getGlobalDescribe().values()) {
                if(targetObjectIdPrefixes.contains(sObjectType.getDescribe().getKeyPrefix())) {
                    targetObjectLabelMap.put(sObjectType.getDescribe().getKeyPrefix(), sObjectType.getDescribe().getLabel());
                }
            }

            return new ApproveItemsResponse(recordList, targetObjectLabelMap, processInstanceMap, quoteMap);
        }
        catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }


    public class ApproveItemsResponse {
        @AuraEnabled public List<ProcessInstanceWorkitem> recordList;
        @AuraEnabled public Map<String, String> targetObjectLabelMap;
        @AuraEnabled public Map<Id, ProcessInstance> processInstanceMap;
        @AuraEnabled public Map<Id, Quote> quoteMap;

        public ApproveItemsResponse(List<ProcessInstanceWorkitem> recordList, Map<String, String> labelMap, Map<Id, ProcessInstance> processInstanceMap, Map<Id, Quote> quoteMap) {
            this.recordList = recordList;
            this.targetObjectLabelMap = labelMap;
            this.processInstanceMap = processInstanceMap;
            this.quoteMap = quoteMap;
        }
    }

}