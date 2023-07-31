/**
* File: TriggerInterface_Invoice
* Project:      
* Created Date: 11/25/2019
* Created By: Raider Data Services, TT
* Test Class: InvoicePostingHandler_TrigTest
* Coverage: 
* *******************************************************************************************************
* @description  Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History: 
*/
public with sharing class TriggerInterface_Invoice {
    /**
     * @description Constructor for TriggerInterface_Invoice
     */
    public TriggerInterface_Invoice() {
        System.debug('Calling TriggerInterface_Invoice class!');
    }
    /**
     * @description Runnable interface for TriggerInterface_Invoice
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_Invoice
         * @param trig instance of TriggerInterface_Invoice.Trig method 
         */ 
        void run(TriggerInterface_Invoice.Trig trig);
    }  
    /**
     * @description Inner class to fetch all the parameters related to Invoice.
     */
    public class Trig {
        public List<blng__Invoice__c> oldList;
        public List<blng__Invoice__c> newList;
        public Map<Id,blng__Invoice__c> oldMap;
        public Map<Id,blng__Invoice__c> newMap;
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