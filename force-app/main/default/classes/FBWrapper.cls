/**
 * TestClass: FormPreviewController_Test
 * Code Coverage : 100%
 */
public with sharing class FBWrapper {
	@AuraEnabled public QuestionGroupWithQuestionsWrap col1Questions;
    @AuraEnabled public QuestionGroupWithQuestionsWrap col2Questions;
    
    @AuraEnabled public String sectionColNumber;
    @AuraEnabled public String sectionName;    
    @AuraEnabled public Boolean isShow;

    public FBWrapper(){
        col1Questions = new QuestionGroupWithQuestionsWrap();
        col2Questions = new QuestionGroupWithQuestionsWrap();               
        sectionColNumber = '';
        sectionName ='';
        isShow=false;
    }
}