/**
* File:         LegalEntityOnOrderItem_Test => UpdateFieldsOnOrderItem_Test
* Project:      PoC SFDC Informa 
* *******************************************************************************************************
* @description : Test Class for LegalEntityOnOrderItemConSch_Trig
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 05/12/2019
* *******************************************************************************************************
*/
@isTest
private class UpdateFieldsOnOrderItem_Test {
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
    static void testSetupLegalEntityOnOrderItemConsumptionSchedule(){
        blng__LegalEntity__c billingLegalEntity = new blng__LegalEntity__c();
        billingLegalEntity.blng__Active__c =true;
        billingLegalEntity.Name ='Test123';
        insert billingLegalEntity;
        
        revRecRule = new blng__RevenueRecognitionRule__c (Name='rev rule 123',blng__Active__c=true,blng__CreateRevenueSchedule__c='Yes');
        if(Schema.sObjectType.blng__RevenueRecognitionRule__c.isCreateable())
        {
          insert revRecRule;
        }
        
        blng__FinanceBook__c revFinanceBook = new blng__FinanceBook__c(blng__Active__c = true, Name = 'Rev Finance Book', blng__PeriodType__c = 'Revenue');
        if(Schema.sObjectType.blng__FinanceBook__c.isCreateable())
        {
           insert revFinanceBook;
        }

        blng__RevenueDistributionMethod__c revDist = new blng__RevenueDistributionMethod__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, Name = 'Monthly Invoice', blng__Type__c = 'Invoice', blng__RevenueTransactionCreationProcess__c = 'Automatic', blng__RevenueScheduleTermStartDate__c = 'Invoice Line Start Date', blng__RevenueScheduleTermEndDate__c = 'Invoice Line End Date', blng__MonthlyRecognitionProration__c = 'Number of Days', blng__DistributionMethod__c = 'Monthly');
        if(Schema.sObjectType.blng__RevenueDistributionMethod__c.isCreateable())
        {
          insert revDist;
        }
        
        blng__GLRule__c glRule = new blng__GLRule__c(blng__Active__c = true, Name = 'GL Rule123');
        if(Schema.sObjectType.blng__GLRule__c.isCreateable())
        {
            insert glRule;
        }
              
