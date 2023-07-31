/**
* File         :   IOM_ConnectionCallbackCtrl_Test 
* Project      :   Order & Billing Plateform
* Created Date :   24th Jan 2022
* Created By   :   Girikon(Ashish)
* ******************************************************************************************************
 @description : Test Class to cover OppLtngOutUtils
*******************************************************************************************************
* Modification log :Girikon(Deepak), GECI-835, 20th Feb 2023
* 1. 
*/
@isTest
private with sharing class OppLtngOutUtils_Test 
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
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id,Bill_To_Account__c=acc.Id);
        
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
        
        Order order = Database.query('SELECT Id , Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.EffectiveDate = Date.today().addDays(70);
        order.Tax_Status__c = 'Tax Complete';
        order.Status='Activated';
        order.SBQQ__Contracted__c =true;
        //update order;
        
        Contract contractObj = new Contract();
        contractObj.SBQQ__Quote__c = quote.Id;
        contractObj.SBQQ__Opportunity__c = opp.Id;
        contractObj.AccountID = acc.Id;
        contractObj.SBQQ__Order__c = order.Id;
        Insert contractObj;
        
        List<OrderItem> listOi = Database.query('SELECT Id FROM OrderItem WHERE OrderId  = \''+order.Id+'\'');
        for(OrderItem oi : listOi){
            oi.SBQQ__Contract__c = contractObj.Id;
            oi.SBQQ__Activated__c = true;
        }
        update listOi;
        
        
        //create invoice
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__Account__c = acc.Id;
        invoice.blng__DueDate__c = Date.today();
        invoice.blng__InvoiceDate__c = Date.today();
        invoice.blng__TargetDate__c = Date.today();
        invoice.blng__Order__c = Order.Id;
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
    
    @isTest static void testGetCollectionNote()
    {
        Test.startTest();
        Contract c = [Select id from Contract limit 1];
        Opportunity opp = [Select id from Opportunity limit 1];
        opp.Main_Contract__c = c.Id;
        update opp;
        
        list<Opportunity> listOpp = database.query('Select Id,IM_Opportunity_No__c from Opportunity LIMIT 1');
        List<Collection_Note__c> listCollectionNotes = OppLtngOutUtils.getCollectionNotes(listOpp.get(0).IM_Opportunity_No__c);
        System.assertNotEquals(1, listCollectionNotes.size(),'One Collection Note Found');
        Test.stopTest();
    }
    
    @isTest static void testGetCollectionNote2()
    {
        Test.startTest();
        list<Opportunity> listOpp = database.query('Select Id,IM_Opportunity_No__c from Opportunity LIMIT 1');
        List<Collection_Note__c> listCollectionNotes = OppLtngOutUtils.getCollectionNotes(listOpp.get(0).IM_Opportunity_No__c);
        System.assertNotEquals(1, listCollectionNotes.size(),'One Collection Note Found');
        Test.stopTest();
    }
    
    @isTest static void testGetInvCrData()
    {
        Test.startTest();
        Contract c = [Select id from Contract limit 1];
        Opportunity opp = [Select id from Opportunity limit 1];
        opp.Main_Contract__c = c.Id;
        update opp;
        
        list<Opportunity> listOpp = database.query('Select Id,IM_Opportunity_No__c,Main_Contract__r.SBQQ__Order__c from Opportunity where Main_Contract__c  = \''+c.Id+'\'');  
        
        list<OppLtngOutUtils.returndata> recordList = OppLtngOutUtils.getInvAndCN(listOpp.get(0).IM_Opportunity_No__c);
        System.assertNotEquals(1, recordList.size(),'One Credit Note Found');
        Test.stopTest();
    }
    
    @isTest static void testGetCollectionNotes()
    {
        Test.startTest();
        Contract c = [Select id from Contract limit 1];
        Opportunity opp = [Select id from Opportunity limit 1];
        opp.Main_Contract__c = c.Id;
        update opp;
        
        list<Account> listacc = database.query('Select Id,IM_Account_No__c from Account LIMIT 1');
        List<Collection_Note__c> listCollectionNotes = OppLtngOutUtils.getaccCollectionNotes(listacc.get(0).IM_Account_No__c);
        System.assertNotEquals(1, listCollectionNotes.size(),'One Collection Note Found');
        Test.stopTest();
    }
    
    @isTest static void testGetCollectionNotes2()
    {
        Test.startTest();
        list<Account> listacc = database.query('Select Id,IM_Account_No__c from Account LIMIT 1');
        List<Collection_Note__c> listCollectionNotes = OppLtngOutUtils.getaccCollectionNotes(listacc.get(0).IM_Account_No__c);
        System.assertNotEquals(1, listCollectionNotes.size(),'One Collection Note Found');
        Test.stopTest();
    }
}