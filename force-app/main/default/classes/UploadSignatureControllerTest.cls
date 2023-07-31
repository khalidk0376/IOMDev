/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Test class for UploadSignatureController apex class
* Modification Log
* Modified by            : 
**/
@IsTest
public class UploadSignatureControllerTest {

    @IsTest
    private static void test1()
    { 
        Test.startTest();
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;

        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        
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
        
       
            
            UserRole userrole = [SELECT Id, DeveloperName FROM UserRole Where DeveloperName = 'Administrator' Limit 1];
            User adminUser = [SELECT Id, UserRoleId FROM User Where Profile.Name='System Administrator' and IsActive = true Limit 1];
            System.RunAs(adminUser)
            {
                adminUser.UserRoleId = userrole.Id;
                update adminUser;
            }
        	User userObj;
        	List<Account> accObj;
        	List<Contact> contObj;
        	Id accId;
        	Id contactId;
            System.runAs(adminUser){
                accObj  = IMCC_TestUtilities.createAccount(250);
                accId = accObj[0].Id;
                contObj = IMCC_TestUtilities.createContact(accId, 250);
                contactId = contObj[0].Id;
                userObj = IMCC_TestUtilities.createCommunityUser(contactId);
            }
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
        
        String responseStr = UploadSignatureController.saveSignatureResponse(formRespEntLst1[0].id,null,string.valueof(cemObj.id),oQue.Id, oQnaire.Id,oQQuesnaireWithOutQstn.Id, EncodingUtil.urlEncode('base64Data','UTF-8'),'https://test.com/survey','1');
        responseStr = UploadSignatureController.saveSignatureResponse(formRespEntLst1[0].id,null,string.valueof(cemObj.id),oQue.Id, oQnaire.Id,oQQuesnaireWithOutQstn.Id, EncodingUtil.urlEncode('base64Data','UTF-8'),'https://test.com/survey','1');
        FBUtils.FBResponse response = (FBUtils.FBResponse)JSON.deserialize(responseStr, FBUtils.FBResponse.class);
        System.assertEquals(true, response.isSuccess);
        Test.stopTest();
    }
}