/**
* File: TriggerInterface_InvoiceLine
* Project:      
* Created Date: 11/25/2019
* Created By: Raider Data Services, TT
* Test Class: InvoiceLineHandler_TrigTest
* Coverage: 
* *******************************************************************************************************
* @description  Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History: 
*/

public with sharing class TriggerInterface_InvoiceLine {
    /**
     * @description Constructor for TriggerInterface_InvoiceLine
     */
    public TriggerInterface_InvoiceLine() {
        System.debug('Calling TriggerInterface_InvoiceLine class!');
    }
    /**
     * @description Runnable interface for TriggerInterface_InvoiceLine
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_InvoiceLine
         * @param trig instance of TriggerInterface_InvoiceLine.Trig method 
         */ 
        void run(TriggerInterface_InvoiceLine.Trig trig);
    }  
    /**
     * @description Inner class to fetch all the parameters related to Invoice.
     */
    public class Trig {
        public List<blng__InvoiceLine__c> oldList;
        public List<blng__InvoiceLine__c> newList;
        public Map<Id,blng__InvoiceLine__c> oldMap;
        public Map<Id,blng__InvoiceLine__c> newMap;
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