/**
* Raider Data Services, TT
* @description Test class for Trigger_InvoiceLine, InvoiceLineHandler_Trig
* Date 12/18/2019
*/
@isTest
public class InvoiceLineHandler_TrigTest {
    
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
        Trigger__c trig = new Trigger__c(Name = 'InvoicePaymentScheduleUpdate_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,After_Update__c = true,Before_Update__c = true,Object__c = 'blng__Invoice__c');
        insert trig;
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
        acc.Legacy_CRM_Instance__c = 'Penton';
        acc.BillingCountryCode='IN';
        acc.BillingPostalCode='12342';
        acc.Accounting_Credit_Hold__c = 'Hold';
        acc.Payment_Term__c='Net 30';
        insert acc;
        
        Contact con=new Contact();
        con.AccountId = acc.Id;
        con.FirstName='Test';
        con.LastName = 'Test';
        con.Legacy_CRM_Instance__c = 'Penton';
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
        product.Revenue_Recognition_End_Date_Rule__c = '[OrderItem.Edition__r.End_Date__c]';
        product.Revenue_Recognition_Start_Date_Rule__c = '[OrderItem.Edition__r.Start_Date__c]';
        update product;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(standardPricebookId,product.Id);
        
        // create the product 
        Product2 product2 = new Product2();
        product2 = TestDataFactory.createProduct2( billingRule, taxRule,  revRecRule);
        product2.Invoice_Line_Item_Description_Format__c = '[Product2.Name] + - +[SBQQ__ChargeType__c]+ - +[Product2.ProductCode]+ - +[Product2.Description]';
        update product2;
        
        // create the PricebookEntry 
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(standardPricebookId,product2.Id);
        
        // create list of edition to be used on the quote
        List<Edition__c> listOfEditions = new List<Edition__c>();
        Edition__c edition = new Edition__c();
        for(Integer i=0;i<1;i++){
        edition =  new Edition__c(Invoice_to_be_issued_before__c='30',End_Date__c = System.today(),Start_Date__c = system.today(), Invoice_To_Customer__c = true);
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
            AccountId=acc.Id,Bill_To_Account__c=acc.Id, Payment_Schedule__c = '100');
        
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
        quote.edition__c = listOfEditions.get(0).Id;
        quote.SBQQ__PaymentTerms__c = ''; 
        insert quote;
        
        // create the quote lines
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
        quoteLine = TestDataFactory.buildTestSFCPQQuoteLine(product.Id, quote.Id, priceBookEntry1.Id, 200,listOfEditions.get(0),1);
        insert quoteLine;
        
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c();
        quoteLine2 = TestDataFactory.buildTestSFCPQQuoteLine(product2.Id, quote.Id, priceBookEntry2.Id, 100,listOfEditions.get(0),1);
        insert quoteLine2;
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote;
    } 
    
