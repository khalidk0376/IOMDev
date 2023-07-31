@isTest
private class InformationInputCtr_Test {
    static testMethod void createInputRecord_TestMethod(){
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
        
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name',Currency_Symbol__c='$',Help_Text_Required__c=false, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c);
        Question__c oQue2 = new Question__c(Name='Test',lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name',Currency_Symbol__c='$',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                           Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue2;
        
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Description__c='Template 1';
        oQnaire.NetworkId__c='testid';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        insert oQnaire;
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c);
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name);
        
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');
        insert oQQuesnaire;
        
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c);
        //setup New Question Record 
        Question__c createNewQuestion = new Question__c(Name='Test',Currency_Symbol__c='$', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
                                                        Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,lookup_Object_API_Name__c='Account',lookup_Object_Field_Name__c='Name');
        
        Test.startTest();
        System.debug(oQnaire.id+'**'+oQG.id);
        InformationInputCtr.createQuestnAndQuestnQnaire(oQnaire.id,oQG.id,createNewQuestion,oQnaire.Name,'1','col1','TestColor','#ajsdj');
        List<Question_Questionnaire__c> lstQuQnaireCreateResult =[Select id,Question__c from 
                                                                  Question_Questionnaire__c where Questionnaire__c=:oQnaire.id and 
                                                                  Question_Group__c =: oQG.id];
        System.assertNotEquals(lstQuQnaireCreateResult,null);  
        //System.assertEquals(lstQuQnaireCreateResult.size(),2);
        InformationInputCtr.saveEditQuesRecord(oQue,oQnaire.id,oQG.id);
        //InformationInputCtr.saveEditQuesRecord(oQue,oQnaire.id,oQG.id);
        List<Question_Questionnaire__c> lstQuQnaireSaveResult =[Select id,Question__c from 
                                                                Question_Questionnaire__c where Questionnaire__c=:oQnaire.id and 
                                                                Question_Group__c =: oQG.id and Question__c=:oQue.id];
        SYstem.debug(lstQuQnaireSaveResult);
        System.assertNotEquals(lstQuQnaireSaveResult,null);  
        System.assertEquals(lstQuQnaireSaveResult.size(),1);
        List<String> lstCurrencySymbol =InformationInputCtr.getQueCurrencySymbol();
        System.assertNotEquals(lstCurrencySymbol,null);
        System.assert(lstCurrencySymbol.size()>0,'exist currency');
        Test.stopTest();
    }
    
}