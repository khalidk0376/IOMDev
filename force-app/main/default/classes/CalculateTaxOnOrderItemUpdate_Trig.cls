/**
* File         :   CalculateTaxOnOrderItemUpdate_Trig 
* Project      :   Order & Billing Plateform
* Created Date :   21 Sept 2021
* Created By   :   Girikon(Deepak)
* Test Class   :   CalculateTaxOnOrderItemUpdate_Trig_Test(100%)
* ******************************************************************************************************
* @description : For Creating Records to API Synchronization After Order Product Tax Status is made Queued
********************************************************************************************************
* Modification History :
*  1. [GECI-1416] - Girikon(Ashish)-  24 April 2023, Tax should be calculated when Order status is Cancelled
*/
public with sharing class CalculateTaxOnOrderItemUpdate_Trig implements TriggerInterface_OrderItem.Runnable{
    
    /**
    * @description [This method is for running the Trigger on Order Item using the interface class on After Update.]
    * @param trig
    */
    public void run(TriggerInterface_OrderItem.Trig trig) {
        if(trig.isAfter && trig.isUpdate){
            Set<Id> orderIds = new Set<Id>();
            for(OrderItem oi : trig.newList){
                if(oi.blng__TaxStatus__c == 'Queued' && oi.blng__TaxStatus__c != trig.oldMap.get(oi.Id).blng__TaxStatus__c){
                    orderIds.add(oi.OrderId);
                }
            }            
            if(!orderIds.isEmpty()){processOrderTax(orderIds);}
        }
    }

    /**
    * @description [This method is used to process order tax.]
    * @param orderIds
    */
    public static void processOrderTax(Set<Id> orderIds){
        List<Order> finalorderList = new List<Order>();
        Map<String,Edition_Setting__mdt> mapES = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
        for(Order o : [SELECT Id,Legacy_CRM_Instance__c,Edition__r.Edition_Code__c FROM Order WHERE Id IN : orderIds AND Status != 'Cancelled' WITH SECURITY_ENFORCED]){
            String key = o.Edition__r.Edition_Code__c + '_' + o.Legacy_CRM_Instance__c;
            Boolean disableTaxCal =  (String.isNotBlank(key) && mapES.containsKey(key))?(mapES.get(key)?.Disable_Tax_Calculation__c):false;
            if(!disableTaxCal){
                finalorderList.add(o);
            }
        }
        
        if(!finalorderList.isEmpty()){
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.type = 'Update';
            obj.startedFrom = 'Order';
            obj.listSObject = finalorderList;
            obj.requestType = GlobalConstants.ASYNCHRONOUS;
            obj.externalTaxSystem = GlobalConstants.ONESOURCE;
            obj.apiCallType = 'POST';
            obj.itemType = 'Tax';
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
}