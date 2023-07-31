/**
* File      	:   DeleteOverrideCtrl_Test
* Project       : 	Informa Order Management 
* Created By  	:   Ansh(Girikon)
* Created Date  :   23rd Jun 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - DeleteOverrideCtrl
* Last Modified By :
*/
@isTest
public class DeleteOverrideCtrl_Test {
	@isTest
    public static void ctrlMethod(){
        // Create Account
        Account acc = new Account(Name = 'Expocad Account', CurrencyIsoCode = 'USD',
        Phone = '2423122323');
        acc.BillingCity = 'Dubai';
        acc.BillingCountry = 'India';
        acc.BillingPostalCode = '00000';
        acc.BillingState = 'Delhi';
        acc.BillingStreet = 'Dubai Test Centre, Building No. 4 - Happiness St';        
        insert acc;
        DeleteOverrideCtrl.sId = acc.Id;
        ApexPages.StandardController sc = new ApexPages.standardController(acc);
        DeleteOverrideCtrl obj = new DeleteOverrideCtrl(sc);

    }
}