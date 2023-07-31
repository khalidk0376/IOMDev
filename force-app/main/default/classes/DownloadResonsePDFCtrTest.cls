/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Test Class
* Test Class             : DownloadResonsePDFCtr
* Modification Log
* Modified by            : Girikon(Mukesh)
**/
@IsTest
public class DownloadResonsePDFCtrTest {
	
    @IsTest
    private static void test1()
    {
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
        
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;

        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Related_To_Column__c='col1',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='Picklist',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        
        //create Question option record.
        Question_Option__c qOption = new Question_Option__c(Name ='Test',Name__c='test',Question__c=oQue.id);
        insert qOption;
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Is_Customize_Buttons__c=false;
        oQnaire.isMerge__c=true;
        oQnaire.Button_Alignment__c='Top-Bottom';
        oQnaire.Description__c='Template 1';
        oQnaire.NetworkId__c='testid';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        insert oQnaire;
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1,Question__c=oQue.Id);
        insert oQQuesnaireWithOutQstn;
        
        Question_Response__c qr = new Question_Response__c();        
        qr.Answer__c=qOption.Id;
        qr.Answer_Long__c=qOption.Id;
        qr.User__c=UserInfo.getUserId();
        qr.Question_Questionnaire__c=oQQuesnaireWithOutQstn.Id;
        qr.Questionnaire__c=oQnaire.id;        
        qr.Question__c=oQue.Id;
        qr.Comment__c='test comment';
        qr.Contact_Edition_Mapping__c=cemObj.Id;
        qr.Form_Response_Entry__c = formRespEntLst1[0].Id;
        insert qr;
        
        //Create Question Record 
        Question__c oQue2 = new Question__c(Name='Test',Related_To_Column__c='col1',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='Checkbox',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue2;
        
        Question_Questionnaire__c oQQuesnaireWithOutQstn2= new Question_Questionnaire__c(Allow_Attachments__c=oQue2.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1,Question__c=oQue.Id);
        insert oQQuesnaireWithOutQstn2;
        
        Question_Response__c qr2 = new Question_Response__c();        
        qr2.Answer__c='true';
        qr2.Answer_Long__c='true';
        qr2.User__c=UserInfo.getUserId();
        qr2.Question_Questionnaire__c=oQQuesnaireWithOutQstn2.Id;
        qr2.Questionnaire__c=oQnaire.id;        
        qr2.Question__c=oQue2.Id;
        qr2.Comment__c='test comment';
        qr2.Contact_Edition_Mapping__c=cemObj.Id;
        qr2.Form_Response_Entry__c = formRespEntLst1[0].Id;
        insert qr2;
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('qnaireId',oQnaire.Id);
        ApexPages.currentPage().getParameters().put('e',formRespEntLst1[0].Id);
        ApexPages.currentPage().getParameters().put('ceid',cemObj.Id);
            
        DownloadResonsePDFCtr controllerObj = new DownloadResonsePDFCtr();
        controllerObj.getQuestnsForQuesGroup();
        controllerObj.getTemplateRecord();
        List<Questionnaire__c> qlist = [Select id from Questionnaire__c where id=:oQnaire.Id];
        System.assertEquals(1, qlist.size());
        Test.stopTest();
    }
}