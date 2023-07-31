/**
* File:         UpdateInvoiceAndCreatePdf_Trig_Test
* Project:      GreenField
* Created Date: 1/22/2020
* Created By:   Yash Gupta
* *******************************************************************************************************
* @description : Test Class for Trigger_ChangeRequest, TriggerInterface_ChangeRequest, UpdateInvoiceAndCreatePdf_Trig
* *******************************************************************************************************
* History:       
*/

@istest
private class UpdateInvoiceAndCreatePdf_Trig_Test{
    
    @istest static void updateInvoiceAndCreatePdfmethodOne(){
    
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'UpdateInvoiceAndCreatePdf_Trig' , Trigger_Name_Unique__c='UpdateInvoiceAndCreatePdf_Trig',Enabled__c=true,Object__c='Change_Request__c',Run_for_Recordypes__c='All',  Description__c='my test',Execution_Order__c=1,After_Insert__c=true);
        Insert trig;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');      
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_ChangeRequest obj = new TriggerInterface_ChangeRequest();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        TriggerInterfaceHelper.runTrigger('UpdateInvoiceAndCreatePdf_Trig','Change_Request__c',5, 'bi', null,null,'All'); 
        TriggerInterfaceHelper.runTrigger('UpdateInvoiceAndCreatePdf_Trig','Change_Request__c',5, 'bu', null,null,'All');
        
        
        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;

        // setup the Custom Settings
        
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = billingLegalEntity.Id;
        insert seriesObj;

        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            edition.Name = 'testEdition'+i;
            edition.Part_of_Series__c = seriesObj.Id;
            edition.Order_Creation__c = false;
            edition.Order_Activation__c = true;
            edition.Contract_Creation__c = true;
            edition.Invoice_Creation__c = true;
            listOfEditions.add(edition);
        }
        insert listOfEditions;
        
        // Create an Oppty
        Opportunity opp = new Opportunity(
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',  
            AccountId=acc.Id);
        insert opp;
        
        Change_Request__c chg = new Change_Request__c();
        chg.Account__c = acc.Id;
        chg.Edition__c = listOfEditions.get(0).Id;
        chg.Opportunity__c = opp.Id;
        chg.CurrencyISOCode = 'USD';
        chg.Change_Request_Status__c = 'New';
        chg.Amendment_Type__c = 'PO number change';
        insert chg;

        System.assertNotEquals(null, chg.Id, 'Insertion failed');
    }
}