/**
* Created By       :   Girikon(Sachin)
* Created On       :   18-12-2019
* @description     :   Test class to provide code coverage.          
* Apex Class       :   OppActionButtonController

* Modification log --
* Modified by      :  Girikon(Ashish) 26 Feb 2020 [IML2R-242] : Change picklist value from Financial Change to Financial
**/

@isTest
public class CalloutActionSubmitChange_test{
    static testmethod void validate(){
        Account acc = new Account();
        acc.name = 'test acc';
        acc.BillingCity ='Delhi' ;
        acc.BillingCountry='india';
        acc.BillingPostalCode='600075';
        acc.BillingState='Delhi';
        acc.BillingStreet='water well street';
        insert acc;
        Edition__c oEventEdition = new Edition__c(name = 'World of Concrete',Event_Code__c='woc17', 
                                                  Payment_Schedule__c= '50-50',CutoffDate_1__c= date.today().addDays(1),CutoffDate__c=date.today(), Approval_Service_Now_ID__c = 'test',
                                                  Tab1__c='esttt',Tab2__c='test',Tab3__c='test',Tab4__c='test',Tab5__c='test',Tab6__c='test',Tab7__c='testtt',Tab8__c='testtt');
        insert oEventEdition;
        
        Opportunity oOpportunity = new Opportunity(Name = 'Expocad Opportunity', CloseDate = Date.today(), StageName = 'Proposal', Default_Edition__c = oEventEdition.Id, AccountId = acc.Id);
        insert oOpportunity;
        oOpportunity.Status__c = 'Pending Change';
        update oOpportunity;
        System.AssertEquals('Proposal' , oOpportunity.StageName,'Error :: Stage should be Proposal'); 
        Change_Request__c c = new Change_Request__c();
        c.Account__c =  acc.Id;          
        c.Opportunity__c = oOpportunity.Id;
        c.Edition__c = oEventEdition.Id;
        c.Type_of_Change__c = 'PO number change';
        c.Product_Type__c = 'Non-Financial'; // updated Picklist Value [IML2R-242]
        insert c;
        
        Set<Id> soppIds = new Set<Id>();
        SoppIds.add(c.Id);
        Test.startTest();
        CalloutActionSubmitChange sc = new CalloutActionSubmitChange(soppIds);
        System.enqueueJob(sc);
        Test.stopTest();
        
    }
}