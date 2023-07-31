/**
 * Created By       :   Girikon(Sachin)
 * Created On       :   Dec 18 2019
 * @description     :   This is the test class of OpportunityCtrl.    
 * Apex Class       :   OpportunityCtrl
 **/

@isTest
public class OpportunityDetailsCtrl_Test {
    
    static testMethod void opportunityCtrlTest()
    {
        User usr = [Select id from User where Id =: userInfo.getUserId()];
        System.assertNotEquals(null, usr.Id , 'Hello');
        
        Account acc1 = new Account();
        acc1.Name='acc1';
        acc1.BillingCity ='Delhi' ;
        acc1.BillingCountry='india';
        acc1.BillingPostalCode='600075';
        acc1.BillingState='Delhi';
        acc1.BillingStreet='water well street';              
        insert acc1;
        System.assertNotEquals(null, acc1.Id  , 'Hello');
        
        Account acc2 = new Account();
        acc2.Name='acc2';
        acc2.BillingCity ='Delhi' ;
        acc2.BillingCountry='india';
        acc2.BillingPostalCode='600075';
        acc2.BillingState='Delhi';
        acc2.BillingStreet='water well street';              
        insert acc2;
        System.assertNotEquals(null, acc2.Id , 'Hello');
        
        Contact oCon1 = new Contact();
        oCon1.FirstName = 'test';
        oCon1.Contact_Type__c = 'Invoice Contact';
        oCon1.LastName = 'ContTest11';
        oCon1.Email = 'abcd1@gmail.com';
        oCon1.AccountId = acc1.Id;
        oCon1.MailingStreet = 'Test1';
        oCon1.MailingCity = 'Test1';
        oCon1.MailingState='';
        oCon1.MailingCountry='India';
        oCon1.Phone = '+12345564788'; 
        oCon1.Inactive__c = false;
        oCon1.AssistantPhone = '+12445567788'; 
        oCon1.HomePhone = '+12345567388'; 
        oCon1.MobilePhone = '+12335567788'; 
        oCon1.OtherPhone = '+12346567788';
        insert oCon1;
        
        Series__c eentseries = new Series__c(Name = 'World Of Concrete', CurrencyISOCode = 'USD');
        insert eentseries;
        
        Edition__c ee = new Edition__c( name='Test Edition' );
        ee.Part_of_Series__c = eentseries.id;
        //ee.EventCurrency__c = 'USD';        
        insert ee;        
        
        EventCurrecies__c eventCurrency = new EventCurrecies__c (Name='USD',Event_Edition__c=ee.id);
        insert eventCurrency;
        ee.EventCurrency__c = eventCurrency.id;
        update ee; 
        
        opportunity opp = new opportunity(Name='World of Concrete 2017', Default_Edition__c=ee.id,AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Discover',CurrencyIsoCode=ee.EventCurrency__r.Name);
        Utility.isReviewProcess = true; 
        Utility.isRebookInProcess = true;
        insert opp;
        
        
        Test.startTest();
        OpportunityDetailsCtrl.getLookupDatas('Contact','Name', 'ContTest11', acc1.Id, acc2.Id, true,1,0);
        OpportunityDetailsCtrl.getCurrentUserDtls();
        OpportunityDetailsCtrl.getRecord(oCon1.Id, 'Contact', 'Phone');
        OpportunityDetailsCtrl.getEventCurrency(ee.Id);
        OpportunityDetailsCtrl.updateOpportunity(opp);
        OpportunityDetailsCtrl.getUserRecordAccess(usr.Id);
        //OpportunityDetailsCtrl.getAllExhibPaidByValues();
        OpportunityDetailsCtrl.getAllDatas(oCon1.Id, 'Contact', 'Phone');
        Test.stopTest();
    }
}