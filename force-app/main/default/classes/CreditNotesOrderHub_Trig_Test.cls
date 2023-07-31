/**
* File      :   CreditNotesOrderHub_Trig_Test
* Project        :   Order & Billing Plateform 
* Created By  :   Suresh(Girikon)
* Created Date  :   30th Sept 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CreditNotesOrderHub_Trig(100%)
* Last Modified By :
*/
@isTest
public class CreditNotesOrderHub_Trig_Test
{
    // Setting up the database for the test
    @testSetup 
    static void setup() 
    {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        //creating test data for testing. 
        Trigger__c trig = new Trigger__c(Name = 'CreditNotesOrderHub_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Update__c = true,After_Update__c = true,Recursive_Execution_Allowed__c=true,Object__c = 'blng__CreditNote__c');
        insert trig;
        CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
        System.debug(LoggingLevel.DEBUG, obj);
        //Call trigger app handler for update event
        TriggerInterfaceHelper.runTrigger('CreditNotesOrderHub_Trig', 'blng__CreditNote__c', 1, 'bi',  null, null,'All'); 
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.BillingStreet = 'Test Street';
        acc.BillingCity = 'Test City';
        acc.BillingState = 'Delhi';
        acc.BillingPostalCode = '12345';
        acc.BillingCountry = 'India';
        insert acc;
        
        System.assertEquals('Test Account', acc.name,'true');
        
        API_Synchronization_Transaction__c  apiSyncTrans = new API_Synchronization_Transaction__c();
        ApiSyncTrans.Type__c = 'Create';
        ApiSyncTrans.Started_From__c = 'Order';
        ApiSyncTrans.X3rd_Party_ERP_System__c = 'Oracle';
        ApiSyncTrans.Status__c ='Queued';
        //ApiSyncTrans.Request_Type__c ='ApiSyncTrans'; 
        Insert ApiSyncTrans;
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
        
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
        
        Edition__c oEdition = new Edition__c(Name = 'Arab Health Exhibition and Congress Test',CurrencyIsoCode = 'USD', Edition_Code__c = 'arabh19',Part_of_Series__c = oSeries.id,Invoice_Posting__c=true);
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
        insert crNote;
    }
    
    @isTest static void testCreditNoteAPITrans() {
        blng__CreditNote__c crNote = [Select Id,blng__Status__c,Tax_Status__c FROM blng__CreditNote__c LIMIT 1];
        
        blng__BillingConfig__c disableBillingTrigger = new blng__BillingConfig__c(Name = 'DISABLE_TRIGGERS',
                                                                          blng__FieldType__c = 'Boolean',
                                                                          blng__Description__c = 'Disable triggers',
                                                                          blng__Category__c ='General',
                                                                          blng__BooleanValue__c = true);
        insert disableBillingTrigger;
        Test.startTest();
        crNote.blng__Status__c = 'Posted';
        crNote.Tax_Status__c = 'Tax Complete';
        update crNote;  
        Test.stopTest();
        
        Integer transCount = Database.countQuery('SELECT Count() FROM API_Synchronization_Item__c');
        System.assertNoTEquals(0, transCount,'NO API Synchronization Item Created');               
    } 
    
    @isTest static void testCreditNoteAPITrans2() {
        blng__CreditNote__c crNote = [Select Id,blng__Status__c,Tax_Status__c FROM blng__CreditNote__c LIMIT 1];
        blng__BillingConfig__c disableBillingTrigger = new blng__BillingConfig__c(Name = 'DISABLE_TRIGGERS',
                                                                          blng__FieldType__c = 'Boolean',
                                                                          blng__Description__c = 'Disable triggers',
                                                                          blng__Category__c ='General',
                                                                          blng__BooleanValue__c = true);
        insert disableBillingTrigger;
        
        Test.startTest();
        crNote.blng__Status__c = 'Posted';
        crNote.Tax_Status__c = 'Tax Complete';
        update crNote; 
        crNote.ERPSync_Status__c = 'Synced';
        crNote.ERPReference__c = 'T-0000000';
        update crNote;  
        Test.stopTest();
        
        Integer transCount = Database.countQuery('SELECT Count() FROM API_Synchronization_Item__c');
        System.assertNoTEquals(0, transCount,'NO API Synchronization Item Created');               
    } 
   
}