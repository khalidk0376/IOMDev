@isTest
public class NewCreateTemplateCtrl_Test {
    @isTest
    static  void createQniareRecordTestMethod(){
        Test.startTest();
        NewCreateTemplateCtr.getDefaultQuestnLibraryId();
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;
		
        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=false, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,Related_To_Column__c='col1');
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c,'Type Mismatch');
        //create Question option record.
        Question_Option__c qOption = new Question_Option__c(Name ='Test',Name__c='test',Question__c=oQue.id);
        insert qOption; 
		List<Question_Option__c> lstqOption = [Select id from Question_Option__c where Question__c=:oQue.id];
        System.assertNotEquals(lstqOption, null,'question options is null');
        
        Question__c oQue2 = new Question__c(Name='Test', Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true,Help_Text_Required__c=true,Related_To_Column__c='col1');

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
        
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c,'Category Mismatch');

        //Create Question Group record
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group',No_Of_Columns__c='1');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name,No_Of_Columns__c from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name,'Question Group Mismatch');		
        
        //Create Question Questionnaire Record Without question id
        Question_Questionnaire__c oQQuesnaireWithOutQstn= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question_Order__c=1,Related_To_Column__c='col1');
        insert oQQuesnaireWithOutQstn;
        
        //Create Question Questionnaire Record
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Allow_Attachments__c=oQue.Allow_Attachments__c,Allow_Comment__c=oQue.Allow_Comment__c,
            Questionnaire__c = oQnaire.id,Name=oQnaire.Name,Question_Group__c =oQG.id,Is_Allow_Branching__c=true,Question__c=oQue.id,Question_Order__c=1,Related_To_Column__c='col1');
        insert oQQuesnaire;
        
		//Create Questionnaire dynamic logic Record
        Questionnaire_Dynamic_Logic__c questnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=oQQuesnaire.id,
                                                                                                 Question_Group__c =oQG.id,
                                                                                                 Question_Option__c=qOption.id,
                                                                                                 Show_Question_Questionnaire__c=oQQuesnaireWithOutQstn.id);
        insert questnDynLogicInsert;
        
        NewCreateTemplateCtr.updateSection(oQG,oQnaire.Id);
        NewCreateTemplateCtr.updateColumn(oQnaire.Id,oQQuesnaire.id, oQue.Id, 'col1', oQG.id,'0');
        
        System.debug(LoggingLevel.DEBUG,[Select Id, Question_Questionnaire__c, Question_Group__c, Question_Option__c, Show_Question_Questionnaire__c from
                Questionnaire_Dynamic_Logic__c where Question_Questionnaire__c = :oQQuesnaire.id]);
        
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:oQQuesnaire.id];
        System.assertEquals(oQQuesnaire.Question__c,lstQuestionQnnaire[0].Question__c,'Question Id Mismatch');
        
        
            List<String> lstCategoris = NewCreateTemplateCtr.getQueCategory();
            System.assert(lstCategoris.size()>0,'exist Categories');

            Question__c questn = NewCreateTemplateCtr.getQuesDetail(oQue.id);
            System.assertEquals(questn.id,oQue.id,'Question Id Mismatch');

            String sDefaultLib = NewCreateTemplateCtr.getDefaultQuestnLibraryId();
            System.assert(sDefaultLib != null,'exist Default Library Id');
            List<Question_Library__c> lstQuestnLib = [Select id from Question_Library__c where Name='Global Default'];
            System.assert(lstQuestnLib != null,'exist Default Library');
            System.assertEquals(lstQuestnLib[0].id,sDefaultLib,'Question Library Id Mismatch');

            NewCreateTemplateCtr.saveEditQuesRecord(oQue);
            List<Question__c> lstQuestion = [Select id,Allow_Comment__c from Question__c where id=: oQue.id];
            System.assertNotEquals(lstQuestion,null,'Question list is null');
            System.assertEquals(lstQuestion[0].Allow_Comment__c,true,'Comments are not allowed');

            FBWrapper questnWrap = NewCreateTemplateCtr.getQuestnsForQuesGroup(oQnaire.id,oQG.id);
        	NewCreateTemplateCtr.getQuestnsForAllQuesGroup(oQnaire.id,oQG.id);
        	NewCreateTemplateCtr.getQuestnsForAllQuesGroup(oQnaire.id,'');
                
            System.assertNotEquals(questnWrap,null,'obejct is null');
            Integer countQuestnQnaireResult = [Select count() from Question_Questionnaire__c where Questionnaire__c =:oQnaire.id and Question_Group__c=:oQG.id];
            System.assertNotEquals(countQuestnQnaireResult,null,'Count is null');

            String templateName = NewCreateTemplateCtr.getTemplateName(oQnaire.id);
            System.assertNotEquals(templateName,null,'template name is null');

            String questionnaireName = [Select Name from Questionnaire__c where id=:oQnaire.id].Name;
            System.assertNotEquals(questionnaireName,null,'questionnaire Name is null');
            System.assertEquals(questionnaireName,templateName,'Template name Mismatch');

            List<Question_Questionnaire__c> lstQuesQnaire = NewCreateTemplateCtr.getAllQuestnGrpNameForQuesnnaire(oQnaire.id);
            System.assertNotEquals(lstQuesQnaire,null,'lstQuesQnaire is null');
            Integer countQutnQnaireResult = [Select count() from Question_Questionnaire__c where Questionnaire__c=:oQnaire.id and Question__c = null];
            System.assertNotEquals(countQutnQnaireResult,null,'countQutnQnaireResult is null');
            System.assertEquals(lstQuesQnaire.size(),countQutnQnaireResult,'countQutnQnaireResult is not same'); 

            NewCreateTemplateCtr.createQuestnAndQuestnQnaire(oQnaire.id,oQG.id,oQue2,oQnaire.Name,'1','col1');
            List<Question_Questionnaire__c> lstQuesQnaireResult = [Select id from Question_Questionnaire__c where Questionnaire__c=:oQnaire.id 
            and Question_Group__c =: oQG.id ]; 
            System.assertNotEquals(lstQuesQnaireResult,null,'lstQuesQnaireResult is null');
            System.assertNotEquals(lstQuesQnaireResult.size(),0,'lstQuesQnaireResult is > 0');
            
            NewCreateTemplateCtr.delQuestion(oQQuesnaire.id);
            List<Question_Questionnaire__c> lstQuesQuestnnaireResult = [Select id from Question_Questionnaire__c where id=:oQQuesnaire.id and is_delete__c =true];
            System.assertNotEquals(lstQuesQuestnnaireResult,null,'lstQuesQuestnnaireResult is null');
            System.assertEquals(lstQuesQuestnnaireResult.size(),1,'lstQuesQuestnnaireResult size is not 1.');

            Question_Group__c sectionObj2 = new Question_Group__c();
            sectionObj2.Name='Test Group1';
            sectionObj2.No_Of_Columns__c='1';
            sectionObj2.Is_Show_On_From__c=true;

            NewCreateTemplateCtr.createSection(sectionObj2,oQnaire.id);
            String groupName = [Select Name from Question_Group__c where Name='Test Group1'].Name ;
            System.assertNotEquals(groupName,null,'groupName is null');
            System.assertEquals(groupName,'Test Group1','groupName is not same');
        
            NewCreateTemplateCtr.temp_record questnRueslt= NewCreateTemplateCtr.getTemplateRecord(oQnaire.id);
            System.assertNotEquals(questnRueslt,null,'questnRueslt is null');
        
            //List<Question_Option__c> lstScoreAndWeight = NewCreateTemplateCtr.getScoreAndWeight(oQue.id);
        	//System.assertNotEquals(lstScoreAndWeight, null);

        	NewCreateTemplateCtr.setpublishStatusOnTemplate(oQnaire.id);
        	List<Questionnaire__c> lstQuQnaireResult = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id and is_Published__c =true];
        	System.assertNotEquals(lstQuQnaireResult, null,'lstQuQnaireResult is null');
        	NewCreateTemplateCtr.deleteSectionWithQuestionsAndQstnQustnry(oQG.id,oQnaire.id);
        
        	
        
            List<Question_Group__c> lstQuestnGroup =[Select id,is_Delete__c from Question_Group__c where id=:oQG.id ];
            System.assertNotEquals(lstQuestnGroup,null,'lstQuestnGroup is null');
            System.assertEquals(lstQuestnGroup[0].is_Delete__c,true,'lstQuestnGroup is Delete is not true');
        Test.stopTest();
    }
    
    @isTest
    static void createBranchingRecordTestMethod(){
        
        //Create Question Library
        Question_Library__c oQL= new Question_Library__c(Name='Global Default',Name__c='Global Default');
        insert oQL;

        //Create Question Record 
        Question__c oQue = new Question__c(Name='Test',Help_Text_Required__c=true, Name__c='Test 1', Help_Text__c='Test Help Text', Label__c='Question 1', 
            Question_Library__c=oQL.id, Required__c=true, Type__c='TextPlain',Allow_Comment__c=true,Allow_Attachments__c=true);
        insert oQue;
        List<Question__c> lstQutn = [Select id,Type__c from Question__c where id=:oQue.id];
        System.assertEquals(oQue.Type__c,lstQutn[0].Type__c,'Type Mismatch');
        //create Question Option
        Question_Option__c qOption = new Question_Option__c(Name ='Option 1',Name__c='Option 1',Question__c =oQue.id);
        insert qOption;
        List<Question_Option__c> listQueOptionData  = [Select id,Name__c from Question_Option__c];
        System.assertNotEquals(listQueOptionData,null,'listQueOptionData is null');
        System.assertEquals(listQueOptionData.size(),1,'listQueOptionData size is not 1');
        //Create Questionnaire record
        Questionnaire__c oQnaire = new Questionnaire__c();
        oQnaire.Name='Template 1';
        oQnaire.Category__c='Manual';
        oQnaire.Description__c='Template 1';
        oQnaire.Community_URL__c=URL.getSalesforceBaseUrl().toExternalForm();
        oQnaire.Is_Customize_Buttons__c=false;
        oQnaire.isMerge__c=true;
        oQnaire.NetworkId__c='testid';
        oQnaire.Button_Alignment__c='Top-Bottom';

        insert oQnaire;
        List<Questionnaire__c> lstQuQnaire = [Select id,Category__c from Questionnaire__c where id=:oQnaire.id];
        System.assertEquals(oQnaire.Category__c,lstQuQnaire[0].Category__c,'Category Mismatch');
		NewCreateTemplateCtr.isMergeSection(oQnaire.id);
        
        //Create Question Group record
        
        Question_Group__c oQG = new Question_Group__c(Name='Test Group');
        insert oQG;
        List<Question_Group__c> lstQuGroup = [Select id,Name from Question_Group__c where id=:oQG.id];
        System.assertEquals(oQG.Name,lstQuGroup[0].Name,'Question Group Name Mismatch');

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
        System.assertNotEquals(lstQuestionQnnaireAdd,null,'lstQuestionQnnaireAdd is null');
        List<Question_Questionnaire__c> lstQuestionQnnaire = [Select id,Question__c from Question_Questionnaire__c where id=:lstQuestionQnnaireAdd[0].id];
        System.assertEquals(lstQuestionQnnaireAdd[0].Question__c,lstQuestionQnnaire[0].Question__c,'Question Id is not same');
        
        NewCreateTemplateCtr.setQuestnQnniareOrder(lstQuestionQnnaire,new Question__c[]{oQue});
        
        //create Questionnaire_Dynamic_Logic record
        Questionnaire_Dynamic_Logic__c questnDynLogic = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=lstQuestionQnnaireAdd[0].id,Question_Group__c =oQG.id,Question_Option__c=qOption.id,Show_Question_Questionnaire__c=lstQuestionQnnaireAdd[1].id);
        insert QuestnDynLogic;
        // for insert data
        Questionnaire_Dynamic_Logic__c questnDynLogicInsert = new Questionnaire_Dynamic_Logic__c(Question_Questionnaire__c=lstQuestionQnnaireAdd[0].id,Question_Group__c =oQG.id,Question_Option__c=qOption.id,Show_Question_Questionnaire__c=lstQuestionQnnaireAdd[1].id);
        List<Questionnaire_Dynamic_Logic__c> lstQDLData = new List<Questionnaire_Dynamic_Logic__c>();
        lstQDLData.add(QuestnDynLogicInsert);
        System.assertNotEquals(lstQDLData,null,'lstQDLData is null');
        List<Questionnaire_Dynamic_Logic__c> lstQDLogic = [Select id from Questionnaire_Dynamic_Logic__c where Question_Questionnaire__c=:lstQuestionQnnaireAdd[0].id and Question_Group__c =:oQG.id and Question_Option__c=:qOption.id];
        System.assertNotEquals(lstQDLogic,null,'lstQDLogic is null');
        System.assertEquals(lstQDLogic.size(),1,'lstQDLogic size is not 1.');
        Test.startTest();
            List<Questionnaire_Dynamic_Logic__c> lstBranchingQuestn = NewCreateTemplateCtr.getBranchingQuestn(oQG.id);
            System.assertNotEquals(lstBranchingQuestn, null,'lstBranchingQuestn is null');
            System.assertEquals(lstBranchingQuestn.size(),1,'lstBranchingQuestn size is not 1.');
            for(Question_Questionnaire__c obj : lstQuestionQnnaireAdd){
                obj.question_order__c = 1;
            }
        	NewCreateTemplateCtr.setQuestnQnniareOrder(lstQuestionQnnaireAdd);        	
        	System.assertNotEquals(lstQuestionQnnaireAdd, null,'lstQuestionQnnaireAdd is null');
        	System.assertEquals(lstQuestionQnnaireAdd[0].question_order__c, 1,'question order is not 1');
        Test.stopTest();
    }            
}