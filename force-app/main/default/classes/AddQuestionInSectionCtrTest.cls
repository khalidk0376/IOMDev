@isTest
public class AddQuestionInSectionCtrTest {
    static testMethod void moveQuestionTest(){
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Currency_Symbol__c='$',Help_Text_Required__c=true, Name__c='Test 1', 
                                           Help_Text__c='Test Help Text', Label__c='Question 1',Required__c=true, 
                                           Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c);
        Test.startTest();
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
        
        //create Question Option
        Question_Option__c qOption = new Question_Option__c(Name ='Option 1',Name__c='Option 1',Question__c =oQue.id);
        insert qOption;
        List<Question_Option__c> listQueOptionData  = [Select id,Name__c from Question_Option__c];
        System.assertNotEquals(listQueOptionData,null);
        System.assertEquals(listQueOptionData.size(),1);
        
        //Create Question Group record
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        
        AddQuestionInSectionCtr.updateQuestionGroupsSortingOrder(new Question_Group__c[]{oQG});
            
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name);
        
        Question_Group__c oQGMove = new Question_Group__c(Name='Test Group');
        insert oQGMove;
        List<Question_Group__c> lstQuGroupMove = [Select id,Name from Question_Group__c where id=:oQGMove.id];
        System.assertEquals(oQGMove.Name,lstQuGroupMove[0].Name);
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                             Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1,Is_Allow_Branching__c=false);
        insert oQQuesnaire;
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c);
        
        //Create branched Question Questionnaire Record
        Question_Questionnaire__c oQQuesnairebranched= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
                                                                                     Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Question__c=oQue.id,Question_Order__c=1,Is_Allow_Branching__c=false);
        insert oQQuesnairebranched;
        List<Question_Questionnaire__c> lstBranchedQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnairebranched.id];
        System.assertEquals(oQQuesnairebranched.Question__c,lstBranchedQuestionQnnaire[0].Question__c);
        
        //Create Questionnaire dynamic logic Record
        Questionnaire_Dynamic_Logic__c QuestnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=oQQuesnaire.id,
                                                                                                 Question_Group__c =oQG.id,
                                                                                                 Question_Option__c=qOption.id,
                                                                                                 Show_Question_Questionnaire__c=oQQuesnairebranched.id);
        insert QuestnDynLogicInsert;
        List<Questionnaire_Dynamic_Logic__c> lstQuestionDynLogic = [Select id,Question_Questionnaire__c from Questionnaire_Dynamic_Logic__c where id=:QuestnDynLogicInsert.id];
        System.assertEquals(QuestnDynLogicInsert.Question_Questionnaire__c,lstQuestionDynLogic[0].Question_Questionnaire__c);        
        
        Boolean moveQstnFalse=AddQuestionInSectionCtr.saveQstnInSection(oQQuesnaire.id,oQG.id,'1');
        System.assertEquals(moveQstnFalse,false);
        Boolean moveQstnTrue=AddQuestionInSectionCtr.saveQstnInSection(oQQuesnaire.id,oQGMove.id,'1');
        System.assertEquals(moveQstnTrue,true);
        oQQuesnaire.Is_Allow_Branching__c=true;
        update oQQuesnaire;
        List<Question_Questionnaire__c> lstUpdatedQuestionQnnaire = [Select id,Question__c,Is_Allow_Branching__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(lstUpdatedQuestionQnnaire[0].Is_Allow_Branching__c,true);
        Boolean moveBranchQstnFalse=AddQuestionInSectionCtr.saveQstnInSection(oQQuesnaire.id,oQG.id,'1');
        System.assertEquals(moveBranchQstnFalse,false);	
        Boolean moveBranchQstnTrue=AddQuestionInSectionCtr.saveQstnInSection(oQQuesnaire.id,oQGMove.id,'1');
        System.assertEquals(moveBranchQstnTrue,true);
        AddQuestionInSectionCtr.getQuestionGroups(oQQuesnaire.id);
        Test.stopTest();
    }
}