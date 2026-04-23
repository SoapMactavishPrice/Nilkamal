public class WorkOrderHandler {

    public static void rollUpOwnerToCaseTeam(List<Work_Order__c> workOrderRecords, Map<Id, Work_Order__c> oldMap) {
        Set<Id> caseIds = new Set<Id>();
        for (Work_Order__c wo : workOrderRecords) {
            if(oldMap == null) {
            	oldMap = new Map<Id, Work_Order__c>();
        	}
            if (oldMap.containsKey(wo.Id)) {
                if(wo.OwnerId != oldMap.get(wo.Id).OwnerId) {
                    caseIds.add(wo.Case__c);
                }
            } else {
                caseIds.add(wo.Case__c);
            }
        }
        if(caseIds.isEmpty()) {
            return;
        }

		Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        Map<String, Case_Team__c> caseTeamMap = new Map<String, Case_Team__c>();

        for(Case_Team__c ct : [SELECT Case__c, Member__c FROM Case_Team__c WHERE Case__c IN :caseIds]) {
            caseTeamMap.put(ct.Case__c + '-' + ct.Member__c, ct);
        }

        List<Case_Team__c> caseTeamToInsert = new List<Case_Team__c>();
        for(Work_Order__c wo : workOrderRecords) {
            Boolean isNewOrUpdated = false;
            if(oldMap.containsKey(wo.Id)) {
                if(wo.OwnerId != oldMap.get(wo.Id).OwnerId) {
                    isNewOrUpdated = true;
                }
            } else {
                isNewOrUpdated = true;
            }

            if(isNewOrUpdated) {
                String key = wo.Case__c + '-' + wo.OwnerId;
                if(caseTeamMap.containsKey(key) == false && caseMap.get(wo.Case__c).OwnerId != wo.OwnerId ) {
                    Case_Team__c ct = new Case_Team__c();
                    ct.Case__c = wo.Case__c;
                    ct.Member__c = wo.OwnerId;
                    ct.Access_Level__c = 'Read';
                    ct.Case_Team_Role__c = 'Support Agent';
                    caseTeamMap.put(key, ct);
                    caseTeamToInsert.add(ct);
                }
            }
        }

        if(!caseTeamToInsert.isEmpty()) {
            insert caseTeamToInsert;
        }
    }


    public static void manageSharingOnInsert(List<Work_Order__c> workOrderRecords) {
        Set<Id> caseIds = new Set<Id>();
        for (Work_Order__c wo : workOrderRecords) {
            caseIds.add(wo.Case__c);
        }
        if (caseIds.isEmpty()) {
            return;
        }

        Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        Map<String, Case_Team__c> caseTeamMap = new Map<String, Case_Team__c>();

        for (Case_Team__c ct : [SELECT Case__c, Member__c FROM Case_Team__c WHERE Case__c IN :caseIds]) {
            caseTeamMap.put(ct.Case__c + '-' + ct.Member__c, ct);
        }

        List<Case_Team__c> caseTeamToInsert = new List<Case_Team__c>();
        for (Work_Order__c wo : workOrderRecords) {
            String key = wo.Case__c + '-' + wo.OwnerId;
            if (!caseTeamMap.containsKey(key) && caseMap.get(wo.Case__c).OwnerId != wo.OwnerId) {
                Case_Team__c ct = new Case_Team__c();
                ct.Case__c = wo.Case__c;
                ct.Member__c = wo.OwnerId;
                ct.Access_Level__c = 'Read';
                ct.Case_Team_Role__c = 'Support Agent';
                caseTeamMap.put(key, ct);
                caseTeamToInsert.add(ct);
            }
        }

        if (!caseTeamToInsert.isEmpty()) {
            insert caseTeamToInsert;
        }

    }

    // 
//     public static void createWorkOrderFromCase(List<Work_Order__c> workOrderRecords) {
//      System.debug('workOrderRecords: ' + workOrderRecords);
//      Set<Id> caseIds = new Set<Id>();
//      for (Work_Order__c wo : workOrderRecords) {
//          caseIds.add(wo.Case__c);
//          System.debug('caseIds: ' + caseIds);
//      }
//      if (caseIds.isEmpty()) {
//          return;
//      }
//      Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId, Status, Type FROM Case WHERE Id IN :caseIds]);

//      List<Work_Order__c> workOrdersToInsert = new List<Work_Order__c>();
//      for (Work_Order__c wo : workOrderRecords) {
//          Case relatedCase = caseMap.get(wo.Case__c);

//          if (relatedCase != null) {
//              Work_Order__c newWorkOrder = new Work_Order__c();
//              newWorkOrder.Work_Order_Type__c = relatedCase.Type;
//              newWorkOrder.Status__c = relatedCase.Status;
//              workOrdersToInsert.add(newWorkOrder);
//          }
//      }

//      if (!workOrdersToInsert.isEmpty()) {
//          try {
//              // Prevent recursive trigger execution
//              if (!WorkOrderHandler.isTriggerExecuting) {
//                 WorkOrderHandler.isTriggerExecuting = true;
//                 insert workOrdersToInsert;
//                 System.debug('Work Orders successfully inserted: ' + workOrdersToInsert);
//              }
//          } catch (Exception e) {
//              System.debug('Error inserting Work Orders: ' + e.getMessage() + e.getLineNumber());
//          }
//      } else {
//          System.debug('No Work Orders to insert.');
//      }
//  }


    public static void createWorkOrderFromCase(List<Work_Order__c> workOrderRecords) {
        if (WorkOrderTriggerHelper.isTriggerExecuting) {
            return; 
        }

        WorkOrderTriggerHelper.isTriggerExecuting = true;
        
        try {
            System.debug('workOrderRecords: ' + workOrderRecords);
            Set<Id> caseIds = new Set<Id>();
            
            for (Work_Order__c wo : workOrderRecords) {
                caseIds.add(wo.Case__c);
                System.debug('caseIds: ' + caseIds);
            }
            
            if (caseIds.isEmpty()) {
                return;
            }
            
            Map<Id, Case> caseMap = new Map<Id, Case>([SELECT Id, OwnerId, Status, Type FROM Case WHERE Id IN :caseIds]);
            
            List<Work_Order__c> workOrdersToInsert = new List<Work_Order__c>();
            
            for (Work_Order__c wo : workOrderRecords) {
                Case relatedCase = caseMap.get(wo.Case__c);
                
                if (relatedCase != null) {
                    // Work_Order__c newWorkOrder = new Work_Order__c();
                    wo.Work_Order_Type__c = relatedCase.Type;
                    wo.Status__c = relatedCase.Status;
                    // workOrdersToInsert.add(newWorkOrder);
                }
            }

            // if (!workOrdersToInsert.isEmpty()) {
            //     try {
            //         insert workOrdersToInsert;
            //         System.debug('Work Orders successfully inserted: ' + workOrdersToInsert);
            //     } catch (Exception e) {
            //         System.debug('Error inserting Work Orders: ' + e.getMessage() + e.getLineNumber());
            //     }
            // } else {
            //     System.debug('No Work Orders to insert.');
            // }
        } catch (Exception e) {
            System.debug('Error inserting Work Orders: ' + e.getMessage() + e.getLineNumber());
        }
    }




}