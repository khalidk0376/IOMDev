/**
* File:         UpdateFieldsOnOrderItem_Trig
* Project:      PoC SFDC Informa 
* Test Class:   UpdateFieldsOnOrderItem_Test
* Coverage:     90%
* *******************************************************************************************************
* @description : Trigger Hundler on SBQQ__OrderItemConsumptionSchedule to set the Legal Entity on the order Item & 
* 				 order Item Consumption schedule for usage based pricing product.
* @author: Ayoub Ouarti (aouarti@salesforce.com)
* @date: 05/12/2019
* *******************************************************************************************************
History
-------
VERSION         AUTHOR              DATE            DETAIL
1.0         Ayoub Ouarti        05/12/2019      Initial Dev
2.0         Ayoub Ouarti		11/12/2019      Reduce the number of queries, set the legal entity on the order item
3.0			Ayoub Ouarti		07/02/2020		Update the file's name, remove the traitment to a Queueable job
4.0         Deepak(Girikon)     01/10/2021      Update blng__InvoiceGrouping__c Field on the order item(OBP-402)
5.0         Ashish(Girikon)     05 May 2022     IOM-1458  - Set the override next billing date field based on the End Date automatically for specific products
6.0         Ashish(Girikon)     06 June 2022    IOM-1591  - The update of the start and end date on the order products should update all the other dates needed
7.0         Ashish(Girikon)     02 Nov 2022     GECI-28   - set Translated_Product_Description from QLI if avaliable
* *******************************************************************************************************/

