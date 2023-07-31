/**
* File:         OpportunityNameUpdate_Trig_Test
* Project:      GreenField
* Created Date: 12/10/2019
* Created By:   Sachin Chaudhary
* *******************************************************************************************************
* @description : Test Class for Trigger_Opportunity, TriggerInterface_Opportunity, OpportunityNameUpdate_Trig
*/

@istest
private class OpportunityNameUpdate_Trig_Test {
    @isTest static void test() {
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'OpportunityNameUpdate_Trig' , Trigger_Name_Unique__c='OpportunityNameUpdate_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Insert__c=true,Before_Update__c=true);
        Insert trig;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');    
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_Opportunity obj = new TriggerInterface_Opportunity();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
       // string accountOnHoldID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity_Account_Unhold').getRecordTypeId();
       // system.debug('accountOnHoldID: '+accountOnHoldID);
        string recTypeId = [Select Id From RecordType Where sObjectType IN ('opportunity') LIMIT 1].Id;
        system.debug(LoggingLevel.DEBUG, 'recTypeId:'+recTypeId);
        TriggerInterfaceHelper.runTrigger('OpportunityNameUpdate_Trig','Opportunity',5, 'bi', recTypeId,null,'All'); 
        
         //Account Insert
        Account acc2 = new Account ();
        acc2.Name = 'Account2';
        acc2.BillingCity='test';
        acc2.BillingPostalCode='12342';
        acc2.BillingStateCode='UP';
        acc2.BillingCountryCode='IN';
        acc2.BillingStreet ='street2';
        acc2.Accounting_Credit_Hold__c ='OK';
        insert acc2;
        
        //Insert Legal Entity
        blng__LegalEntity__c entityObj = new blng__LegalEntity__c();
        entityObj.Name = 'TestLegal';
        entityObj.blng__Active__c = true;
        insert entityObj;
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = entityObj.Id;
        insert seriesObj;
        
        //Insert Edition
        Edition__c editionObj = new Edition__c();
        editionObj.Name = 'testEdition';
        editionObj.Part_of_Series__c = seriesObj.Id;
        insert editionObj;
        
        System.assertNotEquals(null, editionObj, 'Edition cannot be null');

             
        // Creates second opportunity
        Opportunity oppt2 = new Opportunity(Name ='New mAWS Deal2',Is_Barter_Opportunity__c  = true,Default_Edition__c = editionObj.Id, AccountID = acc2.ID, StageName = 'Qualification',CloseDate = System.today());
        insert oppt2;
        
        oppt2.Is_Barter_Opportunity__c  = False;
        update oppt2;
    }
}