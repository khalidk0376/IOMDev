/**
* File:            Cls_amendContract_Test
* Project:         GAP
* Code Coverage:   89%
* Date:            Dec 31, 2019
* Created By:      Sachin Chaudhary
* *************************************************************************
* Description:     Test class for cls_amendContract.
* *************************************************************************
* History:
*/

@isTest(seeAlldata = false)
public class Cls_amendContract_Test {
    
    static testMethod void amendTest() {
        
        
        Trigger__c trig = new Trigger__c(Name = 'OpportunityNameUpdate_Trig' , Trigger_Name_Unique__c='OpportunityNameUpdate_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Insert__c=true,Before_Update__c=true);
        Insert trig;
        
        Application_Bypass__c oAB = new Application_Bypass__c(SetupOwnerId=UserInfo.getOrganizationId(), Bypass_Validation_Rules__c = True);
        Insert oAB ;
        
        Account oAccount = new Account();
        oAccount.Name='Expocad Account';
        oAccount.CurrencyIsoCode = 'USD';
        oAccount.Address_Status__c = 'Valid';
        oAccount.Name = 'Account2';
        oAccount.BillingCity='test';
        oAccount.Legacy_CRM_Instance__c = 'Penton';
        oAccount.BillingPostalCode='12342';
        oAccount.BillingStateCode='UP';
        oAccount.BillingCountryCode='IN';
        oAccount.BillingStreet ='street2';
        oAccount.Accounting_Credit_Hold__c ='OK';
        insert oAccount;
        
        System.assertEquals('Account2' , oAccount.Name, 'true');
        Contact oCon = new Contact(LastName='ContTest1', Legacy_CRM_Instance__c = 'Penton', Email='test1contact@duptest.com', AccountId = oAccount.Id, MailingStreet = 'Test',MailingCity ='Test',MailingState='',MailingCountry='India');
        insert oCon;
        
        User oUser = [SELECT Id FROM User WHERE Id = : UserInfo.getUserId()];
        
        Series__c oEventseries = new Series__c(Name = 'World Of Concrete', CurrencyISOCode = 'USD');
        insert oEventseries;
        
        Edition__c oEvent = new Edition__c(Name = 'World of Concrete 2017',Part_of_Series__c=oEventseries.Id,Approval_Service_Now_ID__c = '123', CurrencyIsoCode = 'USD', Event_Code__c = 'KDB,KDB2');
        insert oEvent;
        
        System.assertEquals('World of Concrete 2017' , oEvent.Name, 'true');
        
        Opportunity oOpportunity = new Opportunity(Name = 'Test Opp', CloseDate = Date.newInstance(2019, 11, 5),StageName = 'Proposal',Address_Status__c = 'Valid', Default_Edition__c = oEvent.Id, Series__c = oEventseries.Id, AccountId = oAccount.Id, Opportunity_Contact__c= oCon.Id,Bill_To_Account__c = oAccount.Id,Billing_Contact__c = oCon.Id);
        insert oOpportunity;
        
        SBQQ__Quote__c oQuote = new SBQQ__Quote__c(CurrencyIsoCode = 'USD', SBQQ__Status__c = 'Draft', SBQQ__Type__c = 'Quote', SBQQ__Opportunity2__c = oOpportunity.Id, SBQQ__Account__c = oAccount.Id, SBQQ__Primary__c = true);
        insert oQuote;
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prd1 = new Product2(Name = 'Post Draw Indoor Booth',Family = 'Booth', Expiry_Date__c = Date.today());
        insert prd1;
        Pricebook2 customPB = new Pricebook2(Name='ICRE', isActive=true);
        insert customPB;
        PricebookEntry stndrdPrice1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prd1.Id,UnitPrice = 100, IsActive = true);
        insert stndrdPrice1;
        PricebookEntry iCREPrice1 = new PricebookEntry(Pricebook2Id = customPB.Id, Product2Id = prd1.Id,UnitPrice = 200, IsActive = true);
        insert iCREPrice1;
        
        SBQQ__QuoteLine__c oQuoteLine = new SBQQ__QuoteLine__c(SBQQ__Quote__c = oQuote.Id, SBQQ__Product__c = prd1.Id, SBQQ__Quantity__c = 2, SBQQ__Number__c = 1, Line_Description__c = 'Test', Booth_Number__c = 'TESTBN3', Booth__c = True);
        insert oQuoteLine ;
        
        Contract oContract = new Contract(AccountId = oAccount.id,CustomerSignedId =oCon.Id ,StartDate = Date.today(), ContractTerm = 12, SBQQ__Opportunity__c = oOpportunity.id, SBQQ__Quote__c = oQuote.Id);
        insert oContract;
        
        Test.StartTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(oOpportunity);
        Apexpages.currentpage().getparameters().put('oppId' , oOpportunity.id);
        Cls_amendContract oAmendContract = new Cls_amendContract(sc);
        oAmendContract.amendContract();
        
        oOpportunity.StageName = 'Closed Won';
        oOpportunity.Main_Contract__c = null;
        update oOpportunity;
        oAmendContract.amendContract();
        
        
        oOpportunity.Main_Contract__c = oContract.id;
        update oOpportunity;
        oAmendContract.amendContract();
        
        oOpportunity.SBQQ__AmendedContract__c = oContract.id;
        update oOpportunity;
        oAmendContract.amendContract();
        
        oAmendContract.redirectOppty();
        Test.StopTest();
    }
}