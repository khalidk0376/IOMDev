/**
* Created/Modified By    : Girikon(Aishwarya Kumar )
* Created On             : 14-04-2022
* Apex Class             : Trig_UpdateStatusOnFormData_Handler(79%)
* Code Coverage          : 86%
* Modification Log-----  : [Arushi IMCC-4186 5 Aug 2022],[Arushi IMCC-4780 21 Nov 2022]
* Modified by 
**/

@isTest
public class imcc_Trig_UpdateStatusOnFormData_Test{
    @TestSetUp
    static void testUserData(){
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'Administrator' Limit 1];
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
        adminUser.UserRoleId = userrole.Id;
        update adminUser;

        User userObj;
        Id contactId;
        Id accId;
        System.runAs(adminUser)
        {
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
        IMCC_TestUtilities.createEventTabs(eveSettingObjId,1,10,null,'Standard','Forms',null);
        
        System.assertEquals(editionObj.Size(),1, 'Edition List size should be 1');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 1);
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(1);
        System.assertEquals(formSettLst.Size(),1, 'Form Setting List size should be 1');
        editionObj[0].Form_Setting__c = formSettLst[0].id;
        update editionObj;
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Description__c='Template 1';        
        insert oQnaire;
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(oQnaire.id,formSettLst[0].id,'Mandatory');
        IMCC_TestUtilities.createPurchaseData(cemObj.Id,accId,1);
        IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,1,'Exhibitor');
        
        List<Form_Data__c> formsDataLst = [SELECT Id,Allowed_Responses__c FROM Form_Data__c];
        Integer freResponses = Integer.valueOf(formsDataLst[0].Allowed_Responses__c);
        List<Form_Response_Entry__c> formRespEntLst2 = IMCC_TestUtilities.createFormRespEntry2(formsDataLst[0].id,cemObj.id,freResponses,null,editionObjId,accId,adminUser.Id);
        System.assertEquals(formRespEntLst2.Size(),freResponses, 'Form Response List size should be acc to freResponses');
        
        List<Email_Templates__c> listEmailTemp = IMCC_TestUtilities.createEmailTemplate();
        Map<String,Email_Template_Types_Mapping__mdt> mapETTTM = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Forms');
        List<String> codes = new List<String>();
        List<String> listEmailTypes = new List<String>();
        for(String s : mapETTTM.keySet()){
            codes.add(mapETTTM.get(s).Email_Template_Code__c);
            listEmailTypes.add('Email:'+s);
        }
        IMCC_TestUtilities.createEditionEmailTemplate(editionObjId,listEmailTemp[0].Id,codes);

        List<Question__c> questList = IMCC_TestUtilities.createQuestions();
        IMCC_TestUtilities.createQuestionOptions(questList[1].Id);
        List<Question_Response__c> lstQRs = new List<Question_Response__c>();
        Question_Response__c questResponse = IMCC_TestUtilities.createQuestionResponse(oQnaire.id,questList[1].Id,userObj.Id,'TestAnswer');
        Question_Response__c questResponse1 = IMCC_TestUtilities.createQuestionResponse(oQnaire.id,questList[1].Id,userObj.Id,'Picklist1');
        Question_Response__c questResponse2 = IMCC_TestUtilities.createQuestionResponse2(oQnaire.id,questList[1].Id,userObj.Id,'Picklist1',formRespEntLst2[0].id);
        lstQRs.add(questResponse);
        lstQRs.add(questResponse1);
        lstQRs.add(questResponse2);
        
        Attachment attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=questResponse.id;
        insert attach;
        
        attach=new Attachment();   	
    	attach.Name='Unit Test Attachment';
    	attach.body=bodyBlob;
        attach.parentId=questResponse2.id;
        insert attach;
        
        ContentVersion contentVersion = new ContentVersion(
          Title = 'Penguins',
          PathOnClient = 'Penguins.jpg',
          VersionData = Blob.valueOf('Test Content'),
          IsMajorVersion = true
        );
		insert contentVersion;
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];

        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = formRespEntLst2[0].id;
        cdl.ContentDocumentId = documents[0].Id;
		cdl.shareType = 'V';
		insert cdl;
        
        update new Form_Response_Entry__c(Id=formRespEntLst2[0].id,Content_Version__c=contentVersion.Id);
    }
    
    @isTest
    static void createFormRecordTestMethod(){
        Map<String,Email_Template_Types_Mapping__mdt> mapETTTM = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Forms');
        List<String> listEmailTypes = new List<String>();
        for(String s : mapETTTM.keySet()){
            listEmailTypes.add('Email:'+s);
        }
        
        Test.startTest();
        String module ='Form';
        Form_Response_Entry__c fre2 = [SELECT Id,Event_Name__c,Event_Name__r.Name,Event_Name__r.Operations_Team__c,Event_Name__r.Event_Setting__c,Response_Status__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__c,Approval_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,
                                       Contact_Edition_Mapping__r.Edition__r.Name,Content_Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Entry__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Feature_Category__c,
                                       Form_Name__c,Form_Deadline__c,Submission_Date__c,Purchase_Data__c,Purchase_Data__r.Booth_Number__c,Purchase_Data__r.Booth_Dimension__c,
                                       Purchase_Data__r.Quantity_Area__c,Event_Name__r.Edition_Code__c,Company_Name__c,Company_Name__r.Name,Form_Type__c,Rejection_Reason__c,
                                       Contact_Edition_Mapping__r.Contact__c,User__c,User__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Email_To__c, 
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_individual_forms__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c
                                       FROM Form_Response_Entry__c LIMIT 1];

        String emailType ='Email:Form In Review';
        
        Trig_UpdateStatusOnFormData_Handler.processFormResponseEmails(fre2,listEmailTypes);
        fre2.Approval_Status__c ='Approved';
        update fre2;
        System.assertEquals('Approved', fre2.Approval_Status__c, 'Status Mismatch');
        fre2.Approval_Status__c ='Rejected';
        update fre2;
        fre2.Approval_Status__c ='In Review';
        update fre2;
        Trig_UpdateStatusOnFormData_Handler.getEmailTemplateKeyWordsByModuleALL(module);
        Trig_UpdateStatusOnFormData_Handler.getEmailIds(fre2);
        List<Question_Response__c> lstQRs = [SELECT Id,Questionnaire__c,Question__c,User__c,Answer__c,Answer_Long__c,Question__r.Label__c,Question__r.Type__c FROM Question_Response__c];
        Trig_UpdateStatusOnFormData_Handler.getTableEmailBody(lstQRs,emailType);
        fre2.Status__c='Resubmitted';
        
        update fre2;
        delete lstQRs;
        delete fre2;
        Test.stopTest();
    }
    
    @isTest
    static void createFormRecordTestMethod2(){
        Form_Allocation__c formAllocLst1 = [Select Id From Form_Allocation__c];
        formAllocLst1.Form_Type__c='PDF';
        update formAllocLst1;
        Map<String,Email_Template_Types_Mapping__mdt> mapETTTM = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Forms');
        List<String> listEmailTypes = new List<String>();
        for(String s : mapETTTM.keySet()){
            listEmailTypes.add('Email:'+s);
        }
        
        Test.startTest();
        String module ='Form';
        Form_Response_Entry__c fre2 = [SELECT Id,Event_Name__c,Event_Name__r.Name,Event_Name__r.Operations_Team__c,Event_Name__r.Event_Setting__c,Response_Status__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__c,Approval_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,
                                       Contact_Edition_Mapping__r.Edition__r.Name,Content_Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Entry__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Feature_Category__c,
                                       Form_Name__c,Form_Deadline__c,Submission_Date__c,Purchase_Data__c,Purchase_Data__r.Booth_Number__c,Purchase_Data__r.Booth_Dimension__c,
                                       Purchase_Data__r.Quantity_Area__c,Event_Name__r.Edition_Code__c,Company_Name__c,Company_Name__r.Name,Form_Type__c,Rejection_Reason__c,
                                       Contact_Edition_Mapping__r.Contact__c,User__c,User__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Email_To__c, 
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_individual_forms__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c
                                       FROM Form_Response_Entry__c LIMIT 1];

        String emailType ='Email:Form In Review';
        
        Trig_UpdateStatusOnFormData_Handler.processFormResponseEmails(fre2,listEmailTypes);
        fre2.Approval_Status__c ='Approved';
        update fre2;
        System.assertEquals('Approved', fre2.Approval_Status__c, 'Status Mismatch');
        fre2.Approval_Status__c ='Rejected';
        update fre2;
        fre2.Approval_Status__c ='In Review';
        update fre2;
        Trig_UpdateStatusOnFormData_Handler.getEmailTemplateKeyWordsByModuleALL(module);
        Trig_UpdateStatusOnFormData_Handler.getEmailIds(fre2);
        List<Question_Response__c> lstQRs = [SELECT Id,Questionnaire__c,Question__c,User__c,Answer__c,Answer_Long__c,Question__r.Label__c,Question__r.Type__c FROM Question_Response__c];
        Trig_UpdateStatusOnFormData_Handler.getTableEmailBody(lstQRs,emailType);
        fre2.Status__c='Resubmitted';
        
        update fre2;
        delete lstQRs;
        delete fre2;
        Test.stopTest();
    }
    
    @isTest
    static void createFormRecordTestMethod3(){

        User userObj1 = [SELECT ID FROM User WHERE Email='davidjones@test.com'];
        
        Form_Allocation__c formAllocLst1 = [Select Id,Send_Response_to_Customer__c From Form_Allocation__c];
        formAllocLst1.Form_Type__c='Online';
        formAllocLst1.Send_Response_to_Customer__c=True;
        update formAllocLst1;
        Map<String,Email_Template_Types_Mapping__mdt> mapETTTM = Trig_UpdateStatusOnFormData_Handler.getEmailTemplateTypesByModule('Forms');
        List<String> listEmailTypes = new List<String>();
        for(String s : mapETTTM.keySet()){
            listEmailTypes.add('Email:'+s);
        }
        
        Test.startTest();
        String module ='Form';
        Form_Response_Entry__c fre2 = [SELECT Id,Receive_an_Email_Copy__c,Additional_Emails__c,Last_Modified_By__c FROM Form_Response_Entry__c LIMIT 1];
        
        fre2.Receive_an_Email_Copy__c =True;
        fre2.Additional_Emails__c ='abc@test.com';
        fre2.Last_Modified_By__c = userObj1.Id;
        update fre2;
        
        Form_Response_Entry__c updatedFRE = [SELECT Id,Event_Name__c,Event_Name__r.Name,Event_Name__r.Operations_Team__c,Event_Name__r.Event_Setting__c,Response_Status__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__c,Approval_Status__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Approval_Required__c,
                                       Contact_Edition_Mapping__r.Edition__r.Name,Content_Version__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Entry__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Form_Type__c,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Feature_Category__c,
                                       Form_Name__c,Form_Deadline__c,Submission_Date__c,Purchase_Data__c,Purchase_Data__r.Booth_Number__c,Purchase_Data__r.Booth_Dimension__c,
                                       Purchase_Data__r.Quantity_Area__c,Event_Name__r.Edition_Code__c,Company_Name__c,Company_Name__r.Name,Form_Type__c,Rejection_Reason__c,
                                       Contact_Edition_Mapping__r.Contact__c,User__c,User__r.Name,Form_Data__r.Forms_Permission__r.Form_Allocation__r.Email_To__c, 
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_individual_forms__c,Receive_an_Email_Copy__c,Additional_Emails__c,
                                       Form_Data__r.Forms_Permission__r.Form_Allocation__r.Send_Response_to_Customer__c,Last_Modified_By__c FROM Form_Response_Entry__c WHERE Id =: fre2.Id];
                                       
        String emailType ='Email:Form Copy';
        
        Trig_UpdateStatusOnFormData_Handler.processFormResponseEmails(updatedFRE,listEmailTypes);
        updatedFRE.Approval_Status__c ='Approved';
        update updatedFRE;
        System.assertEquals('Approved', updatedFRE.Approval_Status__c, 'Status Mismatch');
        updatedFRE.Approval_Status__c ='Rejected';
        update updatedFRE;
        updatedFRE.Approval_Status__c ='In Review';
        update updatedFRE;
        Trig_UpdateStatusOnFormData_Handler.getEmailTemplateKeyWordsByModuleALL(module);
        Trig_UpdateStatusOnFormData_Handler.getEmailIds(updatedFRE);
        List<Question_Response__c> lstQRs = [SELECT Id,Questionnaire__c,Question__c,User__c,Answer__c,Answer_Long__c,Question__r.Label__c,Question__r.Type__c FROM Question_Response__c];
        Trig_UpdateStatusOnFormData_Handler.getTableEmailBody(lstQRs,emailType);
        updatedFRE.Status__c='Resubmitted';
        
        update updatedFRE;
        delete lstQRs;
        delete updatedFRE;
        Test.stopTest();
    }
}