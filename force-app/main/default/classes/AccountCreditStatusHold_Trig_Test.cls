/**
* File:         AccountCreditStatusHold_Trig_Test
* Project:      GreenField
* Created Date: 11/18/2019
* Created By:   Yash Gupta
*****************************************************************************************************
@description : Test Class for Trigger_Account, TriggerInterface_Account, AccountCreditStatusHold_Trig
******************************************************************************************************
* History:       Modified by Yash Gupta [11/27/2019]
*/

@istest
public class AccountCreditStatusHold_Trig_Test {
    @isTest
    static void testAccountCreditStatusHold() {
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'AccountCreditStatusHold_Trig' , Trigger_Name_Unique__c='AccountCreditStatusHold_Trig',Enabled__c=true,Object__c='Account',Run_for_Recordypes__c='All',  Description__c='my test',Execution_Order__c=1,Before_Insert__c=true , Before_Update__c = true);
        Insert trig;
        
        Trigger__c trig1 = new Trigger__c(Name = 'AccountFieldUpdate_Trig' , Trigger_Name_Unique__c='AccountFieldUpdate_Trig',Enabled__c=true,Object__c='Account',Run_for_Recordypes__c='All',  Description__c='my test',Execution_Order__c=1,Before_Insert__c=true , Before_Update__c = true);
        Insert trig1;
        
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');      
        Insert rt;   
        
        //Call account  trigger interface
        TriggerInterface_Account obj = new TriggerInterface_Account();
        
        //Call trigger app handler for insert event
        /*string sAccountUnHoldID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AccountUnHold').getRecordTypeId();
        string sAccountOnHoldID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('AccountOnHold').getRecordTypeId();
        TriggerInterfaceHelper.runTrigger('AccountCreditStatusHold_Trig','Account',5, 'bi', null,null,'All'); 
        TriggerInterfaceHelper.runTrigger('AccountCreditStatusHold_Trig','Account',5, 'bu', null,null,'All');
        TriggerInterfaceHelper.runTrigger('AccountCreditStatusHold_Trig','Account',5, 'bu', sAccountUnHoldID,null,'All');
        TriggerInterfaceHelper.runTrigger('AccountCreditStatusHold_Trig','Account',5, 'bi', sAccountOnHoldID,null,'All');*/
        
        // Create a test account
        Account acc = new Account ();
        acc.Name = 'My Test Account';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingStateCode='UP';
        acc.BillingCountryCode='IN';
        acc.Legacy_CRM_Instance__c = 'GE';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Address_Status__c = 'Valid';
        insert acc;
        
        Account acc2 = new Account ();
        acc2.Name = 'Account2';
        acc2.currencyisocode='USD';
        acc2.BillingStreet ='street2';
        acc2.BillingCity='test';
        acc2.BillingStateCode='UP';
        acc2.BillingCountryCode='IN';
        acc2.BillingPostalCode='12342';
        acc2.Accounting_Credit_Hold__c = 'Ok';
        acc2.Legacy_CRM_Instance__c = 'Penton';
        insert acc2;
        System.assertEquals('Account2', acc2.name,'true');

        // Creates test Edition object
        Edition__c edi = new Edition__c();
        edi.Name = 'FirstOne';
        insert edi;

        // Creates first opportunity
        Opportunity oppt = new Opportunity(Name ='New mAWS Deal', AccountID = acc.ID, StageName = 'Discover', CloseDate = System.today(), CurrencyIsoCode= 'USD' , ForecastCategoryName='Pipeline', Default_Edition__c = edi.Id);
        insert oppt;
        
        // Creates second opportunity
        Opportunity oppt2 = new Opportunity(Name ='New mAWS Deal2', AccountID = acc2.ID, StageName = 'Discover',CloseDate = System.today(), CurrencyIsoCode= 'USD' , ForecastCategoryName='Pipeline', Default_Edition__c = Edi.Id);
        insert oppt2;
        
        acc.Name = 'Account New';
        acc.BillingStreet = 'test2';
        update acc;
    }
}