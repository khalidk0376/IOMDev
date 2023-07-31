/**
* File         :   PaymentTransactionFieldUpdates_Trig
* Project      :   IOM E-Com [IE-435]
* Created Date :   20th Oct 2022
* Created By   :   Girikon(Ashish)
* Test Class   :   PaymentTransactionFieldUpdates_Test (100%)
* *****************************************************************************************************
@description : This Class is used to set the default field values
* *****************************************************************************************************
* Modification log :
*/
public with sharing class PaymentTransactionFieldUpdates_Trig implements TriggerInterface_PaymentTransaction.Runnable 
{
    @TestVisible Private static final String REFUND = 'Refund';
    /** 
    *   @description [Call Interface Class to fetch the new list and old map of PaymentTransaction]
    *   @param trig [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_PaymentTransaction.Trig trig)
    {
        if(trig.isAfter && trig.isUpdate)
        {
            setInvDefaultValues(trig); // IE-[435]
           
        }
    }
    /** 
    *   @description - [Set Invoice Outstanding balance] - [IE-435]
    *   @param trig [fetch the trigger new list and old map]
    */
    private static void setInvDefaultValues(TriggerInterface_PaymentTransaction.Trig trig)
    {
        Set<Id> invIds = new Set<Id>();
        for(Payment_Transaction__c payTrns : trig.newList)
        {
            Payment_Transaction__c oldPayTrns = !trig.oldMap.isEmpty()?trig.oldMap.get(payTrns.Id):new Payment_Transaction__c();

            if(String.isNotBlank(payTrns.Invoice__c) && payTrns.Invoice__c != oldPayTrns.Invoice__c 
                && String.isNotBlank(payTrns.Payment_Type__c) 
                && !REFUND.equalsIgnoreCase(payTrns.Payment_Type__c))
            {
                invIds.add(payTrns.Invoice__c);
            }
        }
        setInvOutStandingValue(invIds);
    }
    /** 
    *   @description - [Set Invoice Outstanding balance] - [IE-435]
    *   @param trig [fetch the trigger new list and old map]
    */
    public static void setInvOutStandingValue(Set<Id> invIds)
    {
        Map<Id,blng__Invoice__c> invMap = new Map<Id,blng__Invoice__c>();

        for(Payment_Transaction__c payTxn : [SELECT Id,Amount__c,Invoice__c,Invoice__r.Outstanding_Balance__c,Invoice__r.blng__TotalAmount__c FROM Payment_Transaction__c  WHERE Invoice__c IN:invIds AND Invoice__r.Tax_Status__c = 'Tax Complete' AND Payment_Type__c !=: REFUND  WITH SECURITY_ENFORCED])
        {
            Decimal defaultOutSanding = payTxn.Invoice__r.Outstanding_Balance__c != null ? payTxn.Invoice__r.Outstanding_Balance__c : payTxn.Invoice__r.blng__TotalAmount__c;

            blng__Invoice__c inv = invMap.containsKey(payTxn.Invoice__c)? invMap.get(payTxn.Invoice__c) :new blng__Invoice__c(Id=payTxn.Invoice__c,Outstanding_Balance__c = defaultOutSanding);
			// system.debug('inv-Outstanding_Balance__c - '+inv.Outstanding_Balance__c);
            inv.Outstanding_Balance__c = inv.Outstanding_Balance__c - payTxn.Amount__c ;

            invMap.put(inv.Id,inv);
        }

        if(!invMap.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable())
        {
            update invMap.values();
        }
        
    }
   
}