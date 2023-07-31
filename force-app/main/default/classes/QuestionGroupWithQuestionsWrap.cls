/**
* Created/Modified By    : Girikon(Mukesh)
* Created On             : 14 Sept, 2021
* @description           : Wrapper class that use in FormPreviewController
* Test Class             : FormPreviewController_Test 
* Code Coverage          : 90%

* Modification Log
* Modified by            : Girikon(Mukesh)
**/
public with sharing class QuestionGroupWithQuestionsWrap {
	
    /** wrapper class for Question Group **/    
    @AuraEnabled public String groupName{get;set;}
    @AuraEnabled public Boolean isShow{get;set;}
    @AuraEnabled public String sectionColNumber{get;set;}
    @AuraEnabled public String groupId{get;set;}
    @AuraEnabled public List<Question__c> lstQuestn{get;set;}
    @AuraEnabled public integer lstSize{get;set;}
    @AuraEnabled public List<String> col1QuestionIds;
    @AuraEnabled public List<String> col2QuestionIds;
    
    public QuestionGroupWithQuestionsWrap(){
        col1QuestionIds = new List<String>();
        col2QuestionIds = new List<String>();
    }
}