/**
* File      	:   CreditNoteRESTService_Test
* Project       : 	Informa Order Management 
* Created By  	:   Suresh(Girikon)
* Created Date  :   03th Feb 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CreditNoteRESTService
* Last Modified By :
*/
@istest
public with sharing class CreditNoteRESTService_Test {

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
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.One_Invoice_Per_Contract__c = true;
        acc.Payment_Term__c='Net 10';
        insert acc;
        //create invoice
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__Account__c = acc.Id;
        invoice.blng__DueDate__c = Date.today();
        invoice.blng__InvoiceDate__c = Date.today();
        invoice.blng__TargetDate__c = Date.today();
        insert invoice;
        
        invoice.Tax_Status__c = 'Tax Complete';
		invoice.blng__InvoiceStatus__c = 'Posted';
        update invoice;
        
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = acc.id;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = invoice.Id;
        insert crNote;
        
    }
    
    @isTest
    private static void  testRest(){
        String filterFieldAPI = GlobalConstants.getValue('Credit_Note_External_No_Field');
        filterFieldAPI = String.isNotBlank(filterFieldAPI)?filterFieldAPI:'Name';
        blng__CreditNote__c cn = Database.query('Select Id,'+filterFieldAPI+' from blng__CreditNote__c limit 1');
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/Credit'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
        CreditNoteRESTService.updateERPRefrenceNumOnCredit(String.valueof(cn.get(filterFieldAPI)),'ERP-0056987');
        Test.stopTest();
        blng__CreditNote__c cnafter = [Select Id,Name,ERPReference__c from blng__CreditNote__c limit 1];
        System.assertEquals('ERP-0056987', cnafter.ERPReference__c, 'Credit Note updated successfully');
    }
    
}