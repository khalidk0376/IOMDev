@isTest
private class QuestionBranchingCtrl_Test {
	
	static testMethod void createBranchingRecordTestMethod(){
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;

        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c);
        //create Question Option
        Question_Option__c qOption = new Question_Option__c(Name ='Option 1',Name__c='Option 1',Question__c =oQue.id);
        insert qOption;
        List<Question_Option__c> listQueOptionData  = [Select id,Name__c from Question_Option__c];
        System.assertNotEquals(listQueOptionData,null);
        System.assertEquals(listQueOptionData.size(),1);
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
        List<Question_Questionnaire__c> lstQuestionQnnaireAdd = new List<Question_Questionnaire__c>();
        Question_Questionnaire__c oQQuesnaireMain= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1);
        lstQuestionQnnaireAdd.add(oQQuesnaireMain);

        Question_Questionnaire__c oQQuesnaireBranching= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=2);
        lstQuestionQnnaireAdd.add(oQQuesnaireBranching);
        Question_Questionnaire__c oQQuesnaireBranchingSecond= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=2);
        lstQuestionQnnaireAdd.add(oQQuesnaireBranchingSecond);
        insert lstQuestionQnnaireAdd;
        System.assertNotEquals(lstQuestionQnnaireAdd,null);
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:lstQuestionQnnaireAdd[0].id];
        System.assertEquals(lstQuestionQnnaireAdd[0].Question__c,lstQuestionQnnaire[0].Question__c);
        
        //create Questionnaire_Dynamic_Logic record
        Questionnaire_Dynamic_Logic__c QuestnDynLogic = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=lstQuestionQnnaireAdd[0].id,Question_Group__c =oQG.id,Question_Option__c=qOption.id,Show_Question_Questionnaire__c=lstQuestionQnnaireAdd[1].id);
        insert QuestnDynLogic;
        // for insert data
        Questionnaire_Dynamic_Logic__c QuestnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=lstQuestionQnnaireAdd[0].id,Question_Group__c =oQG.id,Question_Option__c=qOption.id,Show_Question_Questionnaire__c=lstQuestionQnnaireAdd[1].id);
        List<Questionnaire_Dynamic_Logic__c> lstQDLData = new List<Questionnaire_Dynamic_Logic__c>();
        lstQDLData.add(QuestnDynLogicInsert);
        System.assertNotEquals(lstQDLData,null);
        List<Questionnaire_Dynamic_Logic__c> lstQDLogic = [Select id from Questionnaire_Dynamic_Logic__c where Question_Questionnaire__c=:lstQuestionQnnaireAdd[0].id and Question_Group__c =:oQG.id and Question_Option__c=:qOption.id];
        System.assertNotEquals(lstQDLogic,null);
        System.assertEquals(lstQDLogic.size(),1);
        Test.startTest();
            List<Question_Questionnaire__c> lstQQnResult = QuestionBranchingCtrl.getAllQuestnQuestnnaire(oQnaire.id,oQG.id,1, lstQuestionQnnaireAdd[0].id,'col1');
            System.assertNotEquals(lstQQnResult, null);
            //System.assertEquals(lstQQnResult.size(),2);
        	List<Questionnaire_Dynamic_Logic__c> lstAlraedyBranching = QuestionBranchingCtrl.getAlraedyBranching(oQG.id, lstQuestionQnnaireAdd[0].id);
        	System.assertNotEquals(lstAlraedyBranching, null);
            System.assertEquals(lstAlraedyBranching.size(),1);
        	QuestionBranchingCtrl.saveQuestnDynLogic(oQnaire.id,oQG.id, lstQuestionQnnaireAdd[0].id,lstQDLData,1);
        	List<Questionnaire_Dynamic_Logic__c> lstQDLogicResult = [Select id from Questionnaire_Dynamic_Logic__c where Question_Questionnaire__c=:lstQuestionQnnaireAdd[0].id and Question_Group__c =:oQG.id and Question_Option__c=:qOption.id];
            System.assertNotEquals(lstQDLogicResult,null);
            System.assertEquals(lstQDLogicResult.size(),1);
        Test.stopTest();
    }
	
}