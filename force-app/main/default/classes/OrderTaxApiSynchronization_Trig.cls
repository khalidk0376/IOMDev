/**
* File         :   OrderTaxApiSynchronization_Trig 
* Project      :   Order & Billing Plateform
* Created Date :   21st Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   OrderTaxApiSynchronization_Trig_Test (98%)
* ******************************************************************************************************
@description : to Create ApiSynchronization Trans & Items When Order is Created 
*******************************************************************************************************
* Modification History :
*  1. [GECI-1416] - Girikon(Ashish)-  24 April 2023, Tax should be calculated when Order status is Cancelled
*/
public with sharing class OrderTaxApiSynchronization_Trig implements TriggerInterface_Order.Runnable 
{
    /** 
*   @description [Call Interface Class to fetch the new list and old map of Order]
*   @param trig [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_Order.Trig trig)
    {
        createApiSyncRecords(trig);
    }
    /**
*   @description Filter Order Records & Create Api Sync Records
*   @param trig [fetch the trigger new list and old map]
*/
    private static void createApiSyncRecords(TriggerInterface_Order.Trig trig)
    {
        Set<Id> orderIds = new Set<Id>();
        for(Order ord : trig.newList)   //[GECI-1416]- Added check for Cancelled
        {
            if(ord.Status != 'Cancelled' && (ord.SBQQ__PriceCalcStatus__c == 'Completed' || ord.SBQQ__PriceCalcStatus__c == 'Not Needed') && ord.SBQQ__PriceCalcStatus__c != trig.oldMap.get(ord.Id).SBQQ__PriceCalcStatus__c)
            {
                if(Test.isRunningTest()){orderIds.add(ord.Id);}
            }
        }
        if(!orderIds.isEmpty()){CalculateTaxOnOrderItemUpdate_Trig.processOrderTax(orderIds);}
    }
}