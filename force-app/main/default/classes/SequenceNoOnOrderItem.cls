/**
 *RA ,17/01/2020
 *@description Class to add sequence numbers on OrderItems
 * Test Class:   UpdateFieldsOnOrderItem_Test
 */
public with sharing class SequenceNoOnOrderItem {
    /**
     *@description add sequence No on invoiceLines   
	 *@param listOfOrdItems  list of OrderItems
	 */    
    public static void addOrderItemSequenceNo(List<OrderItem> listOfOrdItems){        
        Map<Id,Integer> mapOrderIdStartSequenceNum = new Map<Id,Integer>();
        for(OrderItem ordItem : listOfOrdItems){
            mapOrderIdStartSequenceNum.put(ordItem.OrderId,0);
        }

        for(OrderItem oli : [SELECT Id,Line_Item_Number__c,OrderId FROM OrderItem WHERE OrderId IN:mapOrderIdStartSequenceNum.keySet() WITH Security_Enforced ORDER BY OrderId,Line_Item_Number__c ASC]){
            mapOrderIdStartSequenceNum.put(oli.OrderId,Integer.valueOf(oli.Line_Item_Number__c));
        }

        //add Sequence No on OrderItems 
        for(OrderItem ordItem : listOfOrdItems){
            Integer seqNo = mapOrderIdStartSequenceNum.get(ordItem.OrderId) + 1;
            ordItem.Line_Item_Number__c = seqNo;
            mapOrderIdStartSequenceNum.put(ordItem.OrderId,seqNo);
        }        
    }
}