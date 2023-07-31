/**
* Created/Modified By: Girikon(Mukesh Gupta)     
* @description  :      This class covers the code coverage of the class FBUtils
* Methods:             testInsertRecords
* Apex Class:          FBUtils,Trig_UpdateStatusOnFormData_Handler(39%)
**/

@IsTest
private class FBUtilTest {
    
    @TestSetUp
    static void testSetupData(){
        UserRole userrole = [SELECT Id, DeveloperName FROM UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [SELECT Id, UserRoleId FROM User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        System.RunAs(adminUser)
        {
            adminUser.UserRoleId = userrole.Id;
            update adminUser;
        }

        List<FBUtils.KeyValuePair> listObj = new List<FBUtils.KeyValuePair>();
        listObj.add(new FBUtils.KeyValuePair('Answer__c', 'responseText'));
        listObj.add(new FBUtils.KeyValuePair('Comment__c', 'bq.comment'));        
        listObj.add(new FBUtils.KeyValuePair('User__c', UserInfo.getUserId()));
        
        
        Map<Integer,List<FBUtils.KeyValuePair>> recordsToInsert = new Map<Integer,List<FBUtils.KeyValuePair>>();
        recordsToInsert.put(0,listObj);
        
        //Test insertRecords() method
        FBUtils.FBResponse response = FBUtils.insertRecords('Question_Response__c', recordsToInsert);
        System.assertEquals(response.isSuccess, true, 'Failed to insert Question Response records');
         
        //Test updateRecords() method
        
        recordsToInsert.get(0).add(new FBUtils.KeyValuePair('Answer__c','Girikon LLC'));
        FBUtils.FBResponse response2 = FBUtils.updateRecords('Question_Response__c', recordsToInsert);
        //Create Question Library
        Question_Library__c oQL = FBUtils.questionLibrary();
        
        //Create Question Record 
        FBUtils.createQst(oQL.Id);
        System.assertEquals(response2.isSuccess, false, 'Failed to update Question Response records');
        
        // Setup Test Data 
        User adminUser2 = [SELECT Id, UserRoleId FROM User WHERE Profile.Name='System Administrator' and IsActive = true and UserRole.Name = 'Administrator' Limit 1];
        User userObj;
        Id contactId;
        Id accId;
        
        System.runAs(adminUser2){
            List<Account> accObj  = IMCC_TestUtilities.createAccount(1);
            accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 1);
            contactId = contObj[0].Id;
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
        List<Edition__c> editionObj = IMCC_TestUtilities.createEventEditionWithEveSetting(serviceObjId,docObjId,eveSettingObjId,1);
        Id editionObjId = editionObj[0].Id;
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),1, 'evntTabsLst size should be 1');
        
        List<Event_Tabs__c> evntTabsLst2 = IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,20,null,'Standard','Manuals',null);
        System.assertEquals(evntTabsLst2.Size(),1, 'evntTabsLst2 size should be 1');
             
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,1,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),1, 'Tab User List size should be 1'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(1);
        System.assertEquals(girikonFormLst.Size(),1, 'Girikon Form List size should be 1');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(1);
        System.assertEquals(formSettLst.Size(),1, 'Form Setting List size should be 1');
        editionObj[0].Form_Setting__c = formSettLst[0].id;
        update editionObj;
        
        List<Purchase_Data__c> purchaseDataLst = IMCC_TestUtilities.createPurchaseData(cemObj.id,accId,2);
        System.assertEquals(purchaseDataLst.Size(),2, 'Form Data List size should be 2');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocation1('Form','Online',girikonFormLst[0].id,formSettLst[0].id,'One Per Account');
        Form_Allocation__c formAllocLst2 = IMCC_TestUtilities.createFormAllocation2('Form','PDF',null,formSettLst[0].id,'Multiple Per Account');
        Form_Allocation__c formAllocLst3 = IMCC_TestUtilities.createFormAllocation1('Form','PDF',null,formSettLst[0].id,'One Per Booth');
        Form_Allocation__c formAllocLst4 = IMCC_TestUtilities.createFormAllocation2('Form','PDF',null,formSettLst[0].id,'Multiple Per Booth');
        Form_Allocation__c formAllocLst5 = IMCC_TestUtilities.createFormAllocation1('Manual','PDF',null,formSettLst[0].id,'One Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),1, 'Tab User List size should be 1');
        
        List<Tab_User_Type__c> tabUserFormAllocLst2 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst2.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst2.Size(),1, 'Tab User List size should be 1');

        List<Tab_User_Type__c> tabUserFormAllocLst3 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst3.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst3.Size(),1, 'Tab User List size should be 1');

        List<Tab_User_Type__c> tabUserFormAllocLst4 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst4.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst4.Size(),1, 'Tab User List size should be 1');
        
        List<Tab_User_Type__c> tabUserFormAllocLst5 = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst5.id,1,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst5.Size(),1, 'Tab User List size should be 1');
    }
    
    @isTest
    public static void testOnlineOnePerAccount()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='One Per Account' AND Feature_Category__c='Form' LIMIT 1];
        fa.Approval_Required__c = true;
        update fa;
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Viewed');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        List<Question_Response__c> lstQR = [SELECT Id FROM Question_Response__c];
        for(Question_Response__c qr : lstQR){
            qr.Form_Response_Entry__c = lst[0].Id;
        }
        update lstQR;
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId',lst[0].Id);
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertEquals(1, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineMultiplePerAccount()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='Multiple Per Account' AND Feature_Category__c='Form' LIMIT 1];
        fa.Approval_Required__c = true;
        update fa;
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        param1.put('version','2');
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        Blob b = Blob.valueOf('test');
        ContentVersion contentVersion1 = new ContentVersion(
            Title='Response - 1', 
            PathOnClient ='Response - 1'+'.pdf',
            VersionData = b, 
            origin = 'H',
            IsMajorVersion = false
        );
        insert contentVersion1;
            
        ContentVersion contentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id WITH SECURITY_ENFORCED LIMIT 1];
            
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = lst[0].Id;
        contentlink.contentdocumentid = contentVersion2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        update new Form_Response_Entry__c(Id=lst[0].Id,Content_Version__c=contentVersion1.Id,File_Name__c=contentVersion1.Title);
        
        ContentVersion contentVersion3 = new ContentVersion(
            Title='Response - 1', 
            PathOnClient ='Response - 1'+'.pdf',
            VersionData = b, 
            origin = 'H',
            IsMajorVersion = false
        );
        insert contentVersion3;
            
        ContentVersion contentVersion4 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion3.Id WITH SECURITY_ENFORCED LIMIT 1];
            
        ContentDocumentLink contentlink2 = new ContentDocumentLink();
        contentlink2.LinkedEntityId = lst[0].Id;
        contentlink2.contentdocumentid = contentVersion4.contentdocumentid;
        contentlink2.ShareType = 'V';
        insert contentlink2;

        update new Form_Response_Entry__c(Id=lst[0].Id,Content_Version__c=contentVersion4.Id,File_Name__c=contentVersion4.Title);
        
        param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId',lst[0].Id);
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        param1.put('version','2');
        FBUtils.saveFormStatus(param1);
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        param2.put('version','');
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);
        
        param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        param2.put('version','2');
        FBUtils.saveFormStatus(param2);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertEquals(2, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineMultiplePerAccountNoApproval()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='Multiple Per Account' AND Feature_Category__c='Form' LIMIT 1];
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        param1.put('version','2');
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id,Version__c FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        Blob b = Blob.valueOf('test');
        ContentVersion contentVersion1 = new ContentVersion(
            Title='Response - 1', 
            PathOnClient ='Response - 1'+'.pdf',
            VersionData = b, 
            origin = 'H',
            IsMajorVersion = false
        );
        insert contentVersion1;
            
        ContentVersion contentVersion2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion1.Id WITH SECURITY_ENFORCED LIMIT 1];
            
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = lst[0].Id;
        contentlink.contentdocumentid = contentVersion2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        update new Form_Response_Entry__c(Id=lst[0].Id,Content_Version__c=contentVersion1.Id,File_Name__c=contentVersion1.Title);
        
        ContentVersion contentVersion3 = new ContentVersion(
            Title='Response - 1', 
            PathOnClient ='Response - 1'+'.pdf',
            VersionData = b, 
            origin = 'H',
            IsMajorVersion = false
        );
        insert contentVersion3;
            
        ContentVersion contentVersion4 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion3.Id WITH SECURITY_ENFORCED LIMIT 1];
            
        ContentDocumentLink contentlink2 = new ContentDocumentLink();
        contentlink2.LinkedEntityId = lst[0].Id;
        contentlink2.contentdocumentid = contentVersion4.contentdocumentid;
        contentlink2.ShareType = 'V';
        insert contentlink2;

        update new Form_Response_Entry__c(Id=lst[0].Id,Content_Version__c=contentVersion4.Id,File_Name__c=contentVersion4.Title);
        
        param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId',lst[0].Id);
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        param1.put('version',string.valueOf(lst[0].Version__c));
        FBUtils.saveFormStatus(param1);
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        param2.put('version','');
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);
        
        param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        param2.put('version','2');
        FBUtils.saveFormStatus(param2);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertEquals(2, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineOnePerBooth()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='One Per Booth' AND Feature_Category__c='Form' LIMIT 1];
        fa.Approval_Required__c = true;
        update fa;
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        List<Purchase_Data__c> lstPD = [SELECT Id FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=:cem.id];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        
        param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId',lst[0].Id);
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        FBUtils.saveFormStatus(param1);
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);
        
        param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        FBUtils.saveFormStatus(param2);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertNotEquals(2, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineOnePerBooth2()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='One Per Booth' AND Feature_Category__c='Form' LIMIT 1];
        fa.Approval_Required__c = false;
        update fa;
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        List<Purchase_Data__c> lstPD = [SELECT Id FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=:cem.id];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        
        param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId',lst[0].Id);
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        FBUtils.saveFormStatus(param1);
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);
        
        param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        FBUtils.saveFormStatus(param2);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertNotEquals(2, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineMultiplePerBooth()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='Multiple Per Booth' AND Feature_Category__c='Form' LIMIT 1];
        fa.Approval_Required__c = true;
        update fa;
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        List<Purchase_Data__c> lstPD = [SELECT Id FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c=:cem.id];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        param1.put('version','2');
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id,Version__c FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        
        param1 = new Map<String,String>();
        param1.put('status','Submitted');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId',lst[0].Id);
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        param1.put('version',string.valueOf(lst[0].Version__c));
        FBUtils.saveFormStatus(param1);
        
        param1 = new Map<String,String>();
        param1.put('status','Viewed');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId',lstPD[0].Id);
        param1.put('version','');
        FBUtils.saveFormStatus(param1);
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        param2.put('version','');
        FBUtils.saveFormStatus(param2);
        FBUtils.sendEmailAfterFormSubmission(null);
        
        param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        param2.put('version','2');
        FBUtils.saveFormStatus(param2);
        
        param2 = new Map<String,String>();
        param2.put('status','Viewed');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId','');
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId',lstPD[1].Id);
        param2.put('version','');
        FBUtils.saveFormStatus(param2);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertEquals(4, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
    
    @isTest
    public static void testOnlineManual()
    {
        Test.startTest();
        Contact_Edition_Mapping__c cem = [SELECT Id FROM Contact_Edition_Mapping__c LIMIT 1];
        Form_Allocation__c fa = [SELECT Id FROM Form_Allocation__c WHERE Form_Entry__c='One Per Account' AND Feature_Category__c='Manual' LIMIT 1];
        Form_Data__c fd = [SELECT Id FROM Form_Data__c WHERE Contact_Edition_Mapping__c=:cem.id AND Forms_Permission__r.Form_Allocation__c=:fa.Id LIMIT 1];
        Map<string,string> param1 = new Map<String,String>();
        param1.put('status','Viewed');
        param1.put('qid','');
        param1.put('conEdMapId',cem.id);
        param1.put('formDataId',fd.id);
        param1.put('entryId','');
        param1.put('pageNo','0');
        param1.put('totalPages','0');
        param1.put('boothId','');
        FBUtils.saveFormStatus(param1);

        List<Form_Response_Entry__c> lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id LIMIT 1];
        
        Map<string,string> param2 = new Map<String,String>();
        param2.put('status','Submitted');
        param2.put('qid','');
        param2.put('conEdMapId',cem.id);
        param2.put('formDataId',fd.id);
        param2.put('entryId',lst[0].Id);
        param2.put('pageNo','0');
        param2.put('totalPages','0');
        param2.put('boothId','');
        FBUtils.saveFormStatus(param2);
        FBUtils.subStr('a',2);
        FBUtils.subStr('ab',1);

        lst = [SELECT Id FROM Form_Response_Entry__c WHERE Form_Data__c=:fd.id];
        System.assertEquals(1, lst.Size(), 'All Response Not Captured');
        Test.stopTest();
    }
}