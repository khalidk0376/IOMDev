/**
* File      	:   CreateAPISyncItemsforOpp_Trig_Test
* Project       : 	Informa Order Management 
* Created By  	:   Girikon(Ansh)
* Created Date  :   25th Feb 2022
******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CreateAPISyncItemsforOpportunity_Trig
******************************************************************************************************
* Last Modified By :
*/
@istest
private class CreateAPISyncItemsforOpp_Trig_Test {
    @testSetup 
    static void setup() 
    {
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'CreateAPISyncItemsforOpportunity_Trig' , Trigger_Name_Unique__c='CreateAPISyncItemsforOpportunity_Trig',Enabled__c=true,Object__c='Opportunity',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_Update__c=true);
        Insert trig;

        // Create an account
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.One_Invoice_Per_Contract__c = true;
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        //create an opportunity
        opportunity opp = new opportunity(Name='World of Concrete 2017',AccountId = acc.id,Amount=20.00,CloseDate=System.Today(),StageName='Closed Won',Probability = 100.00);
        insert opp;
    }

    @isTest
    private static void  testAccountAPITrasCreation()
    {
        opportunity opp = [Select Id,StageName from opportunity limit 1];
        opp.StageName = 'Closed Lost';
        update opp;
       
		integer itemCount = Database.countQuery('SELECT count() FROM API_Synchronization_Item__c WHERE Opportunity__c  = \''+opp.Id+'\'');
        System.assertNotEquals(0,itemCount,'API Synchronization Item not Created');

    }
}