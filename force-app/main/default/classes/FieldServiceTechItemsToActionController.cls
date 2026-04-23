public with sharing class FieldServiceTechItemsToActionController {

    @AuraEnabled
    public static Object getListOfCasesAndFeedItems(Integer offset, Integer lmt, String sortBy, String sortDirection) {
        try {
            String caseQuery = 'SELECT Id,CaseNumber,OwnerId,Owner.Id,Owner.Name, ' +
                '(SELECT Id FROM Feeds WHERE Type = \'TextPost\')' +
                'FROM Case ' +
                'WHERE Tech_Support_Status__c IN (\'Opened by Service Engineer\', \'Comment by Service Engineer\') ' +
                'ORDER BY ' + (sortBy ?? 'CreatedDate') + ' ' + (sortDirection ?? 'ASC') + ' ' +
                'LIMIT ' + lmt + ' OFFSET ' + offset;

            System.debug('caseQuery: ' + caseQuery);

            List<Case> caseList = Database.query(caseQuery);

            if(caseList.size() == 0) {
                return new Map<String, Object> {
                    'caseList' => caseList,
                    'feedItemList' => new List<FeedItem>()
                };
            }

            Set<Id> feedItemIds = new Set<Id>();
            for (Case c : caseList) {
                for(sObject f : c.Feeds) {
                    feedItemIds.add(f.Id);
                }
            }

            String feedItemQuery = 'SELECT Id, ParentId, Type, Body, CreatedBy.Name, CreatedDate, ' +
                '(' +
                    'SELECT Id, FeedItemId, ParentId, CommentBody, CreatedById, CreatedBy.Name, CreatedDate ' +
                    'FROM FeedComments ' +
                    'ORDER BY CreatedDate ASC' +
                ') ' +
                'FROM FeedItem ' +
                'WHERE Id IN (';

            for(String i : feedItemIds) {
                feedItemQuery += '\'' + i + '\',';
            }

            feedItemQuery =  feedItemQuery.substring(0, feedItemQuery.length() - 1) + ') ' +
                'ORDER BY CreatedDate DESC';

            System.debug('feedItemQuery: ' + feedItemQuery);

            List<FeedItem> feedItemList = Database.query(feedItemQuery);

            return new Map<String, Object> {
                'caseList' => caseList,
                'feedItemList' => feedItemList
            };
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}