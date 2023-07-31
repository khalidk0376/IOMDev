/**
* Created/Modified By: Girikon(Garima)
* Created On:          12/11/2021
* @description  :      This class covers the code coverage of the class IMCC_FormsCtrl
* Methods:             testUserData,formsDataInsert
* Apex Class:          IMCC_FormsCtrl(91%) 
**/
@isTest
private class IMCC_FormsCtrl_Test {
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;
    }

    @isTest
    public static void formsDataInsert()
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
        
        System.assertEquals(editionObj.Size(),250, 'Edition List size should be 250');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Event_Tabs__c> evntTabsLst2 = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,20,null,'Standard','Manuals',null);
        System.assertEquals(evntTabsLst2.Size(),5, 'evntTabsLst2 size should be 5');
             
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Purchase_Data__c> purDataLst = IMCC_TestUtilities.createPurchaseData(cemObj.Id,accId,5);
        System.assertEquals(purDataLst.Size(),5, 'Purchase Data List size should be 5');
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Mandatory');
        Form_Allocation__c formAllocLst2 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Additional');
        Form_Allocation__c formAllocLst3 = IMCC_TestUtilities.createFormAllocationWithHeading(girikonFormLst[0].id,formSettLst[0].id,'Optional');
        Form_Allocation__c formAllocLst4 = IMCC_TestUtilities.createFormAllocation1('Manual','PDF',girikonFormLst[0].id,formSettLst[0].id,'One Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        List<Tab_User_Type__c> tabUserFormAllocLst1 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst4.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst1.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        List<Forms_Permission__c> formsPermLst2 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst2.id,5);
        System.assertEquals(formsPermLst2.Size(),5, 'Form Permission List size should be 5');
        List<Forms_Permission__c> formsPermLst3 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst3.id,5);
        System.assertEquals(formsPermLst3.Size(),5, 'Form Permission List size should be 5');
        List<Forms_Permission__c> formsPermLst4 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst1[0].id,formAllocLst4.id,5);
        System.assertEquals(formsPermLst4.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        List<Form_Data__c> formsDataLst1 = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst4[0].id,5);
        System.assertEquals(formsDataLst1.Size(),5, 'Form Data List size should be 5');
        
        List<Form_Response_Entry__c> formResEntryLst = IMCC_TestUtilities.createFormRespEntry(formsDataLst1[0].id,cemObj.id,1,purDataLst[0].Id);
        System.assertEquals(formResEntryLst.Size(),1, 'Form Response Entry List size should be 1');

        List<ContentVersion> cvLst = IMCC_TestUtilities.createContentVer(10);      
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cvLst[0].Id];
        List<ContentDocumentLink> newFileShareLst = IMCC_TestUtilities.createContentDocLink(testContent.ContentDocumentId, formsDataLst[0].id, 1);
        
        System.runAs(userObj) {
            Test.startTest();
            List<Event_Tabs__c> lstEvntTab1 = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: eveSettingObjId and Standard_Tab_Type__c = 'Forms'];
            if(!lstEvntTab1.isEmpty()){
            IMCC_FormsCtrl.customerFormListWrpData(editionObj[0].Edition_Code__c,accId,lstEvntTab1[0].Tab_Code__c);
            }
            List<Event_Tabs__c> lstEvntTab2 = [Select id,Name,Event_Setting__c,Tab_Code__c from Event_Tabs__c where Event_Setting__c =: eveSettingObjId and Standard_Tab_Type__c = 'Manuals'];
            if(!lstEvntTab2.isEmpty()){
            IMCC_FormsCtrl.customerFormListWrpData(editionObj[0].Edition_Code__c,accId,lstEvntTab2[0].Tab_Code__c);
            }
            IMCC_FormsCtrl.updateFormData('Online',formsDataLst[0].id,'true',girikonFormLst[0].id,cemObj.id);
            IMCC_FormsCtrl.updateFormData('Link',formsDataLst[0].id,'true',girikonFormLst[0].id,cemObj.id);
            IMCC_FormsCtrl.updateApplicableFormData(formsDataLst[0].id,true);
            IMCC_FormsCtrl.updateFormDataAfterUpload(formsDataLst[0].id);
            IMCC_FormsCtrl.contactData(accId,cemObj.id);
            IMCC_FormsCtrl.checkDelegateDetails(girikonFormLst[0].id,cemObj.id);
            IMCC_FormsCtrl.assignFormsToDelegate(contactId,editionObj[0].Edition_Code__c,new String[]{girikonFormLst[0].id},accId);
            
            IMCC_FormsCtrl.updateFormAgreed(formsDataLst[0].id);
            IMCC_FormsCtrl.deleteUploadedPdf(newFileShareLst[0].id);
            IMCC_FormsCtrl.updateFormDataNew('Link',formsDataLst[0].id,cemObj.id,'','','');
            IMCC_FormsCtrl.getFormDataDetail(formsDataLst[0].id,new String[]{formsDataLst[0].id});
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','formAllocName','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','formHeading','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','formFeatureCategory','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','formType','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','formEntry','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','BoothNumber','asc');
            IMCC_FormsCtrl.getFormData(cemObj.id,'One Per Account','Status','asc');
            IMCC_FormsCtrl.resetFormDataStatus(formsDataLst1);
            IMCC_FormsCtrl.fetchfileUploadSize(testContent.Id);
            Test.stopTest();
        }
    }   
    
    @isTest
    public static void testException() {

        try{
            IMCC_FormsCtrl.updateFormDataNew('Link',null,null,null,null,null);
        } catch(Exception e){
            System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
         
        try{
            IMCC_FormsCtrl.getFormDataDetail(null,null);
        } catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }   
        try{
            IMCC_FormsCtrl.updateApplicableFormData(null,null);
        } catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            IMCC_FormsCtrl.deleteUploadedPdf(null);
        } catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{IMCC_FormsCtrl.updateFormAgreed(null);}
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }       
        try{
            IMCC_FormsCtrl.assignFormsToDelegate(null,null,null,null);
        } 
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        IMCC_FormsCtrl.CustomerFormListWrp testObj = new IMCC_FormsCtrl.CustomerFormListWrp();
    }
}