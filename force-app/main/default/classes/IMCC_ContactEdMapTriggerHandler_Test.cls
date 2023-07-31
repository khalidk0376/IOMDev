/**
* Created/Modified By: Girikon(Keertiraj)
* Created On:          10 Oct 2021
* @description : This test class covers the apex class : IMCC_ContactEditionMappingTriggerHandler
* Methods Cover:       handleAfterInsert
* Apex Class:          IMCC_ContactEditionMappingTriggerHandler (100%), IMCC_TrigContactEditionMapping(100%), IMCC_UtilityMethod_Handler(92%)
**/
@isTest
public class IMCC_ContactEdMapTriggerHandler_Test {
    
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        
        User userObj;
        Id contactId;
        Id contactId1;
        Id contactId2;
        Id accId;
        
        System.runAs(adminUser){
        List<Account> accObj = IMCC_TestUtilities.createAccount(250);
        accId = accObj[0].Id;
        System.assertEquals('Test Account0', accObj[0].Name, 'Account name does not match');
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
        System.assertEquals('Test0', contObj[0].LastName, 'Contact name does not match');
        contactId = contObj[0].Id;
        contactId1 = contObj[1].Id;
        List<Contact> contObj2 = IMCC_TestUtilities.createContact2(250);
        contactId2 = contObj2[0].Id;
        userObj = IMCC_TestUtilities.createCommunityUser(contObj[1].Id);
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(250);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(250);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 250);
        Id serviceObjId = serviceObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEdition(serviceObjId,docObjId,250);
        Id editionObjId = editionObj[0].Id;
    }
    
    @isTest
    private static void testCreateCEM(){
        List<Contact> con = [Select id,Name,Email,AccountId From Contact where AccountId != '' Limit 1];
        system.debug('Contact Id' +con);
        List<Account> acc = [Select id,Name From Account Limit 1];
        List<Edition__c> listEdt = [SELECT Id, Edition_Code__c FROM Edition__c LIMIT 1];
        Test.startTest();
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(con[0].Id,acc[0].Id,listEdt[0].Id);
        System.assertEquals('Active', cemObj.Relationship_Status__c);
        Test.stopTest();
    }
    
    @isTest
    private static void testCreateCEM2(){
        List<Contact> con = [Select id,Name,Email,AccountId From Contact where AccountId = '' Limit 1];
        system.debug('Contact Id 1 ' +con);
        system.debug('Account Id 1 ' +con[0].AccountId);
        List<Account> acc = [Select id,Name From Account Limit 1];
        List<Edition__c> listEdt = [SELECT Id, Edition_Code__c FROM Edition__c LIMIT 1];
        Test.startTest();
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(con[0].Id,acc[0].Id,listEdt[0].Id);
        System.assertEquals('Active', cemObj.Relationship_Status__c);
        Test.stopTest();
    }

}