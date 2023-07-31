/**
* File:         ActivateOrderAfterCalculate_Trig
* Project:      GreenField
* Created Date: 26 Dec 2019 [IML2R-129]
* Created By:   Girikon(Ashish Anand)
* Test Class:   ActivateOrderAfterCalculate_Trig_Test (94%)
******************************************************************************************************
* @description : Sharing Class to update the Record Type on opportunity.
*****************************************************************************************************
* Modification Log :
* 1. [IML2R-724](12 Feb 2020) - Girikon(Prashant) 
* 2. [IOM-841]  (06 Apr 2020) - Girikon(Ashish)  - Added order Activation on Tax Complete
* 3. [IE-27]    (04 Aug 2022) - Girikon(Ashish)  - Added Condition for IOM Ecom Events 
*/

public with sharing class ActivateOrderAfterCalculate_Trig implements TriggerInterface_Order.Runnable {
    /**
    *   @description [Call Interface Class to fetch the new list and old map of Order]
    *   @param trig TriggerInterface_Order [fetch the trigger new list and old map]
    */
        public void run(TriggerInterface_Order.Trig trig)
        {
            Set<Id> setIdEditions = new set<Id>();  
            if (Trig.isBefore && Trig.isupdate)
            {
                for(Order ord : trig.newList)
                {                
                    if(String.isNotBlank(ord.Edition__c))
                    {
                        setIdEditions.add(ord.Edition__c);                         
                    }
                }
                map<Id,Edition__c> mapEditions  = new map<Id,Edition__c>([select id,Order_Activation__c,Contract_Creation__c,Invoice_Creation__c,No_Order_Creation__c,No_Invoicing__c,Edition_Code__c,Name from Edition__c where id in : setIdEditions]);
                
                automaticOrderProcesses(trig.newList,trig.oldMap,mapEditions);            
            }
        }
    
        /** 
        * Modified By: Girikon(Ashish) (03rd Aug 2022) [IE-27]
        * @description This method is used to automate order activation & contract creation    
        * @param orderlist New order list
        * @param oldMapOrder Old order map
        * @param mapEditions Map of editions
        */
        private void automaticOrderProcesses(list<order> orderlist,map<Id,order> oldMapOrder,map<Id,Edition__c> mapEditions)
        {
            // MAP of Edtion Code & Legacy CRM With Edition Settings
            Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
    
            for(Order ord : orderlist)
            {
                // Check for allowed Automatic order Activation , Price calculated after Queueable execution &  Draft Status
                if(String.isNotBlank(ord.Edition__c) && mapEditions.containskey(ord.Edition__c))
                {    
                    //set<string> finalPriceCalSatus = new set<string> {'Completed','Not Needed'};
                    Edition__c orderEdition = mapEditions.get(ord.Edition__c);
                    
                    String key = orderEdition.Edition_Code__c+'_'+ord.Legacy_CRM_Instance__c;
    
                    Boolean orderNeedsTranslationApproval =  String.isNotBlank(key) && mapEditionSt.containsKey(key)?(mapEditionSt.get(key)?.ByPass_Automatic_Order_Activation__c):false;
                    
                    set<Id> ordersIdsWithBillingDateasToday = filterOrderWithFutureOverrideNextBillingDates(oldMapOrder.keySet());
                    // Added Condition for No_Invoicing__c on order[IML2R-724]
                    // Added Condition for IOM Ecom Events [IE-27]
                    /** [IE-27]
                     *  Order will be automatically activated when tax is complete from Custom & CPQ side and Order Translation Status either complete or not required 
                     *  This process with trigger on change of Tax Status for normal events or on change of Order Translation Status/CPQ PriceCalcStatus val for events where Translation is required 
                     */
                    if(orderEdition.Order_Activation__c 
                        && ord.Status == 'Draft'
                        && ord.Tax_Status__c == 'Tax Complete'
                        //&& finalPriceCalSatus.contains(ord.SBQQ__PriceCalcStatus__c)
                        && ord.No_Invoicing__c == false
                        && (String.isBlank(ord.Order_Translation_Status__c) || ord.Order_Translation_Status__c == 'Completed')
                        && ((oldMapOrder.get(ord.Id).Tax_Status__c != ord.Tax_Status__c
                                //&& orderNeedsTranslationApproval != true
                            )
                            || ((oldMapOrder.get(ord.Id).Order_Translation_Status__c != ord.Order_Translation_Status__c 
                                //|| oldMapOrder.get(ord.Id).SBQQ__PriceCalcStatus__c != ord.SBQQ__PriceCalcStatus__c
                                )
                                && orderNeedsTranslationApproval == true)
                        )
                        && ordersIdsWithBillingDateasToday.contains(ord.Id) // [GECI-247] [GECI-488] [GECI-761]
                    )
                    {
                        ord.Status  =   'Activated';
                        //ord.Description = 'Activtaed at - '+Datetime.now();
                    }
    
                    if(orderEdition.Contract_Creation__c 
                        && ord.Status  == 'Activated' 
                        && oldMapOrder.get(ord.Id).Status != 'Activated')
                    {
                        ord.SBQQ__Contracted__c  = true;
                    }
    
                    if(orderEdition.Invoice_Creation__c  
                        && ord.SBQQ__Contracted__c  == true 
                        && oldMapOrder.get(ord.Id).SBQQ__Contracted__c == false)
                    {
                        ord.blng__InvoiceBatch__c  = 'IOM Automatic';
                    }
                }
            }
        }

        private static Set<Id> filterOrderWithFutureOverrideNextBillingDates(Set<Id> orderIds)
        {
            Set<Id> activateOrderIds = new Set<Id>();
            // Integer totalItemCount ;
            // Integer validItemCount ;

            for (Order ord : [Select Id,Status,(Select OrderId, Product2.ActivateOrder_OverrideBillingDateIsToday__c,blng__OverrideNextBillingDate__c,blng__NextBillingDate__c FROM OrderItems) from Order where Id =: orderIds WITH SECURITY_ENFORCED]) 
            {           
                //totalItemCount = 0;
                //validItemCount = 0;
                for (OrderItem oli : ord.OrderItems) 
                {
                    // totalItemCount++;
                    if(oli.Product2.ActivateOrder_OverrideBillingDateIsToday__c == false ||
                        (oli.Product2.ActivateOrder_OverrideBillingDateIsToday__c == true && 
                            (oli.blng__OverrideNextBillingDate__c <= Date.today() || 
                            (oli.blng__OverrideNextBillingDate__c == null && oli.blng__NextBillingDate__c <= Date.today()))
                        )
                    ){
                        // validItemCount++;
                        activateOrderIds.add(ord.Id);
                    }
                }
                /*
                if(totalItemCount == validItemCount){ // if all products is flaged true + Billing date is today .
                    activateOrderIds.add(ord.Id);
                }*/
            }
            return activateOrderIds;
        }
    }