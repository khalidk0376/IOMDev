/**
* File         :   PaymentTransactionRefund_Trig 
* Project      :   IOM E-Com [IE-150]
* Created Date :   29th AUG 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   PaymentTransactionRefundTrig_Test (100%)
* *****************************************************************************************************
@description : This Class is used to Cancel Invoice & Generate CN for a Refund Type Payment Transaction
* *****************************************************************************************************
* Modification log :
*/
public with sharing class PaymentTransactionRefund_Trig implements TriggerInterface_PaymentTransaction.Runnable 
{
    @TestVisible Private static final String REFUND = 'Refund';
    /** 
    *   @description [Call Interface Class to fetch the new list and old map of PaymentTransaction]
    *   @param trig [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_PaymentTransaction.Trig trig)
    {
        if (trig.isAfter && (trig.isInsert || trig.isUpdate)) 
        {
            cancleInvoiceFromPT(trig);    
        }
    }

    /** 
    *   @description Used to Cancle Invoice & Hold Order products [IE-150]
    *   @param trig [fetch the trigger new list and old map]
    */
    Private static void cancleInvoiceFromPT(TriggerInterface_PaymentTransaction.Trig trig)
    {
        Map<Id,Payment_Transaction__c> orderPaymtTrasMap = new Map<Id,Payment_Transaction__c>();        
        for(Payment_Transaction__c payTrns : trig.newList)
        {
            Payment_Transaction__c oldPayTrns = !trig.oldMap.isEmpty()?trig.oldMap.get(payTrns.Id):new Payment_Transaction__c();

            if(String.isNotBlank(payTrns.Order__c) && payTrns.Order__c != oldPayTrns.Order__c 
                && String.isNotBlank(payTrns.Payment_Type__c) 
                && REFUND.equalsIgnoreCase(payTrns.Payment_Type__c))
            {
                orderPaymtTrasMap.put(payTrns.Order__c,payTrns);
            }
        }

        // cancle Invoices & Hold Order
        if(!orderPaymtTrasMap.isEmpty())
        {
            List<Id> listOfOrderProductId = new List<Id>();
            for(Order odr:[SELECT Id,TotalAmount,SBQQ__TaxAmount__c,(SELECT Id,blng__LegalEntity__c FROM OrderItems) FROM Order Where Id IN:orderPaymtTrasMap.keySet() WITH SECURITY_ENFORCED])
            {
                Payment_Transaction__c payTrns = orderPaymtTrasMap.get(odr.Id);
                Decimal totalAmt = odr.TotalAmount + odr.SBQQ__TaxAmount__c;
                // IN Case Of Full Refund Only [IE-150]
                if(payTrns.Amount__c != null && odr.TotalAmount != null 
                    && payTrns.Amount__c.setScale(2) == totalAmt.setScale(2)) 
                {
                    for(OrderItem ordProd :odr.OrderItems)
                    {
                        listOfOrderProductId.add(ordProd.Id);
                    }
                }
            }
            
            if(!listOfOrderProductId.isEmpty())
            {
                CancelAndRebilPostedInvoicesFCR_Trig.cancelInvoicesForOrderProductIds(listOfOrderProductId,new List<Id>(),true);
            }
        }
    }
}