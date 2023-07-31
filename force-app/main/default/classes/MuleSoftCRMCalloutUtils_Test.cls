/**
* File      	:   MuleSoftCRMCalloutUtils_Test
* Project       : 	Informa Order Management 
* Created By  	:   Girikon(Ashish)
* Created Date  :   03rd Feb 2022
******************************************************************************************************
* @description : Test Class to provide code covrage to classes - MuleSoftCRMCalloutUtils,
******************************************************************************************************
* Last Modified By :
*/
@istest
private class MuleSoftCRMCalloutUtils_Test {
    @testSetup 
    static void setup() 
    {        
        Id standardPricebookId = Test.getStandardPricebookId();
        // Create an account
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
        acc.One_Invoice_Per_Contract__c = true;
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        Translated_Record__c tr = new Translated_Record__c();
        tr.Translated_Contact_LastName__c =	'اسم الاختبار';
        tr.Account__c =	acc.Id;
        tr.Translated_Account_Name__c =	'اسم الاختبار';
        tr.Translated_Language__c =	'ar';
        tr.Translated_Billing_City__c =	'دبي';
        tr.Translated_Billing_Address_Line_1__c ='شارع الاختبار';
        tr.Translated_Billing_Country__c = 'الامارات العربية المتحدة';
        insert tr;
        
        Account_Tax_Number__c taxNm = new Account_Tax_Number__c();
        taxNm.Account__c = acc.Id;
        taxNm.Tax_ID__c = '12342';
        taxNm.Status__c = 'Valid';
        insert taxNm;
        
        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        blng__RevenueRecognitionRule__c revRecRule = TestDataFactory.setupRevRec(billingLegalEntity.Id);
        
        blng__BillingRule__c billingRule = TestDataFactory.setupBillingRule(billingLegalEntity.Id);
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRule(billingLegalEntity.Id);
        
        // create the product 
        Product2 product = new Product2();
        product = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
        
        // create the product 
        Product2 product2 = new Product2();
        product2 = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
        
        // Create Contact
        Contact oCon = new Contact(LastName = 'ContTest1',Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', AccountId = acc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', MailingCountry = 'India', Phone = '2423122323', AssistantPhone = '2423122323', HomePhone = '2121212121', MobilePhone = '2121212145', OtherPhone = '2154215421');
        insert oCon;

        Series__c oSeries = new Series__c(Name = 'Arab Health', CurrencyISOCode = 'USD');
        insert oSeries;
        
        Edition__c oEdition = new Edition__c(Name = 'Arab Health Exhibition and Congress Test',CurrencyIsoCode = 'USD', Edition_Code__c = 'arabh19',Part_of_Series__c = oSeries.id);
        insert oEdition;
        
        Opportunity oOpportunity = new Opportunity(Name = 'API Test Opportunity',Default_Edition__c =oEdition.Id ,CloseDate = Date.today(), StageName = 'Proposal', AccountId = acc.Id, Billing_Contact__c = oCon.Id, Bill_To_Account__c = acc.Id,Ship_To_Account__c = acc.Id);
        insert oOpportunity;
        
         // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('TESTQUOTECITY',oOpportunity.Id, acc.Id, standardPricebookId, 'Quote',oEdition);
        quote.SBQQ__Primary__c = true; 
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,oEdition,1);
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, quote.Id, priceBookEntry2.Id, 100,oEdition,-1);
        insert quoteLine2;
        
        oOpportunity.SBQQ__PrimaryQuote__c=quote.Id;
        update oOpportunity;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote;

        Order ord = [SELECT Id FROM Order LIMIT 1];

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.Id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = billingLegalEntity.Id;
        inv.blng__Order__c = ord.Id;
        inv.ERP_Sync_Status__c = 'Synced';
        inv.ERP_Reference__c = 'T-0000000';
        insert inv;
        
        inv.Tax_Status__c = 'Tax Complete';
		inv.blng__InvoiceStatus__c = 'Posted';
        update inv;
        
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = acc.id;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        crNote.ERPSync_Status__c = 'Synced';
        crNote.ERPReference__c = 'T-0000000';
        insert crNote;
    }

    @isTest
    private static void  testupdateAccountCreditStatus200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The account credit hold status has been successfully updated." } }';
        mapURIBody.put('/holdAccount','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        Account acc = [Select Id,Accounting_Credit_Hold__c from Account limit 1];
        acc.Accounting_Credit_Hold__c = 'Hold';
        update acc;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Account';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ACCOUNTING_CREDIT_STATUS;        
        item.Account__c   = acc.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Account__c  = \''+acc.Id+'\'');
        System.assertNotEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateAccountCreditStatus400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "Error", "message": "The account credit hold status updated failed." } }';
        mapURIBody.put('/holdAccount','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        Account acc = [Select Id,Accounting_Credit_Hold__c from Account limit 1];
        acc.Accounting_Credit_Hold__c = 'Hold';
        update acc;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Account';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ACCOUNTING_CREDIT_STATUS;        
        item.Account__c   = acc.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Account__c  = \''+acc.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateAccountCreditStatusLegacyCRMBlank()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The account credit hold status has been successfully updated." } }';
        mapURIBody.put('/holdAccount','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        Account acc = [Select Id,Accounting_Credit_Hold__c from Account limit 1];
        acc.Legacy_CRM_Instance__c = null;
        update acc;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Account';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ACCOUNTING_CREDIT_STATUS;        
        item.Account__c   = acc.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Account__c  = \''+acc.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateOppStageName200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The opp stagename has been successfully updated." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,StageName from opportunity limit 1];
        opp.StageName = 'Closed Lost';
        update opp;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PUT';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.OPPORTUNITY_CLOSED_LOST;        
        item.Opportunity__c   = opp.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Opportunity__c  = \''+opp.Id+'\'');
        System.assertNotEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateOppProductsInCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The opportunity product has been successfully updated." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        Order ord = [Select Id from Order limit 1];
        
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Order';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.OLI_START_END_AMOUNT_UPDATE;        
        item.Order__c   = ord.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Order__c  = \''+Ord.Id+'\'');
        System.assertNotEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateOppProductsInCRM400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "Error", "message": "The opportunity product updated failed." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        Order ord = [Select Id from Order limit 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.OLI_START_END_AMOUNT_UPDATE;        
        item.Order__c   = ord.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Order__c  = \''+ord.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
     @isTest
    private static void  testcreateAPISyncTransForUpdateInCRM()
    {
        Order ord = [Select Id from Order limit 1];
        
        Test.startTest();
            MuleSoftCRMCalloutUtils.createAPISyncTransForUpdateInCRM(ord.Id);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c,Type__c FROM API_Synchronization_Item__c WHERE Order__c  = \''+ord.Id+'\'');
        System.assertEquals(GlobalConstants.OLI_START_END_AMOUNT_UPDATE,item2.Type__c,'API Synchronization Type not correct');        
    }
    
    @isTest
    private static void  testupdateOppStageName400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "Error", "message": "The opp stagename updated failed." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,StageName from opportunity limit 1];
        opp.StageName = 'Closed Lost';
        update opp;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PUT';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.OPPORTUNITY_CLOSED_LOST;        
        item.Opportunity__c   = opp.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Opportunity__c  = \''+opp.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateAmendmentRequestStatus200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The Amendment Request has been successfully updated." } }';
        mapURIBody.put('/amend/iom2crm/changerequest','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
       opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=opp.AccountId,Opportunity__c=opp.Id,Product_Type__c='Financial'
                                                     ,Type_of_Change__c='Cancellation',New_Payment_Schedule__c='50-50'
                                                    ,Edition__c=Opp.Default_Edition__c);
        insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED ;        
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertNotEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateAmendmentRequestStatus400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "Error", "message": "The Amendment Request updated failed." } }';
        mapURIBody.put('/amend/iom2crm/changerequest','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=opp.AccountId,Opportunity__c=opp.Id,Product_Type__c='Financial'
                                                     ,Type_of_Change__c='Cancellation',New_Payment_Schedule__c='50-50'
                                                    ,Edition__c=Opp.Default_Edition__c);
        insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED ;        
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
     
    @isTest
    private static void  testupdateOpportunityRejectionNotes200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The Opportunity Rejection has been successfully updated." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
       opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.OPPORTUNITY_REJECTED ;        
        item.Opportunity__c  = Opp.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Opportunity__c  = \''+Opp.Id+'\'');
        System.assertNotEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testupdateOpportunityRejectionNotes400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "Error", "message": "The Opportunity Rejection updated failed." } }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Opportunity';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'PATCH';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.OPPORTUNITY_REJECTED ;
        item.Opportunity__c  = Opp.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Opportunity__c  = \''+Opp.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    /************************ Test IOM To CRM*****************************/
    /**@description PO Number Change Test*/
    @isTest 
    private static void  testUpdatedata01IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c,Amount from opportunity limit 1];
        opp.Total_No_of_payment__c = 1;
        opp.Milestone_1_Amount__c = opp.Amount;
        opp.Milestone_1_Delivery_Date__c = System.today();
        opp.Milestone_1_Percent__c = 100;
        update opp;
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='PO number change;Billing Schedule Change;VAT Registration Number Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Bill to Contact Details Change
    private static void  testUpdatedata02IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Bill to Contact Details Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Bill to Contact Details Change
    private static void  testUpdatedata02IOMtoCRM400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Bill to Contact Details Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.ERROR,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Account Name Change
    private static void  testUpdatedata03IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Account Name Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Shipping Address Change
    private static void  testUpdatedata04IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Shipping Address Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Billing Address Change
    private static void  testUpdatedata05IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Billing Address Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Bill To Account Change
    private static void  testUpdatedata06IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Bill To Account Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest // Ship To Account Change
    private static void  testUpdatedata07IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Ship To Account Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    @isTest // Campaign Run Dates Change
    private static void  testUpdatedata08IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Success", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c from opportunity limit 1];
        // Change to Campaign Run Dates Change
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Bill To Account Change',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest 
    private static void  testUpdatedata09IOMtoCRM200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "status": "Error", "message": "The data successfully updated." }';
        mapURIBody.put('/amend/iom2crm/createRecordsFromJson','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        opportunity opp = [Select Id,AccountId,Default_Edition__c,Amount from opportunity limit 1];
        opp.Total_No_of_payment__c = 1;
        opp.Milestone_1_Amount__c = opp.Amount;
        opp.Milestone_1_Delivery_Date__c = System.today();
        opp.Milestone_1_Percent__c = 100;
        update opp;
        
        Change_Request__c cr = new Change_Request__c(Account__c=Opp.AccountId,Opportunity__c=Opp.Id,Amendment_Type__c='Billing Options Update',Edition__c=Opp.Default_Edition__c);
		insert cr;
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Amendment Request';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
		item.Type__c    =   GlobalConstants.AMENDED_DATA_SYNC;
        item.Amendment_Request__c  = cr.Id;
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();
	
        API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Amendment_Request__c  = \''+cr.Id+'\'');
        System.assertEquals(GlobalConstants.COMPLETED,item2.Status__c,'API Synchronization Item not Procesed');        
    }

    @isTest
    private static void  testIOMDocumentRecord200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The JSON is validated successfully and being processed further." } }';
        mapURIBody.put('/erpReferenceNumber','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        blng__Invoice__c inv = [SELECT Id FROM blng__Invoice__c LIMIT 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM;        
        item.Invoice__c   = inv.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Invoice__c  = \''+inv.Id+'\'');
        System.assertEquals('Completed',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testIOMDocumentRecord400()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The JSON is validated successfully and being processed further." } }';
        mapURIBody.put('/erpReferenceNumber','400###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        blng__Invoice__c inv = [SELECT Id FROM blng__Invoice__c LIMIT 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Invoice';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM;        
        item.Invoice__c   = inv.Id;        
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Invoice__c  = \''+inv.Id+'\'');
        System.assertEquals('Error',item2.Status__c,'API Synchronization Item not Procesed');        
    }
    
    @isTest
    private static void  testIOMDocumentRecordCreditNote200()
    {
        Map<String,String> mapURIBody = new Map<String,String>();
        string resJSON = '{ "meta": { "status": "success", "message": "The JSON is validated successfully and being processed further." } }';
        mapURIBody.put('/erpReferenceNumber','200###'+resJSON);
        Test.setMock(HttpCalloutMock.class, new APISynchronization_Mock(mapURIBody));
        
        blng__CreditNote__c crd = [SELECT Id,blng__RelatedInvoice__c FROM blng__CreditNote__c LIMIT 1];
        
        API_Synchronization_Transaction__c apiSyncroTrs = new API_Synchronization_Transaction__c();
        apiSyncroTrs.Request_Type__c    = 'Asynchronous';
        apiSyncroTrs.Started_From__c    = 'Credit Note';
        apiSyncroTrs.Status__c          = 'Queued';
        insert apiSyncroTrs;

        API_Synchronization_Item__c item = new API_Synchronization_Item__c();
        item.API_Call_Type__c   =   'POST';
        item.Status__c          =   'Queued';
        item.Type__c    =   GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM;        
        item.Invoice__c   = crd.blng__RelatedInvoice__c;        
        item.Credit_Note__c   = crd.Id;            
        item.API_Synchronization_Transaction__c = apiSyncroTrs.Id;
        insert item;
       
		Test.startTest();
            Database.executeBatch(new APISynchronizationBatch(),1);
        Test.stopTest();

		API_Synchronization_Item__c item2 = Database.query('SELECT Id ,Status__c FROM API_Synchronization_Item__c WHERE Credit_Note__c  = \''+crd.Id+'\'');
        System.assertEquals('Completed',item2.Status__c,'API Synchronization Item not Procesed');        
    }
}