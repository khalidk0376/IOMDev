/*
* File:         PartialCredit_AdditionalInvoiceTest
* Project:      PoC SFDC Informa
* *******************************************************************************************************
* @description : Testing the PartielCreditNote.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 21/01/2020
* *******************************************************************************************************
*/
@isTest
public class PartialCredit_AdditionalInvoiceTest {
    
    private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(30),Date.toDay().addDays(60),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    
    // Setting up the database for the test
    @testSetup 
    static void setup() {
        Id standardPricebookId = Test.getStandardPricebookId();
        Integer maxTransactionsforOppty = 12;
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        String mileDelDateQuerypart='';
        String mileDelPercentQuerypart='';
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        
        // cut Off dates field Api name to construct the query part
        String cutOffDatesApiNameQuerypart ='';
        // cut Off Percentages field Api name to construct the query part
        String cutOffPercentageQuerypart ='';
        String cutOffApiName='CutoffDate_';
        // Create an account
        // Account acc = new Account(name='TESTACC',Payment_Term__c='Net 10');
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
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        blng__RevenueRecognitionRule__c revRecRule = TestDataFactory.setupRevRec(billingLegalEntity.Id);
        
        blng__BillingRule__c billingRule = TestDataFactory.setupBillingRule(billingLegalEntity.Id);
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRuleasNO(billingLegalEntity.Id);
        
        // create the product 
        Product2 product = TestDataFactory.createProduct2('product', billingRule, taxRule,  revRecRule);
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
       // create the product 
        Product2 product2 = TestDataFactory.createProduct2( 'product2',billingRule, taxRule,  revRecRule);
       // create the product 
        Product2 product3 = TestDataFactory.createProduct2('product3', billingRule, taxRule,  revRecRule);
       // create the product 
        Product2 product4 = TestDataFactory.createProduct2('product4', billingRule, taxRule,  revRecRule);
        final Id product4Id = product4.Id;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            for(Integer j=0;j<maxTransactionsforEdition;j++){
                if(j==0){
                    edition.put(cutOffApiName+'_c',cutOffDatesEdition[j]);
                }else{
                    edition.put(cutOffApiName+j+'__c',cutOffDatesEdition[j]);
                }
                edition.put(billingSchedulesApiNameEdition,billingSchedulesValue);
                edition.put(paymentTermApiNameEdition,'30');
            }
            listOfEditions.add(edition);
        }
        insert listOfEditions;
        
        // Create an Oppty
        Opportunity originalOppty = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',  
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            originalOppty.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            originalOppty.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        insert originalOppty;
        
        // create the quote
        SBQQ__Quote__c originalQuote = new SBQQ__Quote__c();
        originalQuote = TestDataFactory.buildTestSFCPQQuote('ORIGINAL',originalOppty.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        originalQuote.SBQQ__Primary__c = true; 
        originalQuote.SBQQ__PaymentTerms__c = 'Net 30'; 
        
        insert originalQuote;
        List<SBQQ__QuoteLine__c> listQuoteLine = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c originalQuoteLine = new SBQQ__QuoteLine__c();
        originalQuoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, originalQuote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        listQuoteLine.add( originalQuoteLine); 
        
        SBQQ__QuoteLine__c originalQuoteLine2 = new SBQQ__QuoteLine__c();
        originalQuoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, originalQuote.Id, priceBookEntry2.Id, 80,listOfEditions.get(0),1);
        listQuoteLine.add( originalQuoteLine2); 
        
        SBQQ__QuoteLine__c originalQuoteLine4 = new SBQQ__QuoteLine__c();
        originalQuoteLine4 = TestDataFactory.buildTestSFCPQQuoteLine(product4Id, originalQuote.Id, priceBookEntry2.Id, 150,listOfEditions.get(0),1);
        listQuoteLine.add( originalQuoteLine4);
        
        originalOppty.SBQQ__PrimaryQuote__c=originalQuote.Id;
        update originalOppty;
        
        // Create an Oppty
        Opportunity newOppty = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',  
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            newOppty.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            newOppty.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        
        insert newOppty;
        // setup the Custom Settings
        
        // create the quote
        SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
        newQuote = TestDataFactory.buildTestSFCPQQuote('NEW',newOppty.Id, acc.Id, standardPricebookId, 'Amendment',listOfEditions.get(0));
        newQuote.SBQQ__Primary__c = true; 
        newQuote.SBQQ__PaymentTerms__c = 'Net 30'; 
        
