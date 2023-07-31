/**
* Created/Modified By: Girikon(Garima)
* Created On:          8/10/2021
* @description  :      This class covers the code coverage of the class Trig_SetFileVisibility_Handler
* Methods:             testUserData, testUserData
* Apex Class:          Trig_SetFileVisibility_Handler(100%) 
**/

@isTest
private class Trig_SetFileVisibility_Handler_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    public static testMethod void cntntDocLinkInsert(){
        
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
        }
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
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Event_Tabs__c> evntTabs = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,10,'Header and 2 Column','Standard','Floorplan','Manual');
        System.assertEquals(evntTabs[0].Floorplan_Type__c,'Manual', 'Floorplan Type should be manual');
        
        List<PDF_Floorplan__c> pdfFloorplanLst = IMCC_TestUtilities.createPdfFloorplan(evntTabs[0].id,10,'Group 1');
        
        //Insert contentdocument data
        List<ContentVersion> cvLst = IMCC_TestUtilities.createContentVer(10);      
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cvLst[0].Id];
        
        test.startTest();
        List<ContentDocumentLink> newFileShareLst = IMCC_TestUtilities.createContentDocLink(testContent.ContentDocumentId, pdfFloorplanLst[0].id, 1);
        test.stopTest();
    }
}