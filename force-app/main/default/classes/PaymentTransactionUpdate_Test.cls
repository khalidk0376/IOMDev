/**
* File			: 	PaymentTransactionUpdate_Test
* Project      	:   Order & Billing Platform
* Created By	: 	Bharath -IBM
* Created Date	: 	2 Jan 2023
* ******************************************************************************************************
* @description : Test Class to provide code covrage to class - PaymentTransactionUpdateBill_Trig
* Last Modified By :
*/
@isTest
private with sharing class PaymentTransactionUpdate_Test 
{
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
        //Create Trigger test records
        List<Trigger__c> listTriggers = new List<Trigger__c>();
        listTriggers.add(new Trigger__c(Name = 'PaymentTransactionRefund_Trig' , Trigger_Name_Unique__c='PaymentTransactionRefund_Trig',Enabled__c=true,Object__c='Payment_Transaction__c',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_insert__c=true));
        listTriggers.add(new Trigger__c(Name = 'PaymentTransactionUpdateBill_Trig' , Trigger_Name_Unique__c='PaymentTransactionUpdateBill_Trig',Enabled__c=true,Object__c='Payment_Transaction__c',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,After_insert__c=true,After_Update__c=true));

        Insert listTriggers;

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
        acc.Legacy_CRM_Instance__c = 'Penton';
        insert acc;
        

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
            edition.External_Tax_System__c = GlobalConstants.ONESOURCE;
            edition.External_Relationship__c = true; 
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
            Is_Barter_Opportunity__c = true,
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id,Ship_To_Account__c=acc.Id);
        
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
    }

    @isTest static void paymentTransactionUpdateBillTest()
    {
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        Order order = Database.query('SELECT Id,TotalAmount,AccountId,Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
		
        Contact con = TestDataFactoryUtils.createContact(order.AccountId);
        Insert con;
        
        blng__LegalEntity__c lglEntity = Database.query('SELECT Id from  blng__LegalEntity__c limit 1');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = order.AccountId;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.blng__BillToContact__c = con.Id;
        inv.blng__Order__c  = order.Id;
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
         blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        Product2 prd = Database.query('SELECT Id  FROM Product2 limit 1');
       // invLine.blng__OrderProduct__c = listOrderItem[0].Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billrule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = prd.Id;
        invLine.blng__InvoiceLineStatus__c = 'Draft';
        invLine.blng__TotalAmount__c=100;
        insert invLine;  
        
         Payment_Transaction__c pt = new Payment_Transaction__c();
        pt.Amount__c	= 10000;
       	pt.Order__c	=   order.Id;
       	pt.Card_Type__c	=	'Visa';
        pt.Payment_Method__c	=	'Credit Card';
       	pt.Payment_Status__c	=	'Success';
        pt.Payment_Type__c		= 	PaymentTransactionRefund_Trig.REFUND;
        pt.Authorization_Date__c=	DateTime.now();  
        pt.Invoice__c=inv.Id;
        insert pt;   
        
        pt.Amount__c	= 10001;
        update pt;
        
        TriggerInterface_PaymentTransaction obj = new TriggerInterface_PaymentTransaction();
        System.debug(LoggingLevel.DEBUG,obj);
        integer onHoldOrderItems = Database.Countquery('SELECT Count() FROM OrderItem WHERE  OrderId  = \''+order.Id+'\'');
        System.assertNotEquals(0,onHoldOrderItems,'Order Product hold Failed');
    }
}