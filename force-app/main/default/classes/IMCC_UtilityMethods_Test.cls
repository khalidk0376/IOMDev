/**
 * Created/Modified By  : Girikon(Keertiraj)
 * Created On   :  12/10/2021
 * @description : This test class covers the apex class : IMCC_UtilityMethods
 * Apex Class   : IMCC_UtilityMethods (83%)
 
 * Modification Log----- 
 * Modified by : 
**/

@isTest
public class IMCC_UtilityMethods_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void prepareCommunityUserTest(){
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
       
        System.runAs(adminUser){
        List<Account> accObj = IMCC_TestUtilities.createAccount(250);
        accId = accObj[0].Id;
        System.assertEquals('Test Account0', accObj[0].Name, 'Account name does not match');
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
        contactId = contObj[0].Id;
        System.assertEquals('Test0', contObj[0].LastName, 'Contact name does not match');
        List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(250);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        
        System.assertEquals(editionObj.Size(),250, 'Edition List size should be 250');
        Profile p = [SELECT Id FROM Profile WHERE Name= 'IM Customer Community Login User'];
        Test.startTest();
        IMCC_UtilityMethods.prepareCommunityUser(p.Id, contObj);
        IMCC_UtilityMethods.getCommunityURL();
        IMCC_UtilityMethods.getCommProfile();
        IMCC_UtilityMethods.getContactEditionMappings(editionObj[0].Edition_Code__c,accId);
        Test.stopTest();
        }
        
    }
    

}