/**
* File:         InvoicePaymentScheduleUpdate_Trig
* Project:      Greenfield
* Created Date: 1/24/2020
* Created By:   Yash Gupta
* Modified By:  Yash Gupta (Girikon) (27 Jan 2020)
* Test Class:   InvoiceLineHandler_TrigTest
* Coverage:     97%
* *******************************************************************************************************
* @description : This class is used to insert payment schedule object based on payment schedule from opportunity on invoice.
* *******************************************************************************************************
* History:      Modified By: Yash Gupta (Girikon) [28 Jan 2020], Increase code coverage.
*               Modified By: Ashish(Girikon) [28 Jan 2020], Automatic Process for PDF genration And Email [IML2R-597]
*				Modified By: Suresh(Girikon) [31 Jan 2022], Payment Schedule Creation [IOM-666]
*/

public with sharing class InvoicePaymentScheduleUpdate_Trig implements TriggerInterface_Invoice.Runnable {
    
    List<String> lstPaymentSch = new List<String>();    
    
    /**
    * @description [Call Interface Class to fetch all the parameters or events from Invoice object]
    * @param trig [fetch the trigger parameters]
    */
    public void run(TriggerInterface_Invoice.Trig trig) 
    {
        if(trig.isAfter && trig.isUpdate){
            for(blng__Invoice__c inv : trig.newList){
                blng__Invoice__c oldInvoice = trig.oldMap.get(inv.Id);
                if(inv.Tax_Status__c == 'Tax Complete' && oldInvoice.Tax_Status__c != inv.Tax_Status__c){
                    insertSinglePaymentSchedule(inv);
                }
            }
        }
    }
    
    /**
    * @description insert Single Payment Schedule For Invoice
    * @param inv invoice record
    */
    public static void insertSinglePaymentSchedule(blng__Invoice__c inv)
    {
        List<Payment_Schedule__c> lstPaymentSchInsert = new List<Payment_Schedule__c>();
        
        Payment_Schedule__c p = new Payment_Schedule__c();
        p.Invoice__c = inv.Id;
        p.Percentage__c = '100';
        p.Amounts__c = inv.blng__TotalAmount__c;
        p.Due_Dates__c = inv.blng__DueDate__c;
        lstPaymentSchInsert.add(p);
        
        if(!lstPaymentSchInsert.isEmpty() && Schema.sObjectType.Payment_Schedule__c.isCreateable()){
            insert lstPaymentSchInsert;
        }  
    }
}