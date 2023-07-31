/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to create switch(toggle) type question
* Test Class             : SwitchInputCtrl_Test 
* Code Coverage          : 97%

* Modification Log
* Modified by            : Girikon(Mukesh)
**/
public with sharing class SwitchInputCtrl {
    /**
     * Create question and question questionnaire.
     * @param  qnaireId: Questionnaire id.
     * @param  qGroupId: Question group id.
     * @param  question: Question object values.
     * @param  qnaireName : Questionnaire name.
     * @param  qOrder: Order of question.
     * @param  lstQstnOptn: list Question options of the question.
     */
    @AuraEnabled
    public static void createQuestnAndQuestnQnaireWithOptions(String qnaireId, String qGroupId, Question__c question, String qnaireName, String qOrder,
                                                            String colNumber, List<Question_Option__c> lstQstnOptn) 
    {
        String sQLib = NewCreateTemplateCtr.getDefaultQuestnLibraryId();
        if(Schema.sObjectType.Question__c.fields.Name__c.isCreateable()){
            question.Name__c = question.Label__c;
        }          
        if(Schema.sObjectType.Question__c.fields.Related_To_Column__c.isCreateable()){
            question.Related_To_Column__c = colNumber;
        }          
        if (String.isNotBlank(sQLib) && Schema.sObjectType.Question__c.fields.Question_Library__c.isCreateable()) {
            question.Question_Library__c = sQLib;            
        }          
        qOrder = String.valueOf(FieldInputCtr.countQuestnQuestnnaireRecord(qnaireId, qGroupId));
          
        if(Schema.sObjectType.Question__c.fields.Name.isCreateable()){
            question.Name = qOrder;
        }
        if(Schema.sObjectType.Question__c.isCreateable()){
            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Question__c>{question}); 
            Insert sd.getRecords();
            question = [SELECT Id,Type__c,Currency_Symbol__c,lookup_Object_API_Name__c,Required__c,Allow_Currency__c,Decimal_value__c,Help_Text__c,Help_Text_Required__c,Category__c,Allow_Attachments__c,Allow_Comment__c,Is_Allow_Branching__c,Max_Char_Length__c,Minimum_Value__c,Maximum_value__c,Step_Size__c,Default_Value__c FROM Question__c WHERE Id=:sd.getRecords()[0].Id WITH SECURITY_ENFORCED];
        } 
        
        Question_Questionnaire__c oQQuesnaire = new Question_Questionnaire__c(Required__c = question.Required__c,
                            Allow_Currency__c = question.Allow_Currency__c, Decimal_value__c = question.Decimal_value__c, Related_To_Column__c = colNumber,
                            Help_Text__c = question.Help_Text__c, Help_Text_Required__c = question.Help_Text_Required__c, Category__c = question.Category__c,
                            Allow_Attachments__c = question.Allow_Attachments__c, Allow_Comment__c = question.Allow_Comment__c, Questionnaire__c = qnaireId, 
                            Name = qnaireName, Question_Group__c = qGroupId, Question__c = question.id, Question_Order__c = Integer.valueOf(qOrder),
                            Is_Allow_Branching__c =question.Is_Allow_Branching__c);
    
        if(Schema.sObjectType.Question_Questionnaire__c.fields.Max_Char_Length__c.isCreateable()){
            oQQuesnaire.Max_Char_Length__c = (question.Max_Char_Length__c != null ? question.Max_Char_Length__c : 0);
        }
        if(Schema.sObjectType.Question_Questionnaire__c.isCreateable()){            
            SObjectAccessDecision sd2 = Security.stripInaccessible(AccessType.CREATABLE, 
            new List<Question_Questionnaire__c>{oQQuesnaire});
            Insert sd2.getRecords();
            FieldInputCtr.sortQuestions(sd2.getRecords()[0].Id,qnaireId,qGroupId,colNumber,Integer.valueOf(qOrder));
        }
        
        for(Question_Option__c questnOptns : lstQstnOptn) 
        {
            questnOptns.Question__c = question.id;
            questnOptns.Name = FBUtils.subStr(questnOptns.Name__c, 75); // ADd : Changes Here for Long
            questnOptns.Name__c = FBUtils.subStr(questnOptns.Name__c, 75); // ADd : Changes Here for Long
            questnOptns.Name_Long__c = questnOptns.Name__c;  // ADd : Changes Here for Long        
        }
          
        if(!lstQstnOptn.isEmpty() && Schema.sObjectType.Question_Questionnaire__c.isCreateable()){
            Insert Security.stripInaccessible(AccessType.CREATABLE, lstQstnOptn).getRecords();            
        }
    }
 
    /**
     * save edited Question and Question Questionniare record
     * @param  oQues: Question object values.
     * @param  qnaireId: Questionnaire id.
     * @param  sectionId: Question group(Section) Id.
     * @param  lstQstnOptn: list Question options of the question.
     */
    @AuraEnabled
    public static void saveEditQuesRecord(Question__c oQues, String qnaireId, String sectionId, List<Question_Option__c> lstQstnOptn,Boolean isUnderBranching) 
    {
        if (oQues != null) {
            if (oQues.Help_Text_Required__c == false){
                if(Schema.sObjectType.Question__c.fields.Help_Text__c.isUpdateable()){ 
                    oQues.Help_Text__c = '';
                }
            }
            if(Schema.sObjectType.Question__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{oQues}).getRecords();                
            }
            
            List<Question_Questionnaire__c> lstQQnnaire = [SELECT Id, Allow_Attachments__c, Allow_Comment__c,Help_Text_Required__c,Help_Text__c,Category__c,lookup_Object_API_Name__c,
            lookup_Object_Field_Name__c FROM Question_Questionnaire__c WHERE Question__c = :String.escapeSingleQuotes(oQues.id) AND Questionnaire__c = :String.escapeSingleQuotes(qnaireId) AND Question_Group__c = :String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
            
            if (!lstQQnnaire.isEmpty())
            {
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Allow_Attachments__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Attachments__c = oQues.Allow_Attachments__c;
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Allow_Comment__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Comment__c = oQues.Allow_Comment__c;
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Help_Text_Required__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text_Required__c = oQues.Help_Text_Required__c;
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c = '';
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Required__c.isUpdateable()){
                    lstQQnnaire[0].Required__c = oQues.Required__c;
                }
                if (oQues.Help_Text_Required__c == true && Schema.sObjectType.Question_Questionnaire__c.fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c = oQues.Help_Text__c;
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Is_Allow_Branching__c.isUpdateable()){
                    lstQQnnaire[0].Is_Allow_Branching__c =oQues.Is_Allow_Branching__c;
                }
                if(lstQQnnaire[0].Is_Allow_Branching__c==false && isUnderBranching==false){
                    NewCreateTemplateCtr.delQuestnDynLogic(lstQQnnaire[0].id);
                }               
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Max_Char_Length__c.isUpdateable()){
                    lstQQnnaire[0].Max_Char_Length__c = (oQues.Max_Char_Length__c != null ? oQues.Max_Char_Length__c : 0);
                }
                if(Schema.sObjectType.Question_Questionnaire__c.fields.Category__c.isUpdateable()){
                    lstQQnnaire[0].Category__c = oQues.Category__c;
                }
                if(Schema.sObjectType.Question_Questionnaire__c.isUpdateable()){                     
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQQnnaire).getRecords();
                }
            }
            if(!lstQstnOptn.isEmpty() && Schema.sObjectType.Question_Option__c.isUpdateable())
            {
                Update Security.stripInaccessible(AccessType.UPDATABLE, lstQstnOptn).getRecords();                
            }
        }
    }
}