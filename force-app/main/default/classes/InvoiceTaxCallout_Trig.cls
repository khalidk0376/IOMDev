/**
* File         :   InvoiceTaxCallout_Trig 
* Project      :   IOM
* Created Date :   23-02-2022
* Created By   :   Girikon(Deepak)
* Test Class   :   InvoiceTaxCallout_Trig_Test (90%)
* ******************************************************************************************************
@description : to Create Api Synchronization Trans & Items When Invoice Run is Finished For Tax Callout. 
*******************************************************************************************************
* Modification log :
*/
public with sharing class InvoiceTaxCallout_Trig implements TriggerInterface_InvoiceRun.Runnable 
{
    /** 
*   @description [Call Interface Class to fetch the new list and old map of InvoiceRun]
*   @param trig [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_InvoiceRun.Trig trig)
    {
        try {
            Set<Id> runIds = new Set<Id>();
            for(blng__InvoiceRun__c run : trig.newList){
                if((run.blng__Status__c == 'Completed' || run.blng__Status__c == 'Completed with errors') && run.blng__Status__c != trig.oldMap.get(run.Id).blng__Status__c){
                    runIds.add(run.Id);
                }
            }
            if(!runIds.isEmpty()){
                Map<Id,blng__Invoice__c> mapInvoice = new Map<Id,blng__Invoice__c>([SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__c IN:runIds AND blng__InvoiceStatus__c=:GlobalConstants.DRAFT WITH SECURITY_ENFORCED]);
                if(!mapInvoice.isEmpty()){
                    CalculateTaxOnInvoiceLineUpdate_Trig.processInvoiceTax(mapInvoice.keySet());
                }
            }
        } 
        catch (Exception e){
            System.debug(logginglevel.DEBUG,'Exception : '+e.getMessage());
            HandleAllCustomException.LogException(e,'','InvoiceTaxCallout_Trig');  
        }
    }
}