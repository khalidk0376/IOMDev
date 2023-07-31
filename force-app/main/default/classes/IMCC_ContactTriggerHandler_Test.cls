/**
* Created By     :  Girikon(Arushi[IMCC-5341])
* Created On     :  06/06/2023
* @description   :  Contact Email Update in Source Org should be reflected in IMCC
* Apex Test Class: IMCC_ContactUpdate_Trig
**/

@isTest
private class IMCC_ContactTriggerHandler_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        
        Id contactId;
        Id contactId1;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            System.assertEquals('Test Account0', accObj[0].Name, 'Account name does not match');
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 2);
            contactId = contObj[0].Id;
            contactId1 = contObj[1].Id;
            IMCC_TestUtilities.createCommunityUser(contObj[1].Id);
            List<Trigger__c> trig = IMCC_TestUtilities.createTriggerRecodOfContact();
        }
    }
    
    @isTest
    private static void testMethod1(){
        
        Test.startTest();
        List<Contact> conList = [SELECT Id, Name FROM Contact WHERE Name = 'Test1 Test1'];
        System.assertEquals('Test1 Test1', conList[0].Name, 'Contact Name should be matched');
        
        conList[0].Email = 'abc2@test.com';
        update conList;
        
        Test.stopTest();
    }
    
}