    /**
* @description Method to test BllTocontact is populated On Invoice
*/ /*
    @isTest
    static void testBillTocontactPos(){
        Trigger__c trig = new Trigger__c(Name = 'InvoiceLineHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,After_Insert__c = true,Before_Insert__c = true,Object__c = 'blng__InvoiceLine__c');
        insert trig;
        
        //Call InvoiceLine  trigger interface
        TriggerInterface_InvoiceLine obj = new TriggerInterface_InvoiceLine();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        TriggerInterfaceHelper.runTrigger('InvoiceLineHandler_Trig', 'blng__InvoiceLine__c', 1, 'ai',  null, null,'All');
        TriggerInterfaceHelper.runTrigger('InvoiceLineHandler_Trig', 'blng__InvoiceLine__c', 1, 'bi',  null, null,'All');
        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //Activated the order to fire the Billing transaction generator trigger 
        Account acc = Database.query('SELECT Id, Name FROM Account');
        Contact cont = Database.query('SELECT Id,LastName FROM Contact WHERE LastName = \'Test\'');
        order.blng__BillingAccount__c = acc.Id;
        order.BillToContactId = cont.Id;
        order.Status='Activated';
        order.Tax_Status__c  = 'Tax Complete';
        update order;
        
        //After the Activated the order to fire the Billing transaction generator trigger 
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c,Edition__r.End_Date__c ,Edition__r.Start_Date__c,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        List<OrderItem> ordItemToUpdate = new List<OrderItem>();
        for(OrderItem ordItem : listOrderItem){
            ordItem.EndDate = system.today();
            ordItemToUpdate.add(ordItem);
        } 
        update ordItemToUpdate;
        
        List<OrderItem> listPositifOrderItem = new List<OrderItem> ();
        List<String> orderItemId = new List<String> ();
        for(OrderItem orderRecordItem : listOrderItem){
            if(orderRecordItem.Quantity>0){
                listPositifOrderItem.add(orderRecordItem);
                if(!orderItemId.contains(orderRecordItem.Id)){
                    orderItemId.add(orderRecordItem.Id);
                }
            }
        }
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
        Map<Id, blng__BillingSchedule__c>  billingScheduleMap = new Map<Id, blng__BillingSchedule__c>();
        List<Id> billingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c billingSchedule  : listBillingSchedule){
            if(!billingScheduleId.contains(billingSchedule.Id)){
                billingScheduleId.add(billingSchedule.Id);
            }
            if(!billingScheduleMap.containsKey(billingSchedule.blng__OrderProduct__c)){
                billingScheduleMap.put(billingSchedule.blng__OrderProduct__c,billingSchedule);
            }
            
        }
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        System.debug(LoggingLevel.DEBUG, listBillingTransaction);
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
                
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.Id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        Product2 prd = Database.query('SELECT Id  FROM Product2 limit 1');
        
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        invLine.blng__OrderProduct__c = listOrderItem[0].Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billrule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = prd.Id;
        invLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invLine;  
        
        blng__Invoice__c inves = Database.query('SELECT Id,blng__BillToContact__c,Name  FROM blng__Invoice__c');
        list<blng__InvoiceLine__c> invlines = Database.query('SELECT Id,Name,Revenue_Recognition_End_Date__c,Revenue_Recognition_Start_Date__c  FROM blng__InvoiceLine__c');
        system.assertEquals(order.BillToContactId, inves.blng__BillToContact__c,'BillToContact on invoice should be same as on order BillToContact ');
        system.assertNotEquals(null, invlines[0].Revenue_Recognition_End_Date__c,'Revenue Recognition End date should be populated');
        system.assertNotEquals(null, invlines[0].Revenue_Recognition_Start_Date__c,'Revenue Recognition Start date should be populated');
    }*/
    
