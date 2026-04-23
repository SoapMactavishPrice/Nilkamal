public with sharing class CaseTeamLWCController {

    @AuraEnabled(cacheable=true)
    public static Object getCaseTeamRoles() {
        try {
            List<CaseTeamRole> caseTeamRoles = [SELECT Id, Name, AccessLevel FROM CaseTeamRole];
            return caseTeamRoles;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}