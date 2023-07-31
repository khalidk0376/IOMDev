/**
* File      	:   CreateAPISyncItemsforAccount_Trig_Test
* Project       : 	Informa Order Management 
* Created By  	:   Girikon(Ashish)
* Created Date  :   03rd Feb 2022
******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CreateAPISyncItemsforAccount_Trig
******************************************************************************************************
* Last Modified By :
*/
@istest
private class CreateAPISyncItemsforAccount_Trig_Test {
    @testSetup 
    static void setup() 
    {
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'CreateAPISyncItemsforAccount_Trig' , Trigger_Name_Unique__c='CreateAPISyncItemsforAccount_Trig',Enabled__c=true,Object__c='Account',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_Update__c=true);
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
    }

    @isTest
    private static void  testAccountAPITrasCreation()
    {
        Account acc = [Select Id,Accounting_Credit_Hold__c from Account limit 1];
        acc.Accounting_Credit_Hold__c = 'Hold';
        update acc;
       
		integer itemCount = Database.countQuery('SELECT count() FROM API_Synchronization_Item__c WHERE Account__c  = \''+acc.Id+'\'');
        System.assertNotEquals(0,itemCount,'API Synchronization Item not Created');

    }
    @isTest
    private static void  testAccountAPITrasCreation2()
    {
        Account acc = [Select Id,Oracle_Number__c from Account limit 1];
        acc.Oracle_Number__c = 'T-123';
        update acc;
       
		integer itemCount = Database.countQuery('SELECT count() FROM API_Synchronization_Item__c WHERE Account__c  = \''+acc.Id+'\'');
        System.assertNotEquals(0,itemCount,'API Synchronization Item not Created');

    }
}