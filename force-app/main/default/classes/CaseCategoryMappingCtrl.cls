/**
* File			: 	CaseCategoryMappingCtrl
* Project		: 	Service Console Informa
* Created By	: 	Garima Gupta(Girikon)
* Test Class	:  	CaseCategoryMappingCtrl_Test
* Coverage		:  	90%
* Created Date	: 	28th Jan 2021
 ******************************************************************************************************
* @description : class to fetch Categories on Case
 ******************************************************************************************************
* Last Modified By :
*/
public with sharing class CaseCategoryMappingCtrl {


    /**
    * @description : To Fetch Category Value from Case Category Object 
    * @param level
    * @param parentCategoryId
    * @return List<sObject>
    */
    @auraenabled
    public static List<sObject> getCaseCategoryValues(string level, string parentCategoryId) {
         
         string query;
         if(String.isNotBlank(parentCategoryId)){
            query = 'Select id,Name,Level__c,Parent_Category__c from Case_Category__c where level__c = : level and Parent_Category__c =: parentCategoryId ORDER BY Name';
         }
         else{
            query = 'Select id,Name,Level__c,Parent_Category__c from Case_Category__c where level__c = : level and Parent_Category__c =null ORDER BY Name';
         }

         return database.query(query);
    }
    
    
    /**
    * @description : To Fetch Category Value from Case Object 
    * @param recordId
    * @return Case
    */
    @AuraEnabled
    public static Case getCategoryValueOnCase(String recordId){
        Id importRecordId = recordId;
        Id caseId = recordId;
        If( importRecordId.getSObjectType().getDescribe().getName() == 'LiveChatTranscript' && Schema.sObjectType.LiveChatTranscript.isAccessible()){
            
            List<LiveChatTranscript> transcriptLst = new List<LiveChatTranscript>();
            transcriptLst = [Select Id,CaseId from LiveChatTranscript where id =: importRecordId WITH SECURITY_ENFORCED];
            caseId = !transcriptLst.isEmpty() ? transcriptLst[0].CaseId : null;
        }
      

        Case objCase = New Case();
        if (Schema.sObjectType.Case.fields.Category_1__c.isAccessible() && Schema.sObjectType.Case.fields.Category_2__c.isAccessible() && Schema.sObjectType.Case.fields.Category_3__c.isAccessible()) {
        objCase = [Select Id, Category_1__c,Category_2__c,Category_3__c,Category_1__r.Name,Category_2__r.Name,Category_3__r.Name from Case where id =: caseId WITH SECURITY_ENFORCED];
        }
        return objCase;
    }
}