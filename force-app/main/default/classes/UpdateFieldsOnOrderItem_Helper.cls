/**
* File:         UpdateFieldsOnOrderItem_Helper
* Project:      PoC SFDC Informa 
* Test Class:   UpdateFieldsOnOrderItem_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Helper Class to set the Legal Entity From Order , Hold Billing , Invoice Run  Processing Status on the order Item
* 				 
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 07/02/2020
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti        05/12/2019      Initial Dev
2.0         Girikon(Ashish)     05 May 2022     IOM-1458  - Set the override next billing date field based on the End Date automatically for specific products
* *******************************************************************************************************/
public class UpdateFieldsOnOrderItem_Helper implements Queueable{
    public Set<Id> setOrderIds  ;
    List<OrderItem> listOrderProduct;
    
    /**
* @description [This method is constructor for UpdateFieldsOnOrderItem_Helper class]
* @param setOrderIds set Order Ids
* @param listOrderProduct List Order Products
*/
    public UpdateFieldsOnOrderItem_Helper(Set<Id> setOrderIds, List<OrderItem> listOrderProduct){
        this.setOrderIds = setOrderIds;
        this.listOrderProduct = listOrderProduct;
    }
    
    /**
* @description [This method is execute for UpdateFieldsOnOrderItem_Helper Class]
* @param context List Order
*/
    public void execute(QueueableContext context) {
        updateFieldsOnOrderProduct(this.setOrderIds, this.listOrderProduct);
    }
    
    /**
* @description [This method is for updating order line items]
* @param setOrderIds List Order
* @param listOrderProduct List Order Products
*/
    public static void updateFieldsOnOrderProduct(Set<Id> setOrderIds, List<OrderItem> listOrderProduct){
        List<Order> listOrder = Database.query('SELECT Id ,Legal_Entity__c,Order_Product_Count__c from Order where id IN :setOrderIds');
        
        Map<Id,Order> mapOrders = new Map<Id,Order>(listOrder);
        Map<Id,OrderItem> mapOrderItem = new Map<Id,OrderItem>();
        Set<Id> orderIds = new Set<Id>();
        Boolean isCalculateTax = false;
        
        Map<Id,Boolean> orderAllOrverRideNextBillDtFlagMap = getOrderAllOrverRideNextBillDtFlagMap(mapOrders);
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Edition__c,Edition__r.Edition_Code__c,Legacy_CRM_Instance__c FROM Order WHERE Id in:setOrderIds WITH SECURITY_ENFORCED]);
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
        
        for(OrderItem oi : listOrderProduct){
            string key = orderMap.get(oi.OrderId).Edition__r.Edition_Code__c+'_'+orderMap.get(oi.OrderId).Legacy_CRM_Instance__c;
            
            Boolean orderSetBillingDate =  String.isNotBlank(key) && mapEditionSt.containsKey(key)?(mapEditionSt.get(key)?.Set_Override_Billing_Date_to_OrderDate__c):false;
            
            OrderItem orderItem = new OrderItem();
            orderItem.Id = oi.Id;
            orderItem.Edition__c = orderMap.get(oi.OrderId).Edition__c;
            if(oi.blng__LegalEntity__c == null ){
                orderItem.blng__LegalEntity__c = mapOrders.get(oi.OrderId).Legal_Entity__c; 
                mapOrderItem.put(orderItem.id, orderItem);
                isCalculateTax = true;
                orderIds.add(oi.OrderId);
            }
            if(oi.Issue_Date__c != null){
                orderItem.blng__HoldBilling__c = 'Yes';
                mapOrderItem.put(orderItem.id,orderItem);
            }
            if(oi.Quantity < 0){
                orderItem.blng__InvoiceRunProcessingStatus__c = 'Will Not Invoice';
                mapOrderItem.put(orderItem.id,orderItem);
            }
            // [IOM-1458] - On Insert only
            //Set the override next billing date field based on the End Date automatically for specific products
            if(orderSetBillingDate && oi.Set_Override_Next_Billing_Date__c){
                orderItem.blng__OverrideNextBillingDate__c = Date.today();
                system.debug('if'+orderItem.blng__OverrideNextBillingDate__c);
                mapOrderItem.put(orderItem.id,orderItem);
            }else if(oi.Set_Override_Next_Billing_Date__c
               && !oi.Bill_at_Start_of_Campaign__c
               && orderAllOrverRideNextBillDtFlagMap.containsKey(oi.OrderId) 
               && orderAllOrverRideNextBillDtFlagMap.get(oi.OrderId)
               && oi.EndDate != null)
            {
                orderItem.blng__OverrideNextBillingDate__c = oi.EndDate.addDays(1);
                system.debug('elseif'+orderItem.blng__OverrideNextBillingDate__c);
                mapOrderItem.put(orderItem.id,orderItem);
            }
        }
        
        upsert mapOrderItem.values();
        
        if(!orderIds.isEmpty() && isCalculateTax){CalculateTaxOnOrderItemUpdate_Trig.processOrderTax(orderIds);}
    }
    
    /**
* @description : This method is for geting a map of Order Id and a Flag value which is True id All OLI is set for Override Next Billing Date from Product [IOM-1458]
* @param orderMap Order Map key = OrderId ,value = Order data 
* @return Map<Id,Boolean> - Id - Order Id , val - Flag to Change Next Over Ride DT.
*/
    public static Map<Id,Boolean> getOrderAllOrverRideNextBillDtFlagMap(Map<Id,Order> orderMap)
    {
        Map<Id,Boolean> orderAllOrverRideNextBillDtFlagMap = new Map<Id,Boolean>();
        for (AggregateResult ar :  [SELECT OrderId,Count(Id) FROM OrderItem WHERE OrderId IN:orderMap.keySet() AND Set_Override_Next_Billing_Date__c = true GROUP BY OrderId])  
        {
            Id orderID =  (Id)ar.get('OrderId');
            Integer overRideNextBDtOLICount = (Integer)ar.get('expr0');
            Boolean orFlag = (orderMap.get(orderID).Order_Product_Count__c == overRideNextBDtOLICount) ? true:false;
            orderAllOrverRideNextBillDtFlagMap.put(orderID, orFlag);
        }
        return orderAllOrverRideNextBillDtFlagMap;
    }
}