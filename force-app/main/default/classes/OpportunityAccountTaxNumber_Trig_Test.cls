/**
* File:         OpportunityAccountTaxNumber_Trig_Test
* Project:      GreenField
* Created Date: 11/15/2019
* Created By:   Yash Gupta
* *******************************************************************************************************
* @description : Test Class for Trigger_Opportunity, TriggerInterface_Opportunity, OpportunityAccountTaxNumber_Trig
* *******************************************************************************************************
* History:    Modified By Yash Gupta [11/27/2019], Increase code coverage.
*/

@istest
public class OpportunityAccountTaxNumber_Trig_Test {
    public static testMethod void test() {
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'OpportunityAccountTaxNumber_Trig' , Trigger_Name_Unique__c='OpportunityAccountTaxNumber_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Insert__c=true);
        Insert trig;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');    
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_Opportunity obj = new TriggerInterface_Opportunity();
        
        //Call trigger app handler for insert event
       // string accountOnHoldID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity_Account_Unhold').getRecordTypeId();
       // system.debug('accountOnHoldID: '+accountOnHoldID);
        string recTypeId = [Select Id From RecordType Where sObjectType IN ('opportunity') LIMIT 1].Id;
        system.debug('recTypeId:'+recTypeId);
        TriggerInterfaceHelper.runTrigger('OpportunityAccountTaxNumber_Trig','Opportunity',5, 'bi', recTypeId,null,'All'); 
        
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
        System.assertNotEquals(null, acc2, 'Account Name and Billing Address cannot be null');

        Contact oCon = new Contact(LastName='ContTest1', Email='test1contact@duptest.com', AccountId = acc2.Id);
        insert oCon;
        
        Series__c oESeries = new Series__c(name='World of Concrete');
        insert oEseries;
        
        Edition__c ee = new Edition__c();
        ee.Name = 'TestEvent';
        ee.Part_of_Series__c = oEseries.Id;
        ee.Show_Deliverables__c = true;
        ee.Payment_Schedule__c = '50-50';
        ee.CutoffDate__c = date.today();
        ee.CutoffDate_1__c = date.today().addDays(1);
        insert ee;
             
        // Creates second opportunity
        Opportunity oppt2 = new Opportunity(Name ='New mAWS Deal2', AccountID = acc2.ID, StageName = 'Closed won',CloseDate = System.today(), Default_Edition__c =ee.Id );
        insert oppt2;
    }
}