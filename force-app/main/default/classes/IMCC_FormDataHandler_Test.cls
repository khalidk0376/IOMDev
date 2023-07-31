/*
Created By    : Aishwarya[IMCC-616]
Test Class    : IMCC_FormDataHandler_Test()
Created/LastModified Date   : 21/11/2021
*/

@isTest
private class IMCC_FormDataHandler_Test{
    
    public static testMethod void formsDataInsert()
    {
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
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        //List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveAndFormSetting(serviceObjId,docObjId,eveSettingObjId,formSettLst[0].Id,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        Test.startTest();
        List<Form_Allocation__c> formAllocLst1 = IMCC_TestUtilities.createFormAlloc(girikonFormLst[0].id,formSettLst[0].id, 5);
        formAllocLst1[0].Booth_Product_Types__c ='';
        formAllocLst1[1].form_entry__c ='One Per Booth';
        formAllocLst1[1].Booth_Product_Types__c = null;
        update formAllocLst1;
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1[0].id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1[0].id,5);
        System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
        List<Tab_User_Type__c> tabUserFormAllocLst11 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1[1].id,1,'Exhibitor');
        List<Forms_Permission__c> formsPermLst11 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst11[0].id,formAllocLst1[1].id,1);
        
        
        List<Form_Data__c> createFormData = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst[0].Id,5);
        
        If(tabUserFormAllocLst.size()>0)
            delete tabUserFormAllocLst;
        
        tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1[0].id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        try{
            tabUserFormAllocLst[0].User_Type__c='Agent';
            update tabUserFormAllocLst;
        }
        catch(Exception e){}
        Test.stopTest();
    }
    
    public static testMethod void formsDataInsert2()
    {
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
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveAndFormSetting(serviceObjId,docObjId,eveSettingObjId,formSettLst[0].Id,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Purchase_Data__c> createPurchaseData = IMCC_TestUtilities.createPurchaseData2(cemObj.Id, editionObjId , 5);
        System.assertEquals(createPurchaseData.Size(),5, 'createPurchaseData size should be 5');
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        Test.startTest();
        List<Form_Allocation__c> formAllocLst1 = IMCC_TestUtilities.createFormAlloc(girikonFormLst[0].id,editionObj[0].Form_Setting__c, 5);
        formAllocLst1[0].Booth_Product_Types__c ='Space Only';
        formAllocLst1[1].form_entry__c ='One Per Booth';
        formAllocLst1[1].Booth_Product_Types__c = null;
        update formAllocLst1;
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1[0].id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1[0].id,5);
        System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
        List<Tab_User_Type__c> tabUserFormAllocLst11 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1[1].id,1,'Exhibitor');
        List<Forms_Permission__c> formsPermLst11 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst11[0].id,formAllocLst1[1].id,1);
        
        List<Form_Data__c> createFormData = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst[0].Id,5);
        createPurchaseData[0].Booth_Product_Type__c ='Space Only';
        update createPurchaseData;
        Test.stopTest();
    }       
}