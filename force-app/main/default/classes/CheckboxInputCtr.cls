/**
 * TestClass: CheckboxInputCtr_Test
 * Code Coverage : 95%
 */
public with sharing class CheckboxInputCtr{
     /**
      * FLS Check DONE
     * Create question and question questionnaire.
     * @param  qnaireId: Questionnaire id.
     * @param  qGroupId: Question group id.
     * @param  question: Question object values.
     * @param  qnaireName : Questionnaire name.
     * @param  qOrder: Order of question.
     * @param  colNumber: column number of question.
     * @param  questnOptns: Question options of the question.
     */
    @AuraEnabled 
    public static void createQuestnAndQuestnQnaireWithOptions(String qnaireId,String qGroupId,Question__c question,String qnaireName,String qOrder,String colNumber,String questnOptns){
        String sQLib = NewCreateTemplateCtr.getDefaultQuestnLibraryId();
        if(Schema.SObjectType.Question__c.Fields.Name__c.isCreateable()){
            question.Name__c = question.Label__c;    
        }
        if(Schema.SObjectType.Question__c.Fields.Related_To_Column__c.isCreateable()){
            question.Related_To_Column__c = colNumber;
        }

        if(String.isNotBlank( sQLib) && Schema.SObjectType.Question__c.Fields.Question_Library__c.isCreateable()){
            question.Question_Library__c = sQLib; 
        }
        qOrder = String.valueOf(FieldInputCtr.countQuestnQuestnnaireRecord(qnaireId, qGroupId));
        
        if(Schema.SObjectType.Question__c.Fields.Name.isCreateable()){
            question.Name = qOrder;
        }
        if(Schema.SObjectType.Question__c.isCreateable()){
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, new List<Question__c>{question});
            Insert secDec.getRecords();
            question = [SELECT Id,Type__c,Currency_Symbol__c,lookup_Object_API_Name__c,Required__c,Allow_Currency__c,Decimal_value__c,Help_Text__c,Help_Text_Required__c,Category__c,Allow_Attachments__c,Allow_Comment__c,Is_Allow_Branching__c,Max_Char_Length__c,Minimum_Value__c,Maximum_value__c,Step_Size__c,Default_Value__c FROM Question__c WHERE Id=:secDec.getRecords()[0].Id WITH SECURITY_ENFORCED];
        }
        
        Question_Questionnaire__c oQQuesnaire= new Question_Questionnaire__c(Required__c=question.Required__c,
        Allow_Currency__c =question.Allow_Currency__c,Decimal_value__c =question.Decimal_value__c, Related_To_Column__c=colNumber,
        Help_Text__c=question.Help_Text__c,Help_Text_Required__c=question.Help_Text_Required__c,Category__c=question.Category__c,
        Allow_Attachments__c=question.Allow_Attachments__c,Allow_Comment__c=question.Allow_Comment__c,Questionnaire__c = qnaireId,
        Name=qnaireName,Question_Group__c =qGroupId,Question__c=question.id,Question_Order__c=Integer.valueOf(qOrder),
        Is_Allow_Branching__c =question.Is_Allow_Branching__c);

        oQQuesnaire.Max_Char_Length__c=(question.Max_Char_Length__c != null?question.Max_Char_Length__c:0);

        if(String.isNotBlank(question.Currency_Symbol__c)){
            oQQuesnaire.Currency_Symbol__c=question.Currency_Symbol__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.isCreateable()){
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Questionnaire__c> {oQQuesnaire});
            Insert secDec.getRecords();
            FieldInputCtr.sortQuestions(secDec.getRecords()[0].Id,qnaireId,qGroupId,colNumber,Integer.valueOf(qOrder));
        }
    
        List<fieldWrapper> qstnOptnList = (List<fieldWrapper>) JSON.deserialize(questnOptns, List<fieldWrapper>.class);
        List<Question_Option__c> lstQstnOptn=new List<Question_Option__c>();
        Question_Option__c qusthOption;
        for(fieldWrapper wrapper: qstnOptnList){
            qusthOption=new Question_Option__c();
            if(Schema.SObjectType.Question_Option__c.Fields.Name.isCreateable()){
                qusthOption.Name = FBUtils.subStr(wrapper.name,75);// Changes Here for Long
            }
            if(Schema.SObjectType.Question_Option__c.Fields.Name__c.isCreateable()){
                qusthOption.Name__c = FBUtils.subStr(wrapper.name,75);// Changes Here for Long
            }
            // Changes Here for Long
            if(Schema.SObjectType.Question_Option__c.Fields.Name_Long__c.isCreateable()){
                qusthOption.Name_Long__c = wrapper.name;
            }

            if(Schema.SObjectType.Question_Option__c.Fields.Question__c.isCreateable()){
                qusthOption.Question__c = question.id;
            }            
            if(Schema.SObjectType.Question_Option__c.Fields.Value__c.isCreateable()){
                qusthOption.Value__c = wrapper.alias;
            }
            lstQstnOptn.add(qusthOption);
        }
        if(Schema.SObjectType.Question_Option__c.isCreateable()){
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, lstQstnOptn);
            Insert secDec.getRecords();
        }
    }
    
    /**
     * Save question option  when edit question.
     * @param  oQues: Question object.
     * @param  name: Name of question option.
     * @param  alias: Alias of question option.     
     * @return : Question record
     */
    @AuraEnabled
    public static Question__c saveQuestionEditOption(Question__c oQues,String name,String alias,String score){
        Question__c question = new Question__c();
        if(oQues != null && String.isNotBlank(name)){
            // Changes Here for Long
            Question_Option__c qusthOption = new Question_Option__c(Question__c=oQues.id,Name=FBUtils.subStr(name,75),Name__c=FBUtils.subStr(name,75),Name_Long__c=name,Value__c=alias);                
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Option__c>{qusthOption});
            Insert secDec.getRecords();            
            question = NewCreateTemplateCtr.getQuesDetail(oQues.id);
        }    
        return question ;
    }
    
     /**
     * Delete question option  when edit question.
     * @param  oQues: Question object
     * @param  qstnOptionId: Id of question option.
     * @return : Question record
     */
    @AuraEnabled
    public static Question__c deleteQuestionOptionInEdit(Question__c oQues,String qstnOptionId){
        Question__c question = new Question__c();
        
        if(oQues!= null && String.isNotBlank(qstnOptionId) && Schema.SObjectType.Question_Option__c.isDeletable()){
           List<Question_Option__c> qstnOption = [SELECT Id FROM Question_Option__c WHERE Id=:String.escapeSingleQuotes(qstnOptionId) WITH SECURITY_ENFORCED];
           if(!qstnOption.isEmpty()){
               delete qstnOption;
           }
           question=NewCreateTemplateCtr.getQuesDetail(oQues.id);
        }
        return question;
    }
    
    /**
     * Edit question option  when edit question.
     * @param  oQues: Question object
     * @param  qstnOptionId: Id of question option.
     * @return : Question record
     */
    @AuraEnabled
    public static Question__c editQuestionOptionInEdit(Question_Option__c oQuesOption,Question__c oQues){
        Question__c question = new Question__c();
        if(oQuesOption != null && oQues!= null){            
            // Changes Here for Long Edit value received in Name__c                
            oQuesOption.Name_Long__c = oQuesOption.Name__c;
            oQuesOption.name = FBUtils.subStr(oQuesOption.Name__c,75);
            oQuesOption.Name__c = FBUtils.subStr(oQuesOption.Name__c,75);
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.UPDATABLE, new List<Question_Option__c>{oQuesOption});
            Update secDec.getRecords();
            question=NewCreateTemplateCtr.getQuesDetail(oQues.Id);            
        }
        return question;
    }
    
     /**
     * save edited Question and Question Questionniare record
     * @param  oQues: Question object values.
     * @param  qnaireId: Question object values.
     * @param  sectionId: Question object values.
     */
    @AuraEnabled
    public static void saveEditQuesRecord(Question__c oQues,String qnaireId,String sectionId,Boolean isUnderBranching) {
        if (oQues != null) 
        {
            system.debug(oQues);
            if(oQues.Help_Text_Required__c==false){
                oQues.Help_Text__c='';
            }
            if(Schema.SObjectType.Question__c.isUpdateable() && Schema.SObjectType.Question__c.Fields.Help_Text__c.isUpdateable()){
                SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{oQues});
                Update secDec.getRecords();
            }
            
            List<Question_Questionnaire__c> lstQQnnaire=[SELECT Id,Is_Allow_Branching__c from Question_Questionnaire__c where Question__c=:String.escapeSingleQuotes(oQues.id) and Questionnaire__c=:String.escapeSingleQuotes(qnaireId) and Question_Group__c=:String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
            if(!lstQQnnaire.isEmpty())
            {
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Attachments__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Attachments__c=oQues.Allow_Attachments__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Comment__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Comment__c=oQues.Allow_Comment__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text_Required__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text_Required__c=oQues.Help_Text_Required__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c='';
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Required__c.isUpdateable()){
                    lstQQnnaire[0].Required__c=oQues.Required__c;
                }
                if(oQues.Help_Text_Required__c==true && Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){
                    lstQQnnaire[0].Help_Text__c=oQues.Help_Text__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Is_Allow_Branching__c.isUpdateable()){
                    lstQQnnaire[0].Is_Allow_Branching__c =oQues.Is_Allow_Branching__c;
                }
                if(lstQQnnaire[0].Is_Allow_Branching__c==false && isUnderBranching ==false){
                    NewCreateTemplateCtr.delQuestnDynLogic(lstQQnnaire[0].id);
                }
                if(String.isNotBlank(oQues.Currency_Symbol__c) && Schema.SObjectType.Question_Questionnaire__c.Fields.Currency_Symbol__c.isUpdateable()){
                    lstQQnnaire[0].Currency_Symbol__c=oQues.Currency_Symbol__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Decimal_value__c.isUpdateable()){
                    lstQQnnaire[0].Decimal_value__c =oQues.Decimal_value__c;    
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Currency__c.isUpdateable()){
                    lstQQnnaire[0].Allow_Currency__c =oQues.Allow_Currency__c;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Max_Char_Length__c.isUpdateable()){
                    lstQQnnaire[0].Max_Char_Length__c =(oQues.Max_Char_Length__c != null?oQues.Max_Char_Length__c:0);
                }
                if(Schema.SObjectType.Question_Questionnaire__c.Fields.Category__c.isUpdateable()){
                    lstQQnnaire[0].Category__c=oQues.Category__c;
                }
                
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable())
                {
                    SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.UPDATABLE, lstQQnnaire);
                    Update secDec.getRecords();
                }
            }
        
        } 
    }
	
    @AuraEnabled
    public static void sortEditOption(List<Question_Option__c> lstQOption) {
        if(lstQOption != null && lstQOption.size()>0){
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.UPDATABLE, lstQOption);
            Update secDec.getRecords();
        }
    }

    /**
     * Wrapper class to read quetion option values.
    */
    public with sharing class FieldWrapper {
        public String name;
        public String alias;
        public String score;
    }
}