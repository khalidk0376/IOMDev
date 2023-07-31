/**
* File:         CancelAndRebilPostedInvoicesFCR_Trig
* Project:      PoC SFDC Informa 
* Test Class:   cancelAndRebilPostedInvoicesFCR_Test
* Coverage:     95%
* *******************************************************************************************************
* @description : Trigger Hundler on SBQQ_Quote.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 29/11/2019
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
    1.0         Ayoub Ouarti        29/11/2019      Initial Dev
    2.0         Ayoub Ouarti        09/12/2019      IML2R-377 Add the FCR_with_NO_price_change 
    3.0         Girikon(Ashish)     20/04/2022      TDA 2 Issue Fixes [IOM-1258]
* *******************************************************************************************************/
public with sharing class CancelAndRebilPostedInvoicesFCR_Trig  implements TriggerInterface_SBQQ_Quote.Runnable  {
    
    public void run(TriggerInterface_SBQQ_Quote.Trig trig) {
        if (trig.isAfter && trig.isUpdate) {
            String quoteStatus= 'Approved';
            for( SBQQ__Quote__c  eachQuote : trig.newMap.values())
            {  
                if( trig.oldMap.get(eachQuote.Id ).SBQQ__Status__c   != eachQuote.SBQQ__Status__c  && quoteStatus.equals(eachQuote.SBQQ__Status__c) )
                {
                    cancelAndRebilPostedInvoicesFCR(eachQuote);
                }
            }
              
        }
    }
    public static void cancelAndRebilPostedInvoicesFCR(SBQQ__Quote__c  newQuote){
        String amendmentScenarioTypeFCR = 'FCR with price change';
        String amendmentScenarioTypeFC = 'Full cancellation';
        String quoteType= 'Amendment';
        String quoteStatus= 'Approved';
        String qteId = newQuote.Id;
        // if( oldQuote.SBQQ__Status__c   != newQuote.SBQQ__Status__c  && quoteStatus.equals(newQuote.SBQQ__Status__c) )
        // {
            if( (amendmentScenarioTypeFCR.equals(newQuote.Amendment_Scenario_Type__c) || amendmentScenarioTypeFC.equals(newQuote.Amendment_Scenario_Type__c) )
               && quoteType.equals(newQuote.SBQQ__Type__c)){
                   
                   System.debug('Quote '+newQuote.Id+' is about to Cancel-Rebill all the posted invoices with FCR with price change');
                   
                   // Get the Quote Lines for the Quote
                   List<SBQQ__QuoteLine__c> listOfQuoteLines = Database.query('SELECT SBQQ__UpgradedSubscription__c  FROM SBQQ__QuoteLine__c  WHERE SBQQ__Quantity__c  = 0 AND SBQQ__Quote__c  = :qteId ');
                   System.debug('QRY: SELECT SBQQ__UpgradedSubscription__c  FROM SBQQ__QuoteLine__c  WHERE SBQQ__Quantity__c  = 0 AND SBQQ__Quote__c  = :qteId ');
                   
                   System.debug('INFO: listOfQuoteLines size = '+listOfQuoteLines.size());        
                   
                   // construct a list of Upgraded Susbscription Id from the listOfQuoteLines
                   List<Id> listOfUpgradedSusbscriptionId = new List<Id>();
                   for(SBQQ__QuoteLine__c newQuoteLine : listOfQuoteLines){
                       if(!listOfUpgradedSusbscriptionId.contains(newQuoteLine.SBQQ__UpgradedSubscription__c)){
                           listOfUpgradedSusbscriptionId.add(newQuoteLine.SBQQ__UpgradedSubscription__c);
                       }
                   }
                   
                   // Get Upgraded Susbscription from the listOfUpgradedSusbscriptionId
                   List< SBQQ__Subscription__c >listOfSubscription = Database.query('SELECT SBQQ__OrderProduct__c FROM SBQQ__Subscription__c WHERE Id in :listOfUpgradedSusbscriptionId ');
                   System.debug('QRY: SELECT SBQQ__OrderProduct__c FROM SBQQ__Subscription__c WHERE Id  in : '+listToString(listOfUpgradedSusbscriptionId));        
                   
                   System.debug('INFO: listOfSubscription size = '+listOfSubscription.size()); 
                   
                   // construct a list Of Order Product Id from the list Of Subscription
                   List<Id> listOfOrderProductId = new List<Id>();
                   for(SBQQ__Subscription__c eachSubscription : listOfSubscription){
                       if(!listOfOrderProductId.contains(eachSubscription.SBQQ__OrderProduct__c)){
                           listOfOrderProductId.add(eachSubscription.SBQQ__OrderProduct__c);
                       }
                   }
                   
                   cancelInvoicesForOrderProductIds(listOfOrderProductId);
               } 
        // }
    }
    
    public static void cancelInvoicesForOrder(Order order){
        String ordId = order.Id;
        List<OrderItem>  listOfOrderProduct = Database.query('SELECT Id , blng__LegalEntity__c  FROM OrderItem  WHERE OrderId = :ordId ');        
        
        List<Id> listOfOrderProductId = new List<Id>();
        for(OrderItem eachOrderProduct : listOfOrderProduct){
            if(!listOfOrderProductId.contains(eachOrderProduct.Id)){
                listOfOrderProductId.add(eachOrderProduct.Id);
            }
        }
        cancelInvoicesForOrderProductIds(listOfOrderProductId);
    }
    /** 
    * @description  - Cancel Invs with OrderProducts
    * @param listOfOrderProductId OrderProducts Id
    */
    public static void cancelInvoicesForOrderProductIds(List<Id> listOfOrderProductId)
    {
        cancelInvoicesForOrderProductIds(listOfOrderProductId,new List<Id>());
    }
    /** 
    * @description  - Set the Hold Billing on Order Products after Invoice is Canceled
    * @param listOfOrderProductId map of OrderItem items
    * @param listtoCancelInvId list Of Invoice Ids
    */
    public static void cancelInvoicesForOrderProductIds(List<Id> listOfOrderProductId,List<Id> listtoCancelInvId)
    {
        cancelInvoicesForOrderProductIds(listOfOrderProductId,listtoCancelInvId,false);
    }
    /** 
    * @description  - Set the Hold Billing on Order Products after Invoice is Canceled
    * @param listOfOrderProductId map of OrderItem items
    * @param listtoCancelInvId list Of Invoice Ids
    * @param executeAsync Flag to execte through Batch [Default false]
    */
    public static void cancelInvoicesForOrderProductIds(List<Id> listOfOrderProductId,List<Id> listtoCancelInvId,Boolean executeAsync)
    {
        Set <Id> withOutInvoiceOrderProductIds = new Set <Id>(listOfOrderProductId);
        // Get Invoice Line from the listOfOrderProductId
        List< blng__InvoiceLine__c > listOfInvoiceLine = Database.query('SELECT Id, blng__Invoice__c,blng__OrderProduct__c FROM blng__InvoiceLine__c WHERE blng__OrderProduct__c  in :listOfOrderProductId AND blng__Invoice__r.blng__InvoiceStatus__c not in (\'Rebilled\',\'Cancelled\') ');

        // construct a list Of Invoices Id from the list Of Subscription
        List<Id> listOfInvoicesId = new List<Id>();
        for(blng__InvoiceLine__c eachInvoiceLine : listOfInvoiceLine){
            if(!listOfInvoicesId.contains(eachInvoiceLine.blng__Invoice__c)){
                listOfInvoicesId.add(eachInvoiceLine.blng__Invoice__c);
            }
            withOutInvoiceOrderProductIds.remove(eachInvoiceLine.blng__OrderProduct__c);
        }
        if(listtoCancelInvId!=null && !listtoCancelInvId.isEmpty()){
            listOfInvoicesId.clear();listOfInvoicesId.addAll(listtoCancelInvId);
        }
        // Get Invoices from the listOfInvoicesId
        List< blng__Invoice__c > listOfInvoices = Database.query('SELECT Id , CreatedDate FROM blng__Invoice__c WHERE  blng__InvoiceStatus__c not in (\'Rebilled\',\'Cancelled\') AND Id In :listOfInvoicesId Order by blng__InvoiceDate__c DESC ');     
             
        Set<Id> invIds = new Set<Id>();
        // Call the API : creditInvoice for each invoice 
        for(blng__Invoice__c eachInvoice : listOfInvoices){
            System.debug('INFO: Befor calling the InvoiceAPI.creditInvoice API with : invoice = '+eachInvoice.Id+' and action = Cancel and Rebill');
            invIds.add(eachInvoice.Id);            
        }
        if(listOfInvoices.size() == 1 && executeAsync != true) // IOM-1502
        { // Instant Cancel and Rebill 
            blng.InvoiceAPI.creditInvoice(listOfInvoices.get(0).Id, 'Cancel and Rebill');
            holdOrderProductsBilling(listOfOrderProductId);
        }else{
            if(!listOfInvoices.isEmpty()){
                CancelRebillInvoicesBatch criObj = new CancelRebillInvoicesBatch(invIds);
                AmendmentUtils.asyncJobId = Database.executeBatch(criObj,1);
            }            
            // Hold Order Products without invoices
            holdOrderProductsBilling(new List<Id>(withOutInvoiceOrderProductIds));
        }
    }

     /** 
    * @description  - Set the Hold Billing on Order Products after Invoice is Canceled
    * @param listOfOrderProductId map of OrderItem items
    */
    public static void holdOrderProductsBilling(List<Id> listOfOrderProductId)
    {
        // Get  Order Products from the list OfOrderProductId
        List<OrderItem > listOfOrderProducts = Database.query('SELECT Id , blng__HoldBilling__c  FROM OrderItem  WHERE Id in :listOfOrderProductId');   
        
        // Update each order item's blng__HoldBilling__c to YES
        for(OrderItem eachOrderItem : listOfOrderProducts){
            eachOrderItem.blng__HoldBilling__c = 'Yes';
            System.debug('INFO: Hold Billing the Order Product = '+eachOrderItem.Id);            
            
        }
        if(!listOfOrderProducts.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable())
        {
            update listOfOrderProducts;
        }
        
        // Get Billing Schedule from the list listOfOrderProductId                   
        List<blng__BillingSchedule__c> listBillingSchedule = Database.query('SELECT Id FROM blng__BillingSchedule__c where blng__OrderProduct__c in :listOfOrderProductId');
        System.debug('QRY: SELECT Id FROM blng__BillingSchedule__c where blng__OrderProduct__c in :'+listToString(listOfOrderProductId));        
        
        System.debug('INFO: listBillingSchedule size = '+listBillingSchedule.size());  
        
        List<Id> listOfBillingScheduleId = new List<Id>();
        for(blng__BillingSchedule__c eachBillingSchedule : listBillingSchedule){
            if(!listOfBillingScheduleId.contains(eachBillingSchedule.Id)){
                listOfBillingScheduleId.add(eachBillingSchedule.Id);
            }
        }
        
        // Get Billing Transaction from the list listOfBillingScheduleId 
        List<blng__BillingTransaction__c> listBillingTransaction = Database.query('SELECT Id , blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :listOfBillingScheduleId and blng__Status__c=\'Pending\'');
        System.debug('QRY: SELECT Id , blng__Amount__c , blng__BillingSchedule__c, Name, blng__Status__c, blng__BillingTargetDate__c FROM blng__BillingTransaction__c where blng__BillingSchedule__c in :'+listToString(listOfBillingScheduleId));        
        
        System.debug('INFO: listBillingTransaction size = '+listBillingTransaction.size());  
        
        // Update each order item's blng__OverrideStatus__c to Cancelled
        for(blng__BillingTransaction__c eachBillingTransaction : listBillingTransaction){
            eachBillingTransaction.blng__OverrideStatus__c  ='Cancelled' ;
            eachBillingTransaction.blng__OverrideAmount__c   =0 ;
            System.debug('INFO: Canceling the Billing Transaction = '+eachBillingTransaction.Id); 
        }
        if(!listBillingTransaction.isEmpty() && Schema.sObjectType.blng__BillingTransaction__c.isUpdateable()){
            update listBillingTransaction;
        }
    }
    
    public static void inverseCancelInvoicesForOrder(Order order){
        String ordId = order.Id;
        List<OrderItem>  listOfOrderProduct = Database.query('SELECT Id  FROM OrderItem  WHERE OrderId = :ordId ');        
        
        List<Id> listOfOrderProductId = new List<Id>();
        for(OrderItem eachOrderProduct : listOfOrderProduct){
            if(!listOfOrderProductId.contains(eachOrderProduct.Id)){
                listOfOrderProductId.add(eachOrderProduct.Id);
            }
        }
        inverseCancelInvoicesForOrderProductIds(listOfOrderProductId);
        BillingTransactionGenerator.generateBillingTransaction(order);
    }
    
    public static void inverseCancelInvoicesForOrderProductIds(List<Id> listOfOrderProductId){
        // Get Invoice Line from the listOfOrderProductId
        
        // Get  Order Products from the list OfOrderProductId
        List<OrderItem > listOfOrderProducts = Database.query('SELECT Id , blng__HoldBilling__c ,blng__TaxStatus__c FROM OrderItem  WHERE blng__HoldBilling__c = \'Yes\' AND Id in :listOfOrderProductId');
        System.debug('QRY: SELECT Id , blng__HoldBilling__c  FROM OrderItem  WHERE Id in : '+listToString(listOfOrderProductId) );        
        
        System.debug('INFO: listOfOrderProducts size = '+listOfOrderProducts.size());       
        
        // Update each order item's blng__HoldBilling__c to No
        for(OrderItem eachOrderItem : listOfOrderProducts){
            eachOrderItem.blng__HoldBilling__c = 'No';
            eachOrderItem.blng__TaxStatus__c='Queued';
            System.debug('INFO: Hold Billing the Order Product = '+eachOrderItem.Id);
        }
        if(!listOfOrderProducts.isEmpty() && Schema.sObjectType.OrderItem.isUpdateable())
        {
            update listOfOrderProducts;
        }        
    }
    
    public static String listToString(List<Id> listElement){
        String str='';
        for(ID eachId : listElement){
            str+=' , '+eachId;
        }
        return str;
    }
}