        insert newQuote;
        
        // create the quote lines
        
        //REMOVAL
        //SBQQ__QuoteLine__c newQuoteLine2 = new SBQQ__QuoteLine__c();
        //newQuoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, newQuote.Id, priceBookEntry2.Id, 80,listOfEditions.get(0),-1);
        //listQuoteLine.add( newQuoteLine2);
        
        //Donwgrade
        //SBQQ__QuoteLine__c newQuoteLineBoot = new SBQQ__QuoteLine__c();
        //newQuoteLineBoot = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, newQuote.Id, priceBookEntry1.Id, 0,listOfEditions.get(0),0);
        //insert newQuoteLineBoot;      
        //SBQQ__QuoteLine__c newQuoteLine3 = new SBQQ__QuoteLine__c();
        //newQuoteLine3 = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, newQuote.Id, priceBookEntry1.Id, 100,listOfEditions.get(0),1);
        //newQuoteLine3.SBQQ__Source__c=newQuoteLineBoot.Id;
        //listQuoteLine.add( newQuoteLine3);      
        
        
        //SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
        //newQuoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, newQuote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),-1);
        //newQuoteLine.SBQQ__Source__c=newQuoteLineBoot.Id;
        //listQuoteLine.add( newQuoteLine);
        
        
        //Additional
        //SBQQ__QuoteLine__c newQuoteLine4 = new SBQQ__QuoteLine__c();
        //newQuoteLine4 = TestDataFactory.buildTestSFCPQQuoteLine(product3.Id, newQuote.Id, priceBookEntry2.Id, 50,listOfEditions.get(0),1);
        //listQuoteLine.add( newQuoteLine4);
        
        //Upgrade 
        //SBQQ__QuoteLine__c newQuoteLineBoot2 = new SBQQ__QuoteLine__c();
        //newQuoteLineBoot2 = TestDataFactory.buildTestSFCPQQuoteLine(product4Id, newQuote.Id, priceBookEntry1.Id, 0,listOfEditions.get(0),0);
        //insert newQuoteLineBoot2;      
        
        //SBQQ__QuoteLine__c newQuoteLine6 = new SBQQ__QuoteLine__c();
        //newQuoteLine6 = TestDataFactory.buildTestSFCPQQuoteLine(product4Id, newQuote.Id, priceBookEntry1.Id, 150,listOfEditions.get(0),-1);
        //newQuoteLine6.SBQQ__Source__c=newQuoteLineBoot2.Id;
        //listQuoteLine.add( newQuoteLine6);
        
        //SBQQ__QuoteLine__c newQuoteLine5 = new SBQQ__QuoteLine__c();
        //newQuoteLine5 = TestDataFactory.buildTestSFCPQQuoteLine(product4Id, newQuote.Id, priceBookEntry1.Id, 300,listOfEditions.get(0),1);
        //newQuoteLine5.SBQQ__Source__c=newQuoteLineBoot2.Id; 
        //listQuoteLine.add( newQuoteLine5);      
        
        insert listQuoteLine;
        