        blng__RevenueRecognitionTreatment__c revRecTreatment = new blng__RevenueRecognitionTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, blng__RevenueLegalEntity__c = billingLegalEntity.Id, blng__RevenueRecognitionRule__c = revRecRule.Id, blng__ProcessingOrder__c = 10, blng__Percentage__c = 100, blng__Type__c = 'Percentage', blng__RevenueScheduleCreationAction__c = 'Invoice Posting', blng__RevenueScheduleAmount__c = 'Transaction Amount', blng__RevenueFinanceBook__c = revFinanceBook.Id, blng__RevenueDistributionMethod__c = revDist.id, blng__RevenueGLRule__c = glRule.Id);
        if(Schema.sObjectType.blng__RevenueRecognitionTreatment__c.isCreateable())
        {
           insert revRecTreatment;
        }
        
        billingRule = new blng__BillingRule__c(blng__InitialBillingTrigger__c = 'Order Product Activation Date', Name = 'TEST123',blng__Active__c = true, blng__GenerateInvoices__c='Yes');
        if(Schema.sObjectType.blng__BillingRule__c.isCreateable())
        {
            insert billingRule;
        }
        
        blng__FinanceBook__c accoutingFinanceBook = new blng__FinanceBook__c(blng__Active__c = true, Name = 'Accounting Finance Book123', blng__PeriodType__c = 'Accounting');
        if(Schema.sObjectType.blng__FinanceBook__c.isCreateable())
        {
           insert accoutingFinanceBook;
        }
        
        blng__BillingTreatment__c billingTreatment = new blng__BillingTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__BillingFinanceBook__c = accoutingFinanceBook.Id, blng__Active__c = true, blng__BillingLegalEntity__c = billingLegalEntity.Id, blng__BillingRule__c = billingRule.Id /*,blng__CancellationRule__c = 'LIFO based on Termination Date'*/);
        if(Schema.sObjectType.blng__BillingTreatment__c.isCreateable())
        {
           insert billingTreatment;
        }
        
        taxRule = new blng__TaxRule__c(blng__Active__c = true, blng__TaxableYesNo__c = 'Yes', Name = 'Tax Rule123');
        if(Schema.sObjectType.blng__TaxRule__c.isCreateable())
        {
          insert taxRule;
        }
        
        blng__TaxIntegration__c stdTaxInt = new blng__TaxIntegration__c(blng__Active__c = true, blng__Default__c = true, blng__TaxEngine__c = 'Standard');
        if(Schema.sObjectType.blng__TaxIntegration__c.isCreateable())
        {
           insert stdTaxInt;
        }
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c(CurrencyIsoCode = UserInfo.getDefaultCurrency(), blng__Active__c = true, blng__TaxLegalEntity__c = billingLegalEntity.Id, blng__TaxRule__c = taxRule.Id, blng__TaxIntegration__c = stdTaxInt.Id);
        if(Schema.sObjectType.blng__TaxTreatment__c.isCreateable())
        {
           insert taxTreatment;
        }
        
        Trigger__c trig = new Trigger__c(Name = 'UpdateFieldsOnOrderItem_Trig' , Trigger_Name_Unique__c = 'UpdateFieldsOnOrderItem_Trig', Enabled__c = true, Object__c = 'OrderItem', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, After_Update__c = true, After_Insert__c = true, Before_Insert__c = true,Before_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterfaceHelper.runTrigger('UpdateFieldsOnOrderItem_Trig','OrderItem',1, 'bu', rt.Id,null,'All'); 
        
        SBQQ__Quote__c quote = Database.query('SELECT Id ,Amendment_Scenario_Type__c, SBQQ__Type__c ,SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'aaaaaaaaaaz\'');
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status ,Legal_Entity__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        
        set<Id> setOrderId = new set<Id>();
        setOrderId.add(order.id);
        OrderItem  ordrItem = Database.query('SELECT Id,Bill_at_Start_of_Campaign__c,EndDate ,Set_Override_Next_Billing_Date__c,blng__LegalEntity__c,OrderId,Issue_Date__c,Quantity,blng__HoldBilling__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        List<orderItem> listOrderItem = new List<OrderItem>();
        ordrItem.Issue_Date__c  = Date.today();
        //ordrItem.Quantity=-1;
        update ordrItem;
        listOrderItem.add(ordrItem);
        
        UpdateFieldsOnOrderItem_Helper.updateFieldsOnOrderProduct(setOrderId,listOrderItem);
        ordrItem = Database.query('SELECT Id , blng__LegalEntity__c,OrderId,Issue_Date__c,Quantity,blng__HoldBilling__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        System.assertEquals(ordrItem.blng__LegalEntity__c, order.Legal_Entity__c,'legal entity on Order and OrderItem should be same');
        System.assertEquals(ordrItem.blng__HoldBilling__c, 'Yes','OrderItem Hold Billing field value should be Yes');
        //System.assertEquals(ordrItem.blng__InvoiceRunProcessingStatus__c, 'Will Not Invoice');
        
        SBQQ__OrderItemConsumptionSchedule__c orderItemConSch = new SBQQ__OrderItemConsumptionSchedule__c(
            blng__RevenueRecognitionRule__c=revRecRule.Id,blng__BillingRule__c=billingRule.Id,blng__TaxRule__c=taxRule.Id,
            SBQQ__OrderItem__c =ordrItem.Id,SBQQ__BillingTermUnit__c='Month',
            SBQQ__BillingTerm__c=1, SBQQ__Category__c='Rates', SBQQ__RatingMethod__c='Tier', SBQQ__Type__c='Slab');
        
        insert orderItemConSch;
        
        ordrItem.ServiceDate = Date.today().addMonths(1);
        update ordrItem;
        
        orderItemConSch  = Database.query('SELECT blng__LegalEntity__c  FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c = \''+ordrItem.Id+'\'');
        
        System.assertEquals(ordrItem.blng__LegalEntity__c, orderItemConSch.blng__LegalEntity__c,'legal entity on Order and OrderItem should be same');
    }
    
     @isTest
    static void testsetOrderAllOrverRideNextBillDt(){
        Trigger__c trig = new Trigger__c(Name = 'UpdateFieldsOnOrderItem_Trig' , Trigger_Name_Unique__c = 'UpdateFieldsOnOrderItem_Trig', Enabled__c = true, Object__c = 'OrderItem', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, After_Update__c = true, After_Insert__c = true, Before_Insert__c = true,Before_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        
        TriggerInterfaceHelper.runTrigger('UpdateFieldsOnOrderItem_Trig','OrderItem',1, 'bu', rt.Id,null,'All'); 
        
        SBQQ__Quote__c quote = Database.query('SELECT Id ,Amendment_Scenario_Type__c, SBQQ__Type__c ,SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'aaaaaaaaaaz\'');
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status ,Legal_Entity__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');        
                
        set<Id> setOrderId = new set<Id>();
        setOrderId.add(order.id);
        OrderItem  ordrItem = Database.query('SELECT Id,Bill_at_Start_of_Campaign__c,blng__BilledAmountwithouttax__c,EndDate,Set_Override_Next_Billing_Date__c,blng__LegalEntity__c,OrderId,TotalPrice,Quantity,SBQQ__BillingFrequency__c,blng__PendingBillings__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        List<orderItem> listOrderItem = new List<OrderItem>();  
        System.debug(LoggingLevel.DEBUG, listOrderItem);      
        
		//system.debug(' ordrItem -- '+ordrItem.blng__BilledAmountwithouttax__c+' - '+ordrItem.TotalPrice+' - '+ordrItem.SBQQ__BillingFrequency__c);        
        Test.startTest();
        	ordrItem.EndDate  = Date.today().addMonths(2);
        	update ordrItem; 
        Test.stopTest();
        OrderItem  ordrItem1 = Database.query('SELECT Id ,blng__OverrideNextBillingDate__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        System.assertNotEquals(null, ordrItem1.blng__OverrideNextBillingDate__c,'Failed to set OverrideNextBillingDate');
    }
    
    @isTest
    static void testsetQLIupdatedDates(){
        Trigger__c trig = new Trigger__c(Name = 'UpdateFieldsOnOrderItem_Trig' , Trigger_Name_Unique__c = 'UpdateFieldsOnOrderItem_Trig', Enabled__c = true, Object__c = 'OrderItem', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, After_Update__c = true, After_Insert__c = true, Before_Insert__c = true,Before_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        
        TriggerInterfaceHelper.runTrigger('UpdateFieldsOnOrderItem_Trig','OrderItem',1, 'bu', rt.Id,null,'All'); 
        
        SBQQ__Quote__c quote = Database.query('SELECT Id ,Amendment_Scenario_Type__c, SBQQ__Type__c ,SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'aaaaaaaaaaz\'');
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status ,Legal_Entity__c FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');                        
        set<Id> setOrderId = new set<Id>();
        setOrderId.add(order.id);
        OrderItem  ordrItem = Database.query('SELECT Id,ServiceDate,SBQQ__QuoteLine__c,Bill_at_Start_of_Campaign__c,blng__BilledAmountwithouttax__c,EndDate,Set_Override_Next_Billing_Date__c,blng__LegalEntity__c,OrderId,TotalPrice,Quantity,SBQQ__BillingFrequency__c,blng__PendingBillings__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');        
        List<orderItem> listOrderItem = new List<OrderItem>();        
        listOrderItem.add(ordrItem);
        map<Id,orderItem> oldvalmap = new map<Id,orderItem>();
        oldvalmap.put(ordrItem.Id,new orderItem(id=ordrItem.Id,ServiceDate =Date.today(),EndDate =Date.today().addMonths(1)));
		//system.debug(' BIll  - -- '+ordrItem.TotalPrice.setScale(2)+'  ####  '+ordrItem.blng__PendingBillings__c);
        Test.startTest();
        	listOrderItem[0].blng__PendingBillings__c = listOrderItem[0].TotalPrice.setScale(2);
        	listOrderItem[0].ServiceDate  = Date.today().addMonths(1);
        	//update ordrItem; 
        	UpdateFieldsOnOrderItem_Trig.setQLIupdatedDates(listOrderItem,oldvalmap);
        Test.stopTest();
        SBQQ__QuoteLine__c  qL = Database.query('SELECT Id ,SBQQ__StartDate__c  FROM SBQQ__QuoteLine__c  WHERE Id = \''+ordrItem.SBQQ__QuoteLine__c+'\'');
        System.assertEquals(qL.SBQQ__StartDate__c, Date.today().addMonths(1),'Failed to Update QLI Date');
    }
}