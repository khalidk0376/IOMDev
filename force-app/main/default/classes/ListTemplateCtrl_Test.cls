/**
* 
*/
@isTest
public class ListTemplateCtrl_Test {
    static testMethod void createQniareTestMethod(){
        
        ListTemplateCtrl.getCommunities();
        // Create  Questionnaire record        
        Questionnaire__c oQnaireRecord = new Questionnaire__c();
        oQnaireRecord .Name='Test Template 1';
        oQnaireRecord .Category__c='Manual';
        oQnaireRecord .Description__c='Template 1';
        oQnaireRecord.NetworkId__c='testid';
        oQnaireRecord.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        insert oQnaireRecord;
        ListTemplateCtrl.updateQnaire(new Questionnaire__c[]{oQnaireRecord});
        ListTemplateCtrl.getGenericObjectRecord('Questionnaire__c','Id,Name,Category__c,NetworkId__c,Description__c,Community_URL__c',2,false,false,0,'Healthcare','test','Name','ASC');
        
        System.assertNotEquals(oQnaireRecord,null);
        List<Questionnaire__c> lstQnaire=[Select Id,Name From Questionnaire__c Where Id=:oQnaireRecord.id];
        System.assertEquals(lstQnaire.size(),1); 
        
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c);
        
        // Create Question Option
        Question_Option__c qstnOption=new Question_Option__c();
        qstnOption.Name='A';
        qstnOption.Question__c=oQue.id;
        qstnOption.Name__c='A';
        insert qstnOption;
        List<Question_Option__c> lstQutnOptn = [Select id,Name from Question_Option__c where id=:qstnOption.id];
        System.assertEquals(lstQutnOptn.size(),1);
        //Create Question Group record
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name);
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaireRecord.id,Is_Allow_Branching__c=true,Name=oQnaireRecord.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1);
        insert oQQuesnaire;
        
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c);
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                                        Questionnaire__c = oQnaireRecord.id,Name=oQnaireRecord.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1);
        insert oQQuesnaireWithOutQstn;
        
        List<Question_Questionnaire__c> lstQuestionQnnaireWithOutQsrn = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaireWithOutQstn.id];
        System.assertEquals(lstQuestionQnnaireWithOutQsrn[0].Question__c,null);
        System.assertEquals(lstQuestionQnnaireWithOutQsrn.size() ,1);
        
        //Create Questionnaire dynamic logic Record
        Questionnaire_Dynamic_Logic__c QuestnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=oQQuesnaire.id,
                                                                                                 Question_Group__c =oQG.id,
                                                                                                 Question_Option__c=qstnOption.id,
                                                                                                 Show_Question_Questionnaire__c=oQQuesnaireWithOutQstn.id);
        insert QuestnDynLogicInsert;
        Test.startTest();
        ListTemplateCtrl.getQuenaireLanguage();
        List<String> lstCategory = ListTemplateCtrl.getQuenaireCategory();
        System.assert(lstCategory.size()>0,'exist Categories');
        Questionnaire__c oQnaire = new Questionnaire__c(NetworkId__c='testasjdas',Name='Template 1',Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm(),Category__c='Manual',Description__c='Template 1');
        String questnId = ListTemplateCtrl.createQnaire(oQnaire,'sectionName','1');
        System.assert(questnId != null ,'exist id');
        List<Questionnaire__c> lstQQnaire = [SELECT id FROM Questionnaire__c WHERE id=:String.escapeSingleQuotes(questnId) WITH SECURITY_ENFORCED];
        System.assertNotEquals(lstQQnaire,null);
        System.assertEquals(questnId,lstQQnaire[0].id); 
        Questionnaire__c qnaire=ListTemplateCtrl.getQnaireRecord(oQnaireRecord.id);
        System.assertNotEquals(qnaire,null);
        ListTemplateCtrl.saveQnaireCloneRecord(oQnaireRecord);            
        Integer countOfQuestnnaire = [Select count() from Questionnaire__c];
        
        ListTemplateCtrl.getAllApps();
        new ListTemplateCtrl.Wrapper_Class('label','value','networkId');
        System.assertNotEquals(countOfQuestnnaire,0);            
        Test.stopTest();
    }
}