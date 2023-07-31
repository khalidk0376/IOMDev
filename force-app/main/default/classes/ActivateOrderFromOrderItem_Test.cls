/**
* File			: 	ActivateOrderFromOrderItem_Test
* Project      	:   GE-IOM
* Created By	: 	Ansh(Girikon)
* Created Date	: 	17/01/2023
* ************************************************************************************
* @description : Test Class to provide code covrage to classes - ActivateOrderFromOrderItem
* Last Modified By :
*/
@isTest
public class ActivateOrderFromOrderItem_Test {
	private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    public static   blng__LegalEntity__c billingLegalEntity = null;
    
    public static   blng__RevenueRecognitionRule__c revRecRule = null;
    
    public static    blng__BillingRule__c billingRule = null;
    
    public static    blng__TaxRule__c taxRule = null;
    @testSetup 
    static void setup() {
        Id standardPricebookId = Test.getStandardPricebookId();
        
        //Integer maxTransactionsforOppty = 12;
        Integer maxTransactionsforEdition = 4;
        String billingSchedulesValue='25-25-25-25';
        String mileDelDateApiNamePart1='Milestone_';
        String mileDelPercentApiNamePart1='Milestone_';
        String mileDelDateApiNamePart2='_Delivery_Date__c';
        String mileDelPercentApiNamePart2='_Percent__c';
        //String mileDelDateQuerypart='';
        //String mileDelPercentQuerypart='';
        
        String billingSchedulesApiNameEdition='Payment_Schedule__c';
        
        // cut Off dates field Api name to construct the query part
        //String cutOffDatesApiNameQuerypart ='';
        // cut Off Percentages field Api name to construct the query part
        //String cutOffPercentageQuerypart ='';
        String cutOffApiName='CutoffDate_';
        
        // Create an account
        Account acc = new Account ();
        acc.Name = 'TESTACC';
        acc.currencyisocode='USD';
        acc.BillingStreet ='street2';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 15';
        insert acc;
        
        
        // setup the Custom Settings
        TestDataFactory.insertBillingCustomSettings();
        
        billingLegalEntity = TestDataFactory.setupLegalEntity();
        
        revRecRule = TestDataFactory.setupRevRec(billingLegalEntity.Id);
        
        billingRule = TestDataFactory.setupBillingRule(billingLegalEntity.Id);
        
        taxRule = TestDataFactory.setupTaxRule(billingLegalEntity.Id);
        
        // create the product 
        Product2 product = new Product2();
        product = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        product.SBQQ__ChargeType__c ='Recurring';
        product.SBQQ__BillingFrequency__c ='Monthly';
        product.ActivateOrder_OverrideBillingDateIsToday__c = true;
        product.SBQQ__BillingType__c ='Arrears';
        product.Set_Override_Next_Billing_Date__c = true;
        update product;
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
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
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Name ='TESTOPP',
            Default_Edition__c=listOfEditions[0].Id,
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        insert opp;
        
        blng__LegalEntity__c  lglEnty = new blng__LegalEntity__c();
        lglEnty.blng__Active__c =true;
        lglEnty.Name ='Test';
        insert lglEnty;
        
        // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('aaaaaaaaaaz',opp.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        quote.SBQQ__BillingFrequency__c = 'Monthly';
        quote.SBQQ__Primary__c = true; 
        quote .Legal_Entity__c=lglEnty.Id;
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        quoteLine.SBQQ__EndDate__c = Date.today().addMonths(1);
        quoteLine.SBQQ__BillingFrequency__c = 'Monthly';
        insert quoteLine;

        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
    }
    @isTest
    public static void testOrderActivate(){
        SBQQ__Quote__c quote = Database.query('SELECT Id ,Amendment_Scenario_Type__c, SBQQ__Type__c ,SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'aaaaaaaaaaz\'');
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status ,Legal_Entity__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Tax_Status__c = 'Tax Complete';
        update order;
        OrderItem  ordrItem = Database.query('SELECT Id,blng__OverrideNextBillingDate__c,SBQQ__DefaultSubscriptionTerm__c,OrderId,SBQQ__BillingFrequency__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        ordrItem.blng__OverrideNextBillingDate__c = date.today();
        ordrItem.SBQQ__DefaultSubscriptionTerm__c = 2;
        update ordrItem;
        Test.startTest();
        ActivateOrderFromOrderItem.getOrderIds();
        Test.stopTest();
        Order ord = Database.query('SELECT Id ,Status FROM Order WHERE Id  = \''+order.Id+'\'');
        System.assertEquals('Activated',ord.Status,'Order Activated');
    }
}