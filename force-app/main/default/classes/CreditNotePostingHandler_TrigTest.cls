/**
 * Raider Data Services, TT
 * @description Test class for CreditNoteTrigger.
 * Date: Date : 10/01/2019
 */
@isTest
public class CreditNotePostingHandler_TrigTest {
	/**
     * @description setup data for test class.
	 */
    @testSetup static void setup() {
       
        //creating test data for testing.
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.BillingStreet = 'Test Street';
        acc.BillingCity = 'Test City';
        acc.BillingState = 'Delhi';
        acc.BillingPostalCode = '12345';
        acc.BillingCountry = 'India';
        insert acc;
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        inv.Tax_Status__c = 'Tax Complete';
        inv.blng__InvoiceStatus__c = 'Posted';
        update inv;

        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = acc.id;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        crNote.blng__CreditNoteDate__c = Date.today();
        insert crNote;
        
        Product2 prod = new Product2();
        prod.Name = 'Product X';
        prod.ProductCode = 'Pro-X';
        prod.isActive = true;
        prod.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + Test + [Product2.IsActive]';
        insert prod;

        blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
        crNoteLine.blng__CreditNote__c = crNote.Id;
        crNoteLine.blng__Product__c = prod.id;
        crNoteLine.blng__TotalAmount__c = 10;
        insert crNoteLine;
    }
    @isTest
    /**
     * @description Method to test Updation of Credit Note Number and Unique Sequence Number on credit Note.
     */
    public static void testCreditNoteNumberUpdation(){
        //creating test data for testing.
       
        Trigger__c trig = new Trigger__c(Name = 'CreditNotePostingHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Update__c = true, Before_Insert__c = true,Object__c = 'blng__CreditNote__c');
        trig.Recursive_Execution_Allowed__c = true;
        insert trig;
        
        TriggerInterface_CreditNote obj = new TriggerInterface_CreditNote();
        System.debug(LoggingLevel.DEBUG, obj);
		TriggerInterfaceHelper.runTrigger('CreditNotePostingHandler_Trig', 'blng__CreditNote__c', 1, 'bu',  null, null,'All');
        
        blng__CreditNote__c crNote = [Select id, blng__Account__c, blng__CreditNoteDate__c, blng__Status__c, blng__RelatedInvoice__c From blng__CreditNote__c Limit 1];
        crNote.blng__Status__c = 'Posted';
        update crNote;

        system.assert(obj!=null, 'error');
    }

    @isTest
    /**
     * @description Negative test method for Updation of Credit Note Number and Unique Sequence Number on credit Note
	 */
    public static void negativeTestCreditNoteNumberUpdation(){
        //creating test data for testing.
        
        Trigger__c trig = new Trigger__c(Name = 'CreditNotePostingHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Insert__c = true,Before_Update__c = true,Object__c = 'blng__CreditNote__c');
        insert trig;

        blng__CreditNote__c crNote = [Select id, blng__Account__c, Credit_Note_Number__c, blng__CreditNoteDate__c, blng__Status__c, blng__RelatedInvoice__c From blng__CreditNote__c Limit 1];
        crNote.blng__CreditNoteDate__c = Date.today()+3;
        update crNote;
        
        blng__CreditNote__c blngCrdNt = [Select id, Credit_Note_Number__c from blng__CreditNote__c where id=: crNote.id];
        system.assertEquals(blngCrdNt.Credit_Note_Number__c, null, 'Credit Note Number should have been NULL');
    }
    
    @isTest
    /**
     * @description Method to test Updation of Exchange Rates on credit Note
     */ 
    public static void updateExchangeRateTest(){
        //creating test data for testing.
        Trigger__c trig = new Trigger__c(Name = 'CreditNotePostingHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Insert__c = true,Before_Update__c = true,Object__c = 'blng__CreditNote__c');
        insert trig;
        
        blng__Invoice__c inv = [Select id, blng__Account__c, blng__InvoiceStatus__c, Legal_Entity__c from blng__Invoice__c Limit 1];
            
		blng__CreditNote__c crNote = [Select id, blng__Account__c, Credit_Note_Number__c, blng__CreditNoteDate__c, blng__Status__c, blng__RelatedInvoice__c From blng__CreditNote__c Limit 1];
        
        Product2 prod = new Product2();
        prod.Name = 'Product X';
        prod.ProductCode = 'Pro-X';
        prod.isActive = true;
        prod.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + Test + [Product2.IsActive]';
        insert prod;
        
        blng__CreditNoteLine__c crdLine = new blng__CreditNoteLine__c();
        crdLine.blng__TotalAmount__c = 60;
        crdLine.blng__BaseCurrencyFXRate__c = 100;
        crdLine.blng__CreditNote__c = crNote.Id;
        crdLine.blng__Product__c = prod.id;
        insert crdLine;
        
        crNote.blng__Status__c = 'Posted';
        update crNote;
        
        blng__CreditNote__c crdNote = [Select id, blng__RelatedInvoice__c from blng__CreditNote__c where blng__RelatedInvoice__c=: inv.id];
    	system.assertEquals(crdNote.blng__RelatedInvoice__c, inv.Id,'Base Exchange Rate of credit note should have been updated by Base Exchange Rate of Invoice');
    }
    @isTest
    /**
     * @description Method to test Updation of Credit Note Contract Number Field if Related Invoice has Contract Number
     */
    public static void testCreditNoteUpdation(){
        
        Trigger__c trig = new Trigger__c(Name = 'CreditNotePostingHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Update__c = true, Before_Insert__c = true,Object__c = 'blng__CreditNote__c');
        insert trig;
        
        TriggerInterface_CreditNote obj = new TriggerInterface_CreditNote();
        System.debug(LoggingLevel.DEBUG, obj);
        TriggerInterfaceHelper.runTrigger('CreditNotePostingHandler_Trig', 'blng__CreditNote__c', 1, 'bi',  null, null,'All');
        
        //creating test data for testing.
        Account accn = new Account();
        accn.Name = 'Test1 Account';
        accn.BillingStreet = 'Test Street';
        accn.BillingCity = 'Test City';
        accn.BillingState = 'Delhi';
        accn.BillingPostalCode = '12345';
        accn.BillingCountry = 'India';
        insert accn;
        
        blng__LegalEntity__c lglEnty = new blng__LegalEntity__c();
        lglEnty.Name = 'lgl1 Test';
        insert lglEnty;
        
        blng__Invoice__c invc = new blng__Invoice__c();
        invc.blng__Account__c = accn.id;
        invc.blng__InvoiceStatus__c = 'Draft';
        invc.Legal_Entity__c = lglEnty.Id;
        insert invc;
        
        invc.Tax_Status__c = 'Tax Complete';
        invc.blng__InvoiceStatus__c = 'Posted';
        update invc;

        blng__CreditNote__c crNt = new blng__CreditNote__c();
        crNt.blng__Account__c = accn.id;
        crNt.blng__CreditNoteDate__c = Date.today();
        crNt.blng__Status__c = 'Draft';
        crNt.blng__RelatedInvoice__c = invc.Id;
        crNt.blng__CreditNoteDate__c = Date.today();
        insert crNt;
        
        blng__CreditNote__c crdnt = [Select id, Contract_Number__c From blng__CreditNote__c where id=: crNt.id Limit 1];
        blng__Invoice__c invoice = [Select id, Contract_Number__c From blng__Invoice__c where id=: invc.id];
        System.assertEquals(invoice.Contract_Number__c, crdnt.Contract_Number__c, 'Contract Number on Credit Note should be same as on Its related Invoice');
    }
}