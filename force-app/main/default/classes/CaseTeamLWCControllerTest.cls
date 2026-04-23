@isTest
public class CaseTeamLWCControllerTest {

    @testSetup
    static void setup() {
        CaseTeamRole role1 = new CaseTeamRole(Name = 'Role 1', AccessLevel = 'Read');
        CaseTeamRole role2 = new CaseTeamRole(Name = 'Role 2', AccessLevel = 'Edit');
        insert new List<CaseTeamRole>{role1, role2};
    }

    @isTest
    static void testGetCaseTeamRoles_Success() {
        Test.startTest();
        Object result = CaseTeamLWCController.getCaseTeamRoles();
        Test.stopTest();

        System.assert(result instanceof List<CaseTeamRole>, 'Result should be a List of CaseTeamRole');

        List<CaseTeamRole> roles = (List<CaseTeamRole>)result;
        System.assert(roles.size() > 0, 'There should be some CaseTeamRole records returned');

        for (CaseTeamRole role : roles) {
            System.assertNotEquals(null, role.Name, 'Role Name should not be null');
            System.assertNotEquals(null, role.AccessLevel, 'AccessLevel should not be null');
        }
    }
}