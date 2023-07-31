/**
* File			: CustomLookupLwcCtrl_Test
* Project		: Order & Billing Plateform  [GECI-236]
* Created Date	: 15th Dec 2022
* Created By   	: Girikon(Ashish)  
*****************************************************************************************************
@description : Test Class for CustomLookupLwcCtrl
******************************************************************************************************
* Modification log :
*/

@istest
private class CustomLookupLwcCtrl_Test {
	@isTest
    static void testAccountCreditStatusHold() {        
        // Create a test account
        Account acc = new Account ();
        acc.Name = 'My Test Account';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingStateCode='UP';
        acc.BillingCountryCode='IN';
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
		
        CustomLookupLwcCtrl.fetchDefaultRecord(acc.Id,'Account');
        string reqJSON = '{"sObjectApiName":"Account","labelFieldAPI":"Name","filterCondition":"","otherSearchFields":"Type"}';
		list<sObject> listAccs =  CustomLookupLwcCtrl.fetchLookupData('Account',reqJSON);
        system.assertEquals(listAccs.Size(),2,'No Account Record Found!');
    }
}