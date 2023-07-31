/**
* File:        InvoiceHandler_Trig.cls
* Project:     PirrePoint
* Date:        28 Feb 2020
* Created By:  Girikon(Prashant)[IML2R-867]
* Test Class:  InvoiceHandler_Trig_Test(91%) 
* *************************************************************************
* @description : This class is used for handling 'One Invoice Per Contract' functionality.
* *************************************************************************
* Modified By:
*  1.  Girikon(Ashish) 18 March 2020- Added Currency[IML2R-1958]
   2. Yash Gupta(3/26/2020), Replace Payment_Term__c to Invoice_to_be_issued_before__c field from edition object.
*/

public with sharing class InvoiceHandler_Trig implements TriggerInterface_Invoice.Runnable{
   /**
    * @description [Call Interface Class to fetch all the parameters or events from Invoice object]
    * @param trig [fetch the trigger parameters]
    */
    public void run(TriggerInterface_Invoice.Trig trig) {
        if (trig.isBefore && trig.isUpdate) {
            updateOneInvPerContOnInvoice(trig.newList, trig.oldMap);
        }
    }

    /**
    * @description [Update One Invoice Per Contarct on Invoice object]
    * @param newInvLst
    * @param oldInvMap 
    */
    private void updateOneInvPerContOnInvoice(List<blng__Invoice__c> newInvLst, Map<id, blng__Invoice__c> oldInvMap)
    {
        Set<Id> orderIds = new Set<Id>();
        for(blng__Invoice__c inv : newInvLst)
        {
            if(!String.isBlank(inv.blng__Order__c) && String.isBlank(oldInvMap.get(inv.Id).blng__Order__c)){
                orderIds.add(inv.blng__Order__c);
            }
        }
        Map<Id,Order> mapOrder = new Map<Id,Order>();
        if(!orderIds.isEmpty()){
            mapOrder = new Map<Id,Order>([Select Id,SBQQ__Quote__r.Edition__r.One_Invoice_Per_Contract__c,blng__BillingAccount__r.One_Invoice_Per_Contract__c From Order Where Id In:orderIds]);
        }
        for(blng__Invoice__c inv : newInvLst)
        {
            if(!String.isBlank(inv.blng__Order__c) && String.isBlank(oldInvMap.get(inv.Id).blng__Order__c)){
                Order ord = mapOrder.get(inv.blng__Order__c);
                inv.One_Invoice_Per_Contract__c = (ord.SBQQ__Quote__r.Edition__r.One_Invoice_Per_Contract__c || ord.blng__BillingAccount__r.One_Invoice_Per_Contract__c);
            }
        }
    }
}