    /**
* @description Method to test BllTocontact is populated On Invoice
*/ 
    /*
    @isTest
    static void testBillTocontactNeg(){
        Trigger__c trig = new Trigger__c(Name = 'InvoiceLineHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,After_Insert__c = true,Object__c = 'blng__InvoiceLine__c');
        insert trig;
        
        //Call InvoiceLine  trigger interface
        TriggerInterface_InvoiceLine obj = new TriggerInterface_InvoiceLine();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        TriggerInterfaceHelper.runTrigger('InvoiceLineHandler_Trig', 'blng__InvoiceLine__c', 1, 'ai',  null, null,'All');
        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //Activated the order to fire the Billing transaction generator trigger 
        Contact cont = Database.query('SELECT Id,LastName FROM Contact WHERE LastName = \'Test\'');System.debug(LoggingLevel.DEBUG, cont);
        order.Status='Activated';
        order.Tax_Status__c  = 'Tax Complete';
        update order;
        
        //After the Activated the order to fire the Billing transaction generator trigger 
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        List<OrderItem> ordItemToUpdate = new List<OrderItem>();
        for(OrderItem ordItem : listOrderItem){
            ordItem.EndDate = system.today();
            ordItemToUpdate.add(ordItem);
        } 
        update ordItemToUpdate;
        
        List<OrderItem> listPositifOrderItem = new List<OrderItem> ();
        List<String> orderItemId = new List<String> ();
        for(OrderItem orderRecordItem : listOrderItem){
            if(orderRecordItem.Quantity>0){
                listPositifOrderItem.add(orderRecordItem);
                if(!orderItemId.contains(orderRecordItem.Id)){
                    orderItemId.add(orderRecordItem.Id);
                }
            }
        }
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
        Map<Id, blng__BillingSchedule__c>  billingScheduleMap = new Map<Id, blng__BillingSchedule__c>();
        List<Id> billingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c billingSchedule  : listBillingSchedule){
            if(!billingScheduleId.contains(billingSchedule.Id)){
                billingScheduleId.add(billingSchedule.Id);
            }
            if(!billingScheduleMap.containsKey(billingSchedule.blng__OrderProduct__c)){
                billingScheduleMap.put(billingSchedule.blng__OrderProduct__c,billingSchedule);
            }
        }
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        System.debug(LoggingLevel.DEBUG, listBillingTransaction);
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
        
        Account acc = Database.query('SELECT Id , Name  FROM Account');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.Id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<Product2> lstProd = Database.query('SELECT Id  FROM Product2');
        
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        invLine.blng__OrderProduct__c = listOrderItem[0].Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billrule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = lstProd[1].Id;
        invLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invLine;  
        blng__Invoice__c inves = Database.query('SELECT Id,blng__BillToContact__c,Name  FROM blng__Invoice__c');
        blng__InvoiceLine__c invlines = Database.query('SELECT Id,Name,Revenue_Recognition_End_Date__c,Revenue_Recognition_Start_Date__c  FROM blng__InvoiceLine__c');
        system.assertEquals(null, inves.blng__BillToContact__c,'BillToContact on invoice should be blank ');
        system.assertEquals(null, invlines.Revenue_Recognition_End_Date__c ,'Revenue Recognition End date should be blank');
        system.assertEquals(null, invlines.Revenue_Recognition_Start_Date__c ,'Revenue Recognition Start date should be blank');
    }*/
    