        //newOppty.SBQQ__PrimaryQuote__c=newQuote.Id;
        //update newOppty;
    }
    
    
    @isTest
    static void testPartialCreditNoteTest1(){
        SBQQ__Quote__c originalQuote = Database.query('SELECT Id ,Amendment_Scenario_Type__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'ORIGINAL\'');
        SBQQ__Quote__c newQuote = Database.query('SELECT Id,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'NEW\'');
        
        List<SBQQ__QuoteLine__c> listQuoteLine = new List<SBQQ__QuoteLine__c>();
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry2 = [Select Id,Product2Id from PricebookEntry Where Pricebook2Id=:standardPricebookId and Product2.Name='product2'];
        PricebookEntry priceBookEntry1 = [Select Id,Product2Id from PricebookEntry Where Pricebook2Id=:standardPricebookId and Product2.Name='product'];
        Product2 product3 = [Select Id from Product2 Where Name='product3'];
        Product2 product4 = [Select Id from Product2 Where Name='product4'];
        Edition__c edition = [Select Id From Edition__c Limit 1];
        
        //REMOVAL
        SBQQ__QuoteLine__c newQuoteLine2 = new SBQQ__QuoteLine__c();
        newQuoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry2.Product2Id, newQuote.Id, priceBookEntry2.Id, 80,edition,-1);
        listQuoteLine.add( newQuoteLine2);
        
        //Donwgrade
        SBQQ__QuoteLine__c newQuoteLineBoot = new SBQQ__QuoteLine__c();
        newQuoteLineBoot = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 0,edition,0);
        insert newQuoteLineBoot;      
        SBQQ__QuoteLine__c newQuoteLine3 = new SBQQ__QuoteLine__c();
        newQuoteLine3 = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 100,edition,1);
        newQuoteLine3.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add( newQuoteLine3);      
        
        
        SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
        newQuoteLine = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 200,edition,-1);
        newQuoteLine.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add(newQuoteLine);
        
        
        //Additional
        SBQQ__QuoteLine__c newQuoteLine4 = new SBQQ__QuoteLine__c();
        newQuoteLine4 = TestDataFactory.buildTestSFCPQQuoteLine(product3.Id, newQuote.Id, priceBookEntry2.Id, 50,edition,1);
        listQuoteLine.add( newQuoteLine4);
        
        //Upgrade 
        SBQQ__QuoteLine__c newQuoteLineBoot2 = new SBQQ__QuoteLine__c();
        newQuoteLineBoot2 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 0,edition,0);
        insert newQuoteLineBoot2;      
        
        SBQQ__QuoteLine__c newQuoteLine6 = new SBQQ__QuoteLine__c();
        newQuoteLine6 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 150,edition,-1);
        newQuoteLine6.SBQQ__Source__c=newQuoteLineBoot2.Id;
        listQuoteLine.add( newQuoteLine6);
        
        SBQQ__QuoteLine__c newQuoteLine5 = new SBQQ__QuoteLine__c();
        newQuoteLine5 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 300,edition,1);
        newQuoteLine5.SBQQ__Source__c=newQuoteLineBoot2.Id; 
        listQuoteLine.add( newQuoteLine5);      
        insert listQuoteLine;
        
        Opportunity newOppty = new Opportunity(Id=newQuote.SBQQ__Opportunity2__c);
        newOppty.SBQQ__PrimaryQuote__c=newQuote.Id;
        update newOppty;
        
        Test.startTest();
        originalQuote.SBQQ__Ordered__c  = true;  
        update originalQuote;
        
        Order originalOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+originalQuote.Id+'\'');
        originalOrder.Status='Activated';
         originalOrder.Tax_Status__c = 'Tax Complete';
        update originalOrder;
        
        List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        if(billingScheduleFromBD == null || billingScheduleFromBD.size()==0 ){
            BillingTransactionGenerator.generateBillingTransaction(originalOrder);
        }
        
        newQuote.SBQQ__Ordered__c  = true;   
        newQuote.Amendment_Scenario_Type__c='PC/AI';
        
        update newQuote;
        
        Order newOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+newQuote.Id+'\'');
        
        
        // update originalOrder;
        List<OrderItem> listOriginalOrderItem = Database.query('SELECT  Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+originalOrder.Id+'\'');
        List<OrderItem> listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');
        
        
        billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        List<String> billingScheduleFromBDIds = new List<String>();
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            if(!billingScheduleFromBDIds.contains(bs.Id)){
                billingScheduleFromBDIds.add(bs.Id);
            } 
        }
        
        List<blng__BillingTransaction__c> billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        List<String> billngTransactionIds = new List<String>();
        
        for(blng__BillingTransaction__c bt : billingTransactionFromBD){
            if(!billngTransactionIds.contains(bt.Id)){
                billngTransactionIds.add(bt.Id);
            }
        }
        
        originalOrder.blng__BillNow__c=true;
        update originalOrder; 
        
        blng__Invoice__c originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        List<blng__InvoiceLine__c> billingTransactionInvoiceLines2 = Database.query('SELECT Id,blng__OrderProduct__r.Product2.Name,blng__Invoice__r.blng__BillToContact__c,blng__Invoice__c , blng__BillingTransaction__c FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c  in :billngTransactionIds ');
        for(blng__InvoiceLine__c line : billingTransactionInvoiceLines2){
            if(line.blng__OrderProduct__r.Product2.Name == 'product'
              || line.blng__OrderProduct__r.Product2.Name == 'product2'
              || line.blng__OrderProduct__r.Product2.Name == 'product4')
            line.blng__TaxAmount__c = 1;
        }
        update billingTransactionInvoiceLines2;
        
        originalInvoice.blng__TaxStatus__c  = 'Completed';
        originalInvoice.blng__InvoiceStatus__c ='Posted';	
        update originalInvoice;
        
        originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        System.assertEquals('Posted',originalInvoice.blng__InvoiceStatus__c,'Invoice is not Posted');  
        
        billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        
        List<blng__InvoiceLine__c> billingTransactionInvoiceLines = Database.query('SELECT Id,blng__Invoice__r.blng__BillToContact__c,blng__Invoice__c , blng__BillingTransaction__c FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c  in :billngTransactionIds ');
        
        System.assertNotEquals(billingTransactionInvoiceLines,null,'Invoice lines not created');  
        System.assertNotEquals(billingTransactionInvoiceLines.size(),0,'Invoice lines not created');  
        
        for(OrderItem newOrderItem : listNewOrderItem){
            for(OrderItem originalOrderItem : listOriginalOrderItem){
                
                if(newOrderItem.quantity<0  && newOrderItem.TotalPrice != originalOrderItem.TotalPrice && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Downgrad 
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }else if(newOrderItem.quantity<0 && newOrderItem.TotalPrice == originalOrderItem.TotalPrice  && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Removal
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }
            }
            
        }
        
        
        
        update listOriginalOrderItem;
        update listNewOrderItem;
     
        newOrder.Status='Activated';
         newOrder.Tax_Status__c = 'Tax Complete';
        update newOrder;
        
        listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');              
        
        billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
		       
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            for(blng__BillingTransaction__c bt : billingTransactionFromBD){
                if(!'Billed'.equals(bt.blng__Status__c) && bs.Id == bt.blng__BillingSchedule__c && (bs.blng__Amount__c== 100 || bs.blng__Amount__c == 80)){
                    System.assert(bt.blng__OverrideStatus__c!='test','Wrong Billing transaction status');      
                }
            }
        }
            
        Test.stopTest();     
    }
    
    
    @isTest
    static void testPartialCreditNoteTest2(){
        SBQQ__Quote__c originalQuote = Database.query('SELECT Id ,Amendment_Scenario_Type__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'ORIGINAL\'');
        SBQQ__Quote__c newQuote = Database.query('SELECT Id,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'NEW\'');
        
        List<SBQQ__QuoteLine__c> listQuoteLine = new List<SBQQ__QuoteLine__c>();
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry2 = [Select Id,Product2Id from PricebookEntry Where Pricebook2Id=:standardPricebookId and Product2.Name='product2'];
        PricebookEntry priceBookEntry1 = [Select Id,Product2Id from PricebookEntry Where Pricebook2Id=:standardPricebookId and Product2.Name='product'];
        Product2 product3 = [Select Id from Product2 Where Name='product3'];
        Product2 product4 = [Select Id from Product2 Where Name='product4'];
        Edition__c edition = [Select Id From Edition__c Limit 1];
        
        
        //Donwgrade
        SBQQ__QuoteLine__c newQuoteLineBoot = new SBQQ__QuoteLine__c();
        newQuoteLineBoot = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 0,edition,0);
        insert newQuoteLineBoot;      
        SBQQ__QuoteLine__c newQuoteLine3 = new SBQQ__QuoteLine__c();
        newQuoteLine3 = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 100,edition,1);
        newQuoteLine3.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add( newQuoteLine3);      
        
        
        SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
        newQuoteLine = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 200,edition,-1);
        newQuoteLine.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add(newQuoteLine);
        
        
        //Additional
        SBQQ__QuoteLine__c newQuoteLine4 = new SBQQ__QuoteLine__c();
        newQuoteLine4 = TestDataFactory.buildTestSFCPQQuoteLine(product3.Id, newQuote.Id, priceBookEntry2.Id, 50,edition,1);
        listQuoteLine.add( newQuoteLine4);
        
        //Upgrade 
        SBQQ__QuoteLine__c newQuoteLineBoot2 = new SBQQ__QuoteLine__c();
        newQuoteLineBoot2 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 0,edition,0);
        insert newQuoteLineBoot2;      
        
        SBQQ__QuoteLine__c newQuoteLine6 = new SBQQ__QuoteLine__c();
        newQuoteLine6 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 150,edition,-1);
        newQuoteLine6.SBQQ__Source__c=newQuoteLineBoot2.Id;
        listQuoteLine.add( newQuoteLine6);
        
        SBQQ__QuoteLine__c newQuoteLine5 = new SBQQ__QuoteLine__c();
        newQuoteLine5 = TestDataFactory.buildTestSFCPQQuoteLine(product4.Id, newQuote.Id, priceBookEntry1.Id, 300,edition,1);
        newQuoteLine5.SBQQ__Source__c=newQuoteLineBoot2.Id; 
        listQuoteLine.add( newQuoteLine5);      
        insert listQuoteLine;
        
        Opportunity newOppty = new Opportunity(Id=newQuote.SBQQ__Opportunity2__c);
        newOppty.SBQQ__PrimaryQuote__c=newQuote.Id;
        update newOppty;
        
        Test.startTest();
        
        originalQuote.SBQQ__Ordered__c  = true;  
        update originalQuote;
        
        Order originalOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+originalQuote.Id+'\'');
        originalOrder.Status='Activated';
         originalOrder.Tax_Status__c = 'Tax Complete';
        update originalOrder;
        
        List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        if(billingScheduleFromBD == null || billingScheduleFromBD.size()==0 ){
            BillingTransactionGenerator.generateBillingTransaction(originalOrder);
        }
        
        newQuote.SBQQ__Ordered__c  = true;   
        newQuote.Amendment_Scenario_Type__c='PC/AI';
        
        update newQuote;
        
        Order newOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+newQuote.Id+'\'');
        
        
        // update originalOrder;
        List<OrderItem> listOriginalOrderItem = Database.query('SELECT  Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+originalOrder.Id+'\'');
        List<OrderItem> listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');
        
        
        billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        List<String> billingScheduleFromBDIds = new List<String>();
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            if(!billingScheduleFromBDIds.contains(bs.Id)){
                billingScheduleFromBDIds.add(bs.Id);
            } 
        }
        
        List<blng__BillingTransaction__c> billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        List<String> billngTransactionIds = new List<String>();
        
        for(blng__BillingTransaction__c bt : billingTransactionFromBD){
            
            if(!billngTransactionIds.contains(bt.Id)){
                billngTransactionIds.add(bt.Id);
            }
            
        }
        
        
        //originalOrder.SBQQ__Contracted__c =true;
        //update originalOrder;
        originalOrder.blng__BillNow__c=true;
        update originalOrder; 
        
        blng__Invoice__c originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        originalInvoice.blng__TaxStatus__c  = 'Completed';
        update originalInvoice;
        
        originalInvoice.blng__InvoiceStatus__c ='Posted';	
        update originalInvoice;
        
        originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        System.assertEquals('Posted',originalInvoice.blng__InvoiceStatus__c,'Invoice is not Posted');  
        
        billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        
        
        
        
        List<blng__InvoiceLine__c> billingTransactionInvoiceLines = Database.query('SELECT Id,blng__Invoice__r.blng__BillToContact__c,blng__Invoice__c , blng__BillingTransaction__c FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c  in :billngTransactionIds ');
        
        System.assertNotEquals(billingTransactionInvoiceLines,null,'Invoice lines not created');  
        System.assertNotEquals(billingTransactionInvoiceLines.size(),0,'Invoice lines not created');  
        
        for(OrderItem newOrderItem : listNewOrderItem){
            for(OrderItem originalOrderItem : listOriginalOrderItem){
                
                if(newOrderItem.quantity<0  && newOrderItem.TotalPrice != originalOrderItem.TotalPrice && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Downgrad 
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }else if(newOrderItem.quantity<0 && newOrderItem.TotalPrice == originalOrderItem.TotalPrice  && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Removal
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }
            }
            
        }
        
        
        
        update listOriginalOrderItem;
        update listNewOrderItem;
     
        newOrder.Status='Activated';
         newOrder.Tax_Status__c = 'Tax Complete';
        update newOrder;
        
        listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');
        
        //System.assertNotEquals(listNewOrderItem.get(0).SBQQ__RevisedOrderProduct__c,null,'Wrong Revised Order Product');               
        
        billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
		       
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            for(blng__BillingTransaction__c bt : billingTransactionFromBD){
                if(!'Billed'.equals(bt.blng__Status__c) && bs.Id == bt.blng__BillingSchedule__c && (bs.blng__Amount__c== 100 || bs.blng__Amount__c == 80)){
                    System.assert(bt.blng__OverrideStatus__c!='test','Wrong Billing transaction status');      
                }
            }
        }
            
        Test.stopTest();     
    }
    
    @isTest
    static void testPartialCreditNoteTest3(){
        SBQQ__Quote__c originalQuote = Database.query('SELECT Id ,Amendment_Scenario_Type__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'ORIGINAL\'');
        SBQQ__Quote__c newQuote = Database.query('SELECT Id,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'NEW\'');
        
        List<SBQQ__QuoteLine__c> listQuoteLine = new List<SBQQ__QuoteLine__c>();
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry1 = [Select Id,Product2Id from PricebookEntry Where Pricebook2Id=:standardPricebookId and Product2.Name='product'];
        Edition__c edition = [Select Id From Edition__c Limit 1];
        
        
        //Donwgrade
        SBQQ__QuoteLine__c newQuoteLineBoot = new SBQQ__QuoteLine__c();
        newQuoteLineBoot = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 0,edition,0);
        insert newQuoteLineBoot;  
        
        SBQQ__QuoteLine__c newQuoteLine3 = new SBQQ__QuoteLine__c();
        newQuoteLine3 = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 100,edition,1);
        newQuoteLine3.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add( newQuoteLine3);  
        
        SBQQ__QuoteLine__c newQuoteLine = new SBQQ__QuoteLine__c();
        newQuoteLine = TestDataFactory.buildTestSFCPQQuoteLine(priceBookEntry1.Product2Id, newQuote.Id, priceBookEntry1.Id, 200,edition,-1);
        newQuoteLine.SBQQ__Source__c=newQuoteLineBoot.Id;
        listQuoteLine.add(newQuoteLine);
        
        insert listQuoteLine;
        
        Opportunity newOppty = new Opportunity(Id=newQuote.SBQQ__Opportunity2__c);
        newOppty.SBQQ__PrimaryQuote__c=newQuote.Id;
        update newOppty;
        
        Test.startTest();
        
        originalQuote.SBQQ__Ordered__c  = true;  
        update originalQuote;
        
        Order originalOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+originalQuote.Id+'\'');
        originalOrder.Status='Activated';
        originalOrder.Tax_Status__c = 'Tax Complete';
        update originalOrder;
        
        List<blng__BillingSchedule__c> billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        if(billingScheduleFromBD == null || billingScheduleFromBD.size()==0 ){
            BillingTransactionGenerator.generateBillingTransaction(originalOrder);
        }
        
        newQuote.SBQQ__Ordered__c  = true;   
        newQuote.Amendment_Scenario_Type__c='PC/AI';
        
        update newQuote;
        
        Order newOrder = Database.query('SELECT Id ,CurrencyIsoCode, Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+newQuote.Id+'\'');
        
        
        // update originalOrder;
        List<OrderItem> listOriginalOrderItem = Database.query('SELECT  Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+originalOrder.Id+'\'');
        List<OrderItem> listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');
        
        
        billingScheduleFromBD = Database.query('SELECT Name,Payment_Term_Reason__c,Billing_Schedule_Reason__c, blng__Amount__c,  blng__OrderProduct__c FROM blng__BillingSchedule__c WHERE blng__OrderProduct__r.OrderId =  \''+originalOrder.Id+'\' ');
        List<String> billingScheduleFromBDIds = new List<String>();
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            if(!billingScheduleFromBDIds.contains(bs.Id)){
                billingScheduleFromBDIds.add(bs.Id);
            } 
        }
        
        List<blng__BillingTransaction__c> billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        List<String> billngTransactionIds = new List<String>();
        
        for(blng__BillingTransaction__c bt : billingTransactionFromBD){
            if(!billngTransactionIds.contains(bt.Id)){
                billngTransactionIds.add(bt.Id);
            }
        }
        
        originalOrder.blng__BillNow__c=true;
        update originalOrder; 
        
        blng__Invoice__c originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        List<blng__InvoiceLine__c> billingTransactionInvoiceLines = Database.query('SELECT Id,blng__OrderProduct__r.Product2.Name,blng__Invoice__r.blng__BillToContact__c,blng__Invoice__c , blng__BillingTransaction__c FROM blng__InvoiceLine__c WHERE blng__BillingTransaction__c  in :billngTransactionIds ');
        blng__InvoiceLine__c invLine = null;
        for(blng__InvoiceLine__c line : billingTransactionInvoiceLines){
            if(line.blng__OrderProduct__r.Product2.Name == 'product'){
                invLine = line;
            }
        }
        invLine.blng__TaxAmount__c = 1;
        update invLine;
        
        originalInvoice.blng__TaxStatus__c  = 'Completed';
        originalInvoice.blng__InvoiceStatus__c ='Posted';	
        update originalInvoice;
        
        originalInvoice =  Database.query('SELECT blng__TaxStatus__c,Id,blng__InvoiceStatus__c , blng__Order__c  FROM blng__Invoice__c where blng__Order__c  = \''+originalOrder.Id+'\'');
        
        System.assertEquals('Posted',originalInvoice.blng__InvoiceStatus__c,'Invoice is not Posted');  
        
        
        
        
        blng.InvoiceAPI.creditInvoice(originalInvoice.Id, 'Cancel and Rebill');
            
        billingTransactionFromBD = Database.query('SELECT Id,blng__OverrideStatus__c,blng__BillingSchedule__r.blng__OrderProduct__r.Product2.Name,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
        boolean isFirst = false;
        for(blng__BillingTransaction__c bt : billingTransactionFromBD){
            if(!isFirst && bt.blng__BillingSchedule__r.blng__OrderProduct__r.Product2.Name == 'product')
            {
                isFirst = true;
                bt.PC_AI_Original_Invoice_Line__c = invLine.Id;
                bt.blng__OverrideStatus__c = 'Cancelled';
                bt.Amendment_Adjustment__c = 'Cancelled BT for Invoiced Amount';
            }
        }
        update billingTransactionFromBD;
        
        System.assertNotEquals(billingTransactionInvoiceLines,null,'Invoice lines not created');  
        System.assertNotEquals(billingTransactionInvoiceLines.size(),0,'Invoice lines not created');  
        
        for(OrderItem newOrderItem : listNewOrderItem){
            for(OrderItem originalOrderItem : listOriginalOrderItem){
                
                if(newOrderItem.quantity<0  && newOrderItem.TotalPrice != originalOrderItem.TotalPrice && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Downgrad 
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }else if(newOrderItem.quantity<0 && newOrderItem.TotalPrice == originalOrderItem.TotalPrice  && newOrderItem.Product2Id ==originalOrderItem.Product2Id ){
                    //Removal
                    newOrderItem.SBQQ__RevisedOrderProduct__c = originalOrderItem.Id;
                    // system.debug('--------- newOrderItem = '+newOrderItem.TotalPrice +' --- originalOrderItem = '+originalOrderItem.TotalPrice);
                }
            }
            
        }
        
        
        
        update listOriginalOrderItem;
        update listNewOrderItem;
     
        newOrder.Status='Activated';
         newOrder.Tax_Status__c = 'Tax Complete';
        update newOrder;
        
        listNewOrderItem = Database.query('SELECT Product_Invoice_property__c,Payment_Term__c,Issue_Date__c,Linked_Order_Item_for_PC_AI__c ,SBQQ__BundleRoot__c,Product2Id,SBQQ__RevisedOrderProduct__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+newOrder.Id+'\'');
        
        //System.assertNotEquals(listNewOrderItem.get(0).SBQQ__RevisedOrderProduct__c,null,'Wrong Revised Order Product');               
        
        billingTransactionFromBD = Database.query('SELECT blng__OverrideStatus__c,PC_AI_Original_Invoice_Line__r.blng__Invoice__c,PC_AI_Original_Invoice_Line__c ,Amendment_Adjustment__c ,CurrencyIsoCode,blng__BillingSchedule__c,blng__Amount__c , Name , blng__Status__c , blng__BillingTargetDate__c , Billing_sequence__c ,  Billing_Percentage__c , blng__Quantity__c FROM blng__BillingTransaction__c WHERE blng__BillingSchedule__c in :billingScheduleFromBDIds');
		       
        for(blng__BillingSchedule__c bs : billingScheduleFromBD){
            for(blng__BillingTransaction__c bt : billingTransactionFromBD){
                if(!'Billed'.equals(bt.blng__Status__c) && bs.Id == bt.blng__BillingSchedule__c && (bs.blng__Amount__c== 100 || bs.blng__Amount__c == 80)){
                    System.assert(bt.blng__OverrideStatus__c!='test','Wrong Billing transaction status');      
                }
            }
        }
            
        Test.stopTest();     
    }
    
}