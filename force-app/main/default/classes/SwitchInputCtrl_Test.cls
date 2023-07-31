@isTest
private class SwitchInputCtrl_Test {

    static testMethod void createSwitchInputRecordTestMethod(){
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;

         //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Currency_Symbol__c='$',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c);
        
        // Create Question options
        Question_Option__c createQuestionOption =new Question_Option__c(Name='Male',Name__c='Male',Question__c=oQue.id,Value__c='M');
        insert createQuestionOption;
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
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1);
        insert oQQuesnaire;

        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c);
        //setup New Question Record 
        Question__c createNewQuestion = new Question__c(Name='Test',Currency_Symbol__c='$', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        // setup new Question option record
        Question_Option__c oNewQuestionOption=new Question_Option__c(Name='Male',Name__c='Male',Question__c=oQue.id,Value__c='M');
        Test.startTest();
           List<Question_Option__c> lstNewQustnOption = new List<Question_Option__c>();
           lstNewQustnOption.add(oNewQuestionOption);
           System.assertNotEquals(lstNewQustnOption, null);
           System.assertEquals(lstNewQustnOption.size(),1);
           
           SwitchInputCtrl.createQuestnAndQuestnQnaireWithOptions(oQnaire.id,oQG.id,createNewQuestion,oQnaire.Name,'2','1',lstNewQustnOption);
           List<Question__c> lstQutnResult = [Select id,(Select id from Question_Options__r) from Question__c];
           System.assertNotEquals(lstQutnResult,null);
           System.assertEquals(lstQutnResult.size(),2);
           System.assertNotEquals(lstQutnResult[0].Question_Options__r,null);
           System.assert(lstQutnResult[0].Question_Options__r.size()>0,'exist Question option in Question');

           // saveEditQuesRecord(Question__c oQues, String qnaireId, String sectionId, List<Question_Option__c> lstQstnOptn)
           List<Question_Option__c> lstupdateQustnOption = new List<Question_Option__c>();
           lstupdateQustnOption.add(createQuestionOption);
           SwitchInputCtrl.saveEditQuesRecord(oQue, oQnaire.id, oQG.id, lstupdateQustnOption,false);
           List<Question__c> lstUpdateQutnResult = [Select id,(Select id from Question_Options__r) from Question__c where Id=:oQue.id];
           System.assertNotEquals(lstUpdateQutnResult,null);
           System.assertEquals(lstUpdateQutnResult.size(),1);
           System.assertNotEquals(lstUpdateQutnResult[0].Question_Options__r,null);
           System.assert(lstUpdateQutnResult[0].Question_Options__r.size()>0,'updated Question option in Question');
        Test.stopTest();
    }
    
}