    /**
* @description Method to test testPaymentSchedule is inserted from Invoice.
* Modified By: Yash Gupta [1/28/2020]
*/ 
    @isTest
    static void testPaymentSchedule(){
        Trigger__c trig = new Trigger__c(Name = 'PaymentScheduleUpdate_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,After_Insert__c = true,Object__c = 'Payment_Schedule__c');
        insert trig;
        
        //Call InvoiceLine  trigger interface
        TriggerInterface_PaymentSchedule obj = new TriggerInterface_PaymentSchedule();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        TriggerInterfaceHelper.runTrigger('PaymentScheduleUpdate_Trig', 'Payment_Schedule__c', 1, 'ai',  null, null,'All');
        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //Activated the order to fire the Billing transaction generator trigger 
        Contact cont = Database.query('SELECT Id,LastName FROM Contact WHERE LastName = \'Test\'');
        System.debug(LoggingLevel.DEBUG, cont);
        order.Status='Activated';
        order.Tax_Status__c  = 'Tax Complete';
        update order;
        
        //After the Activated the order to fire the Billing transaction generator trigger 
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        List<OrderItem> ordItemToUpdate = new List<OrderItem>();
        for(OrderItem ordItem : listOrderItem){
            ordItem.EndDate = system.today();
            ordItemToUpdate.add(ordItem);
        } 
        update ordItemToUpdate;
        
        List<OrderItem> listPositifOrderItem = new List<OrderItem> ();
        List<String> orderItemId = new List<String> ();
        for(OrderItem orderRecordItem : listOrderItem){
            if(orderRecordItem.Quantity>0){
                listPositifOrderItem.add(orderRecordItem);
                if(!orderItemId.contains(orderRecordItem.Id)){
                    orderItemId.add(orderRecordItem.Id);
                }
            }
        }
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
        Map<Id, blng__BillingSchedule__c>  billingScheduleMap = new Map<Id, blng__BillingSchedule__c>();
        List<Id> billingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c billingSchedule  : listBillingSchedule){
            if(!billingScheduleId.contains(billingSchedule.Id)){
                billingScheduleId.add(billingSchedule.Id);
            }
            if(!billingScheduleMap.containsKey(billingSchedule.blng__OrderProduct__c)){
                billingScheduleMap.put(billingSchedule.blng__OrderProduct__c,billingSchedule);
            }
        }
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');System.debug(LoggingLevel.DEBUG, listBillingTransaction);
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
        
        Account acc = Database.query('SELECT Id , Name  FROM Account');
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.Id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        insert inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<Product2> lstProd = Database.query('SELECT Id  FROM Product2');
        
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        invLine.blng__OrderProduct__c = listOrderItem[0].Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billrule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = lstProd[1].Id;
        invLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invLine;  
        
        blng__Invoice__c inves = Database.query('SELECT Id,blng__BillToContact__c,Name  FROM blng__Invoice__c');
        blng__InvoiceLine__c invlines = Database.query('SELECT Id,Name,Revenue_Recognition_End_Date__c,Revenue_Recognition_Start_Date__c  FROM blng__InvoiceLine__c');
        system.assertEquals(null, inves.blng__BillToContact__c,'BillToContact on invoice should be blank ');
        system.assertEquals(null, invlines.Revenue_Recognition_End_Date__c ,'Revenue Recognition End date should be blank');
        system.assertEquals(null, invlines.Revenue_Recognition_Start_Date__c ,'Revenue Recognition Start date should be blank');
        
        Payment_Schedule__c paySch = new Payment_Schedule__c();
        paySch.Invoice__c = inv.Id;
        paySch.Payment_Schedule_Rows__c = '50% Payable by 12/27/2019 - 100.00';
        paySch.Amounts__c = 100.00;
        paySch.Due_Dates__c = date.today();
        paySch.Percentage__c = '50%';
        insert paySch;
        
        Payment_Schedule__c paySch1 = new Payment_Schedule__c();
        paySch1.Invoice__c = inv.Id;
        paySch1.Payment_Schedule_Rows__c = '100% Immediate Payment - 100.00';
        paySch1.Amounts__c = 100.00;
        paySch1.Due_Dates__c = date.today();
        paySch1.Percentage__c = '100%';
        insert paySch1;
    }
    
