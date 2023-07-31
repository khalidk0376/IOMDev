/**
 * TestClass: AddQuestionInSectionCtrTest
 * Code Coverage : 98%
 */
public with sharing class AddQuestionInSectionCtr{
    /*** 
     * Save questions in saction 
	***/
    @AuraEnabled 
    public static boolean saveQstnInSection(String qquaireId,String selectedSectionId,String targetCol){
        boolean isUpdated=false;
        
        //Check isUpdateable for each objects and fields
                
        if(String.isNotBlank(qquaireId) && String.isNotBlank(selectedSectionId)){
            Question_Questionnaire__c qstnQuaire=[SELECT Id,Question__c, Question_Group__c,Is_Allow_Branching__c,Question_Order__c FROM Question_Questionnaire__c WHERE Id=:String.escapeSingleQuotes(qquaireId) WITH SECURITY_ENFORCED LIMIT 1];
            // When no question branching is available            
            Integer order=[SELECT count() from Question_Questionnaire__c WHERE Question_Group__c=:String.escapeSingleQuotes(selectedSectionId) WITH SECURITY_ENFORCED];
            if(qstnQuaire!=null && qstnQuaire.Is_Allow_Branching__c==false && qstnQuaire.Question_Group__c!=selectedSectionId){
                
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Related_To_Column__c.isUpdateable()){
                    qstnQuaire.Related_To_Column__c=targetCol;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Group__c.isUpdateable()){
                    qstnQuaire.Question_Group__c=selectedSectionId;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Order__c.isUpdateable()){
                    qstnQuaire.Question_Order__c=order+1;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    update qstnQuaire;
                }

                Question__c ques = [SELECT Id FROM Question__C WHERE Id=:String.escapeSingleQuotes(qstnQuaire.Question__c) WITH SECURITY_ENFORCED LIMIT 1];
                
                if(Schema.SObjectType.Question__c.fields.Related_To_Column__c.isUpdateable()){
                    ques.Related_To_Column__c = targetCol;
                }
                if(Schema.SObjectType.Question__c.isUpdateable()){
                    Update ques;
                }
                isUpdated=true;            
            }
            else if(qstnQuaire!=null && qstnQuaire.Question_Group__c!=selectedSectionId){
                // When question branching is available                                  
                List<String> questionIdList = new List<string>();
                List<Question__c> questionToUpdate = new List<Question__c>();

                List<String> lstChildQstnQuariIds=new List<String>();
                List<Questionnaire_Dynamic_Logic__c> lstQuestnnaireDynLogic = [SELECT Id,Question_Questionnaire__c,Question_Group__c,
                Question_Option__c,Show_Question_Questionnaire__c FROM
                Questionnaire_Dynamic_Logic__c WHERE Question_Questionnaire__c =:String.escapeSingleQuotes(qquaireId) WITH SECURITY_ENFORCED];
                for(Questionnaire_Dynamic_Logic__c qstnDynlgc:lstQuestnnaireDynLogic){
                    if(Schema.SObjectType.Questionnaire_Dynamic_Logic__c.fields.Question_Group__c.isUpdateable()){
                        qstnDynlgc.Question_Group__c=selectedSectionId;
                    }                        
                    lstChildQstnQuariIds.add(qstnDynlgc.Show_Question_Questionnaire__c);
                }
                
                List<Question_Questionnaire__c> lstQstnQuaire=[SELECT Id,Question__c,Question_Group__c,
                Is_Allow_Branching__c,Question_Order__c From Question_Questionnaire__c
                WHERE Id IN:lstChildQstnQuariIds WITH SECURITY_ENFORCED];
                Integer i=2;
                for(Question_Questionnaire__c childQstnQuaire:lstQstnQuaire){
                    if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Group__c.isUpdateable()){
                        childQstnQuaire.Question_Group__c=selectedSectionId;
                    }
                    if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Order__c.isUpdateable()){
                        childQstnQuaire.Question_Order__c=order+i;
                    }
                    i=i+1;
                    questionIdList.add(childQstnQuaire.Question__c);
                }
                
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Related_To_Column__c.isUpdateable()){
                    qstnQuaire.Related_To_Column__c=targetCol;
                }
                
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Group__c.isUpdateable()){
                    qstnQuaire.Question_Group__c=selectedSectionId;
                }
                if(Schema.SObjectType.Questionnaire_Dynamic_Logic__c.isUpdateable()){
                    update lstQuestnnaireDynLogic;
                }
                
                // Update order in parent
                if(Schema.SObjectType.Question_Questionnaire__c.fields.Question_Order__c.isUpdateable()){
                    qstnQuaire.Question_Order__c=order+1;
                }
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    update qstnQuaire;
                }
                questionIdList.add(qstnQuaire.Question__c);
                List<Question__c> ques2List = [SELECT Id FROM Question__c WHERE Id IN:questionIdList WITH SECURITY_ENFORCED];
                for(Question__c ques2 : ques2List)
                {
                    if(Schema.SObjectType.Question__c.Fields.Related_To_Column__c.isUpdateable()){
                        ques2.Related_To_Column__c = targetCol;
                    }
                    questionToUpdate.add(ques2);
                }                    
                if(Schema.SObjectType.Question__c.isUpdateable()){
                    update questionToUpdate;
                }
                
                // Update question order in childs                             
                if(Schema.SObjectType.Question_Questionnaire__c.isUpdateable()){
                    update lstQstnQuaire;
                }                           
                isUpdated=true;                    
            
            }        
        }
        return isUpdated;
    }
    
    @AuraEnabled 
    public static List<Question_Group__c> getQuestionGroups(String qnaireId){
        List<String> lstQstnGrpIds=new List<String>();
        List<Question_Group__c> lstQsthGroup = new List<Question_Group__c>();
        List<sobject> lstQQ = Database.query('SELECT Question_Group__c from Question_Questionnaire__c WHERE Questionnaire__c=\''+String.escapeSingleQuotes(qnaireId)+'\' AND is_delete__c=false WITH SECURITY_ENFORCED');
        for(sobject qq:lstQQ){
            lstQstnGrpIds.add(String.valueOf(qq.get('Question_Group__c')));
        }
        return [SELECT Id,Name,Sort_Order__c FROM Question_Group__c WHERE Id IN:lstQstnGrpIds WITH SECURITY_ENFORCED ORDER BY Sort_Order__c ASC];        
    }
    
    @AuraEnabled 
    public static List<Question_Group__c> updateQuestionGroupsSortingOrder(List<Question_Group__c> lstUpdatedQstnGrp){
        if(Schema.SObjectType.Question_Group__c.isUpdateable()){
            update lstUpdatedQstnGrp;
        }        
        return lstUpdatedQstnGrp;
    }
}