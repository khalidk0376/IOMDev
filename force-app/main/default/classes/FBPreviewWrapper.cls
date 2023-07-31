/**
 * TestClass: FormPreviewController_Test
 * Code Coverage : 100%
 */
public with sharing class FBPreviewWrapper {
	@AuraEnabled public List<FBWrapper> sectionList;
	@AuraEnabled public Questionnaire__c questionnaire;

	public FBPreviewWrapper(){
		sectionList = new List<FBWrapper>();
		questionnaire = new Questionnaire__c();
	}
}