/*
* Created/Modified By: Girikon(Keertiraj)
* Created On:          17/11/2021
* @description : This test class covers the apex class : IMCC_FBUtilsHelper
* Apex Class: IMCC_FBUtilsHelper(90%)
*/
@isTest
private class IMCC_FBUtilsHelper_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    @isTest
    public static void IMCC_FBUtilsHelperTest()
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,250);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocation1('Form','Online',girikonFormLst[0].id,formSettLst[0].id,'Multiple Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst1 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst1.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst1[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst1= IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Response_Entry__c> formRespEntLst1 = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[0].id,cemObj.id,5,null);
        System.assertEquals(formRespEntLst1.Size(),5, 'Form Response List size should be 5');
        
        Form_Allocation__c formAllocLst2 = IMCC_TestUtilities.createFormAllocation1('Form','PDF',null,formSettLst[0].id,'One Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst2 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst2.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst2.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst2 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst2[0].id,formAllocLst2.id,5);
        System.assertEquals(formsPermLst2.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst2= IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst2[0].id,5);
        System.assertEquals(formsDataLst2.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Response_Entry__c> formRespEntLst2 = IMCC_TestUtilities.createFormRespEntry(formsDataLst2[0].id,cemObj.id,5,null);
        System.assertEquals(formRespEntLst2.Size(),5, 'Form Response List size should be 5');
        
        List<Question__c> questList = IMCC_TestUtilities.createQuestions();
        List<Question_Option__c> questOptionList = IMCC_TestUtilities.createQuestionOptions(questList[1].Id);
        Question_Response__c questResponse = IMCC_TestUtilities.createQuestionResponse(girikonFormLst[0].id,questList[0].Id,userObj.Id,'TestAnswer');
        Question_Response__c questResponse1 = IMCC_TestUtilities.createQuestionResponse(girikonFormLst[0].id,questList[1].Id,userObj.Id,'Picklist1');
        Question_Response__c questResponse2 = IMCC_TestUtilities.createQuestionResponse2(girikonFormLst[0].id,questList[1].Id,userObj.Id,'Picklist1',formRespEntLst1[0].id);
        
        system.debug('Con Map Id ' +cemObj.id);
        system.debug('Girikon Id ' +girikonFormLst[0].id);
        
        //System.runAs(userObj) {
            Test.startTest();
            IMCC_FBUtilsHelper.sendEmailFormResponse(formRespEntLst1[0].Id);
            IMCC_FBUtilsHelper.sendEmailFormResponse(formRespEntLst2[0].Id);
            Test.stopTest();
        //}
    }

}