/**
* Created/Modified By :(Arushi [IMCC-5107])
* Created On:          28/03/2023
* @description  :      As an Ops User, I should be able to easily create Test Accounts to validate In Progress events
* Methods:             getEixstingTestData,testDataCreated,cancelInvitation,sendEmailInvite
* Apex Class:          IMCC_CreateViewTestDataCTRL
**/
@isTest
public class IMCC_CreateViewTestDataCTRLTest {
    
    public static testMethod void headerDataInsert()
    {
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        // Setup Test Data 
        // User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            contObj[0].IsTestUser__c = True;
            contObj[0].Access_Type__c = 'Agent';
            update contObj[0];
            
            userObj = IMCC_TestUtilities.createCommunityUser2(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
            
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
            
            //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code'); 
            
            List<Edition_Popup__c> listEditionPopup = IMCC_TestUtilities.createEditionPopupData(editionObj[0].Id,200);
            
            List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabListData(eveSettingObj[0].Id,200);
            
            System.assertEquals(evntTabsLst.Size(),200, 'evntTabsLst size should be 200');
            
            List<Tab_User_Type__c> evntTabUserTypeList = IMCC_TestUtilities.createEventntTabUserTypeData(evntTabsLst[0].Id,listEditionPopup[0].Id,200);
            
            Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
            List<Email_Templates__c> lisEmailTemp = IMCC_TestUtilities.createEmailTemplateWelcomeTestUser();
            
            Test.startTest();
            IMCC_CreateViewTestDataCTRL.getEixstingTestData(editionObjId);
            IMCC_CreateViewTestDataCTRL.testDataCreated(editionObjId, 'Agent', 'Space Only');
            IMCC_CreateViewTestDataCTRL.sendEmailInvite(cemObj.Id, 'abc@test.com');
            
            Test.stopTest();
        }
        
    }   
    
    public static testMethod void headerDataInsert2()
    {
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
        // Setup Test Data 
        // User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            contObj[0].IsTestUser__c = True;
            contObj[0].Access_Type__c = 'Agent';
            update contObj[0];
            
            userObj = IMCC_TestUtilities.createCommunityUser2(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
            
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
            
            //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code'); 
            
            List<Edition_Popup__c> listEditionPopup = IMCC_TestUtilities.createEditionPopupData(editionObj[0].Id,200);
            
            List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabListData(eveSettingObj[0].Id,200);
            
            System.assertEquals(evntTabsLst.Size(),200, 'evntTabsLst size should be 200');
            
            List<Tab_User_Type__c> evntTabUserTypeList = IMCC_TestUtilities.createEventntTabUserTypeData(evntTabsLst[0].Id,listEditionPopup[0].Id,200);
            
            Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping2(contactId,accId,editionObjId);
            
            Test.startTest();
            IMCC_CreateViewTestDataCTRL.getEixstingTestData(editionObjId);
            IMCC_CreateViewTestDataCTRL.testDataCreated(editionObjId, 'Agent', 'Space Only');
            IMCC_CreateViewTestDataCTRL.cancelInvitation(cemObj.Id);
            
            Test.stopTest();
        }
        
    }    

}