    /**
* @description Method to test testPaymentSchedule once invoice will update.
* Modified By: Yash Gupta [1/28/2020]
*/ 
    @isTest
    static void testInvoiceFieldUpdate(){
        Trigger__c trig = new Trigger__c(Name = 'InvoicePrintSendEmailPdf_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Update__c = true, Object__c = 'blng__Invoice__c');
        insert trig;
         Trigger__c trig2 = new Trigger__c(Name = 'InvoiceLineHandler_Trig',Run_for_Recordypes__c = 'All',Execution_Order__c = 1,Enabled__c = true,Before_Insert__c = true,Object__c = 'blng__InvoiceLine__c');
        insert trig2;
        
        //Call InvoiceLine  trigger interface
        TriggerInterface_Invoice obj = new TriggerInterface_Invoice();
        System.debug(LoggingLevel.DEBUG, obj);
        
        //Call trigger app handler for insert event
        TriggerInterfaceHelper.runTrigger('InvoicePrintSendEmailPdf_Trig', 'blng__Invoice__c', 1, 'ai',  null, null,'All');
        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //Activated the order to fire the Billing transaction generator trigger 
        Contact cont = Database.query('SELECT Id,LastName FROM Contact WHERE LastName = \'Test\'');
        System.debug(LoggingLevel.DEBUG, cont);
        order.Status='Activated';
        order.Tax_Status__c  = 'Tax Complete';
        update order;
        
        //After the Activated the order to fire the Billing transaction generator trigger 
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        List<OrderItem> ordItemToUpdate = new List<OrderItem>();
        for(OrderItem ordItem : listOrderItem){
            ordItem.EndDate = system.today();
            ordItemToUpdate.add(ordItem);
        } 
        update ordItemToUpdate;
        
        List<OrderItem> listPositifOrderItem = new List<OrderItem> ();
        List<String> orderItemId = new List<String> ();
        for(OrderItem orderRecordItem : listOrderItem){
            if(orderRecordItem.Quantity>0){
                listPositifOrderItem.add(orderRecordItem);
                if(!orderItemId.contains(orderRecordItem.Id)){
                    orderItemId.add(orderRecordItem.Id);
                }
            }
        }
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
        Map<Id, blng__BillingSchedule__c>  billingScheduleMap = new Map<Id, blng__BillingSchedule__c>();
        List<Id> billingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c billingSchedule  : listBillingSchedule){
            if(!billingScheduleId.contains(billingSchedule.Id)){
                billingScheduleId.add(billingSchedule.Id);
            }
            if(!billingScheduleMap.containsKey(billingSchedule.blng__OrderProduct__c)){
                billingScheduleMap.put(billingSchedule.blng__OrderProduct__c,billingSchedule);
            }
        }
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');System.debug(LoggingLevel.DEBUG, listBillingTransaction);
        
        blng__LegalEntity__c lglEntity = new blng__LegalEntity__c();
        lglEntity.Name = 'lgl Test';
        insert lglEntity;
        
        Account acc = Database.query('SELECT Id , Name  FROM Account');
        
        Account_Tax_Number__c atn = new Account_Tax_Number__c();
        atn.Account__c = acc.Id;
        atn.Status__c = 'valid';
        //atn.Tax_Country__c = 'Bolivia';
        insert atn;
        
        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = acc.Id;
        inv.blng__InvoiceStatus__c = 'Draft';
        inv.Legal_Entity__c = lglEntity.Id;
        inv.blng__Order__c = order.Id;
        //inv.Invoice_Print_Status__c = NULL;
        inv.Invoice_Print_Status__c = 'Not Printed';
        //inv.Contract_Number__c = '00000267';
        inv.Tax_Registration__c = atn.Id;
        insert inv;
        inv.blng__InvoiceStatus__c = 'Posted';
        inv.Invoice_Print_Status__c = 'Ready to Print';
        inv.Tax_Status__c ='Tax Complete';
        inv.Payment_Schedule_Revised__c = '50% Payable by 12/27/2019 - 100.00';
        inv.PO_Number__c = '1236';
        update inv;
        
        blng__BillingRule__c billrule = Database.query('SELECT Id  FROM blng__BillingRule__c');
        blng__TaxRule__c taxRule =  Database.query('SELECT Id  FROM blng__TaxRule__c');
        
        List<Product2> lstProd = Database.query('SELECT Id  FROM Product2');
        
        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = inv.Id;
        invLine.blng__OrderProduct__c = listOrderItem[0].Id;
        invLine.blng__ChargeType__c = 'Recurring';
        invLine.blng__BillingFrequency__c ='Invoice Plan';
        invLine.blng__BillingRule__c =billrule.Id ;
        invLine.blng__TaxRule__c = taxRule.Id;
        invLine.blng__Product__c = lstProd[1].Id;
        invLine.blng__InvoiceLineStatus__c = 'Draft';
        insert invLine;  
        
        blng__Invoice__c inves = Database.query('SELECT Id,blng__BillToContact__c,Name  FROM blng__Invoice__c');
        blng__InvoiceLine__c invlines = Database.query('SELECT Id,Name,Revenue_Recognition_End_Date__c,Revenue_Recognition_Start_Date__c  FROM blng__InvoiceLine__c');
        system.assertEquals(null, inves.blng__BillToContact__c,'BillToContact on invoice should be blank ');
        system.assertEquals(null, invlines.Revenue_Recognition_End_Date__c ,'Revenue Recognition End date should be blank');
        system.assertEquals(null, invlines.Revenue_Recognition_Start_Date__c ,'Revenue Recognition Start date should be blank');
    }
    
}