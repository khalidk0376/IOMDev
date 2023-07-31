/**
* File:         ActivateOrderFromOrderItem
* Project:      GE-IOM
* Test Class:   ActivateOrderFromOrderItem_Test
* Coverage:     90%
* *******************************************************************************************************
* @description : Class to Activate order based on Order Item
* 				 
* @author: Girikon(Ansh)
* @date: 17/01/2023
* *******************************************************************************************************/

public class ActivateOrderFromOrderItem implements Schedulable{
    /**
    * @description [This method is executed for ActivateOrderFromOrderItem Class]
    * @param sc SchedulableContext
    */
    public void execute(SchedulableContext sc) {
        getOrderIds();
    }

    /**
    * @description [This method is for fetching orderIds from order line items]
    */
    public static void getOrderIds(){
        Set<Id> orderIds = new Set<Id>();
        for(OrderItem oi : [SELECT Id,OrderId FROM OrderItem WHERE Order.Status = 'Draft' AND Order.Tax_Status__c = 'Tax Complete' AND Product2.ActivateOrder_OverrideBillingDateIsToday__c = true AND (blng__OverrideNextBillingDate__c = TODAY OR (blng__OverrideNextBillingDate__c =null AND blng__NextBillingDate__c = TODAY)) AND SBQQ__BillingFrequency__c != 'Invoice Plan' WITH SECURITY_ENFORCED]){
            if(oi.OrderId != null){
                orderIds.add(oi.OrderId);
            }
        }
        updateOrderStatus(orderIds);
    }
    /**
    * @description [This method is for updating all orders which have products marked for flag [Activate Order if billing Date is today] & it's billing date is today]
    * @param orderIds Set of Order Ids
    */
    public static void updateOrderStatus(Set<Id> orderIds){
        Map<Id,Order> mapOrd = new Map<Id,Order>();  

        for(Order ord : [SELECT Id,Status,(SELECT OrderId, Product2.ActivateOrder_OverrideBillingDateIsToday__c,blng__OverrideNextBillingDate__c,blng__NextBillingDate__c FROM OrderItems) FROM Order WHERE Id =: orderIds AND Status != 'Activated' AND Tax_Status__c = 'Tax Complete' WITH SECURITY_ENFORCED]) 
        {
            for (OrderItem oli : ord.OrderItems) 
            {
                if(oli.Product2.ActivateOrder_OverrideBillingDateIsToday__c == true && 
                    (oli.blng__OverrideNextBillingDate__c == Date.today() || 
                    (oli.blng__OverrideNextBillingDate__c == null && oli.blng__NextBillingDate__c == Date.today())
                    )
                ){
                    Order order = new Order(Id = ord.Id);
                    order.Status = 'Activated';
                    mapOrd.put(ord.Id,order);
                }
            }
        }
        if(!mapOrd.isEmpty()){
            update mapOrd.values();
        }
    }
}