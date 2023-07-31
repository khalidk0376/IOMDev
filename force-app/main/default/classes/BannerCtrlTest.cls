/**
 * Raider Data Services, TT
 * @description Test class for BannerCtrl
 * Date 02/06/2020
 */
@isTest
public class BannerCtrlTest {
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
        acc.BillingStreet ='street2';
        acc.BillingCity='test';
        acc.BillingCity='Alaska';
        acc.BillingState='tamil nadu';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 10';
        insert acc;
        
        Contact con=new Contact();
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
        product.Tax_Category__c = 'Exhibition Services';
        update product;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
        
        // create the product 
        Product2 product2 = new Product2();
        product2.Tax_Category__c = 'Exhibition Services';
        product2 = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        //product2.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + - +[SBQQ__ChargeType__c]+ - +[Product2.ProductCode]+ - +[Product2.Description]';
        update product2;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
       
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
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<2;i++){
            edition =  new Edition__c(Invoice_to_be_issued_before__c='30',End_Date__c = System.today(), Part_of_Series__c = seriesObj.Id);
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
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',
            Non_Reseller_Agent__c = true,
            AccountId=acc.Id);
        
        // set the cutOff dates to the Oppty
        for(Integer i = 1 ; i<= cutOffDatesOppty.size();i++){
            opp.put(mileDelDateApiNamePart1+i+mileDelDateApiNamePart2,cutOffDatesOppty[i-1]);
            opp.put(mileDelPercentApiNamePart1+i+mileDelPercentApiNamePart2,cutOffPercentagesOppty[i-1]);
        }
        
        insert opp;
        
        opp.Default_Edition__c = listOfEditions[0].id;
        opp.Bill_To_Account__c = acc.Id;
        update opp;
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
        
        OpportunityLineItem oppItem = new OpportunityLineItem();
        oppItem.OpportunityId = opp.Id;
        oppItem.Product2Id = product2.Id;
        oppItem.UnitPrice = 100;
        oppItem.Quantity = 1;
        insert oppItem;
    }

    /**
	 * @description Method to test Account Record.
	 */ 
    @isTest
    static void testgetAccRecord(){
        //string recTypeId = [Select Id From RecordType Where sObjectType IN ('Account') LIMIT 1].Id;
        Account acc = Database.query('Select Id, Name, Address_Status__c, Accounting_Credit_Hold__c FROM Account');
        BannerCtrl.getAccRecord(acc.Id);
        System.assertEquals(acc, BannerCtrl.getAccRecord(acc.Id), 'Method should return Account Record');
    }
    /**
	 * @description Method to test Account Record from Contact.
	 */ 
    @isTest
    static void testgetContRecord(){
        //string recTypeIdCon = [Select Id From RecordType Where sObjectType IN ('Contact') LIMIT 1].Id;
        Account acc = Database.query('Select Id, Name, Address_Status__c, Accounting_Credit_Hold__c  FROM Account');
        Contact con = Database.query('SELECT Id , Name  FROM Contact');
        BannerCtrl.getAccRecord(con.Id);
        System.assertEquals(acc, BannerCtrl.getAccRecord(con.Id), 'Method should return Account Record');
    }
    /**
	 * @description Method to test Account Record from Opportunity.
	 */ 
    @isTest
    static void testgetOppRecord(){
        Account acc = Database.query('Select Id, Name, Address_Status__c, Accounting_Credit_Hold__c FROM Account');
        Opportunity opp = Database.query('SELECT Id , Name  FROM Opportunity');
        BannerCtrl.getAccRecord(opp.Id);
        System.assertEquals(acc, BannerCtrl.getAccRecord(opp.Id), 'Method should return Account Record');
    }
        
}