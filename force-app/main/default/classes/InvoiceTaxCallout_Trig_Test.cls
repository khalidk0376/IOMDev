/**
* File			: 	InvoiceTaxCallout_Trig_Test
* Project      	:   IOM
* Created By	: 	Deepak(Girikon)
* Created Date	: 	23-02-2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - InvoiceTaxCallout_Trig_Test(90%),Trigger_BLNG_InvoiceRun(96%),TriggerInterface_InvoiceRun(100%)
* Last Modified By :
*/
@isTest
private with sharing class InvoiceTaxCallout_Trig_Test {
    private static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
    private static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
    private static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
    private static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
    private static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    private static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    private static  String billingSchedulesApiNameOppty='Payment_Schedule__c';

    // Setting up the database for the test
    @testSetup 
    static void setup() 
    {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Integer maxTransactionsforOppty = 12;
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        // String mileDelDateQuerypart='';
        // String mileDelPercentQuerypart='';
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        
        // cut Off dates field Api name to construct the query part
        // String cutOffDatesApiNameQuerypart ='';
        // cut Off Percentages field Api name to construct the query part
        // String cutOffPercentageQuerypart ='';
        String cutOffApiName='CutoffDate_';
        
        // Trigger Record 
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'ActivateOrderAfterCalculate_Trig' , Trigger_Name_Unique__c='ActivateOrderAfterCalculate_Trig',Enabled__c=true,Object__c='Order',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_Update__c=true);
        Insert trig;

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
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRule(billingLegalEntity.Id);
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = billingLegalEntity.Id;
        insert seriesObj;
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++)
        {
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30');
            edition.Name = 'testEdition'+i;
            edition.Part_of_Series__c = seriesObj.Id;
            edition.Order_Creation__c = false;
            edition.Order_Activation__c = true;
            edition.Contract_Creation__c = true;
            edition.Invoice_Creation__c = true;
            for(Integer j=0;j<maxTransactionsforEdition;j++)
            {
                if(j==0)
                {
                    edition.put(cutOffApiName+'_c',cutOffDatesEdition[j]);
                }else
                {
                    edition.put(cutOffApiName+j+'__c',cutOffDatesEdition[j]);
                }
                edition.put(billingSchedulesApiNameEdition,billingSchedulesValue);
                edition.put(paymentTermApiNameEdition,'30');
            }
            listOfEditions.add(edition);
        }
        insert listOfEditions;
        
        // Create an Oppty
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c = listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }

        insert opp;
        
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
        
        // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('TESTQUOTECITY',opp.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        quote.SBQQ__Primary__c = true; 
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, quote.Id, priceBookEntry2.Id, 100,listOfEditions.get(0),-1);
        insert quoteLine2;
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote;
        
        Trigger__c trig2 = new Trigger__c(Name='InvoiceTaxCallout_Trig',Trigger_Name_Unique__c='InvoiceTaxCallout_Trig',Enabled__c=true,Object__c='blng__InvoiceRun__c',Run_for_Recordypes__c='All',Recursive_Execution_Allowed__c=true,Execution_Order__c=1,After_Update__c=true);
        Insert trig2;
    }

    @isTest 
    static void testInvoiceTax()
    {
        Test.startTest();
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule2 =  Database.query('SELECT Id  FROM blng__TaxRule__c');  

        blng__InvoiceRun__c run = new blng__InvoiceRun__c(blng__TargetDate__c=System.Today(),blng__Status__c='Started');
        insert run;
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        inv.blng__InvoiceRunCreatedBy__c = run.Id;
        insert inv;
        
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        
        List<blng__InvoiceLine__c> lstInvoiceLineInsert =  new List<blng__InvoiceLine__c>();
        for(OrderItem item :lstOrdItemInsert)
        {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
            invLine.blng__Invoice__c = inv.Id;
            invLine.blng__OrderProduct__c = item.Id;
            invLine.blng__ChargeType__c = 'Recurring';
            invLine.blng__BillingFrequency__c ='Invoice Plan';
            invLine.blng__BillingRule__c =billrule.Id ;
            invLine.blng__TaxRule__c = taxRule2.Id;
            invLine.blng__Product__c = item.Product2Id;
            invLine.blng__UnitPrice__c = 100;
            invLine.blng__Subtotal__c = 100;
            invLine.blng__TotalAmount__c = 100;
            invLine.blng__InvoiceLineStatus__c = 'Draft';
            lstInvoiceLineInsert.add(invLine);
        }
		insert lstInvoiceLineInsert;

        run.blng__Status__c = 'Completed with errors';
        update run;
        TriggerInterface_InvoiceRun newRun = new TriggerInterface_InvoiceRun();
        System.debug(LoggingLevel.DEBUG,newRun);
        Test.stopTest();
        List<API_Synchronization_Item__c> items = [SELECT Id FROM API_Synchronization_Item__c where Invoice__c =:inv.Id and Type__c=: GlobalConstants.TAX ];
        System.assertEquals(1,items.size(),'All items not created');
    }
}