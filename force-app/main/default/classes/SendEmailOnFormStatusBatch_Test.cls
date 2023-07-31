/**
* Created/Modified By: Girikon(Garima)
* Created On:          12/11/2021
* @description  :      This class covers the code coverage of the class SendEmailOnFormStatusBatch
* Methods:             testUserData,formsDataInsert
* Apex Class:          SendEmailOnFormStatusBatch(93%) 
**/
@isTest
private class SendEmailOnFormStatusBatch_Test {
  @TestSetUp
    static void testUserData(){
        //UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where UserRole.Name='Administrator' AND Profile.Name='System Administrator' and IsActive = true Limit 1];
        //adminUser.UserRoleId = userrole.Id;
        //update adminUser;

        // Setup Test Data 
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
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
             
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
      
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData2(cemObj.id,formsPermLst1[0].id,5,editionObjId,accId);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        
        List<Form_Response_Entry__c> formsRespLst = IMCC_TestUtilities.createFormRespEntry(formsDataLst[0].id,cemObj.id,1,null);
        System.assertEquals(formsRespLst.Size(),1, 'Form Data List size should be 2');
        List<Form_Response_Entry__c> freLst = new List<Form_Response_Entry__c>();
        for(Form_Response_Entry__c fre : formsRespLst){
            fre.Approval_Status__c = 'Approved';
            freLst.add(fre);
        }
        //update freLst;
        
        List<ContentVersion> cvLst = IMCC_TestUtilities.createContentVer(10);      
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cvLst[0].Id];
        IMCC_TestUtilities.createContentDocLink(testContent.ContentDocumentId, formsDataLst[0].id, 1);
    }
        
    @isTest
    public static void formsDataInsert()
    {
        User userObj = [SELECT Id FROM User WHERE Profile.Name='IM Customer Community Login User' AND Email='davidjones@test.com' LIMIT 1];
            Test.startTest();
        System.runAs(userObj) {
            Set<Id> freIds = new Set<Id>();
            List<Form_Response_Entry__c> freLst = [SELECT Id FROM Form_Response_Entry__c];
            for(Form_Response_Entry__c fre : freLst){
            	freIds.add(fre.Id);
            }
            System.assertEquals(1, freLst.size(), 'More Than one data');
        }
            Test.stopTest();
        }
    }