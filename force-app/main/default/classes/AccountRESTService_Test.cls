/**
* File      	:   AccountRESTService_Test
* Project       : 	Informa Order Management 
* Created By  	:   Girikon(Ashish)
* Created Date  :   03rd Feb 2022
******************************************************************************************************
* @description : Test Class to provide code covrage to classes - AccountCreditStatusRESTService
******************************************************************************************************
* Last Modified By :
*/
@istest
private class AccountRESTService_Test {
    @testSetup 
    static void setup() 
    {
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
    private static void  testAccountCreditStatusRESTService()
    {
        Account acc = [Select Id,IM_Account_No__c from Account limit 1];
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/accountcreditstatus'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
            AccountCreditStatusRESTService.updateCreditStatusOnAccount(acc.IM_Account_No__c,'Hold');
        Test.stopTest();

        Account accafter = [Select Id,Accounting_Credit_Hold__c from Account limit 1];
        System.assertEquals('Hold', accafter.Accounting_Credit_Hold__c, 'Accounting Credit Status updated successfully');
    }
}