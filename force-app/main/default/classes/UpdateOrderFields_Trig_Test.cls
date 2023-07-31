/**
* File			: 	UpdateOrderFields_Trig_Test
* Project      	:   Order & Billing Plateform
* Created By	: 	Ashish(Girikon)
* Created Date	: 	28th Jan 2022
* ******************************************************************************************************
* @description : Test Class to provide code covrage to classes - UpdateOrderFields_Trig
* Last Modified By :
*/
@isTest
private  with sharing Class UpdateOrderFields_Trig_Test 
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
        Trigger__c trig = new Trigger__c(Name = 'UpdateOrderFields_Trig' , Trigger_Name_Unique__c='UpdateOrderFields_Trig',Enabled__c=true,Object__c='Order',Run_for_Recordypes__c='All',Description__c='my test',Execution_Order__c=1,Before_insert__c=true,Before_update__c=true);
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
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 15';
        insert acc;
        
        // Create Contact
        Contact oCon = new Contact(LastName = 'ContTest1', Legacy_CRM_Instance__c = 'Penton', Email = 'test1contact@duptest.com', 
        AccountId = acc.Id, MailingStreet = 'Test', MailingCity = 'Test', MailingState = '', 
        MailingCountry = 'India', Phone = '2423122323', AssistantPhone = '2423122323', 
        HomePhone = '2121212121', MobilePhone = '2121212145', OtherPhone = '2154215421');
        insert oCon;
        
        Account_Tax_Number__c atn = new Account_Tax_Number__c(Account__c=acc.Id,Status__c='Valid',Tax_Country__c='US',
         Tax_ID__c='123',Tax_Number_Name__c='123',Start_Date__c=System.today(),End_Date__c=System.today());
        insert atn;
        
        
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
            StageName ='Closed Won',
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',Address_Status__c = 'Valid',  
            AccountId=acc.Id,Ship_To_Account__c=acc.Id,Bill_To_Account__c=acc.Id,
        	Billing_Contact__c=oCon.Id,PO_Number__c='1234',Tax_Rule__c='UAE VAT Refund',
            Account_Tax_Number__c=atn.Id);
        
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
        //quote.SBQQ__Ordered__c  = true;     
        //update quote;
    }
    @isTest static void testShipToAccountUpdateonInsert()
    {
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c,SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        quote.SBQQ__Ordered__c  = true;     
        update quote;
        Order order = Database.query('SELECT Id ,AccountId,Status,Ship_To_Account__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        System.assertNotEquals(null,order.Ship_To_Account__c,'Ship To Account not updated on Order');
    }
    @isTest static void testOrderFieldUpdateWithoutOpp()
    {
        SBQQ__Quote__c quote = Database.query('SELECT Id,Edition__c,SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        quote.SBQQ__Ordered__c  = true;     
        update quote;
        Order order = Database.query('SELECT Id ,AccountId,Status,OpportunityId FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.OpportunityId = null;
        Test.startTest();
        	update order;
        Test.stopTest();
        System.assertNotEquals(null,order.Id,'Order Update Failed');
    }
}