/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Use to create branching question 
* Test Class             : QuestionBranchingCtrl_Test 
* Code Coverage          : 90%

* Modification Log----- 
* Modified by            : Girikon(Mukesh)
**/
public with sharing class QuestionBranchingCtrl {
    /**
     * fetching Question_Questionnaire records 
     * @param  qnaireId    :Quenstionnaire id
     * @param  sectionId   : Question group id
     * @param  questnOrder : Question order
     * @param mainQuesQuetnnaireId: Question Questionnaire id
     * @return             : Question_Questionnaire records
     */
    @AuraEnabled
    public static List<Question_Questionnaire__c>  getAllQuestnQuestnnaire(String qnaireId,
        String sectionId,Integer questnOrder, 
        String mainQuesQuetnnaireId,String colnum) {
        
        List<Id> lstQQuestnniareId = new List<Id>();
        
        List<Questionnaire_Dynamic_Logic__c> lstQuestnnaireDynLogic = [SELECT Id,Question_Questionnaire__c,Show_Question_Questionnaire__c FROM Questionnaire_Dynamic_Logic__c WHERE Question_Group__c =:String.escapeSingleQuotes(sectionId) WITH SECURITY_ENFORCED];
        
        lstQQuestnniareId.add(mainQuesQuetnnaireId);
    
        for(Questionnaire_Dynamic_Logic__c objQDLogic : lstQuestnnaireDynLogic){
            if(objQDLogic.Question_Questionnaire__c != mainQuesQuetnnaireId){
                lstQQuestnniareId.add(objQDLogic.Question_Questionnaire__c);
                lstQQuestnniareId.add(objQDLogic.Show_Question_Questionnaire__c);
            }
        }
    
        questnOrder = QuestionBranchingCtrl.getQuestnQuestnniareOrder(mainQuesQuetnnaireId);
        
        List<Question_Questionnaire__c> lstQQuestnnaire = [SELECT id, Name, Question__c,Question__r.Label__c from Question_Questionnaire__c 
            WHERE Questionnaire__c =:String.escapeSingleQuotes(qnaireId) AND Question_Group__c =:String.escapeSingleQuotes(sectionId) AND Question__c != null AND Is_Allow_Branching__c =false
            AND question_order__c >=:questnOrder AND Related_To_Column__c=:String.escapeSingleQuotes(colnum) AND ID NOT IN :lstQQuestnniareId AND is_Delete__c=false WITH SECURITY_ENFORCED ORDER By question_order__c asc];
                
        return lstQQuestnnaire; 
    }
    
    public static Integer getQuestnQuestnniareOrder(String qQnniareID){
        Integer orderVal;
        if(String.isNotBlank(qQnniareID)){
            List<Question_Questionnaire__c> qqList =  [SELECT question_order__c FROM Question_Questionnaire__c WHERE Id=:String.escapeSingleQuotes(qQnniareID) WITH SECURITY_ENFORCED LIMIT 1];
            if(qqList.size()==0){
                orderVal=0;
            }
            else{
                orderVal = Integer.valueOf(qqList[0].question_order__c);
            }
        }
        return orderVal;
    }

    /**
     * fetching already branching questionnaire record
     * @param  sectionId            Question Grorp Id
     * @param  mainQuesQuetnnaireId Question Questionnaire Id
     * @return                      list of Questinniare dynamic logic record
     */
    @AuraEnabled
    public static List<Questionnaire_Dynamic_Logic__c>  getAlraedyBranching(String sectionId, String mainQuesQuetnnaireId) {                         
        return [SELECT Id,Question_Questionnaire__c,Question_Group__c,Question_Option__c,Show_Question_Questionnaire__c FROM
            Questionnaire_Dynamic_Logic__c WHERE Question_Group__c =:String.escapeSingleQuotes(sectionId) and Question_Questionnaire__c =:String.escapeSingleQuotes(mainQuesQuetnnaireId) WITH SECURITY_ENFORCED];                            
    }
    /**
     * Insert new branching record in questinnaire dynamic logic object.
     * Delete old branching record in questionniare dynamic logic object.
     * @param qnaireId               Questionnaire Id
     * @param sectionId              Question Group section
     * @param mainQuesQuetnnaireId   Question Questionnaire Id
     * @param lstQuestnnaireDynLogic List of Questionnaire Dynamic login object record
     * @param questionnaireOrder     Question Order Number.
     */
    @AuraEnabled
    public static void saveQuestnDynLogic(String qnaireId,String sectionId, String mainQuesQuetnnaireId,List<Questionnaire_Dynamic_Logic__c> lstQuestnnaireDynLogic,Integer questionnaireOrder){
        List<Questionnaire_Dynamic_Logic__c>  lstQDLogic = QuestionBranchingCtrl.getAlraedyBranching(sectionId, mainQuesQuetnnaireId);
        if(lstQuestnnaireDynLogic != null && lstQuestnnaireDynLogic.size()>0){            
            if(!lstQDLogic.isEmpty() && Schema.SObjectType.Questionnaire_Dynamic_Logic__c.isDeletable()){
                Delete lstQDLogic;
            }
            SObjectAccessDecision secDec = Security.stripInaccessible(AccessType.CREATABLE, lstQuestnnaireDynLogic);
            Insert secDec.getRecords();            
        }
    }
}