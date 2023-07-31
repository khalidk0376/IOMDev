/**
* File:         CreateInvoiceSchedulerSchedulable
* Project:      IOM
* Created Date: 22 October 2022
* Created By:   Girikon(Deepak)
* Test Class:   CreateInvoiceSchedulerSchedulable_Test (94%)
*****************************************************************************************************
* @description :  Crete Invoice Schedule Records
*****************************************************************************************************
* Modification Log :
* 1. [GECI-970] - Girikon(Ansh)-  3 March 2023   Added Dup Invoice prevention
* 1. [GECI-1297] - Girikon(Ansh)-  27 April 2023   Added More condition for Dup Invoice prevention
*/
public without sharing class CreateInvoiceSchedulerSchedulable implements Schedulable
{
    private String currencyCode;

    /**
    *   @description [Constructor]
    *   @param currencyCode null incase of all or a Specific Currency Code 
    */
    public CreateInvoiceSchedulerSchedulable(String currencyCode){
        this.currencyCode = currencyCode;
    }
    
    /**
    *   @description execute
    *   @param sc
    */
    public void execute(SchedulableContext sc)
    {
        List<blng__InvoiceRun__c> invoiceRuns = [SELECT Id,blng__Status__c FROM blng__InvoiceRun__c WHERE blng__InvoiceScheduler__r.blng__InvoiceBatches__c = 'IOM Automatic' AND blng__InvoiceScheduler__r.blng__Type__c = 'Once' AND blng__InvoiceScheduler__r.Name LIKE 'IOM Invoice generation Scheduler at -%' WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];

        List<blng__ErrorLog__c> errorlogList = new List<blng__ErrorLog__c>();
        if(!invoiceRuns.isEmpty()){
            errorlogList = [SELECT Id FROM blng__ErrorLog__c WHERE blng__InvoiceRun__c=:invoiceRuns[0].Id WITH SECURITY_ENFORCED];
        }

        if(invoiceRuns.isEmpty() || (!invoiceRuns.isEmpty() && (invoiceRuns[0].blng__Status__c == 'Completed' || invoiceRuns[0].blng__Status__c == 'Completed with errors' || !errorlogList.isEmpty()))){
            blng__InvoiceScheduler__c invoiceScheduler = new blng__InvoiceScheduler__c();
            invoiceScheduler.Name = 'IOM Invoice generation Scheduler at - ' + DateTime.now().addMinutes(2);
            invoiceScheduler.blng__IncludeAllCurrencies__c = String.isNotBlank(this.currencyCode)?false:true;
            if(String.isNotBlank(this.currencyCode)){
                invoiceScheduler.CurrencyIsoCode  = this.currencyCode;
            }
            invoiceScheduler.blng__InvoiceBatches__c = 'IOM Automatic';
            invoiceScheduler.blng__TargetDate__c = Date.today();
            invoiceScheduler.blng__Type__c = 'Once';
            invoiceScheduler.blng__StartDateTime__c = DateTime.now().addMinutes(2);
            if(Schema.sObjectType.blng__InvoiceScheduler__c.isCreateable()){
                insert invoiceScheduler;
            } 
        }
    }
}

/*
Integer interval = 5;
Integer count = (60/interval);
for(Integer i = 0; i < count; i++){
	String sch = '0 ' + String.valueOf(i*interval).leftPad(2,'0') + ' * * * ?';
	CreateInvoiceSchedulerSchedulable obj = new CreateInvoiceSchedulerSchedulable(null);
	System.schedule('IOM Invoice Schedular Creation Job - ' + String.valueOf(i*interval).leftPad(2,'0'), sch, obj);
}
*/