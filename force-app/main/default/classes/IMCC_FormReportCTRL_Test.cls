/**
* Created/Modified By    : Girikon(Arushi)
* Created On             : 8th July, 2022
* @description           : Test class for  IMCC_FormReportCTRL
* Code Coverage          : IMCC_FormReportCTRL(97%)
**/
@isTest
private class IMCC_FormReportCTRL_Test {
    @isTest
    static void createFormRecordTestMethod(){
        Test.startTest();
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            Id accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            Id contactId = contObj[0].Id;
        
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
        
       // System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        //Create Question Library
        Question_Library__c oQesLib= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQesLib;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name',Currency_Symbol__c='$',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQesLib.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c, 'Type Mismatch');
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Description__c='Template 1';        
        insert oQnaire;
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c, 'Category Mismatch');
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name, 'Name Mismatch');
        
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');
        insert oQQuesnaire;
        
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id AND Questionnaire__c=:oQnaire.Id AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Media' AND Question__r.Type__c!='Signature' AND 
                                                              Question__r.Type__c!='Header/Footer' AND Question__c!=null ];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c, 'Question Id Mismatch');
        //setup New Question Record 
        new Question__c(Name='Test',Currency_Symbol__c='$', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                                        Question_Library__c=oQesLib.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');
 		Question_Option__c qo = new Question_Option__c();
        qo.Name='test';
        qo.Name__c='test';
        qo.Question__c=oQue.Id;
        Insert qo;
        
        
        
        //Test Pagination logic
        Form_Pagination__c fp = new Form_Pagination__c();
        fp.Questionnaire__c = oQnaire.id;
        fp.Name='test';
        fp.Total_Pages__c = 4;

        //create pagination
        fp = NewCreateTemplateCtr.createPage(fp);


        //update page
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        editionObj[0].Form_Setting__c = formSettLst[0].id;
        update editionObj;
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(oQnaire.id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        
        List<Form_Response_Entry__c> formRespEntLst2 = IMCC_TestUtilities.createFormRespEntry(formsDataLst[0].id,cemObj.id,1,null);
        System.assertEquals(formRespEntLst2.Size(),1, 'Form Response List size should be 1');
        
        Question_Response__c quesRes = new Question_Response__c();
        quesRes.Answer__c='Text 1';
        quesRes.Question__c=oQue.id;
        quesRes.Questionnaire__c=oQnaire.id; 
        quesRes.Form_Response_Entry__c=formRespEntLst2[0].id; 
        quesRes.Contact_Edition_Mapping__c=cemObj.id; 
        insert quesRes;
        
        String base64Data = 'PGh0bWwgeG1sbnM6bz0idXJuOnNjaGVtYXMtbWljcm9zb2Z0LWNvbTpvZmZpY2U6b2ZmaWNlIiB4bWxuczp4PSJ1cm46'+
                            'c2NoZW1hcy1taWNyb3NvZnQtY29tOm9mZmljZTpleGNlbCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnL1RSL1JFQy1o'+
                            'dG1sNDAiPjxoZWFkPjwhLS1baWYgZ3RlIG1zbyA5XT48eG1sPjx4OkV4Y2VsV29ya2Jvb2s2BPHg6RXhjZWxXb3Jrc2'+
                            'hlZXRzPjx4OkV4Y2VsV29ya3NoZWV0Pjx4Ok5hbWU2BT25saW5lLWZvcm08L3g6TmFtZT48eDpXb3Jrc2hlZXRPcHRp'+
                            'b25zPjx4OkRpc3BsYXlHcmlkbGluZXMvPjwveDpXb3Jrc2hlZXRPcHRpb25zPjwveDpFeGNlbFdvcmtzaGVldD48L3g6'+
                            'RXhjZWxXb3Jrc2hlZXRzPjwveDpFe';
            
        Attachment attObj = new Attachment();        
        attObj.ParentId = editionObjId;
		attObj.Description = 'Online form report';
		attObj.Body = EncodingUtil.base64Decode(base64Data);
		attObj.Name = 'Online form.xls';
		attObj.ContentType = 'application/vnd.ms-excel';    
        Insert attObj;
            
        List<String> idSet = new List<String>();
        for(Question__c q : lstQutn){
            idSet.add(q.Id);
        }
        IMCC_FormReportCTRL.getEditions();
        IMCC_FormReportCTRL.formPicklistOptions(String.valueOf(editionObjId));
        IMCC_FormReportCTRL.getReportData(String.valueOf(editionObjId),String.valueOf(formAllocLst1.Id),idSet,null);
        IMCC_FormReportCTRL.getGirikonForm(String.valueOf(formAllocLst1.Id));
        IMCC_FormReportCTRL.saveChunk(editionObjId,'',base64Data);
        List<string> emailIds = new List<string>{'test1@test.com','test2@test.com'};
        IMCC_FormReportCTRL.sendMail(emailIds,'Test Subject','Test Body',attObj.Id);
        
        Test.stopTest();
    }

    @isTest
    static void createFormRecordTestMethod2(){
        Test.startTest();
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
            Id accId = accObj[0].Id;
            List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
            Id contactId = contObj[0].Id;
        
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
        
       // System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        //Create Question Library
        Question_Library__c oQesLib= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQesLib;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name',Currency_Symbol__c='$',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQesLib.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c, 'Type Mismatch');
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Description__c='Template 1';        
        insert oQnaire;
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c, 'Category Mismatch');
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name, 'Name Mismatch');
        
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');
        insert oQQuesnaire;
        
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id AND Questionnaire__c=:oQnaire.Id AND is_Delete__c=false AND Question__r.Type__c!='Information' AND Question__r.Type__c!='Media' AND Question__r.Type__c!='Signature' AND 
                                                              Question__r.Type__c!='Header/Footer' AND Question__c!=null ];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c, 'Question Id Mismatch');
        //setup New Question Record 
        new Question__c(Name='Test',Currency_Symbol__c='$', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1',Question_Library__c=oQesLib.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');

 		Question_Option__c qo = new Question_Option__c();
        qo.Name='test';
        qo.Name__c='test';
        qo.Question__c=oQue.Id;
        Insert qo;
        
        
        
        //Test Pagination logic
        Form_Pagination__c fp = new Form_Pagination__c();
        fp.Questionnaire__c = oQnaire.id;
        fp.Name='test';
        fp.Total_Pages__c = 4;

        //create pagination
        fp = NewCreateTemplateCtr.createPage(fp);


        //update page
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        editionObj[0].Form_Setting__c = formSettLst[0].id;
        update editionObj;
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(oQnaire.id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        
        List<Form_Response_Entry__c> formRespEntLst2 = IMCC_TestUtilities.createFormRespEntry(formsDataLst[0].id,cemObj.id,1,null);
        System.assertEquals(formRespEntLst2.Size(),1, 'Form Response List size should be 1');
        
        Question_Response__c quesRes = new Question_Response__c();
        quesRes.Answer__c='Text 1';
        quesRes.Question__c=oQue.id;
        quesRes.Questionnaire__c=oQnaire.id; 
        quesRes.Form_Response_Entry__c=formRespEntLst2[0].id; 
        quesRes.Contact_Edition_Mapping__c=cemObj.id; 
        insert quesRes;
        
        String base64Data = 'PGh0bWwgeG1sbnM6bz0idXJuOnNjaGVtYXMtbWljcm9zb2Z0LWNvbTpvZmZpY2U6b2ZmaWNlIiB4bWxuczp4PSJ1cm46'+
                            'c2NoZW1hcy1taWNyb3NvZnQtY29tOm9mZmljZTpleGNlbCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnL1RSL1JFQy1o'+
                            'dG1sNDAiPjxoZWFkPjwhLS1baWYgZ3RlIG1zbyA5XT48eG1sPjx4OkV4Y2VsV29ya2Jvb2s2BPHg6RXhjZWxXb3Jrc2'+
                            'hlZXRzPjx4OkV4Y2VsV29ya3NoZWV0Pjx4Ok5hbWU2BT25saW5lLWZvcm08L3g6TmFtZT48eDpXb3Jrc2hlZXRPcHRp'+
                            'b25zPjx4OkRpc3BsYXlHcmlkbGluZXMvPjwveDpXb3Jrc2hlZXRPcHRpb25zPjwveDpFeGNlbFdvcmtzaGVldD48L3g6'+
                            'RXhjZWxXb3Jrc2hlZXRzPjwveDpFe';
            
        Attachment attObj = new Attachment();        
        attObj.ParentId = editionObjId;
		attObj.Description = 'Online form report';
		attObj.Body = EncodingUtil.base64Decode(base64Data);
		attObj.Name = 'Online form.xls';
		attObj.ContentType = 'application/vnd.ms-excel';    
        Insert attObj;
            
        List<String> idSet = new List<String>();
        for(Question__c q : lstQutn){
            idSet.add(q.Id);
        }
        IMCC_FormReportCTRL.getEditions();
        IMCC_FormReportCTRL.formPicklistOptions(String.valueOf(editionObjId));
        IMCC_FormReportCTRL.getReportData(String.valueOf(editionObjId),String.valueOf(formAllocLst1.Id),idSet,null);
        IMCC_FormReportCTRL.getFormQuestions(String.valueOf(formAllocLst1.Id));
        IMCC_FormReportCTRL.getGirikonForm(String.valueOf(formAllocLst1.Id));
        IMCC_FormReportCTRL.saveChunk(editionObjId,attObj.Id,base64Data);
        List<string> emailIds = new List<string>{'test1@test.com','test2@test.com'};
        IMCC_FormReportCTRL.sendMail(emailIds,'Test Subject','Test Body',attObj.Id);
        
        Test.stopTest();
    }
}