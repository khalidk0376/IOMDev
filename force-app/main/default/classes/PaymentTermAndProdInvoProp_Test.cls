/*
* File:         PaymentTermAndProdInvoProp_Test
* Project:      PoC SFDC Informa
* *******************************************************************************************************
* @description : Testing the PaymentTermAndProdInvoProp_Trig.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 17/12/2019
* *******************************************************************************************************
*/
@isTest
public class PaymentTermAndProdInvoProp_Test {
    
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
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        
        // Create an Oppty
        Opportunity opp = new Opportunity( 
            Pricebook2Id =standardPricebookId,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Name ='TESTOPP',  
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        
        
        insert opp;
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
        product.SBQQ__BillingType__c ='Arrears';
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
                edition.put(paymentTermApiNameEdition,'10');
            }
            listOfEditions.add(edition);
        }
        insert listOfEditions;
       Product_Edition__c productEdition = new Product_Edition__c(Product__c=product.Id,Edition__c =listOfEditions.get(0).Id,Product_Invoice_property__c='Invoice in Full as per the first invoice schedule',Payment_Term__c = 'Net 60' );
        insert productEdition;        
        
        
        // create the quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote = TestDataFactory.buildTestSFCPQQuote('aaaaaaaaaaz',opp.Id, acc.Id, standardPricebookId, 'Quote',listOfEditions.get(0));
        quote.SBQQ__Primary__c = true;
        insert quote;
        
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        insert quoteLine;
        
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
    }
    
    @isTest
    static void testPaymentTermAndProdInvoProp(){
        
        Test.startTest(); 
        Trigger__c trig = new Trigger__c(Name = 'PaymentTermAndProdInvoProp_Trig' , Trigger_Name_Unique__c = 'PaymentTermAndProdInvoProp_Trig', Enabled__c = true, Object__c = 'OrderItem', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, Before_Insert__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterfaceHelper.runTrigger('PaymentTermAndProdInvoProp_Trig','OrderItem',1, 'bu', rt.Id,null,'All'); 
        
        SBQQ__Quote__c quote = Database.query('SELECT SBQQ__Ordered__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'aaaaaaaaaaz\'');
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        OrderItem  orderItem = Database.query('SELECT Product2Id ,Edition__c ,Product_Invoice_property__c ,Payment_Term__c FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
   
        Product_Edition__c productEdition = Database.query('SELECT Product__c ,Edition__c ,Product_Invoice_property__c , Payment_Term__c from Product_Edition__c  where Product__c = \''+orderItem.Product2Id+'\' AND  Edition__c =\''+orderItem.Edition__c+'\'');
        
        System.assertEquals(orderItem.Product_Invoice_property__c, productEdition.Product_Invoice_property__c,'The Product invoice property on the Order product is not equals to the Product invoice property in the Product Edition');
        
        System.assertEquals(orderItem.Payment_Term__c, productEdition.Payment_Term__c,'The payment term in the Order Product is not the same in the Product Edition');

        Test.stopTest();         
    }
}