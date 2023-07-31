/**
* Created/Modified By: Girikon(Aishwarya)
* Created On:          07/9/2021
* @description  :      This class covers the code coverage of the class IMCC_EditionPopupHandler and Trigger - IMCC_trgUpdateMarkAsRead
* Apex Class:          IMCC_EditionPopupHandler(88%) 
**/

@isTest
private class IMCC_EditionPopupHandler_Test{
    
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
            
            cemObj.Edition__c = listEditionPopup[0].Edition__c;
            cemObj.Access_Type__c = evntTabUserTypeList[0].User_Type__c;
            update cemObj;
            IMCC_EditionPopupHandler.additionalUsersCEM(cemObj.Id);
            IMCC_EditionPopupHandler.searchContact('test');
            IMCC_EditionPopupHandler.ReplaceUserData rud = new IMCC_EditionPopupHandler.ReplaceUserData();
            rud.editionId=listEditionPopup[0].Edition__c;
            rud.accountId=accId;
            rud.contactId=contObj[5].Id;
            rud.recordId=cemObj.Id;
            rud.selectedRecordId=contObj[5].Id;
            IMCC_EditionPopupHandler.replaceUser(JSON.serialize(rud));
            Test.startTest();
            
            listEditionPopup[0].Reset_Pop_up_Preferences__c = true;
            update listEditionPopup;
            List<Email_Templates__c> lisEmailTemp = IMCC_TestUtilities.createEditionEmailTemplate3();
            IMCC_EditionPopupHandler.cloneGlobalTemplates(editionObjId);
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
            accId = accObj[2].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            contactId = contObj[0].Id;
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
            Contact_Edition_Mapping__c cemObj2 = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
            
            cemObj.Edition__c = listEditionPopup[0].Edition__c;
            cemObj.Access_Type__c = evntTabUserTypeList[0].User_Type__c;
            //update cemObj;
            IMCC_EditionPopupHandler.additionalUsersCEM(cemObj.Id);
           
            Test.startTest();
            Purchase_Data__c purData=new Purchase_Data__c(Contact__c=contactId,Edition__c = listEditionPopup[1].Edition__c,Account__c =accId,
            Booth_Product_Type__c = 'Space Only', Booth_Number__c = 'H2.11', Purchase_Status__c = 'Active', Transaction_Status__c ='Active',Contact_Edition_Mapping__c =cemObj.Id);
            insert purData;
            
            List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
            System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
            List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
            System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
            
            Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithEmail(girikonFormLst[0].id,formSettLst[0].id);
            
            List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
            System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
            
            List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
            System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
            List<Form_Data__c> fdList = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst[0].Id,1);
                 
            Form_Response_Entry__c fsEntry = new Form_Response_Entry__c();
            fsEntry.Entry_Number__c = 1;
            fsEntry.Form_Data__c = fdList[0].id;
            fsEntry.Contact_Edition_Mapping__c =cemObj.Id;
            fsEntry.Ops_Contact_Name__c =contObj[5].Id;
            fsEntry.User__c=userObj.Id;
            insert fsEntry;
            
            List<Contractor_Mapping__c> cmObj = IMCC_TestUtilities.createContractorMappingData(accId,contactId,cemObj.Id,purData.Id,'Contractor Nominated',listEditionPopup[1].Edition__c,'',1);
            FAQ_Contact_Mapping__c faqs = new FAQ_Contact_Mapping__c(Contact_Edition_Mapping__c=cemObj.Id,Upvote_Downvote__c='Upvote');
            insert faqs;
               
            IMCC_EditionPopupHandler.ReplaceUserData rud1 = new IMCC_EditionPopupHandler.ReplaceUserData();
            rud1.editionId=listEditionPopup[1].Edition__c;
            rud1.accountId=accId;
            //rud.contactId=contObj[5].Id;
            rud1.recordId=cemObj.Id;
            rud1.selectedRecordId=cemObj2.Id;
            IMCC_EditionPopupHandler.replaceUser(JSON.serialize(rud1));
            Test.stopTest();
        }
        
    }   
}