public with sharing class UpdateFieldsOnOrderItem_Trig implements TriggerInterface_OrderItem.Runnable{
    
    private static final String INVOICE_GROUP = 'Invoice_Group';
    
    /**
    * @description Trigger handler method for OrderItem based on the event called, the processing is dispatched accordingly
    * @param trig TriggerInterface_OrderItem.Trig instance.
    */
    public void run(TriggerInterface_OrderItem.Trig trig){
        handleBefore(trig);
        handleAfter(trig);
    } 

    /**
    * @description Trigger handler method for OrderItem based on before Insert, the processing is dispatched accordingly
    * @param trig TriggerInterface_OrderItem.Trig instance.
    */
    public void handleBefore(TriggerInterface_OrderItem.Trig trig){
        Set<Id> orderIds = new Set<Id>();
        if(trig.isBefore && trig.isInsert){
            for(OrderItem orderRecordItem : trig.newList){
                if(orderRecordItem.Quantity < 0){
                    orderRecordItem.blng__InvoiceRunProcessingStatus__c = 'Will Not Invoice';
                }
                orderRecordItem.blng__InvoiceGrouping__c = GlobalConstants.getValue(INVOICE_GROUP);//IOM-275
            }
            SequenceNoOnOrderItem.addOrderItemSequenceNo(trig.newList);
            setFieldsFromProduct(trig.newList,null);
        }
        // Before Update
        if(trig.isBefore && trig.isUpdate)
        {
            setOrderAllOrverRideNextBillDt(trig.oldMap,trig.newList);
            //
            setTaxData(trig.oldMap,trig.newList);
        }
        // After Update
        if(trig.isAfter && trig.isUpdate){
            for(OrderItem oi : trig.newList){
                orderIds.add(oi.OrderId);
            }
            ActivateOrderFromOrderItem.updateOrderStatus(orderIds);
        }
    }

    /**
    * @description Trigger handler method for OrderItem based on After Insert and After Update, the processing is dispatched accordingly
    * @param trig TriggerInterface_OrderItem.Trig instance.
    */
    public void handleAfter(TriggerInterface_OrderItem.Trig trig){
        // Set the Legal Entity on the Order Product Consumption Schedule from the Order Product
        if(trig.isAfter && trig.isUpdate){
            Set<Id> ids = trig.newMap.keySet();
            System.debug(LoggingLevel.DEBUG, ids);
            List<SBQQ__OrderItemConsumptionSchedule__c> listOrderItemConSch = Database.query('SELECT SBQQ__OrderItem__c,blng__BillingRule__c,blng__TaxRule__c,blng__RevenueRecognitionRule__c,blng__LegalEntity__c  FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c in :ids');
            legalEntityOnOrderItemConSch(trig.newMap,listOrderItemConSch);
            setQLIupdatedDates(trig.newList,trig.oldMap);
            
            setTaxStatus(trig.oldMap,trig.newList);
        }
        // Set the Legal Entity on the Order Product
        if(trig.isAfter && trig.isInsert){
            Set<Id> orderIds = new Set<Id>();
            for(OrderItem oi : trig.newList){
                orderIds.add(oi.OrderId);
            }
            UpdateFieldsOnOrderItem_Helper job = new UpdateFieldsOnOrderItem_Helper(orderIds,trig.newList);
            System.enqueueJob(job); 

            // Set the Legal Entity on the Order Product Consumption Schedule from the Order Product
            Set<Id> ids = trig.newMap.keySet();
            System.debug(LoggingLevel.DEBUG, ids);
            List<SBQQ__OrderItemConsumptionSchedule__c> listOrderItemConSch = Database.query('SELECT SBQQ__OrderItem__c,blng__BillingRule__c,blng__TaxRule__c,blng__RevenueRecognitionRule__c,blng__LegalEntity__c  FROM SBQQ__OrderItemConsumptionSchedule__c WHERE SBQQ__OrderItem__c in :ids ');
            legalEntityOnOrderItemConSch(trig.newMap,listOrderItemConSch);
        }
    }
    
    /**
    * @description to set legal entity on Order Product's Consumption Schedule
    * @param newMap map of oarder items
    * @param listOrderItemConSch list of Consumption Schedule
    */
    public static void legalEntityOnOrderItemConSch(Map<Id, OrderItem> newMap, List<SBQQ__OrderItemConsumptionSchedule__c> listOrderItemConSch){
        List<SBQQ__OrderItemConsumptionSchedule__c> listOrderItemConSchtoSave = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        for(SBQQ__OrderItemConsumptionSchedule__c orderItemConSch : listOrderItemConSch){
            if(orderItemConSch.blng__LegalEntity__c == null && orderItemConSch.blng__RevenueRecognitionRule__c != null && orderItemConSch.blng__TaxRule__c != null && orderItemConSch.blng__BillingRule__c!= null){
                   if(newMap.get(orderItemConSch.SBQQ__OrderItem__c).blng__LegalEntity__c != null ){
                       orderItemConSch.blng__LegalEntity__c  = newMap.get(orderItemConSch.SBQQ__OrderItem__c).blng__LegalEntity__c;
                       listOrderItemConSchtoSave.add(orderItemConSch);
                   }
            }
        }
        if(!listOrderItemConSchtoSave.isEmpty() && Schema.sObjectType.SBQQ__OrderItemConsumptionSchedule__c.isUpdateable()){
            update listOrderItemConSchtoSave;
        }
    }
    /** [IOM-1458]
    * @description  - Set the override next billing date field based on the End Date automatically for specific products [IOM-1458]            
    * @param oldMapOLI map of OrderItem items
    * @param newlistOLI Map of Old OLI
    */
    public static void setOrderAllOrverRideNextBillDt(Map<Id, OrderItem> oldMapOLI,List<OrderItem> newlistOLI )
    {
        Set<Id> setOrderIds = new Set<Id>();
        for(OrderItem oi : newlistOLI)
        {
            if(oi.EndDate != null && oi.EndDate != oldMapOLI.get(oi.Id).EndDate)
            {
                setOrderIds.add(oi.OrderId);
            }            
        }
        
        if(!setOrderIds.isEmpty())
        {
            List<Order> listOrder = Database.query('SELECT Id ,Legal_Entity__c,Order_Product_Count__c from Order where id IN :setOrderIds');
            Map<Id,Order> mapOrders = new Map<Id,Order>(listOrder);
            Map<Id,Boolean> orderAllOrverRideNextBillDtFlagMap = UpdateFieldsOnOrderItem_Helper.getOrderAllOrverRideNextBillDtFlagMap(mapOrders);

            for(OrderItem oi : newlistOLI)
            {
                if(oi.EndDate != null 
                    && oi.EndDate != oldMapOLI.get(oi.Id).EndDate
                    && oi.Set_Override_Next_Billing_Date__c
                    && !oi.Bill_at_Start_of_Campaign__c
                    && orderAllOrverRideNextBillDtFlagMap.containsKey(oi.OrderId) 
                    && orderAllOrverRideNextBillDtFlagMap.get(oi.OrderId))
                {                    
                    oi.blng__OverrideNextBillingDate__c = oi.EndDate.addDays(1);
                }            
            } 
        }       
    }

    /** -----[IOM-1591]-----
    * @description  - Set New updated Order Products Dates [Start+End] back to QLI --
    * @param newOrderProducts List of new OrderItem items
    * @param oldOrderProductsMap Map of Old OLI
    */
    public static void setQLIupdatedDates(list<OrderItem> newOrderProducts,map<Id,OrderItem> oldOrderProductsMap)
    {
        List<SBQQ__QuoteLine__c> listQuoteLines = new List<SBQQ__QuoteLine__c>();
        for(OrderItem oi : newOrderProducts)
        {        
            //system.debug(' OL - -- '+oi.ServiceDate+' & '+oi.EndDate+' --> '+oldOrderProductsMap.get(oi.Id).ServiceDate);            
            if(oi.TotalPrice.setScale(2)  == oi.blng__PendingBillings__c && oi.SBQQ__QuoteLine__c!=null &&
                (oi.ServiceDate != oldOrderProductsMap.get(oi.Id).ServiceDate ||
                oi.EndDate != oldOrderProductsMap.get(oi.Id).EndDate))
            {
                SBQQ__QuoteLine__c qli      = new SBQQ__QuoteLine__c(Id = oi.SBQQ__QuoteLine__c);
                qli.SBQQ__StartDate__c      = oi.ServiceDate;
                qli.SBQQ__EndDate__c        = oi.EndDate;
                
                listQuoteLines.add(qli);
            }
        }
        if(!listQuoteLines.isEmpty() && Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable())
        {
            Update listQuoteLines;
        }        
    }
    /** [IOM-1591]
    * @description  - Set OLI fields from Products Fields
    * @param newOrderProducts List of new OrderItem items
    * @param oldOrderProductsMap Map of Old OLI
    */
    public static void setFieldsFromProduct(list<OrderItem> newOrderProducts,map<Id,OrderItem> oldOrderProductsMap)
    {
        Set<Id> setProductIds = new Set<Id>();
        for(OrderItem oi : newOrderProducts)
        {   
            setProductIds.add(oi.Product2Id);
        }     
        Map<Id,Product2> productMap = new Map<Id,Product2>([SELECT Id,Translated_Product_Description__c,Source_Product_Code__c FROM Product2 WHERE Id in:setProductIds WITH SECURITY_ENFORCED]);

        for(OrderItem oi : newOrderProducts)
        {   
            if(String.isBlank(oi.Translated_Product_Description__c) // GECI-28
            && productMap.containsKey(oi.Product2Id) 
            && String.isNotBlank(productMap.get(oi.Product2Id).Translated_Product_Description__c))
            {
                Product2 product = productMap.get(oi.Product2Id);
                oi.Translated_Product_Description__c = product.Translated_Product_Description__c;
                oi.Source_Product_Code__c = product.Source_Product_Code__c;
            }
        }
    }
    
    /**
    * @description  - Set the override next billing date field based on the End Date automatically for specific products        
    * @param oldMapOLI map of OrderItem items
    * @param newlistOLI Map of Old OLI
    */
    public static void setTaxData(Map<Id, OrderItem> oldMapOLI,List<OrderItem> newlistOLI)
    {        
        set<Id> orderIds = new set<Id>();
        for(OrderItem oi : newlistOLI)
        {
            orderIds.add(oi.OrderId);
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Edition__c,Edition__r.Edition_Code__c,Legacy_CRM_Instance__c FROM Order WHERE Id in:orderIds WITH SECURITY_ENFORCED]);
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
        for(OrderItem oi : newlistOLI)
        {
            string key = orderMap.get(oi.OrderId).Edition__r.Edition_Code__c+'_'+orderMap.get(oi.OrderId).Legacy_CRM_Instance__c;
            Boolean orderDisableTax =  String.isNotBlank(key) && mapEditionSt.containsKey(key)?(mapEditionSt.get(key)?.Disable_Tax_Calculation__c):false;
            oi.Edition__c = orderMap.get(oi.OrderId).Edition__c;
            if(orderDisableTax 
                && String.isNotBlank(oi.blng__LegalEntity__c) 
                && oi.SBQQ__TaxAmount__c != null
                && oi.blng__LegalEntity__c != oldMapOLI.get(oi.Id).blng__LegalEntity__c
              )
            {                
                oi.blng__TaxErrorMessage__c = null;
                oi.blng__TaxStatus__c = 'Completed';
                oi.Tax_Status__c = 'Tax Complete';
            }
        }
    }
    
    /**
    * @description  - Set the override next billing date field based on the End Date automatically for specific products        
    * @param oldMapOLI map of OrderItem items
    * @param newlistOLI Map of Old OLI
    */
    public static void setTaxStatus(Map<Id, OrderItem> oldMapOLI,List<OrderItem> newlistOLI)
    {        
        set<Id> orderIds = new set<Id>();
        for(OrderItem oi : newlistOLI)
        {
            orderIds.add(oi.OrderId);
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Tax_Status__c,Edition__c,Edition__r.Edition_Code__c,Legacy_CRM_Instance__c FROM Order WHERE Id in:orderIds WITH SECURITY_ENFORCED]);
        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
        Map<Id,Boolean> maporderIdTax = new Map<Id,Boolean>();
        
        for(OrderItem oi : newlistOLI){
            string key = orderMap.get(oi.OrderId).Edition__r.Edition_Code__c+'_'+orderMap.get(oi.OrderId).Legacy_CRM_Instance__c;

            Boolean orderDisableTax =  String.isNotBlank(key) && mapEditionSt.containsKey(key)?(mapEditionSt.get(key)?.Disable_Tax_Calculation__c):false;
            if(!maporderIdTax.containsKey(oi.OrderId)){
                maporderIdTax.put(oi.OrderId, false);
            }
            if(orderDisableTax && oi.blng__TaxStatus__c == 'Completed' && oi.Tax_Status__c == 'Tax Complete')
            {
                maporderIdTax.put(oi.OrderId, true);
            }
            else{
                maporderIdTax.put(oi.OrderId, false);
            }
        }
        List<Order> listOrderUpdate = new List<Order>();
        for(String key : maporderIdTax.keySet()){
            if(maporderIdTax.get(key) && orderMap.get(key).Tax_Status__c != 'Tax Complete'){
                listOrderUpdate.add(new Order(Id=key,Tax_Status__c='Tax Complete'));
            }
        }
        if(!listOrderUpdate.isEmpty() && Schema.sObjectType.Order.isUpdateable()){
            update listOrderUpdate;
        }
    }

}