/**
* File      	:   InvoiceRESTService_Test
* Project       : 	Informa Order Management 
* Created By  	:   Suresh(Girikon)
* Created Date  :   20th Dec 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - InvoiceRESTService , InvoiceOutstandingBalanceRESTService,InvoiceCollectionNotesRESTService
* Last Modified By :
*/
@istest
private class InvoiceRESTService_Test {
    
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
        invoice.Ship_To_Account__c = acc.Id;
        invoice.blng__DueDate__c = Date.today();
        invoice.blng__InvoiceDate__c = Date.today();
        invoice.ERP_Reference__c = 'ERP-00000';
        invoice.blng__TargetDate__c = Date.today();
        insert invoice;
    }
    
    @isTest
    private static void  testInvoiceREST(){
        
        blng__Invoice__c inv = [Select Id,Name from blng__Invoice__c limit 1];
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/Invoice'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"invoiceNumber":"'+inv.Name+'","erpRefrence": "ERP-00788", "erpAccountNumber": {"billTo": "ERP-00001", "shipTo": "ERP-00002", "soldTo": "ERP-00003"}, "payments": [ { "paymentId": "txn_AzZl8HSSwHz4E25D", "paymentTransERPRefrence": "002365" } ]}');
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
            InvoiceRESTService.updateERPRefrenceNumOnInv();
        Test.stopTest();
        blng__Invoice__c invafter = [Select Id,Name,ERP_Reference__c from blng__Invoice__c limit 1];
        System.assertEquals('ERP-00788', invafter.ERP_Reference__c, 'Invoice updated successfully');
    }
    
    @isTest
    private static void  testInvoiceREST02(){
        
        blng__Invoice__c inv = [Select Id,Name,blng__Order__c from blng__Invoice__c limit 1];
        
        Payment_Transaction__c pt = new Payment_Transaction__c();
        pt.Order__c = inv.blng__Order__c;        
        pt.Card_Type__c	= 'VISA';
        pt.Gateway_Account_ID__c	=  'bsc001236qs';
        pt.Invoice__c		= inv.Id;
        pt.Payment_Method__c	= 'Online';
        pt.Payment_Type__c	= 'Credit Card';
        pt.Source_Payment_ID__c = 'txn_AzZl8HSSwHz4E25D';
        pt.ERP_Sync_Status__c = 'Sync Required';
        insert pt;

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/Invoice'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf('{"invoiceNumber":"'+inv.Name+'","erpRefrence": "ERP-00788", "erpAccountNumber": {"billTo": "ERP-00001", "shipTo": "ERP-00002", "soldTo": "ERP-00003"}, "payments": [ { "paymentId": "txn_AzZl8HSSwHz4E25D", "paymentTransERPRefrence": "T-1236698" } ]}');
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
            InvoiceRESTService.updateERPRefrenceNumOnInv();
        Test.stopTest();
        Payment_Transaction__c oldPT = [Select Id,Name,ERP_Reference__c from Payment_Transaction__c limit 1];
        System.assertEquals('T-1236698', oldPT.ERP_Reference__c, 'Payment Transaction updated successfully');
    }

    @isTest
    private static void  testInvoiceOutstandingBalance(){
        
        blng__Invoice__c inv = [Select Id,Name,ERP_Reference__c from blng__Invoice__c limit 1];
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Invoice__c = inv.Id;
        paySch.Payment_Schedule_Rows__c = '50% Payable by 12/27/2019 - 100.00';
        paySch.Amounts__c = 100.00;
        paySch.Due_Dates__c = date.today();
        paySch.Percentage__c = '50%';
        insert paySch;
        
        paySch = [select id,name from Payment_Schedule__c where id = :paySch.id LIMIT 1];
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InvoiceOutstandingBalance'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        req.requestBody = Blob.valueOf('{"invoiceNumber":"'+inv.ERP_Reference__c+'","outstandingBalance":350.5,"currencyISOCode":"USD","PaymentSchedules":[{"paymentScheduleNumber":"'+paySch.Name+'","outstandingBalance":0,"dueDate":"2021-12-21"},{"paymentScheduleNumber":"PS-0002","outstandingBalance":350.5,"dueDate":"2022-01-15"}]}');
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
            InvoiceOutstandingBalanceRESTService.updateOutstandingBalanceOnInv();
        Test.stopTest();
        blng__Invoice__c invafter = [Select Id,Name,Outstanding_Balance__c from blng__Invoice__c limit 1];
        System.assertNotEquals(0, invafter.Outstanding_Balance__c, 'Invoice updated successfully');
        
    }

    @isTest
    private static void  testInvoiceCollectionNotes(){
        
        blng__Invoice__c inv = [Select Id,Name from blng__Invoice__c limit 1];
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/InvoiceCollectionNotes'; 
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        req.requestBody = Blob.valueOf('{"invoiceNumber":"'+inv.Name+'","collectionNotes":[{"accountNumber":"0001","invoiceReferenceNumber":"006","noteID":"CN-005","note":"Test Note","type":"Callback","noteDate":"2019-08-18T00:00:00"},{"accountNumber":"0001","invoiceReferenceNumber":"006","noteID":"CN-008","note":"Test Note","type":"Callback","noteDate":"2021-11-18T00:00:00"}]}');
        RestContext.request = req;
        RestContext.response = res; 
        
        Test.startTest();
        InvoiceCollectionNotesRESTService.upsertCollectionNotesOnInv();
        Test.stopTest();
        Integer collectionNoteCount = Database.countQuery('Select Count() from Collection_Note__c where Invoice__c =\''+ inv.Id+'\'');
        System.assertEquals(2,collectionNoteCount, 'Collection Note uodated successfully');
    }
}