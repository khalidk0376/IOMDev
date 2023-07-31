/**
* File:         OpportunityBillToAccount_Trig_Test
* Project:      GAP
* Created Date: 24 Feb 2020
* Created By:   Girikon(Garima Gupta)
* *******************************************************************************************************
* @description : Test Class for TriggerInterface_Opportunity, OpportunityBillToAccount_Trig
*/

@isTest
public with sharing class OpportunityBillToAccount_Trig_Test {
    
    // @description : Setting up all test data
    public static testMethod void test(){
        
        
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'OpportunityBillToAccount_Trig' , Trigger_Name_Unique__c='OpportunityBillToAccount_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Insert__c=true,After_Update__c=true);
        Insert trig;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');    
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_Opportunity obj = new TriggerInterface_Opportunity();
        
        //Call trigger app handler for insert event
       // string accountOnHoldID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity_Account_Unhold').getRecordTypeId();
       // system.debug('accountOnHoldID: '+accountOnHoldID);
        string recTypeId = [Select Id From RecordType Where sObjectType IN ('SBQQ__Quote__c') LIMIT 1].Id;
        system.debug('recTypeId:'+recTypeId);
        TriggerInterfaceHelper.runTrigger('OpportunityBillToAccount_Trig','Opportunity',5, 'bi', recTypeId,null,'All'); 
        
        Account accountObj = TestDataFactoryUtils.createAccount();
        accountObj.Legacy_CRM_Instance__c = 'Penton';
        insert accountObj;
        System.assertNotEquals(null, accountObj, 'Account Name and Billing Address cannot be null');
        
        Contact conObj = TestDataFactoryUtils.createContact(accountObj.Id);
        conObj.Legacy_CRM_Instance__c = 'Penton';
        insert conObj;
        
        APXTConga4__Conga_Template__c congaContractTemplObj = TestDataFactoryUtils.createCongaContractTemplate();
        insert congaContractTemplObj;
        
        APXTConga4__Conga_Template__c congaInvoiceTemplObj = TestDataFactoryUtils.createCongaInvoiceTemplate();
        insert congaInvoiceTemplObj;
        
        APXTConga4__Conga_Template__c congaQuoteTemplObj = TestDataFactoryUtils.createCongaQuoteTemplate();
        insert congaQuoteTemplObj;
        
        APXTConga4__Conga_Template__c congaCreditNoteTemplObj = TestDataFactoryUtils.createCongaCreditNoteTemplate();
        insert congaCreditNoteTemplObj;
        
        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        blng__LegalEntity__c legalEntityObj = TestDataFactoryUtils.createLegalEntity(congaContractTemplObj.Id, congaInvoiceTemplObj.Id, congaQuoteTemplObj.Id, congaCreditNoteTemplObj.Id);
        insert legalEntityObj;

        Series__c seriesObj = TestDataFactoryUtils.createSeries(legalEntityObj.Id);
        insert seriesObj;
        
        Edition__c editionObj = TestDataFactoryUtils.createEdition(seriesObj.Id, congaCreditNoteTemplObj.Id, congaInvoiceTemplObj.Id);
        editionObj.Part_of_Series__c = seriesObj.id;
        insert editionObj;
                
        Payment_Term_Code__c ptC = new Payment_Term_Code__c(Payment_Term_Code__c='PTC-01',Payment_Split_Percentage__c='25-25-25-25',Edition__c=editionObj.Id);
        insert ptC;
        
        Id standardPricebookId = Test.getStandardPricebookId();

        TestDataFactoryUtils.WrapperOpportunity wrpOpp = new TestDataFactoryUtils.WrapperOpportunity();
        wrpOpp.accountId = accountObj.Id;
        wrpOpp.seriesId = seriesObj.Id;
        wrpOpp.editionId = editionObj.Id;
        wrpOpp.contactId = conObj.Id;

        Opportunity opportunityObj = TestDataFactoryUtils.createOpportunity(wrpOpp);
        insert opportunityObj;
        ////opportunityObj.Invoice_to_be_issued_before_in_Days__c = '90';
        update opportunityObj;
                
    }
}