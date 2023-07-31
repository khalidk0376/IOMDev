/**
* Created/Modified By         : Girikon(Arushi)
* Created On/Last Modified By : 10/11/2023
* @description                : This class is used to fetch forms permission and Contact Edition Mapping and also to update some fields on Form Data Object
* Methods                     : getTasksForAssignment,getLoggedInUserInfo,assignFormToTeam
* Apex Class                  : IMCC_ManageTaskAssignmentCtrl 

**/
@isTest
public class IMCC_ManageTaskAssignmentCtrl_Test {
    
     @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }
    
    public static testMethod void testMethod1(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        Contact con1 = new Contact();
        User userObj;
        User userObj2;
        Id contactId;
        Id contactId2;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 2);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
            
            contactId2 = contObj[1].Id;
            con1 = contObj[1];
            userObj2 = IMCC_TestUtilities.createCommunityUser2(contactId2);
            System.assertEquals(userObj2.ContactID,contactId2, 'Same contact');
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(1);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs2(eveSettingObj[0].Id, 200, 10, null, 'Standard', 'Manage My Task',null);
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        Contact_Edition_Mapping__c cemObj2 = IMCC_TestUtilities.createContactEditionMapping(contactId2,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        
        Purchase_Data__c booth1 = IMCC_TestUtilities.createPurchaseData3(contactId2,editionObjId,accId);
        booth1.Contact_Edition_Mapping__c = cemObj2.Id;
        Update booth1;
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');

        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst1 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst1.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst4 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst1[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst4.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst1 = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst4[0].id,5);
        System.assertEquals(formsDataLst1.Size(),5, 'Form Data List size should be 5');
        formsDataLst1[0].Is_Active__c=true;
        formsDataLst1[1].Is_Active__c=true;
        List<Form_Data__c> updatedFD = new List<Form_Data__c>();
        updatedFD.add(formsDataLst1[0]);
        updatedFD.add(formsDataLst1[1]);
        Update updatedFD;
        
        List<Form_Response_Entry__c> formResEntryLst = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[0].id,cemObj.Id,1,booth.Id);
        List<Form_Response_Entry__c> formResEntryLst1 = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[1].id,cemObj.Id,1,booth.Id);
        System.assertEquals(formResEntryLst.Size(),1, 'Form Response Entry List size should be 1');
        System.assertEquals(formResEntryLst1.Size(),1, 'Form Response Entry List size should be 1');

        Test.startTest();        
        System.runAs(userObj) {
            String eventTabCode = [SELECT Id,Tab_Code__c FROM Event_Tabs__c WHERE Id =: evntTabsLst[0].Id].Tab_Code__c;
            List<Form_Data__c> fDToBeUpdated = new List<Form_Data__c>();
            fDToBeUpdated.add(formsDataLst1[0]);
            fDToBeUpdated[0].Assign_To__c = cemObj2.Id;
            
            IMCC_ManageTaskAssignmentCtrl.getTasksForAssignment(editionObj[0].Edition_Code__c,accId,eventTabCode);
            IMCC_ManageTaskAssignmentCtrl.getLoggedInUserInfo(editionObj[0].Edition_Code__c,accId);
            IMCC_ManageTaskAssignmentCtrl.assignFormToTeam(editionObj[0].Edition_Code__c,accId,fDToBeUpdated,eventTabCode,'/IMCC/s/manage-my-task');
        }
        Test.stopTest();
    }  
    
    public static testMethod void testMethod2(){
        // Setup Test Data 
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        Contact con = new Contact();
        User userObj;
        User userObj2;
        Id contactId;
        Id contactId2;
        Id accId;
        
        System.runAs(adminUser){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
            con = contObj[0];
            userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            System.assertEquals(userObj.ContactID,contactId, 'Same contact');
            
        }
        List<Document> docObj  = IMCC_TestUtilities.createDocument(1);
        Id docObjId = docObj[0].Id;
        List<Brand__c> brandObj  = IMCC_TestUtilities.createBrand(1);
        Id brandObjId = brandObj[0].Id;
        List<Series__c> serviceObj  = IMCC_TestUtilities.createEventSeries(brandObjId, 1);
        Id serviceObjId = serviceObj[0].Id;
        List<Event_Setting__c> eveSettingObj = IMCC_TestUtilities.createEventSetting(1);
        Id eveSettingObjId = eveSettingObj[0].Id;
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting2(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs2(eveSettingObj[0].Id, 200, 10, null, 'Standard', 'Manage My Task',null);
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
       
        Purchase_Data__c booth = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId,accId);
        booth.Contact_Edition_Mapping__c = cemObj.Id;
        Update booth;
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');

        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst1 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst1.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst4 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst1[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst4.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst1 = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst4[0].id,5);
        System.assertEquals(formsDataLst1.Size(),5, 'Form Data List size should be 5');
        formsDataLst1[0].Is_Active__c=true;
        formsDataLst1[1].Is_Active__c=true;
        List<Form_Data__c> updatedFD = new List<Form_Data__c>();
        updatedFD.add(formsDataLst1[0]);
        updatedFD.add(formsDataLst1[1]);
        Update updatedFD;
        
        /*List<Form_Response_Entry__c> formResEntryLst = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[0].id,cemObj.Id,1,booth.Id);
        List<Form_Response_Entry__c> formResEntryLst1 = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[1].id,cemObj.Id,1,booth.Id);
        System.assertEquals(formResEntryLst.Size(),1, 'Form Response Entry List size should be 1');
        System.assertEquals(formResEntryLst1.Size(),1, 'Form Response Entry List size should be 1');*/

        Test.startTest();        
        System.runAs(userObj) {
            String eventTabCode = [SELECT Id,Tab_Code__c FROM Event_Tabs__c WHERE Id =: evntTabsLst[0].Id].Tab_Code__c;
            List<Form_Data__c> fDToBeUpdated = new List<Form_Data__c>();
            fDToBeUpdated.add(formsDataLst1[0]);
            fDToBeUpdated[0].Assign_To__c = cemObj.Id;
            
            IMCC_ManageTaskAssignmentCtrl.getTasksForAssignment(editionObj[0].Edition_Code__c,accId,eventTabCode);
            IMCC_ManageTaskAssignmentCtrl.getLoggedInUserInfo(editionObj[0].Edition_Code__c,accId);
            IMCC_ManageTaskAssignmentCtrl.assignFormToTeam(editionObj[0].Edition_Code__c,accId,fDToBeUpdated,eventTabCode,'/IMCC/s/manage-my-task');
        }
        Test.stopTest();
    }  

}