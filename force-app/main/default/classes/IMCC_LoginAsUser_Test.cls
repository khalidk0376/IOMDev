/**
* Created/Modified By : IMCC_LoginAsUser_Test(Arushi)
* Created On:          19/01/2022
* @description  :      This class covers the code coverage of the class IMCC_LoginAsUser
* Methods:             getUserLoginData
* Apex Class:          IMCC_LoginAsUser(100%) 
**/
@isTest
private class IMCC_LoginAsUser_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }

    @IsTest
    private static void getUserLoginData()
    {
        Test.startTest();
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
        Map<String,String> contactUserData = IMCC_LoginAsUser.getUserLoginData(contactId);
        System.assertEquals(contactUserData.get('UserId'),userObj.Id, 'Same User');
        Test.stopTest();
    }    

    @isTest
    private static void getUserLoginDataFail()
    {
        Test.startTest();
        try{
            IMCC_LoginAsUser.getUserLoginData(null);
        }
        catch(Exception e){
          System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        Test.stopTest();
    }    
}