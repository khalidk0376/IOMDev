/*
* File:         CancelAndRebilPostedInvoicesFCR_Test
* Project:      PoC SFDC Informa
* *******************************************************************************************************
* @description : Testing the CancelAndRebilPostedInvoicesFCR_Trig.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 29/11/2019
* *******************************************************************************************************
*/

@isTest
public class CancelAndRebilPostedInvoicesFCR_Test {
    
    private static Pricebook2 stdPriceBook;
    public static Date[] cutOffDatesOppty = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
        public static Date[] cutOffDatesEdition = new Date[]{Date.toDay().addDays(60),Date.toDay().addDays(90),Date.toDay().addDays(120),Date.toDay().addDays(160)};
            public static Decimal[] cutOffPercentagesOppty = new Decimal[]{25,25,25,25};
                public static Decimal[] cutOffPercentagesEdition = new Decimal[]{25,25,25,25};
                    public static  String nbrOfTransactionApiName='Total_No_of_payment__c';
    public static String paymentTermApiNameEdition = 'Invoice_to_be_issued_before__c';
    public static  String billingSchedulesApiNameOppty='Payment_Schedule__c';
    
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
            Default_Edition__c=listOfEditions[0].Id,
            Name ='TESTOPP',  
            AccountId=acc.Id,Bill_TO_Account__c=acc.Id);
        
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
        
        opp.SBQQ__PrimaryQuote__c=quote.Id;
        update opp;
        
        // create the Order from the quote
        quote.SBQQ__Ordered__c  = true;     
        update quote; 
        
        Order order = Database.query('SELECT Id , Status FROM Order WHERE SBQQ__Quote__c  = \''+quote.Id+'\'');
        order.EffectiveDate = Date.today().addDays(70);
        order.Tax_Status__c = 'Tax Complete';
        update order;
        order.Status='Activated';
        update order;
        order.SBQQ__Contracted__c =true;
        update order;
        order.blng__BillNow__c=true;
        update order;
        
        OrderItem  ordrItem = Database.query('SELECT Id , blng__HoldBilling__c  FROM OrderItem  WHERE OrderId = \''+order.Id+'\'');
        
        SBQQ__Subscription__c subs = new SBQQ__Subscription__c(SBQQ__Quantity__c=0,SBQQ__OrderProduct__c=ordrItem.Id,SBQQ__QuoteLine__c=quoteLine.Id );
        insert subs;
        quoteLine.SBQQ__UpgradedSubscription__c =subs.Id;
        quoteLine.SBQQ__Quantity__c = 0;
        update quoteLine;
        
        List< blng__InvoiceLine__c > listOfInvoiceLine = Database.query('SELECT Id ,blng__Invoice__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__c = \''+ordrItem.Id+'\'' );
        
        System.debug('INFO: listOfInvoiceLine size = '+listOfInvoiceLine.size());        
        
        
        
        List<Id> listOfInvoicesId = new List<Id>();
        for(blng__InvoiceLine__c eachInvoiceLine : listOfInvoiceLine){
            if(!listOfInvoicesId.contains(eachInvoiceLine.blng__Invoice__c)){
                listOfInvoicesId.add(eachInvoiceLine.blng__Invoice__c);
            }
        }
        
        List< blng__Invoice__c > listOfInvoices = Database.query('SELECT Id , blng__Action__c,CreatedDate  FROM blng__Invoice__c WHERE Id in :listOfInvoicesId Order By CreatedDate DESC');
        System.debug('QRY: SELECT Id ,blng__Action__c, CreatedDate  FROM blng__Invoice__c WHERE Id in :'+listToString(listOfInvoicesId)+' Order By CreatedDate DESC');        
        
        System.debug('INFO: listOfInvoice size = '+listOfInvoices.size());       
        
        for(blng__Invoice__c eachInvoice : listOfInvoices){
            eachInvoice.blng__InvoiceStatus__c ='Posted';
            eachInvoice.blng__TaxStatus__c  = null;
        }
        update listOfInvoices;
    }
    
    @isTest
    static void testCancelAndRebilPostedInvoicesFCR(){
        
        
        Trigger__c trig = new Trigger__c(Name = 'CancelAndRebilPostedInvoicesFCR_Trig' , Trigger_Name_Unique__c = 'CancelAndRebilPostedInvoicesFCR_Trig', Enabled__c = true, Object__c = 'SBQQ__Quote__c', Run_for_Recordypes__c = 'All',  Description__c = 'my test', Execution_Order__c = 1, After_Update__c = true );
        Insert trig;
        Trigger_Recordtype__c rt = new Trigger_Recordtype__c(Enabled__c=true,Recordtype_Id__c=trig.Id,Trigger__c=trig.Id,Parameters__c='param=1;param=2');
        Insert rt;
        TriggerInterfaceHelper.runTrigger('CancelAndRebilPostedInvoicesFCR_Trig','SBQQ__Quote__c',1, 'bu', rt.Id,null,'All'); 
        
        Test.startTest(); 
        SBQQ__Quote__c quote = Database.query('SELECT Id ,Amendment_Scenario_Type__c, SBQQ__Type__c ,SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__BillingCity__c = \'TESTQUOTECITY\'');
        
        quote.Amendment_Scenario_Type__c='FCR with price change';
        quote.SBQQ__Type__c='Amendment';
        update quote;
        quote.SBQQ__Status__c='Approved';
        update quote;
        // CancelAndRebilPostedInvoicesFCR_Trig.cancelAndRebilPostedInvoicesFCR(new SBQQ__Quote__c(SBQQ__Status__c='Draft'),quote);
        
        
        
        List<SBQQ__QuoteLine__c> listOfQuoteLines = Database.query('SELECT SBQQ__UpgradedSubscription__c  FROM SBQQ__QuoteLine__c  WHERE SBQQ__Quantity__c  = 0 AND SBQQ__Quote__c  = \''+quote.Id+'\'');
        System.debug('QRY: SELECT SBQQ__UpgradedSubscription__c  FROM SBQQ__QuoteLine__c  WHERE SBQQ__Quantity__c  = 0 AND SBQQ__Quote__c  = \''+quote.Id+'\'');        
        System.debug('INFO: listOfQuoteLines size = '+listOfQuoteLines.size());
        
        List<Id> listOfUpgradedSusbscriptionId = new List<Id>();
        for(SBQQ__QuoteLine__c eachQuoteLine : listOfQuoteLines){
            if(!listOfUpgradedSusbscriptionId.contains(eachQuoteLine.SBQQ__UpgradedSubscription__c)){
                listOfUpgradedSusbscriptionId.add(eachQuoteLine.SBQQ__UpgradedSubscription__c);
            }
        }
        
        List< SBQQ__Subscription__c >listOfSubscription = Database.query('SELECT SBQQ__OrderProduct__c FROM SBQQ__Subscription__c WHERE Id in :listOfUpgradedSusbscriptionId ');
        System.debug('QRY: SELECT SBQQ__OrderProduct__c FROM SBQQ__Subscription__c WHERE Id  in : '+listToString(listOfUpgradedSusbscriptionId));        
        
        System.debug('INFO: listOfSubscription size = '+listOfSubscription.size()); 
        
        List<Id> listOfOrderProductId = new List<Id>();
        for(SBQQ__Subscription__c eachSubscription : listOfSubscription){
            if(!listOfOrderProductId.contains(eachSubscription.SBQQ__OrderProduct__c)){
                listOfOrderProductId.add(eachSubscription.SBQQ__OrderProduct__c);
            }
        }   
        
        List< blng__InvoiceLine__c > listOfInvoiceLine = Database.query('SELECT Id ,blng__Invoice__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__c  in :listOfOrderProductId ');
        System.debug('QRY: SELECT Id, blng__Invoice__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__c  in :'+listToString(listOfOrderProductId));        
        
        System.debug('INFO: listOfInvoiceLine size = '+listOfInvoiceLine.size());        
        
        
        
        List<Id> listOfInvoicesId = new List<Id>();
        for(blng__InvoiceLine__c eachInvoiceLine : listOfInvoiceLine){
            if(!listOfInvoicesId.contains(eachInvoiceLine.blng__Invoice__c)){
                listOfInvoicesId.add(eachInvoiceLine.blng__Invoice__c);
            }
        }
        
        List< blng__Invoice__c > listOfInvoices = Database.query('SELECT Id , blng__Action__c,CreatedDate  FROM blng__Invoice__c WHERE Id in :listOfInvoicesId Order By CreatedDate DESC');
        System.debug('QRY: SELECT Id ,blng__Action__c, CreatedDate  FROM blng__Invoice__c WHERE Id in :'+listToString(listOfInvoicesId)+' Order By CreatedDate DESC');        
        
        System.debug('INFO: listOfInvoice size = '+listOfInvoices.size());       
        
        
        for(blng__Invoice__c eachInvoice : listOfInvoices){
            System.assertEquals('Cancel and Rebill', eachInvoice.blng__Action__c,'Action on the invoice is not set to Cancel and Rebill' );
        }
        
        List<OrderItem > listOfOrderProducts = Database.query('SELECT Id , blng__HoldBilling__c  FROM OrderItem  WHERE Id in :listOfOrderProductId');
        System.debug('QRY: SELECT Id , blng__HoldBilling__c  FROM OrderItem  WHERE Id in : '+listToString(listOfOrderProductId) );        
        
        System.debug('INFO: listOfOrderProducts size = '+listOfOrderProducts.size());       
        
        for(OrderItem eachOrderItem : listOfOrderProducts){
            System.assertEquals('Yes', eachOrderItem.blng__HoldBilling__c ,'fail to set the hold billing on the order product' );
        }
        
        
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id FROM blng__BillingSchedule__c where blng__OrderProduct__c in :listOfOrderProductId');
        System.debug('QRY: SELECT Id FROM blng__BillingSchedule__c where blng__OrderProduct__c in :'+listToString(listOfOrderProductId));        
        
        System.debug('INFO: listBillingSchedule size = '+listBillingSchedule.size());  
        
        List<Id> listOfBillingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c eachBillingSchedule : listBillingSchedule){
            if(!listOfBillingScheduleId.contains(eachBillingSchedule.Id)){
                listOfBillingScheduleId.add(eachBillingSchedule.Id);
            }
        }
        
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id , blng__OverrideStatus__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :listOfBillingScheduleId');
        System.debug('QRY: SELECT Id , blng__OverrideStatus__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :'+listToString(listOfBillingScheduleId));        
        
        System.debug('INFO: listBillingTransaction size = '+listBillingTransaction.size());  
        
        for(blng__BillingTransaction__c eachBillingTransaction : listBillingTransaction){
            System.assertEquals('Cancelled', eachBillingTransaction.blng__OverrideStatus__c,'Failed to cancel the Billing transactiion' );
        }
        Boolean fCRwithNOpricechange = true;
        if(fCRwithNOpricechange){
            String fCRwithNOpricechangeTemp ='FCR_with_NO_price_change_Temp__c';
            
            OrderItem orderProduct = Database.query('SELECT OrderId FROM OrderItem WHERE Id = \''+listOfOrderProductId.get(0)+'\'');  
            Order order = Database.query('SELECT '+fCRwithNOpricechangeTemp+' FROM Order WHERE Id = \''+orderProduct.OrderId+'\'');  
            
            order.FCR_with_NO_price_change_Temp__c='Unhold';
            update order;
            
            //After the Activated the order to fire the Billing transaction generator trigger 
            List<OrderItem> listOrderItem = Database.query('SELECT  blng__HoldBilling__c,blng__TaxStatus__c  FROM OrderItem where OrderId = \''+order.Id+'\'');
            List<String> orderItemId = new List<String> ();
            for(OrderItem orderRecordItem : listOrderItem){
                System.assertEquals('No', orderRecordItem.blng__HoldBilling__c,'Failed to set the hold Billing');
                System.assertEquals('Queued', orderRecordItem.blng__TaxStatus__c,'Failed to set the Tax status');
                
            }
            
            order.FCR_with_NO_price_change_Temp__c='Cancel-Rebill and Hold';
            update order;
            
            //After the Activated the order to fire the Billing transaction generator trigger 
            listOrderItem = Database.query('SELECT  blng__HoldBilling__c,blng__TaxStatus__c  FROM OrderItem where OrderId = \''+order.Id+'\'');
            orderItemId = new List<String> ();
            for(OrderItem orderRecordItem : listOrderItem){
                System.assertEquals('Yes', orderRecordItem.blng__HoldBilling__c,'Failed to set the Hold Billing');            
            }
        }
        
        Test.stopTest();
    }
    
    
    public static String listToString(List<Id> listElement){
        String str='';
        for(ID eachId : listElement){
            str+=' , '+eachId;
        }
        return str;
    }
    
}