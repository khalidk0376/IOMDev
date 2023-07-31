/**
* File         :   IOM_CustomComponentsCtrl_Test 
* Project      :   Order & Billing Plateform [GECI-445]
* Created Date :   16th Jan 2023
* Created By   :   Girikon(Ashish)
* ************************************************************************************************
 @description : Test Class for IOM_CustomComponentsCtr
**************************************************************************************************
* Modification log :
* 1. 
*/
@isTest
public class IOM_CustomComponentsCtrl_Test {
    @testsetup
    static void createdata(){
        Id pricebookId = Test.getStandardPricebookId(); // StandardPricebook
        
        Product2 packagePrd = new Product2(Name = 'Booth Package');
        insert packagePrd; // Main Package Product
        
        PricebookEntry pbStndrdPriceP = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = packagePrd.Id, UnitPrice = 100, IsActive = true);
        insert pbStndrdPriceP;
        
        Account acc1 = new Account();
        acc1.Name='acc1';
        acc1.BillingCity ='Delhi' ;
        acc1.BillingCountry='india';
        acc1.BillingPostalCode='600075';
        acc1.BillingState='Delhi';
        acc1.BillingStreet='water well street';
        acc1.IOM_Account_No__c ='IM-0001';
        insert acc1;
        
        Contact oCon1 = new Contact();
        oCon1.FirstName = 'test';
        oCon1.LastName = 'ContTest11';
        oCon1.Email = 'abcd1@gmail.com';
        oCon1.AccountId = acc1.Id;
        oCon1.MailingStreet = 'Test1';
        oCon1.MailingCity = 'Test1';
        oCon1.MailingState='';
        oCon1.MailingCountry='India';
        oCon1.Phone = 'aa345564788a'; 
        oCon1.AssistantPhone = '+12445567788'; 
        oCon1.HomePhone = '+12345567388'; 
        oCon1.MobilePhone = '+12335567788'; 
        oCon1.OtherPhone = '+12346567788';
        insert oCon1;
        
    }

    @isTest static void testGetOpportunityRecord() {
        Account acc1 = [Select Id from Account limit 1];
        Product2 packagePrd = [Select Id from Product2 limit 1];
        PricebookEntry pbStndrdPriceP = [Select Id from PricebookEntry limit 1];

        List<Opportunity> opplst = new List<Opportunity>();
        opportunity opp = new opportunity(Name='World of Concrete 2017',AccountId = acc1.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
        opplst.add(opp);
        insert opplst;

        Opportunity opp2 = IOM_CustomComponentsCtrl.getOpportunityRecord('Id,name', opplst[0].id);
        System.assertNotEquals(null, opp2.Id,'Failed to find the opportunity');
    }
}