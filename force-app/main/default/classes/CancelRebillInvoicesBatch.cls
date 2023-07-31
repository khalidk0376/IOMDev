/**
* File              :   CancelRebillInvoicesBatch 
* Project           :   Order & Billing Plateform
* Created By        :   Girikon(Ashish)
* Created On        :   11 May 2022 [IOM-1502]
* @description      :   This Class is to use to create Credit Notes & Cancel the Invoices in batch
* Test Class        :   CancelRebillInvoicesBatch_Test(88%)
***********************************************************************************************
* Modification Log :
* 1.
*/
public class CancelRebillInvoicesBatch implements Database.Batchable<sObject>, Database.Stateful {

    public Set<Id> invoiceIds = new Set<Id>();
    public Boolean holdOrderProductsBilling = true;
    /**
    * @description - Constructor
    * @param  invoiceIds   invoice Ids
    */
    public CancelRebillInvoicesBatch(set<Id> invoiceIds) 
    {
        this.invoiceIds = invoiceIds;
        this.holdOrderProductsBilling = true;
    }

    /**
    * @description - Constructor
    * @param  invoiceIds   invoice Ids
    */
    public CancelRebillInvoicesBatch(set<Id> invoiceIds,Boolean holdProductsBilling) 
    {
        this.invoiceIds = invoiceIds;
        this.holdOrderProductsBilling = holdProductsBilling;
    }

    /**
    * @description - start of Batch to get Data
    * @param  batchableContext   batchableContext
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext) 
    {
        String query = 'SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE  blng__InvoiceStatus__c not in (\'Rebilled\',\'Cancelled\') AND Id In :invoiceIds Order by blng__InvoiceDate__c desc';

        return Database.getQueryLocator(query);
    }
     /**
    * @description - Executed when the batch job is completed.
    * @param  batchableContext   batchableContext
    */
    public void execute(Database.BatchableContext batchableContext, List<sObject> scope) 
    {
        Set<Id> invIds = new Set<Id>();
        for(sObject customObject: scope) 
        {
            blng__Invoice__c invoice = (blng__Invoice__c) customObject;
            blng.InvoiceAPI.creditInvoice(invoice.Id, 'Cancel and Rebill');
            invIds.add(invoice.Id);
        }
        List<Id> listOfOrderProductId = new List<Id>();
        // get order unHold Product Ids
        for(OrderItem oli :[SELECT Id FROM OrderItem WHERE Id in (SELECT blng__OrderProduct__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c in :invIds)])
        {
            listOfOrderProductId.add(oli.Id);
        }
        if(!listOfOrderProductId.isEmpty() && this.holdOrderProductsBilling)
        {
            CancelAndRebilPostedInvoicesFCR_Trig.holdOrderProductsBilling(listOfOrderProductId);
        }
    }
 
    /**
    * @description - Executed when the batch job is completed.
    * @param  batchableContext   batchableContext
    */
    public void finish(Database.BatchableContext batchableContext)
    {
        if(batchableContext != null) 
        {
            System.debug(logginglevel.DEBUG,'CancelRebillInvoicesBatch Finished ' + batchableContext.getJobId());
        }               
    }
}