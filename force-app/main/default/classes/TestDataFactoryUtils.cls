/**
* File:          TestDataFactoryUtils
* Project:       Greenfield 
* Created Date:  30 Jan 2020
* Created By:    Prashant(Girikon)
* *******************************************************************************************************
* @description : This class is used as a Test Data Factory for all test classes.
* *******************************************************************************************************
* History:       Yash Gupta(3/26/2020), Remove Event_Type__c, Invoice_Template__c, Credit_Note_Template__c field from edition obj inst.
*/

public with sharing class TestDataFactoryUtils {

    /**
    * @description Made a wrapper to get all the parameters required for Opportunity.
    */ 
    public class WrapperOpportunity
    {
        /**
        * @description For getting Account Id for Opportunity
        */
        public Id accountId{get;set;}
        /**
        * @description For getting Series Id for Opportunity
        */
        public Id seriesId{get;set;}
        /**
        * @description For getting Edition Id for Opportunity
        */
        public Id editionId{get;set;}
        /**
        * @description For getting Contact Id for Opportunity
        */
        public Id contactId{get;set;}
    }

    /**
    * @description Method is used for creating Account
    * @return Account
    */
    public static Account createAccount(){
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.CurrencyIsoCode = 'USD';
        testAccount.Phone = '2423122323';
        testAccount.BillingCountry='India';
        testAccount.BillingPostalCode='121212';
        testAccount.BillingCity='Noida';
        testAccount.BillingState='Uttar Pradesh';
        testAccount.BillingStreet='ABC';
        return testAccount;
    }

    /**
    * @description Method is used for creating Contact
    * @param accountId
    * @return Contact
    */
    public static Contact createContact(Id accountId){
        Contact testContact = new Contact();
        testContact.LastName = 'Test Contact';
        testContact.Email = 'test@test.com';
        testContact.AccountId = accountId;
        testContact.MailingStreet = 'Test';
        testContact.MailingCity = 'Test';
        testContact.MailingState = '';
        testContact.MailingCountry = 'India';
        testContact.Phone = '2423122323';
        testContact.AssistantPhone = '2423122323';
        testContact.HomePhone = '2121212121';
        testContact.MobilePhone = '2121212145';
        testContact.OtherPhone = '2154215421';
        return testContact;
    }

    /**
    * @description Method is used for creating Conga Contract Template
    * @return APXTConga4__Conga_Template__c
    */
    public static APXTConga4__Conga_Template__c createCongaContractTemplate() {
        APXTConga4__Conga_Template__c congaTemp = new APXTConga4__Conga_Template__c();
        congaTemp.APXTConga4__Name__c = 'Test Contract';
        congaTemp.APXTConga4__Template_Group__c = 'Contract';
        congaTemp.APXTConga4__Template_Type__c = 'Document';
        return congaTemp;
    }

    /**
    * @description Method is used for creating Conga Invoice Template
    * @return APXTConga4__Conga_Template__c
    */
    public static APXTConga4__Conga_Template__c createCongaInvoiceTemplate() {
        APXTConga4__Conga_Template__c congaTemp = new APXTConga4__Conga_Template__c();
        congaTemp.APXTConga4__Name__c = 'Test Invoice';
        congaTemp.APXTConga4__Template_Group__c = 'Invoice';
        congaTemp.APXTConga4__Template_Type__c = 'Document';
        return congaTemp;
    }

    /**
    * @description Method is used for creating Conga Quote Template
    * @return APXTConga4__Conga_Template__c
    */
    public static APXTConga4__Conga_Template__c createCongaQuoteTemplate() {
        APXTConga4__Conga_Template__c congaTemp = new APXTConga4__Conga_Template__c();
        congaTemp.APXTConga4__Name__c = 'Test Quote';
        congaTemp.APXTConga4__Template_Group__c = 'Quote';
        congaTemp.APXTConga4__Template_Type__c = 'Document';
        return congaTemp;
    }

    /**
    * @description Method is used for creating Conga Credit Note Template
    * @return APXTConga4__Conga_Template__c
    */
    public static APXTConga4__Conga_Template__c createCongaCreditNoteTemplate() {
        APXTConga4__Conga_Template__c congaTemp = new APXTConga4__Conga_Template__c();
        congaTemp.APXTConga4__Name__c = 'Test QCredit Noteuote';
        congaTemp.APXTConga4__Template_Group__c = 'Credit Note';
        congaTemp.APXTConga4__Template_Type__c = 'Document';
        return congaTemp;
    }

    /**
    * @description Method is used for creating Legal Entity
    * @param congaContractTemplId
    * @param congaInvoiceTemplId
    * @param congaQuoteTemplId
    * @param congaCreditNoteTemplId
    * @return blng__LegalEntity__c
    */
    public static blng__LegalEntity__c createLegalEntity(Id congaContractTemplId, Id congaInvoiceTemplId, Id congaQuoteTemplId, Id congaCreditNoteTemplId) {
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name = 'Test Legal';
        legalEntity.blng__Active__c=true; 
        legalEntity.blng__Country__c='USA';
        legalEntity.Contract_Template__c = congaContractTemplId;
        legalEntity.Invoice_Template__c = congaInvoiceTemplId;
        legalEntity.Quote_Template__c = congaQuoteTemplId;
        legalEntity.Credit_Note_Template__c = congaCreditNoteTemplId;
        return legalEntity;
    }

    /**
    * @description Method is used for creating Series
    * @param legalEntityId
    * @return Series__c
    */
    public static Series__c createSeries(Id legalEntityId){

        Series__c testSeries = new Series__c();
        testSeries.Name = 'Arab Health';
        testSeries.CurrencyISOCode = 'USD';
        testSeries.Legal_Entity__c = LegalEntityId;
        return testSeries;
    }

    /**
    * @description Method is used for creating Edition
    * @param seriesId
    * @param congaCreditNoteTemplId
    * @param congaInvoiceTemplId
    * @return Edition__c
    */
    public static Edition__c createEdition(Id seriesId, Id congaCreditNoteTemplId, Id congaInvoiceTemplId){
        Edition__c testEdition = new Edition__c(Name = 'Arab Health 2020');        
        testEdition.Approval_Service_Now_ID__c = '123';
        testEdition.CurrencyIsoCode = 'USD';
        testEdition.Edition_Code__c = 'KDB,KDB2';     
        testEdition.Part_Of_Series__c = seriesId;
        testEdition.Start_Date__c = Date.today();
        testEdition.End_Date__c = Date.today()+ 30;
        testEdition.Invoice_to_be_issued_before__c = '30';
        testEdition.Venue__c = 'abc';
        testEdition.Payment_Schedule__c = '25-25-25-25';
        testEdition.CutoffDate__c = Date.today();
        testEdition.CutoffDate_1__c = Date.today()+30;
        testEdition.CutoffDate_2__c = Date.today()+60;
        testEdition.CutoffDate_3__c = Date.today()+90;
        testEdition.CC_Emails__c = 'test@test.com';
        testEdition.Informa_Logo__c = 'testLogo';
        testEdition.Edition_Image_URL__c = 'testImage';
        testEdition.Logo_Shape__c = 'Rectangle';
        testEdition.Edition_Status__c  = 'Active';
        testEdition.No_Order_Creation__c = false;
        testEdition.Order_Creation__c = false;
        testEdition.Order_Creation__c = false;
        //testEdition.No_Invoicing__c = false;
        testEdition.Invoice_Creation__c = false;
        testEdition.Edition_Type__c = 'Conference';
        return testEdition;
    }

    /**
    * @description Method is used for creating Opportunity
    * @param opp
    * @return Opportunity
    */
    public static Opportunity createOpportunity(WrapperOpportunity opp){

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.CloseDate = Date.today();
        testOpportunity.StageName = 'Proposal';
        testOpportunity.Default_Edition__c = opp.editionId;
        testOpportunity.Series__c = opp.seriesId;
        testOpportunity.AccountId = opp.accountId;
        testOpportunity.Billing_Contact__c = opp.contactId;
        testOpportunity.Bill_To_Account__c = opp.accountId;
        testOpportunity.Address_Status__c = 'Valid';
        return testOpportunity;
    }
}