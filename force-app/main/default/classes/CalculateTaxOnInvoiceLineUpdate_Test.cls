/**
* File			: 	CalculateTaxOnInvoiceLineUpdate_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Deepak(Girikon)
* Created Date	: 	21th Sept 2021
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - CalculateTaxOnInvoiceLineUpdate_Trig(100%)
* Last Modified By :
*/
@isTest
private class CalculateTaxOnInvoiceLineUpdate_Test {
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
        
        
        // Create an Oppty
        

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
        
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }

        insert opp;
        
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
        
        Order order = Database.query('SELECT Id ,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');

        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;

        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule2 =  Database.query('SELECT Id  FROM blng__TaxRule__c');        
		
        List<OrderItem> lstOrdItemInsert =  new List<OrderItem>();
        integer num = 1;
        for(OrderItem item :Database.query('SELECT Id,Line_Item_Number__c,Product2Id  FROM OrderItem  WHERE OrderId = \''+order.Id+'\''))
        {
            item.Line_Item_Number__c = num;
            num++;
            lstOrdItemInsert.add(item);
        }
        update lstOrdItemInsert;
        
        list<Tax_Lines__c> listTaxLines = new list<Tax_Lines__c>();
        for(OrderItem oi:lstOrdItemInsert)
        {
            Tax_Lines__c taxLine = new Tax_Lines__c ();
            taxLine.Order_Product__c = oi.Id;
            taxLine.Tax_Rate__c = 6;
            taxLine.Tax_Code__c = 'USAPA';
            taxLine.Tax_Amount__c = 18.00;
            listTaxLines.add(taxLine);
        }
        insert listTaxLines;
        
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
        
        Trigger__c trig2 = new Trigger__c(Name='CalculateTaxOnInvoiceLineUpdate_Trig',Trigger_Name_Unique__c='CalculateTaxOnInvoiceLineUpdate_Trig',Enabled__c=true,Object__c='blng__InvoiceLine__c',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_Update__c=true);
        Insert trig2;
    }
    
    @isTest 
    static void testInvoiceTax()
    {
        Test.startTest();
        List<blng__InvoiceLine__c> listInvLine = [Select Id From blng__InvoiceLine__c];
        for(blng__InvoiceLine__c invLine : listInvLine){
            invLine.blng__TaxStatus__c = 'Queued';
        }
        update listInvLine;
        Test.stopTest();
        List<API_Synchronization_Item__c> items = [SELECT Id FROM API_Synchronization_Item__c];
        System.assertEquals(1,items.size(),'All items not created');
    }
    @isTest 
    static void testcloneInvoiceTax()
    {
        Map<Id,Id> mapOfOrdItemAndInvLineIds = new Map<Id,Id>();
        Set<Id> invLineIds = new set<Id>();
        Test.startTest();
        List<blng__InvoiceLine__c> listInvLine = [Select Id,blng__OrderProduct__c,blng__Invoice__c From blng__InvoiceLine__c];
        for(blng__InvoiceLine__c invLine : listInvLine){
            invLineIds.add(invLine.id);
            mapOfOrdItemAndInvLineIds.put(invLine.blng__OrderProduct__c,invLine.blng__Invoice__c);
        }
		CalculateTaxOnInvoiceLineUpdate_Trig.cloneTaxLines(mapOfOrdItemAndInvLineIds);
        Test.stopTest();
        Integer taxLinesCount = Database.countQuery('Select Count() FROM Tax_Lines__c WHERE Invoice_Line__c in:invLineIds');
        System.assertNotEquals(0, taxLinesCount, 'Tax Lines Not Copied');
    }
}