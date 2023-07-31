/**
* File			: 	TaxCategoryUpdate_Trig_Test
* Project      	:   IE ECOM
* Created By	: 	Ansh(Girikon)
* Created Date	: 	2th Sept 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - TaxCategoryUpdate_Trig,Trigger_AccountTaxNumber
* Last Modified By :
*/
@isTest
public class TaxCategoryUpdate_Trig_Test {
    @isTest
    public static void testUpdateCategory(){
        
        // Trigger Record 
        //Create Trigger test records
        List<Trigger__c> listTriggers = new List<Trigger__c>();
        listTriggers.add(new Trigger__c(Name = 'TaxCategoryUpdate_Trig' , Trigger_Name_Unique__c='TaxCategoryUpdate_Trig',Enabled__c=true,Object__c='Account_Tax_Number__c',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_insert__c=true,Before_update__c=true));
        
        Insert listTriggers;
        
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        Account_Tax_Number__c atn = new Account_Tax_Number__c(Account__c=acc.Id,Status__c='Valid',Tax_Country__c='US',
         Tax_ID__c='123',Tax_Number_Name__c='123',Start_Date__c=System.today(),End_Date__c=System.today());
        insert atn;
        
        TriggerInterface_AccountTaxNumber obj = new TriggerInterface_AccountTaxNumber();
        System.debug(LoggingLevel.DEBUG,obj);
        Account_Tax_Number__c atn1 = [Select Id,Tax_Category__c from Account_Tax_Number__c limit 1];
        System.assertEquals('US01',atn1.Tax_Category__c,'Tax category is not matching');
    }
}