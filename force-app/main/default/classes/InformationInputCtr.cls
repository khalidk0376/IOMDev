/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to create information type question 
* Test Class             : InformationInputCtr_Test 
* Code Coverage          : 100%

* Modification Log----- 
* Modified by            : Girikon(Mukesh)
**/
public with sharing class InformationInputCtr{
    /**
     * Create question and question questionnaire.
     * @param  qnaireId: Questionnaire id.
     * @param  qGroupId: Question group id.
     * @param  question: Question object values.
     * @param  qnaireName : Questionnaire name.
     * @param  qOrder: Order of question.
     * @param  colNumber: column number of question.
     */
    @AuraEnabled
    public static void createQuestnAndQuestnQnaire(String qnaireId,String qGroupId,Question__c question,String qnaireName,String qOrder,String colNumber,String colorCode,String textColor){
        String sQLib = NewCreateTemplateCtr.getDefaultQuestnLibraryId();
        if(Schema.SObjectType.Question__c.Fields.Related_To_Column__c.isCreateable()){
            question.Related_To_Column__c = colNumber;
        }
        
        if(String.isNotBlank( sQLib)){
            if(Schema.SObjectType.Question__c.Fields.Question_Library__c.isCreateable()){
                question.Question_Library__c = sQLib;
            }
            if(Schema.SObjectType.Question__c.Fields.Metadata__c.isCreateable()){
                question.Metadata__c=colorCode;
            }
            if(Schema.SObjectType.Question__c.Fields.Background_Color__c.isCreateable()){
                question.Background_Color__c = textColor;
            }
        } 
        
        qOrder = String.valueOf(FieldInputCtr.countQuestnQuestnnaireRecord(qnaireId, qGroupId));
        if(Schema.SObjectType.Question__c.Fields.Name.isCreateable()){
            question.Name = qOrder;
        }
        if(Schema.SObjectType.Question__c.isCreateable()){
            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Question__c>{question}); 
            Insert sd.getRecords();
            question = [SELECT Id,Type__c,Currency_Symbol__c,lookup_Object_API_Name__c,Required__c,Allow_Currency__c,Decimal_value__c,Help_Text__c,Help_Text_Required__c,Category__c,Allow_Attachments__c,Allow_Comment__c,Is_Allow_Branching__c,Max_Char_Length__c,Minimum_Value__c,Maximum_value__c,Step_Size__c,Default_Value__c FROM Question__c WHERE Id=:sd.getRecords()[0].Id WITH SECURITY_ENFORCED];
        }

        Question_Questionnaire__c oQQuesnaire   =   new Question_Questionnaire__c();
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Metadata__c.isCreateable()){
            oQQuesnaire.Metadata__c=colorCode;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Required__c.isCreateable()){
            oQQuesnaire.Required__c=question.Required__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Currency__c.isCreateable()){
            oQQuesnaire.Allow_Currency__c =question.Allow_Currency__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Decimal_value__c.isCreateable()){
            oQQuesnaire.Decimal_value__c =question.Decimal_value__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Related_To_Column__c.isCreateable()){
            oQQuesnaire.Related_To_Column__c=colNumber;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isCreateable()){
            oQQuesnaire.Help_Text__c=question.Help_Text__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text_Required__c.isCreateable()){
            oQQuesnaire.Help_Text_Required__c=question.Help_Text_Required__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Category__c.isCreateable()){
            oQQuesnaire.Category__c=question.Category__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Attachments__c.isCreateable()){
            oQQuesnaire.Allow_Attachments__c=question.Allow_Attachments__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Allow_Comment__c.isCreateable()){
            oQQuesnaire.Allow_Comment__c=question.Allow_Comment__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Questionnaire__c.isCreateable()){
            oQQuesnaire.Questionnaire__c = qnaireId;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Name.isCreateable()){
            oQQuesnaire.Name=qnaireName;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question_Group__c.isCreateable()){
            oQQuesnaire.Question_Group__c =qGroupId;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question__c.isCreateable()){
            oQQuesnaire.Question__c=question.id;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Question_Order__c.isCreateable()){
            oQQuesnaire.Question_Order__c=Integer.valueOf(qOrder);
        }
        if(Schema.SObjectType.Question_Questionnaire__c.Fields.Max_Char_Length__c.isCreateable()){
            oQQuesnaire.Max_Char_Length__c=(question.Max_Char_Length__c != null?question.Max_Char_Length__c:0);
        }

        if(String.isNotBlank(question.Currency_Symbol__c) && Schema.SObjectType.Question_Questionnaire__c.Fields.Currency_Symbol__c.isCreateable()){
            oQQuesnaire.Currency_Symbol__c=question.Currency_Symbol__c;
        }
        if(Schema.SObjectType.Question_Questionnaire__c.isCreateable()){            
            SObjectAccessDecision sd = Security.stripInaccessible(AccessType.CREATABLE, new List<Question_Questionnaire__c>{oQQuesnaire});
            Insert sd.getRecords();
            FieldInputCtr.sortQuestions(sd.getRecords()[0].Id,qnaireId,qGroupId,colNumber,Integer.valueOf(qOrder));
        }
    }
    /**
     * save edited Question and Question Questionniare record
     * @param  oQues: Question object values.
     * @param  qnaireId: Questionnaire id.
     * @param  sectionId: Question group(Section) Id.
     */
    @AuraEnabled
    public static void saveEditQuesRecord(Question__c oQues,String qnaireId,String sectionId) {
        if (oQues != null) 
        {
            if(oQues.Help_Text_Required__c==false && Schema.SObjectType.Question__c.Fields.Help_Text__c.isUpdateable()){
                oQues.Help_Text__c='';
            }
            if(Schema.SObjectType.Question__c.isUpdateable()){
                Update Security.stripInaccessible(AccessType.UPDATABLE, new List<Question__c>{oQues}).getRecords();                
            }
            
            List<Question_Questionnaire__c> lstQQnnaire = [Select Id,Allow_Attachments__c,Allow_Comment__c,Help_Text_Required__c,Help_Text__c,Category__c from Question_Questionnaire__c where Question__c=:oQues.id and Questionnaire__c=:String.escapeSingleQuotes(qnaireId) and Question_Group__c=:String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
            
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
                
                if(oQues.Help_Text_Required__c==true && Schema.SObjectType.Question_Questionnaire__c.Fields.Help_Text__c.isUpdateable()){lstQQnnaire[0].Help_Text__c=oQues.Help_Text__c;}
                if(String.isNotBlank(oQues.Currency_Symbol__c) && Schema.SObjectType.Question_Questionnaire__c.Fields.Currency_Symbol__c.isUpdateable()){lstQQnnaire[0].Currency_Symbol__c=oQues.Currency_Symbol__c;}
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
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    Update Security.stripInaccessible(AccessType.UPDATABLE, lstQQnnaire).getRecords();
                }
            }
        } 
    }
    
    /**
     * fetch Question Currency Symbols picklist value
     * @return : list of Question Currency sysmbol.
     */
    @AuraEnabled
    public static List<String> getQueCurrencySymbol(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Question__c.Currency_Symbol__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
        return options;
    }
}