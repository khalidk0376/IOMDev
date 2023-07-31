/**
* File         :   PaymentTransactionUpdateBill_Trig 
* Project      :   IOM [GECI-443]
* Created Date :   29th Dec 2022
* Created By   :   IBM(Bharath)
* Test Class   :   PaymentTransactionUpdate_Test (100%)
* *****************************************************************************************************
@description : This Class is used to update Payment_Status__c in related INVOICE record of Payment Transaction
* *****************************************************************************************************
*/
public class PaymentTransactionUpdateBill_Trig implements TriggerInterface_PaymentTransaction.Runnable  {
  public void run(TriggerInterface_PaymentTransaction.Trig trig)
    {
       /* if (trig.isAfter && trig.isInsert) 
        {
            updateBillingStageInsert(trig.newList);
        }
        if (trig.isAfter && (trig.isUpdate)) {
            updateBillingStageUpdate(trig.newList,trig.oldMap);
			}*/
         if (trig.isAfter && (trig.isInsert || trig.isUpdate)) 
        {
            updateBillingStageUpdate(trig.newList,trig.oldMap);
        }
    }
     
     /**
    * @description  This method is used to update Payment_Status__c
    * @param newInvoiceList new Payment_Transaction__c List
    * @param oldInvoiceMap Old Payment_Transaction__c Map
    * //GECI-443
    */
     private static void updateBillingStageUpdate(list<Payment_Transaction__c> newPTList,Map<Id,Payment_Transaction__c>oldPTMap){
      Map<Id,Decimal> invoiceAmountMap = new Map<Id,Decimal>();
      Decimal totalAmount;
      Id invId ;
      List<Id> invoiceToUpdate = new List<Id>();
         for(Payment_Transaction__c payTrns : [SELECT id,Amount__c,Invoice__c,Invoice__r.blng__TotalAmount__c From Payment_Transaction__c WHERE Id in:newPTList WITH SECURITY_ENFORCED])
        {
			//Payment_Transaction__c oldPayTrns = !oldPTMap.isEmpty()?oldPTMap.get(payTrns.Id):new Payment_Transaction__c();
            if(payTrns.Invoice__r.blng__TotalAmount__c!=null && payTrns.Amount__c != null)
            {
                invoiceAmountMap.put(payTrns.Invoice__c,payTrns.Invoice__r.blng__TotalAmount__c);
            }
         }
         if(!invoiceAmountMap.isEmpty()){
        for(AggregateResult aggr : [SELECT Invoice__c,Sum(Amount__c) total From Payment_Transaction__c WHERE Invoice__c IN: invoiceAmountMap.keyset() WITH SECURITY_ENFORCED GROUP BY Invoice__c ])
        {
             totalAmount=(decimal)aggr.get('total'); 
             invId = (Id)aggr.get('Invoice__c');
             if(totalAmount >= invoiceAmountMap.get(invId)){
                    invoiceToUpdate.add(invId);
                }
            
        }
         }
        List<blng__Invoice__c> invoiceToUpdaterecs = new List<blng__Invoice__c>();
        for(blng__Invoice__c inv:[select id,name,Payment_Status__c from blng__Invoice__c where id in:invoiceToUpdate WITH SECURITY_ENFORCED])
        { 
           
            inv.Payment_Status__c='Paid';
            invoiceToUpdaterecs.add(inv);
        }
        if (!invoiceToUpdaterecs.isEmpty()){
        		update invoiceToUpdaterecs;
		}
     } 
}