/**
* File:         TriggerInterface_PaymentSchedule
* Project:      Greenfield
* Created Date: 1/24/2020
* Created By:   Yash Gupta
* Test Class:   InvoiceLineHandler_TrigTest
* Coverage:     100%
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:       Modified By Yash Gupta [1/28/2020], Increase code coverage.
*/

public with sharing class TriggerInterface_PaymentSchedule {

    /*
    * Description: Constructor for TriggerInterface_PaymentSchedule
    */
    public TriggerInterface_PaymentSchedule() { 
        System.debug('Calling TriggerInterface_PaymentSchedule class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_PaymentSchedule
    */
    public interface Runnable {
        void run(TriggerInterface_PaymentSchedule.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to Payment_Schedule__c.
    */
    public class Trig {
        public List<Payment_Schedule__c> oldList;
        public List<Payment_Schedule__c> newList;
        public Map<Id,Payment_Schedule__c> oldMap;
        public Map<Id,Payment_Schedule__c> newMap;
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