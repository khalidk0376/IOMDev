/**
* File:         PaymentTermOnOrder_Trig
* Project:      PoC SFDC Informa 
* Test Class:   PaymentTermOnOrder_Test
* Coverage:     96%
* *******************************************************************************************************
* @description : Setting the Net Payment Term on the Order level at the time of Order Activation 
*               ( the Invoice due date calculation as Invoice due date = Invoice Start date + ‘Net Payment’ Term on Order)
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 20/12/2019
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti            20/12/2019      Initial Dev

* *******************************************************************************************************/

public with sharing class PaymentTermOnOrder_Trig {
    /**
    * @description [This method is used to set parment term and reason on order]
    * @param ord Order
    */
    public static void setPaymentTermOnOrder(Order ord){
        Boolean onEdition  = false;
        String ordQuoteId = ord.SBQQ__Quote__c;
        if(String.isNotBlank(ordQuoteId))
        {
            List<Quote_Edition__c> listQuoteEdition = Database.query('SELECT Edition__r.Start_Date__c ,Edition__r.Edition_Cut_Off_days__c   FROM Quote_Edition__c WHERE Quote__c   = :ordQuoteId ');
            SBQQ__Quote__c quote = Database.query('SELECT Amendment_Scenario_Type__c FROM SBQQ__Quote__c WHERE Id = :ordQuoteId ');
            if(listQuoteEdition.size()>0 ){
                for(Quote_Edition__c  eachQuoteEdition :listQuoteEdition){
                    //Case 1 : Edition start day - Cutt of days < today
                    if(eachQuoteEdition.Edition__r.Start_Date__c!=null  && eachQuoteEdition.Edition__r.Edition_Cut_Off_days__c!=null 
                       && eachQuoteEdition.Edition__r.Start_Date__c.addDays( -1 *integer.valueof( eachQuoteEdition.Edition__r.Edition_Cut_Off_days__c)) <= Date.toDay()){
                           ord.SBQQ__PaymentTerm__c ='Due on receipt';
                           ord.Payment_Term_Reason__c ='One of more Editions with Payment Term "Due on Receipt"';
                           System.debug(LoggingLevel.DEBUG, ord.Payment_Term_Reason__c);
                           onEdition = true;
                           break;
                       } 
                }
            }
              // Case 2 : Full cancellation on the Quote
            if(!onEdition && 'Full cancellation'.equals(quote.Amendment_Scenario_Type__c)){
                ord.SBQQ__PaymentTerm__c ='Due on receipt'; 
                ord.Payment_Term_Reason__c ='"Full cancellation" amendment Scenario';
                System.debug(LoggingLevel.DEBUG, ord.Payment_Term_Reason__c);
            }  
        }
    } 
    
     /**
    * @description [This method is used to set parment term and reason on order based on order item]
    * @param orderID Order Id
    */
    public static void setPaymentTermOnOrderFromOrderItem(ID orderID){
     
        Boolean sameValue = true;
        String ordId = String.valueOf(orderID);
        System.debug(LoggingLevel.DEBUG, ordId);
        Order order =  Database.query('SELECT SBQQ__PaymentTerm__c,Payment_Term_Reason__c ,Status FROM Order where Id = :ordId ');
        List<OrderItem> orderItems =  Database.query('SELECT SBQQ__Activated__c,OrderId,Payment_Term_used_for_BT_Calculation__c,Product_Invoice_property__c, Payment_Term__c,Quantity , blng__InvoiceRunProcessingStatus__c  ,Edition__c ,TotalPrice,SBQQ__QuoteLine__c ,SBQQ__BillingFrequency__c  FROM OrderItem where  OrderId = :ordId ');

         // Case 3 : Make sure that the payment term reason have not fulfilled yet
        if(order.Payment_Term_Reason__c==null ){        
            if('Activated'.equals(order.Status)){
                for(OrderItem ordItem : orderItems){
                    if(!ordItem.SBQQ__Activated__c ){
                        sameValue = false; break;
                    }
                     // Case 3 : Make sure that all the product have the same payment term value
                    if(ordItem.Payment_Term_used_for_BT_Calculation__c ==null ||orderItems.get(0).Payment_Term_used_for_BT_Calculation__c != ordItem.Payment_Term_used_for_BT_Calculation__c){sameValue = false;Break;}else{
                        System.debug(LoggingLevel.DEBUG, 'ordItem.Payment_Term_used_for_BT_Calculation__c -------- '+ ordItem.Payment_Term_used_for_BT_Calculation__c);
                    }
                }
                if(sameValue && Schema.sObjectType.Order.isUpdateable()){
                    order.SBQQ__PaymentTerm__c =orderItems.get(0).Payment_Term_used_for_BT_Calculation__c;
                    order.Payment_Term_Reason__c ='Same Payment Term on all Products to be invoiced';                    
                    update order;
                }
            }
        }
    }
    
}