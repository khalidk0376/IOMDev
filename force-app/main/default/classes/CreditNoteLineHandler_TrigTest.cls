/**
* Raider Data Services, TT
* @description Test class for CreditNoteLineTrigger.
* Date: Date : 10/01/2019
*/
@isTest
private class CreditNoteLineHandler_TrigTest {
    @isTest
    /**
    * @description Method to test Add Sequence Number.
    */
    Public Static Void testLineNo(){
        //creating test data for testing.
        Trigger__c trig = new Trigger__c(Name = 'CreditNoteLineHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Insert__c = true,Object__c = 'blng__CreditNoteLine__c');
        insert trig;
        
        //Call account  trigger interface
        TriggerInterface_CreditNoteLine obj = new TriggerInterface_CreditNoteLine();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for update event
        TriggerInterfaceHelper.runTrigger('CreditNoteLineHandler_Trig', 'blng__CreditNoteLine__c', 1, 'bi',  null, null,'All'); 
        
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
        
        Product2 prod = new Product2();
        prod.Name = 'Product X';
        prod.ProductCode = 'Pro-X';
        prod.isActive = true;
        prod.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + Test + [Product2.IsActive]';
        insert prod;
        
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
        insert crNote;
                
        blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
        crNoteLine.blng__CreditNote__c = crNote.Id;
        crNoteLine.blng__Product__c = prod.id;
        crNoteLine.blng__TotalAmount__c = 10;
        insert crNoteLine;
        
        crNote.blng__Status__c = 'Posted'; 
        update crNote;      
        
        blng__CreditNoteLine__c blngcrNoteLine = [select id, name ,Line_Item_Number__c from blng__CreditNoteLine__c where id =:crNoteLine.Id];
    	System.assert(blngcrNoteLine.Line_Item_Number__c !=null ,'Line Item Number');
    }
    @isTest
    /**
    * @description Method to test Created Tax Lines.
    */
    Public Static void testcreateTaxLines(){      
        Trigger__c trig = new Trigger__c(Name = 'CreditNoteLineHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,After_Insert__c = true,Object__c = 'blng__CreditNoteLine__c');
        insert trig;
        
        //Call account  trigger interface
        TriggerInterface_CreditNoteLine obj = new TriggerInterface_CreditNoteLine();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for update event
        TriggerInterfaceHelper.runTrigger('CreditNoteLineHandler_Trig', 'blng__CreditNoteLine__c', 1, 'ai',  null, null,'All'); 
        
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
        
        Product2 prod = new Product2();
        prod.Name = 'Product X';
        prod.ProductCode = 'Pro-X';
        prod.isActive = true;
        prod.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + Test + [Product2.IsActive]';
        insert prod;
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__RevenueRecognitionRule__c revRecRule = TestDataFactory.setupRevRec(lglEntity.Id);
        
        blng__BillingRule__c billingRule = TestDataFactory.setupBillingRule(lglEntity.Id);
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRule(lglEntity.Id);
        
        Product2 product = new Product2();
        product = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        product.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + - +[SBQQ__ChargeType__c]+ - +[Product2.ProductCode]+ - +[Product2.Description]';
        product.Revenue_Recognition_End_Date_Rule__c = '[OrderItem.Edition__r.End_Date__c]';
        product.Revenue_Recognition_Start_Date_Rule__c = '[OrderItem.Edition__r.Start_Date__c]';
        update product;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        System.debug(LoggingLevel.DEBUG, priceBookEntry1);
        
        inv.Tax_Status__c = 'Tax Complete';
		inv.blng__InvoiceStatus__c = 'Posted';
        update inv;
        
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billingRule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = product.Id;
        invLine.blng__TotalAmount__c = 50.00;
        invLine.blng__InvoiceLineStatus__c = 'Posted';
        insert invLine;  
        
        blng__InvoiceLine__c invLine1 = new blng__InvoiceLine__c();
        invLine1.blng__Invoice__c = inv.Id;
        invLine1.blng__ChargeType__c = 'Recurring';
        invLine1.blng__BillingFrequency__c ='Invoice Plan';
        invLine1.blng__BillingRule__c =billingRule.Id ;
        invLine1.blng__TaxRule__c = taxRule.Id;
        invLine1.blng__Product__c = product.Id;
        invLine1.blng__TotalAmount__c = 60.00;
        invLine1.blng__InvoiceLineStatus__c = 'Posted';
        insert invLine1; 
        
        Tax_Lines__c taxLines = new Tax_Lines__c();
        taxLines.Tax_Code__c = 'GBVAT';
        taxLines.CurrencyIsoCode = 'USD';
        taxLines.Invoice_Line__c = invLine.Id;
        taxLines.Tax_Rate__c = 5.000000000;
        taxLines.Tax_Amount__c = 10.00;
        insert taxLines;        
       
        Tax_Lines__c taxLines1 = new Tax_Lines__c();
        taxLines1.Tax_Code__c = 'GBVAT';
        taxLines1.CurrencyIsoCode = 'USD';
        taxLines1.Invoice_Line__c = invLine.Id;
        taxLines1.Tax_Rate__c = 4.000000000;
        taxLines1.Tax_Amount__c = 10.00;
        insert taxLines1;
       
        Tax_Lines__c txlines = [select id,Tax_Rate__c,Tax_Amount__c from Tax_Lines__c where id=:taxLines.Id ];
        System.assert(txlines.Tax_Rate__c != NUll, 'Tax Rate Should not have been Null');
        System.assert(txlines.Tax_Amount__c != NUll, 'Tax Amount Should not have been Null');
        
        blng__CreditNote__c crNote = new blng__CreditNote__c();
        crNote.blng__Account__c = acc.id;
        crNote.blng__CreditNoteDate__c = Date.today();
        crNote.blng__Status__c = 'Draft';
        crNote.blng__RelatedInvoice__c = inv.Id;
        insert crNote;
                
        blng__CreditNoteLine__c crNoteLine = new blng__CreditNoteLine__c();
        crNoteLine.blng__InvoiceLine__c = invLine.Id;
        crNoteLine.blng__CreditNote__c = crNote.Id;
        crNoteLine.blng__Product__c = prod.id;
        crNoteLine.blng__TotalAmount__c = 10;
        insert crNoteLine;
                                            
        crNote.blng__Status__c = 'Posted'; 
        update crNote;  
                                       
    }
}