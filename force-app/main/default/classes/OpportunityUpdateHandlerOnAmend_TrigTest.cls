/**
* Raider Data Services, TT
* @description Test class for OpportunityUpdateHandlerOnAmend_Trig
* Date 11/02/2020
*/
@isTest
public class OpportunityUpdateHandlerOnAmend_TrigTest {
    private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    
    /**
	* @description Setting up the database for the test
	*/
    @testSetup 
    static void setup() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        String cutOffApiName='CutoffDate_';
        
        // Create an account
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='test';
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingCity='Alaska';
        acc.BillingState='Delhi';
        acc.BillingCountry='India';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        Contact con = new Contact();
        con.Legacy_CRM_Instance__c = 'Penton';
        con.AccountId = acc.Id;
        con.FirstName='Test';
        con.LastName = 'Test';
        con.Email = 'Test@gtest.com';
        con.Phone = '0000000000';
        insert con;
        
        
        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        blng__LegalEntity__c billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        blng__RevenueRecognitionRule__c revRecRule = TestDataFactory.setupRevRec(billingLegalEntity.Id);
        
        blng__BillingRule__c billingRule = TestDataFactory.setupBillingRule(billingLegalEntity.Id);
        
        blng__TaxRule__c taxRule = TestDataFactory.setupTaxRule(billingLegalEntity.Id);
        
        // create the product 
        Product2 product = new Product2();
        product = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        product.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + - +[SBQQ__ChargeType__c]+ - +[Product2.ProductCode]+ - +[Product2.Description]';
        product.Revenue_Recognition_End_Date_Rule__c = '[OrderItem.EndDate]';
        product.Revenue_Recognition_Start_Date_Rule__c = '[OrderItem.Edition__r.End_Date__c]';
        update product;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
        
        // create the product 
        Product2 product2 = new Product2();
        product2 = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        //product2.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + - +[SBQQ__ChargeType__c]+ - +[Product2.ProductCode]+ - +[Product2.Description]';
        update product2;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30',End_Date__c = System.today());
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
        
        // Create an Opportunity
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            Default_Edition__c=listOfEditions[0].Id,
            StageName ='Proposal',
            Name ='TESTOPP',  
            AccountId=acc.Id,Bill_To_Account__c =acc.Id);
        
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
    @isTest
    static void testOpportunityUpdate(){
        
        Trigger__c trig = new Trigger__c(Name = 'OpportunityNameUpdate_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Update__c = true, Before_Insert__c= true, Object__c = 'Opportunity');
        insert trig;
        
        //Call Invoice  trigger interface
        TriggerInterface_Opportunity obj = new TriggerInterface_Opportunity();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for update event
        TriggerInterfaceHelper.runTrigger('OpportunityNameUpdate_Trig', 'Opportunity', 1, 'bu',  null, null,'All');
        
        Account acc = Database.query('SELECT Id , Name  FROM Account');
        
        List<Edition__c> edlist = [Select Id from Edition__c];
        
        Contact cont = Database.query('SELECT Id,LastName FROM Contact WHERE LastName = \'Test\'');
        
        Opportunity opp = Database.query('Select id, Name,StageName from Opportunity');
      
        //Insert Legal Entity
        blng__LegalEntity__c entityObj = new blng__LegalEntity__c();
        entityObj.Name = 'TestLegal';
        entityObj.blng__Active__c = true;
        insert entityObj;
        
        //Insert Series
        Series__c seriesObj = new Series__c();
        seriesObj.Name = 'testSeries';
        seriesObj.Status__c = 'Active';
        seriesObj.Legal_Entity__c = entityObj.Id;
        insert seriesObj;
        
        List<Edition__c> editionObj1 = Database.query('Select id, Name from Edition__c');
        System.debug(LoggingLevel.DEBUG, editionObj1);
        
        SBQQ__Quote__c quote = Database.query('Select id, SBQQ__Primary__c from SBQQ__Quote__c ');
        //Insert Quote
        SBQQ__Quote__c quoteObj = new SBQQ__Quote__c();
        quoteObj.SBQQ__Primary__c = true;
        quoteObj.SBQQ__Opportunity2__c = opp.Id;
        Insert quoteObj;
        
        List<SBQQ__QuoteLine__c> quoteLine = Database.query('Select id from SBQQ__QuoteLine__c');
        System.debug(LoggingLevel.DEBUG, quoteLine);
        
        List<SBQQ__QuoteLine__c> quoteLine2 = Database.query('Select id from SBQQ__QuoteLine__c');
        System.debug(LoggingLevel.DEBUG, quoteLine2);
        
        Order order = Database.query('SELECT Id , Status,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.blng__BillingAccount__c = acc.Id;
        order.BillToContactId = cont.Id;
        order.Tax_Status__c = 'Tax Complete';
        order.Type = 'Amendment';
        order.OpportunityId = opp.Id;
        update order;
        
        order.Status='Activated';
        order.SBQQ__Contracted__c = true;
        update order;
        
        System.debug(LoggingLevel.DEBUG, 'order==>'+order);
        
        Contract contractObj = new Contract();
        contractObj.SBQQ__Quote__c = quote.Id;
        contractObj.SBQQ__Opportunity__c = opp.Id;
        contractObj.AccountID = acc.Id;
        contractObj.SBQQ__Order__c = order.Id;
        Insert contractObj;

        Contract ctrObj = [select Id,ContractNumber,SBQQ__Order__c from Contract];
        System.debug(LoggingLevel.DEBUG, 'ctrObj==>'+ctrObj);
        
        //Creates second opportunity
        Opportunity oppt2 = new Opportunity();
        oppt2.SBQQ__AmendedContract__c = contractObj.Id; 
        oppt2.Name ='Amendment for contract #'+ctrObj.ContractNumber;
        oppt2.Is_Amend_Opportunity__c = true;
        oppt2.Default_Edition__c = edlist[0].Id;
        oppt2.AccountID = acc.Id;
        oppt2.StageName = 'Qualification';
        oppt2.CloseDate = System.today();
        insert oppt2;
        
        list<Opportunity> opporuty = [Select Id, Master_Contract_No_Previous__c, Master_Contract_Auto_Number__c,
                                      Master_Contract_No_Version__c, Master_Contract_No__c from Opportunity];
        
        system.assertEquals(opporuty[0].Master_Contract_Auto_Number__c, opporuty[1].Master_Contract_No_Previous__c,'Master Contract Previous should be populated on Ammended Opportunity');
        system.assertEquals(1, opporuty[1].Master_Contract_No_Version__c,'Master Contract version should be Incremented by one for Ammended Opportunity');
        
        
    }
}