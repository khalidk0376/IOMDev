@isTest
public with sharing class caseCategoryMappingCtrl_Test {
    
     @isTest
     static void testData(){
         
        Case_Category__c objCaseCategory1 = new Case_Category__c(Name = 'Test Category1' , Level__c = 'L1');
        insert objCaseCategory1;
         
        Case_Category__c objCaseCategory2 = new Case_Category__c(Name = 'Test Category2' , Level__c = 'L2' , Parent_Category__c = objCaseCategory1.id);
        insert objCaseCategory2;
         
        Case_Category__c objCaseCategory3 = new Case_Category__c(Name = 'Test Category3' , Level__c = 'L3' , Parent_Category__c = objCaseCategory2.id);
        insert objCaseCategory3;
         
        Case objCase = new Case(Status ='New', Priority = 'Medium', Origin = 'Web',Category_1__c = objCaseCategory1.id ,Category_2__c = objCaseCategory2.id,Category_3__c= objCaseCategory3.id);
        insert objCase;
        System.AssertNotEquals(objCase, null, 'Case must not be null');
         
        LiveChatVisitor visitor = new LiveChatVisitor();
        insert visitor;
         
        LiveChatTranscript chatObj = new LiveChatTranscript(
            chatKey = '123',
            liveChatVisitorId = visitor.id,
            CaseId = objCase.Id
        );

        insert chatObj;
         
         test.startTest();
         CaseCategoryMappingCtrl.getCaseCategoryValues('L1' , null);
         CaseCategoryMappingCtrl.getCategoryValueOnCase(objCase.id);
         CaseCategoryMappingCtrl.getCategoryValueOnCase(chatObj.Id);
         
         test.stopTest();
    }
}