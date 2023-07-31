@IsTest
public class FileUploadCtrlTest {
    
    @IsTest
    private static void test1()
    {
        Test.startTest(); 
        //Create Question Library
        Question_Library__c oQL = FBUtils.questionLibrary();
        
        //Create Question Record 
        Question__c oQue = FBUtils.createQst(oQL.Id);
        
        //create Question option record.
        Question_Option__c qOption = new Question_Option__c(Name ='Test',Name__c='test',Question__c=oQue.id);
        insert qOption;
        
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
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                                        Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1);
        insert oQQuesnaireWithOutQstn;
        
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
        
        //System.assertEquals(editionObj[0].Edition_Code__c,'TEV21', 'Event Code');
        
        Contact_Edition_Mapping__c cemObj = IMCC_TestUtilities.createContactEditionMapping(contactId,accId,editionObjId);
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(oQnaire.id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        
        Purchase_Data__c prchseData = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId, accId);
        
        List<Form_Response_Entry__c> formRespEntry = IMCC_TestUtilities.createFormRespEntry(formsDataLst[0].id,cemObj.id,1,prchseData.id);
        System.assertEquals(formRespEntry.Size(),1, 'Form Response List size should be 1');
        
        String attId = FileUploadCtrl.saveChunk(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id, oQQuesnaireWithOutQstn.Id,'test.png', EncodingUtil.urlEncode('base64Data','UTF-8'), 'image/png', '', 'fileDescription','1',true);
        FileUploadCtrl.saveChunk(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id,oQQuesnaireWithOutQstn.Id, 'test.png', EncodingUtil.urlEncode('base64Data','UTF-8'), 'image/png', attId, 'fileDescription','1',true);
        System.assertNotEquals('', attId);
        
        String resId = FileUploadCtrl.getReponseId(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id, oQQuesnaireWithOutQstn.Id,'test.png','1',true);
        FileUploadCtrl.getReponseId(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id,oQQuesnaireWithOutQstn.Id, 'test.png','1',true);
        System.assertNotEquals('', resId,'resid should not be blank');
        
        FileUploadCtrl.getAllAttchments(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id, oQQuesnaireWithOutQstn.Id);
        Test.stopTest();
    }
    @IsTest
    private static void test2()
    {
        Test.startTest(); 
        //Create Question Library
        Question_Library__c oQL = FBUtils.questionLibrary();
        
        //Create Question Record 
        Question__c oQue = FBUtils.createQst(oQL.Id);
        
        //create Question option record.
        Question_Option__c qOption = new Question_Option__c(Name ='Test',Name__c='test',Question__c=oQue.id);
        insert qOption;
        
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
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                                        Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1);
        insert oQQuesnaireWithOutQstn;
        
        List<Account> accObj  = IMCC_TestUtilities.createAccount(250);
        Id accId = accObj[0].Id;
        List<Contact> contObj = IMCC_TestUtilities.createContact(accId, 250);
        Id contactId = contObj[0].Id;
        user userObj = IMCC_TestUtilities.createCommunityUser(contactId);
        System.assertEquals(userObj.ContactID,contactId, 'Same contact');
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
        List<Edition_Websites__c> edwebObj = IMCC_TestUtilities.createEditionWebsites(editionObjId, 250);
        
        List<Form_Setting__c> formSettLst = IMCC_TestUtilities.createFormSettings(5);
        System.assertEquals(formSettLst.Size(),5, 'Form Setting List size should be 5');
        
        Form_Allocation__c formAllocLst1 = IMCC_TestUtilities.createFormAllocationWithHeading(oQnaire.id,formSettLst[0].id,'Mandatory');
        
        List<Tab_User_Type__c> tabUserFormAllocLst = IMCC_TestUtilities.createTabUserTypeFormAlloc(formAllocLst1.id,5,'Exhibitor');
        System.assertEquals(tabUserFormAllocLst.Size(),5, 'Tab User List size should be 5');
        
        List<Forms_Permission__c> formsPermLst1 = IMCC_TestUtilities.createFormsPermission(tabUserFormAllocLst[0].id,formAllocLst1.id,5);
        System.assertEquals(formsPermLst1.Size(),5, 'Form Permission List size should be 5');
        
        List<Form_Data__c> formsDataLst = IMCC_TestUtilities.createFormData(cemObj.id,formsPermLst1[0].id,5);
        System.assertEquals(formsDataLst.Size(),5, 'Form Data List size should be 5');
        
        Purchase_Data__c prchseData = IMCC_TestUtilities.createPurchaseData3(contactId,editionObjId, accId);
        
        List<Form_Response_Entry__c> formRespEntry = IMCC_TestUtilities.createFormRespEntry(formsDataLst[0].id,cemObj.id,1,prchseData.id);
        System.assertEquals(formRespEntry.Size(),1, 'Form Response List size should be 1');
        
        Question_Response__c questResponse2 = IMCC_TestUtilities.createQuestionResponse2(oQnaire.id,oQue.Id,userObj.Id,'Picklist1',formRespEntry[0].id);
        
        String attId = FileUploadCtrl.saveChunk(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id, oQQuesnaireWithOutQstn.Id,'test.png', EncodingUtil.urlEncode('base64Data','UTF-8'), 'image/png', '', 'fileDescription','1',true);
        FileUploadCtrl.saveChunk(formRespEntry[0].id,string.valueof(cemObj.id), oQue.Id, oQnaire.Id,oQQuesnaireWithOutQstn.Id, 'test.png', EncodingUtil.urlEncode('base64Data','UTF-8'), 'image/png', attId, 'fileDescription','1',true);
        System.assertNotEquals('', attId,'attid should not be blank');
        Test.stopTest();
    }
}