/**
* File:         TriggerInterface_PaymentTransaction
* Created By:   Girikon(Ashish) -
* Test Class:   PaymentTransactionRefundTrig_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
*/
public class TriggerInterface_PaymentTransaction 
{
	/*
    * Description: Runnable interface for TriggerInterface_Contract
    */
    public interface Runnable {
        void run(TriggerInterface_PaymentTransaction.Trig trig);
    }      
    /*
    * Description: Inner class to fetch all the parameters related to Contact.
    */
    public class Trig {
        public List<Payment_Transaction__c> oldList;
        public List<Payment_Transaction__c> newList;
        public Map<Id,Payment_Transaction__c> oldMap;
        public Map<Id,Payment_Transaction__c> newMap;
        public Integer triggerSize;
        public Boolean isBefore;
        public Boolean isAfter;
        public Boolean isInsert;
        public Boolean isUpdate;
        public Boolean isDelete;
        public Boolean isUnDelete;
        public Map<Id,Map<String,String>> mapRtIdsToParams;
    }
}