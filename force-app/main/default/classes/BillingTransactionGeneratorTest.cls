/*
* File:         BillingTransactionGeneratorTest
* Project:      PoC SFDC Informa
* *******************************************************************************************************
* @description : Testing the BillingTransactionGenerator.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 25/11/2019
* *******************************************************************************************************
*/
@isTest
public class BillingTransactionGeneratorTest {
    
    private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    
    // Setting up the database for the test
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
            Default_Edition__c=listOfEditions[0].Id,
            CloseDate =Date.newInstance(2019, 11, 5),
            StageName ='Proposal',
            Name ='TESTOPP',  
            AccountId=acc.Id,
            Bill_To_Account__c =acc.Id);
        
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
        quote.SBQQ__PaymentTerms__c = ''; 
        
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
    
    // the first test without overriding the Billing Scedule on oppry 
    @isTest
    static void testGenerateBillingTransaction1(){
        Test.startTest(); 
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //Activated the order to fire the Billing transaction generator trigger 
        order.Status='Activated';
        // update order;
        BillingTransactionGenerator.generateBillingTransaction(order);
        
        //After the Activated the order to fire the Billing transaction generator trigger 
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'Fail to create Billing Schedule for each order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals the Total Amount in the Order product');
            listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
            
            for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                sum+=bs.blng__Amount__c;
                System.assertEquals(cutOffDatesEdition[i].addDays(-10),bs.blng__BillingTargetDate__c,'Billing  Target Date is wrong');
                System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                i++;
            }
            i=0;
            System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The price on the Billing Schedule not equals the Total Amount in the Order product');
            sum = 0;
        }
        Test.stopTest();     
    }
    
    // the Second test with overriding the Billing Scedule on oppry 
    @isTest
    static void testGenerateBillingTransaction2(){
        Test.startTest(); 
        Opportunity opp = Database.query('SELECT Id, Name From Opportunity where Name = \'TESTOPP\'');
        opp.put(billingSchedulesApiNameOppty,'Custom');
        opp.put(nbrOfTransactionApiName,4);
        update opp;
        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.Status='Activated';
        // update order;
        BillingTransactionGenerator.generateBillingTransaction(order);
        
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'Fail to create Billing Schedule for each order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals the Total Amount in the Order product');
            listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
            
            for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                sum+=bs.blng__Amount__c;
                System.assertEquals(cutOffDatesEdition[i].addDays(0),bs.blng__BillingTargetDate__c,'Billing  Target Date is wrong');
                System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                i++;
            }
            i=0;
            System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
            sum = 0;
        }
        Test.stopTest();     
    }

    @isTest
    static void testGenerateBillingTransaction3(){
        Test.startTest(); 
        Account acc = Database.query('SELECT Id, Payment_Term__c FROM Account WHERE name = \'TESTACC\'');
        acc.Payment_Term__c = null; 
        update acc;        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //order.EffectiveDate = Date.today().addDays(70);
        update order;
        order.Status='Activated';
        //update order;
        BillingTransactionGenerator.generateBillingTransaction(order);
        List<OrderItem> listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'Fail to create Billing Schedule for each order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
            listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
            
            for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                sum+=bs.blng__Amount__c;                
                System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                i++;
            }
            i=0;
            System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
            sum = 0;
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateBillingTransaction4(){
        Test.startTest(); 
        
        Account acc = Database.query('SELECT Id, Payment_Term__c FROM Account WHERE name = \'TESTACC\'');
        acc.Payment_Term__c = null; 
        update acc;        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //order.EffectiveDate = Date.today().addDays(70);
        update order;
        order.Status='Activated';
        //update order;
        
        List<OrderItem> listOrderItem = Database.query('SELECT Product_Invoice_property__c ,Payment_Term__c, Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        OrderItem orderItem1 = listPositifOrderItem.get(0);
        orderItem1.Product_Invoice_property__c='Invoice in Full as per the first invoice schedule';
        orderItem1.Payment_Term__c = 'Net 10';
        update orderItem1;
        BillingTransactionGenerator.generateBillingTransaction(order);
        listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Billing_Schedule_Reason__c,Payment_Term_Reason__c,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'Fail to create Billing Schedule for each order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            if(orderItem1.Id == orderRecordItem.Id){
                
                System.assertEquals(  orderRecordItem.TotalPrice, billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).size(),  1,'Fail to create the right number of Billing transactions');  
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Billing_Schedule_Reason__c,  'Product Edition Object Level','Wrong Billing Schedule Reason');   
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Payment_Term_Reason__c,  'Product Edition Object Level','Wrong Payment Term Reason');   
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).Billing_Percentage__c,  100,'Wrong Percentage'); 
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).blng__BillingTargetDate__c,  cutOffDatesEdition[0].addDays(-10),'Wrong Billing Target Date');                  
                
            }else{
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
                
                for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                    sum+=bs.blng__Amount__c;
                    System.assertEquals(cutOffDatesEdition[i+1].addDays(-10),bs.blng__BillingTargetDate__c,'Wrong Billing Target Date');
                    System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                    i++;
                }
                i=0;
                System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
                sum = 0;  
            }
        }
        Test.stopTest();     
    }
    
    @isTest
    static void testGenerateBillingTransaction5(){
        Test.startTest(); 
        Account acc = Database.query('SELECT Id, Payment_Term__c FROM Account WHERE name = \'TESTACC\'');
        acc.Payment_Term__c = null; 
        update acc;        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //order.EffectiveDate = Date.today().addDays(70);
        update order;
        order.Status='Activated';
        //update order;
        
        List<OrderItem> listOrderItem = Database.query('SELECT Product_Invoice_property__c ,Payment_Term__c, Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        OrderItem orderItem1 = listPositifOrderItem.get(0);
        orderItem1.Product_Invoice_property__c='Invoice in Full as per the second invoice schedule';
        orderItem1.Payment_Term__c = 'Net 10';
        update orderItem1;
        BillingTransactionGenerator.generateBillingTransaction(order);
        listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Billing_Schedule_Reason__c,Payment_Term_Reason__c,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'Fail to create Billing Schedule for each order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            if(orderItem1.Id == orderRecordItem.Id){
                
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).size(),  1,'Fail to create the right number of Billing transactions');  
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Billing_Schedule_Reason__c,  'Product Edition Object Level','Wrong Billing Schedule Reason');   
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Payment_Term_Reason__c,  'Product Edition Object Level','Wrong Payment Term Reason');   
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).Billing_Percentage__c,  100,'Wrong Percentage'); 
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).blng__BillingTargetDate__c,  cutOffDatesEdition[1].addDays(-10),'Wrong Billing Target Date');                  
                
            }else{
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
                
                for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                    sum+=bs.blng__Amount__c;
                    System.assertEquals(cutOffDatesEdition[i+1].addDays(-10),bs.blng__BillingTargetDate__c,'Wrong Billing Target Date');
                    System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                    i++;
                }
                i=0;
                System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
                sum = 0;  
            }
        }
        Test.stopTest();     
    }
    
    @isTest
    static void testGenerateBillingTransaction6(){
        Test.startTest(); 
        
        Account acc = Database.query('SELECT Id, Payment_Term__c FROM Account WHERE name = \'TESTACC\'');
        acc.Payment_Term__c = null; 
        update acc;        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //order.EffectiveDate = Date.today().addDays(70);
        update order;
        order.Status='Activated';
        //update order;
        
        List<OrderItem> listOrderItem = Database.query('SELECT Product_Invoice_property__c ,Payment_Term__c, Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        OrderItem orderItem1 = listPositifOrderItem.get(0);
        orderItem1.Product_Invoice_property__c='Invoice in Full';
        orderItem1.Payment_Term__c = 'Net 10';
        update orderItem1;
        BillingTransactionGenerator.generateBillingTransaction(order);
        listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Billing_Schedule_Reason__c,Payment_Term_Reason__c,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'The price on the Billing Schedule not equals to the Total Amount in the Order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            if(orderItem1.Id == orderRecordItem.Id){
                
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).size(),  1,'Fail to create the right number of Billing transactions');  
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Billing_Schedule_Reason__c,  'Product Edition Object Level','Wrong Billing Schedule Reason');   
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Payment_Term_Reason__c,  'Product Edition Object Level','Wrong Payment Term Reason'); 
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).Billing_Percentage__c,  100,'Wrong Percentage');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).blng__BillingTargetDate__c, Date.toDay(),'Wrong Billing Target Date');              
                
            }else{
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
                
                for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                    sum+=bs.blng__Amount__c;
                    System.assertEquals(cutOffDatesEdition[i+1].addDays(-10),bs.blng__BillingTargetDate__c,'Wrong Billing Target Date');
                    System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                    i++;
                }
                i=0;
                System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
                sum = 0;  
            }
        }
        Test.stopTest();     
    }
    
    @isTest
    static void testGenerateBillingTransaction7(){
        Test.startTest(); 
        
        Account acc = Database.query('SELECT Id, Payment_Term__c FROM Account WHERE name = \'TESTACC\'');
        acc.Payment_Term__c = null; 
        update acc;        
        SBQQ__Quote__c quote = Database.query('SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        Order order = Database.query('SELECT Id , Status ,OpportunityId,EffectiveDate FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        //order.EffectiveDate = Date.today().addDays(70);
        update order;
        order.Status='Activated';
        //update order;
        
        List<OrderItem> listOrderItem = Database.query('SELECT Product_Invoice_property__c ,Payment_Term__c, Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
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
        OrderItem orderItem1 = listPositifOrderItem.get(0);
        Edition__c edi = Database.query('SELECT Start_Date__c,Edition_Cut_Off_days__c FROM Edition__c WHERE Id = \''+orderItem1.Edition__c+'\'');
        edi.Edition_Cut_Off_days__c = 60;
        edi.Start_Date__c = Date.today().addDays(30);
        
        update edi;
        orderItem1.Product_Invoice_property__c='Invoice in Full';
        orderItem1.Payment_Term__c = 'Net 10';
        update orderItem1;
        
        BillingTransactionGenerator.generateBillingTransaction(order);
        listOrderItem = Database.query('SELECT Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where SBQQ__BillingFrequency__c = \'Invoice Plan\' and OrderId = \''+order.Id+'\'');
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Billing_Schedule_Reason__c,Payment_Term_Reason__c,blng__OrderProduct__c ,blng__Amount__c  FROM blng__BillingSchedule__c where blng__OrderProduct__c in :orderItemId');
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
        System.assertEquals(listPositifOrderItem.size(), listBillingSchedule.size(),'The price on the Billing Schedule not equals to the Total Amount in the Order product');
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id ,Billing_sequence__c,Billing_Percentage__c, blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :billingScheduleId order by blng__BillingTargetDate__c ASC');
        Map<Id, List<blng__BillingTransaction__c>>  billingTransactionMap = new Map<Id, List<blng__BillingTransaction__c>>();
        List<blng__BillingTransaction__c> listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
        
        for(blng__BillingTransaction__c billingTransaction  : listBillingTransaction){
            if(!billingTransactionMap.containsKey(billingTransaction.blng__BillingSchedule__c)){
                for(blng__BillingTransaction__c bt : listBillingTransaction){
                    if(billingTransaction.Id == bt.blng__BillingSchedule__c){
                        listBillingTransaction.add(bt);
                    }     
                }
                billingTransactionMap.put(billingTransaction.blng__BillingSchedule__c,listBillingTransaction);
                listBillingTransactionPerShedule = new List<blng__BillingTransaction__c>();
            }
        }
        Decimal sum = 0;
        Integer i = 0;
        for(OrderItem orderRecordItem : listPositifOrderItem){
            if(orderItem1.Id == orderRecordItem.Id){
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).size(),  1,'Fail to create the right number of Billing transactions');  
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Billing_Schedule_Reason__c,  'Edition Cut-off Days','Wrong Billing Schedule Reason');   
                System.assertEquals(  billingScheduleMap.get(orderRecordItem.Id).Payment_Term_Reason__c,  'Edition Cut-off Days','Wrong Payment Term Reason');
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).Billing_Percentage__c,  100,'Wrong Percentage'); 
                System.assertEquals(  billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id).get(0).blng__BillingTargetDate__c, Date.toDay(),'Wrong Billing Target Date');                        
            }else{
                System.assertEquals(orderRecordItem.TotalPrice,  billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,'The price on the Billing Schedule not equals to the Total Amount in the Order product');
                listBillingTransactionPerShedule = billingTransactionMap.get(billingScheduleMap.get(orderRecordItem.Id).Id);
                
                for(blng__BillingTransaction__c bs : listBillingTransactionPerShedule){
                    sum+=bs.blng__Amount__c;
                    System.assertEquals(cutOffDatesEdition[i+1].addDays(-10),bs.blng__BillingTargetDate__c,'Wrong Billing Target Date');
                    System.Debug('Transaction Billing : '+bs.Billing_Percentage__c +' , '+bs.Billing_sequence__c);
                    i++;
                }
                i=0;
                System.assertEquals(billingScheduleMap.get(orderRecordItem.Id).blng__Amount__c,sum,'The sum prices in the Billing Transactions is not equals to The price on the Billing Schedule');
                sum = 0;  
            }
        }
        Test.stopTest();     
    }
}