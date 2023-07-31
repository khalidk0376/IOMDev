/**
* File:         OrderTriggerHandler
* Project:      PoC SFDC Informa 
* Test Class:   cancelAndRebilPostedInvoicesFCR_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Trigger Hundler on Order.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 25/11/2019
* *******************************************************************************************************

VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti        25/11/2019      Initial Dev
2.0         Ayoub Ouarti		09/12/2019      [IML2R-377] Add the FCR_with_NO_price_change 
3.0         Ayoub Ouarti		20/12/2019      [IML2R-126] Setting the Net Payment Term on the Order level at the time of Order Activation  
4.0			Ayoub Ouarti		24/01/2020		Adding the Partial Credit call


* *******************************************************************************************************/

public class OrderTriggerHandler extends TriggerHandler {
    
    Map<Id, Order> newOrdersMap;
    Map<Id, Order> oldOrdersMap;
    List<Order> newList;
    
    public OrderTriggerHandler(){
        this.newOrdersMap = (Map<Id, Order>)  Trigger.newMap;
        this.oldOrdersMap = (Map<Id, Order>)  Trigger.oldMap;
        this.newList = (List<Order>)  Trigger.new;
    }
    
    public override void beforeUpdate() {
        System.debug('Before Update on  Order ');      
        Map<Id, Order> mapOrder = new Map<Id, Order>([SELECT Id,Status,SBQQ__Quote__r.Amendment_Scenario_Type__c  FROM Order where Id  IN :Trigger.New]); 
        for( Order eachOrder : this.newList) {
            
            if( newOrdersMap.get( eachOrder.Id ).Status  != oldOrdersMap.get( eachOrder.Id ).Status
               && 'Activated'.equals(newOrdersMap.get( eachOrder.Id ).Status) )
            {
               
                //set the paymentterm on the order from the Edition & the full cancelation quote
                PaymentTermOnOrder_Trig.setPaymentTermOnOrder(eachOrder);
            } 
        }        
    }
    
    public override void afterUpdate() {
        System.debug('After Update on  Order ');
        Map<Id, Order> mapOrder = new Map<Id, Order>([SELECT Id,Status,SBQQ__Quote__c,SBQQ__Quote__r.Amendment_Scenario_Type__c  FROM Order where Id  IN :Trigger.New]); 
        for( Order eachOrder : this.newOrdersMap.values())
        {
            
            if(String.isNotBlank(mapOrder.get( eachOrder.Id ).SBQQ__Quote__c)
            && 'PC/AI'.equals(mapOrder.get( eachOrder.Id ).SBQQ__Quote__r.Amendment_Scenario_Type__c )
            && newOrdersMap.get( eachOrder.Id ).Status  != oldOrdersMap.get( eachOrder.Id ).Status
            && 'Activated'.equals(newOrdersMap.get( eachOrder.Id ).Status))
            {
                System.debug('$**$ Amendment case');
                PartialCredit_AdditionalInvoice.Create_PartialCredit_OR_AddtionalInvoice(newOrdersMap.get( eachOrder.Id ));
            }
            
            if( String.isNotBlank(mapOrder.get( eachOrder.Id ).SBQQ__Quote__c)
                && !'PC/AI'.equals(mapOrder.get( eachOrder.Id ).SBQQ__Quote__r.Amendment_Scenario_Type__c )
                && newOrdersMap.get( eachOrder.Id ).Status  != oldOrdersMap.get( eachOrder.Id ).Status
                && 'Activated'.equals(newOrdersMap.get( eachOrder.Id ).Status) )
            { 
                BillingTransactionGenerator bt = new BillingTransactionGenerator(eachOrder);
                ID jobID = System.enqueueJob(bt);   
            }
            
            Boolean FCR_with_NO_price_change = true;
            
            if(FCR_with_NO_price_change){
                String FCR_with_NO_price_change_Temp = 'FCR_with_NO_price_change_Temp__c';
                if( newOrdersMap.get( eachOrder.Id ).get(FCR_with_NO_price_change_Temp)   != oldOrdersMap.get( eachOrder.Id ).get(FCR_with_NO_price_change_Temp) ){
                    if('Cancel-Rebill and Hold'.equals(newOrdersMap.get( eachOrder.Id ).get(FCR_with_NO_price_change_Temp) ) )
                    {
                        CancelAndRebilPostedInvoicesFCR_Trig.cancelInvoicesForOrder(eachOrder);
                    }
                    if('Unhold'.equals(newOrdersMap.get( eachOrder.Id ).get(FCR_with_NO_price_change_Temp) ) )
                    {
                        CancelAndRebilPostedInvoicesFCR_Trig.inverseCancelInvoicesForOrder(eachOrder);
                    }
                }    
            }
        }
    }
}