/**
* Created/Modified By: Girikon(Mukesh Gupta)     
* @description  :      This class covers the code coverage of the class FormPreviewController
* Methods:             createQniareRecordTestMethod,testSaveResponse
* Apex Class:          FormPreviewController
**/

@IsTest
private with sharing class FormPreviewController_Test {
    @isTest
    static void createQniareRecordTestMethod(){
        Test.startTest();
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c,'Question Type did not match');
        //create Question option record.
        Question_Option__c qOption = new Question_Option__c(Name ='Test',Name__c='test',Question__c=oQue.id);
        insert qOption; 
        List<Question_Option__c> lstqOption = [Select id from Question_Option__c where Question__c=:oQue.id];
        System.assertNotEquals(lstqOption, null,'list question option is null');
        
        //Question__c oQue2 = new Question__c(Name='Test', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
        //    Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,Help_Text_Required__c=true);
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Form';
        oQnaire.Is_Customize_Buttons__c=false;
        oQnaire.isMerge__c=true;
        oQnaire.Button_Alignment__c='Top-Bottom';
        oQnaire.Description__c='Template 1';
        oQnaire.NetworkId__c='testid';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        insert oQnaire;
        
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c,'Questionnaire Category did not match');
        
        //Create Question Group record
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name,'Question group did not match');
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                                        Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1);
        insert oQQuesnaireWithOutQstn;
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question__c=oQue.id,Question_Order__c=1);
        insert oQQuesnaire;
        
        //Create Questionnaire dynamic logic Record
        Questionnaire_Dynamic_Logic__c questnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=oQQuesnaire.id,
                                                                                                 Question_Group__c =oQG.id,
                                                                                                 Question_Option__c=qOption.id,
                                                                                                 Show_Question_Questionnaire__c=oQQuesnaireWithOutQstn.id);
        insert questnDynLogicInsert;    
        
        
        FormPreviewController.getAllQuestnGrpNameForQuesnnaire(oQnaire.id);
        FormPreviewController.getQuestnsForAllQuesGroup(oQnaire.id,oQG.id);                        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveResponse()
    {
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        System.assertNotEquals(oQue.Id, null,'Failed to insert Question');
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Form';
        oQnaire.Description__c='Template 1';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        oQnaire.Is_Customize_Buttons__c=false;
        oQnaire.isMerge__c=true;
        oQnaire.Button_Alignment__c='Top-Bottom';
        oQnaire.NetworkId__c='asdhjasd';
        insert oQnaire;
        
        //String mockData2 = '{"datas":{"qid":"'+oQnaire.Id+'","alignment":"slds-float_right slds-var-p-around_small","nextButonLabel":"Next Questions","prevButonLabel":"Previous Questions","submitButonLabel":"Submit","nextButonColor":"#0b7477_#0b7477_#FFFFFF","prevButonColor":"#00aea9_#00aea9_#FFFFFF","submitButonColor":"#2196F3_#2196F3_#FFFFFF","isCutomize":true,"buttonPosition":"Bottom"}}';
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire = new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                              Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question__c=oQue.id,Question_Order__c=1);
        insert oQQuesnaire;
        
        String questionId=oQue.Id;
        String questionaryId=oQQuesnaire.Id;
        String mockData = '[{"Id":"'+questionId+'","Label":"test branch 2","Step_Size":0,"Is_Allow_Branching":true,"Allow_Currency":false,"Type":"Picklist","Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Required":false,"Question_Questionnairesr":[{"Question":"'+questionId+'","Id":"'+questionaryId+'","Allow_Currency":false,"Max_Char_Length":0,"Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Related_To_Column":"col1","Required":false,"Step_Size":0,"Is_Allow_Branching":true,"Maximum_value":0,"Question_Order":12,"Questionr":{"Label":"test branch 2","Type":"Picklist","Allow_Currency":false,"Id":"'+questionId+'"},"responseValue1":"a026A00000GSqTxQAL","responseValue2":"","comment":"","attachment":"Alok Anibha Signature.png","branchingQuestnQuetnnaire":[{"Question":"'+questionId+'","Id":"'+questionaryId+'","Allow_Currency":false,"Max_Char_Length":0,"Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Related_To_Column":"col1","Required":false,"Step_Size":0,"Default_Value":0,"Is_Allow_Branching":false,"Maximum_value":0,"Minimum_Value":0,"Question_Order":14,"Questionr":{"Label":"test media under branching","Type":"Media","Allow_Currency":false,"Id":"'+questionId+'"},"responseValue1":"null","responseValue2":"","comment":"","attachment":"amp-validation-error.png","branchingQuestnQuetnnaire":[],"QuestionOptions":[],"isShowQuestion":true,"MainQuestionId":"'+questionId+'"}]}],"Question_Optionsr":[{"Question":"'+questionId+'","Id":"a026A00000GSqTxQAL","Name":"Option 1","label":"Option 1","value":"Option 1"},{"Question":"'+questionId+'","Id":"a026A00000GSqTyQAL","Name":"Option 2","label":"Option 2","value":"Option 2"}]}]';
        
        //Test Pagination logic
        Form_Pagination__c fp = new Form_Pagination__c();
        fp.Questionnaire__c = oQnaire.id;
        fp.Name='test';
        fp.Total_Pages__c = 4;
        
        //create pagination
        fp = NewCreateTemplateCtr.createPage(fp);
        
        //update pagination
        fp.Total_Pages__c=5;
        fp = NewCreateTemplateCtr.updatePaginationAction(fp);
        
        fp.Total_Pages__c=4;
        fp = NewCreateTemplateCtr.updatePaginationAction(fp);
        
        NewCreateTemplateCtr.updatePaginationAction(fp);
        
        //update page
        Form_Page__c formPage = fp.Form_Pages__r[0];
        NewCreateTemplateCtr.updateSelectedPage(formPage,oQG.id);
        
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
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        
        List<Event_Tabs__c> evntTabsLst = IMCC_TestUtilities.createEventTabs(eveSettingObjId,5,10,null,'Standard','Forms',null);
        System.assertEquals(evntTabsLst.Size(),5, 'evntTabsLst size should be 5');
        
        List<Tab_User_Type__c> tabUserLst = IMCC_TestUtilities.createTabUserType(evntTabsLst[0].id,5,'Exhibitor');
        System.assertEquals(tabUserLst.Size(),5, 'Tab User List size should be 5'); 
        
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocation1('Form','Online',girikonFormLst[0].id,formSettLst[0].id,'One Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> fdList = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst[0].Id,1);
        
        Form_Response_Entry__c fsEntry = new Form_Response_Entry__c();
        fsEntry.Entry_Number__c = 1;
        fsEntry.Status__c = 'Submitted';
        fsEntry.Form_Data__c = fdList[0].id;
        insert fsEntry;
        FormPreviewController.getFormResponseEntry(fsEntry.id);
        Question_Response__c qr = new Question_Response__c(Form_Response_Entry__c = fsEntry.id,Question__c = oQue.id,Questionnaire__c=oQnaire.id);
        insert qr;
        //Get pagination
        FormPreviewController.getPage(oQnaire.id);
        
        //set form status
        String param = '{"entryId":"'+fsEntry.Id+'","status":"Submitted","formDataId":"'+fdList[0].Id+'","conEdMapId":"'+cemObj.Id+'","pageId":"'+formPage.Id+'","currentPageNo":"1","totalPages":"4","version":"2"}';
        String param1 = '{"entryId":"'+fsEntry.Id+'","currentPageNo":"1","totalPages":"4","conEdMapId":"'+cemObj.Id+'"}';
        FormPreviewController.setFormStatus(oQnaire.id,param);
        
        FormPreviewController.saveQuestionResponse(mockData, oQnaire.Id,param);
        FormPreviewController.saveQuestionResponseAsPDF(oQnaire.id,cemObj.Id,fsEntry.Id,fdList[0].id);
        FormPreviewController.saveQuestionResponseAsPDF(oQnaire.id,cemObj.Id,fsEntry.Id,fdList[0].id);
        FormPreviewController.clearQuestionResponse(oQnaire.Id,param1,oQG.id);
        //FormPreviewController.saveQuestionResponse(mockData, oQnaire.Id,param);
        FormPreviewController.getQuestionResponses(oQnaire.Id, oQG.Id,cemObj.Id,'1',false);                 
        
        FBUtils.sendEmailAfterFormSubmission(oQnaire.Id);
        FormPreviewController.getRelatedBooths(null);
        FormPreviewController.getFormEntries(fdList[0].Id);
        FormPreviewController.deleteFormRespEntry(fsEntry.Id);
    }

    public  @IsTest
    static void testException(){
        
        Test.startTest();
        FormPreviewController.deleteFormRespEntry(null);
        try{ FormPreviewController.getFormPreviewDetail(null,null);}
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.setFormStatus(null,null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.getQuestnsForAllQuesGroup(null,null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.getRelatedBooths(null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.clearQuestionResponse(null,null,null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.saveQuestionResponseAsPDF(null,null,null,null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
        try{
            FormPreviewController.getFormResponseEntry(null);
        }
        catch(Exception e){
           System.assertEquals('System.AuraHandledException',e.getTypeName(),'Exception is different');
        }
       
        Test.stopTest();
        
    }
    
    @isTest
    static void testSaveResponse2()
    {
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        System.assertNotEquals(oQue.Id, null,'Failed to insert Question');
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Form';
        oQnaire.Description__c='Template 1';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        oQnaire.Is_Customize_Buttons__c=false;
        oQnaire.isMerge__c=true;
        oQnaire.Button_Alignment__c='Top-Bottom';
        oQnaire.NetworkId__c='asdhjasd';
        insert oQnaire;
        
        //String mockData2 = '{"datas":{"qid":"'+oQnaire.Id+'","alignment":"slds-float_right slds-var-p-around_small","nextButonLabel":"Next Questions","prevButonLabel":"Previous Questions","submitButonLabel":"Submit","nextButonColor":"#0b7477_#0b7477_#FFFFFF","prevButonColor":"#00aea9_#00aea9_#FFFFFF","submitButonColor":"#2196F3_#2196F3_#FFFFFF","isCutomize":true,"buttonPosition":"Bottom"}}';
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire = new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                              Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question__c=oQue.id,Question_Order__c=1);
        insert oQQuesnaire;
        
        String questionId=oQue.Id;
        String questionaryId=oQQuesnaire.Id;
        String mockData = '[{"Id":"'+questionId+'","Label":"test branch 2","Step_Size":0,"Is_Allow_Branching":true,"Allow_Currency":false,"Type":"Picklist","Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Required":false,"Question_Questionnairesr":[{"Question":"'+questionId+'","Id":"'+questionaryId+'","Allow_Currency":false,"Max_Char_Length":0,"Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Related_To_Column":"col1","Required":false,"Step_Size":0,"Is_Allow_Branching":true,"Maximum_value":0,"Question_Order":12,"Questionr":{"Label":"test branch 2","Type":"Picklist","Allow_Currency":false,"Id":"'+questionId+'"},"responseValue1":"a026A00000GSqTxQAL","responseValue2":"","comment":"","attachment":"Alok Anibha Signature.png","branchingQuestnQuetnnaire":[{"Question":"'+questionId+'","Id":"'+questionaryId+'","Allow_Currency":false,"Max_Char_Length":0,"Allow_Attachments":false,"Allow_Comment":false,"Help_Text_Required":false,"Related_To_Column":"col1","Required":false,"Step_Size":0,"Default_Value":0,"Is_Allow_Branching":false,"Maximum_value":0,"Minimum_Value":0,"Question_Order":14,"Questionr":{"Label":"test media under branching","Type":"Media","Allow_Currency":false,"Id":"'+questionId+'"},"responseValue1":"null","responseValue2":"","comment":"","attachment":"amp-validation-error.png","branchingQuestnQuetnnaire":[],"QuestionOptions":[],"isShowQuestion":true,"MainQuestionId":"'+questionId+'"}]}],"Question_Optionsr":[{"Question":"'+questionId+'","Id":"a026A00000GSqTxQAL","Name":"Option 1","label":"Option 1","value":"Option 1"},{"Question":"'+questionId+'","Id":"a026A00000GSqTyQAL","Name":"Option 2","label":"Option 2","value":"Option 2"}]}]';
        
        //Test Pagination logic
        Form_Pagination__c fp = new Form_Pagination__c();
        fp.Questionnaire__c = oQnaire.id;
        fp.Name='test';
        fp.Total_Pages__c = 4;
        
        //create pagination
        fp = NewCreateTemplateCtr.createPage(fp);
        
        //update pagination
        fp.Total_Pages__c=5;
        fp = NewCreateTemplateCtr.updatePaginationAction(fp);
        
        fp.Total_Pages__c=4;
        fp = NewCreateTemplateCtr.updatePaginationAction(fp);
        
        NewCreateTemplateCtr.updatePaginationAction(fp);
        
        //update page
        Form_Page__c formPage = fp.Form_Pages__r[0];
        NewCreateTemplateCtr.updateSelectedPage(formPage,oQG.id);
        
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
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        //Get pagination
        FormPreviewController.getPage(oQnaire.id);
        List<Questionnaire__c> girikonFormLst = IMCC_TestUtilities.createGirikonForm(5);
        System.assertEquals(girikonFormLst.Size(),5, 'Girikon Form List size should be 5');
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocation1('Form','Online',girikonFormLst[0].id,formSettLst[0].id,'One Per Account');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> fdList = IMCC_TestUtilities.createFormData(cemObj.Id,formsPermLst[0].Id,1);
        Form_Response_Entry__c fsEntry = new Form_Response_Entry__c();
        fsEntry.Entry_Number__c = 1;
        fsEntry.Form_Data__c = fdList[0].id;
        insert fsEntry;
        FormPreviewController.getFormResponseEntry(fsEntry.id);
        Question_Response__c qr = new Question_Response__c(Form_Response_Entry__c = fsEntry.id,Question__c = oQue.id,Questionnaire__c=oQnaire.id);
        insert qr;
        //set form status
        //String param = '{"status":"Viewed","pageId":"'+formPage.Id+'","currentPageNo":"1","totalPages":"4"}';
        String param = '{"entryId":"'+fsEntry.Id+'","status":"Viewed","formDataId":"'+fdList[0].Id+'","conEdMapId":"'+cemObj.Id+'","pageId":"'+formPage.Id+'","currentPageNo":"1","totalPages":"4","check":"0","version":"1"}';
        FormPreviewController.setFormStatus(oQnaire.id,param);
        
        FormPreviewController.saveQuestionResponse(mockData, oQnaire.Id,param);
        FormPreviewController.getQuestionResponses(oQnaire.Id, oQG.Id,cemObj.Id,'1',false);                 
        FBUtils.sendEmailAfterFormSubmission(oQnaire.Id);
    }       
}