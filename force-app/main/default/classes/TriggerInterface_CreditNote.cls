/**
 * File: TriggerInterface_CreditNote
 * Project:      
 * Created Date: 11/26/2019
 * Created By: Raider Data Services, TT
 * Test Class: 
 * Coverage: 
   *******************************************************************************************************
 * @description  Interface Class to provide Trigger values. 
 * *******************************************************************************************************
  History: 
 */
public with sharing class TriggerInterface_CreditNote {
    /**
     * @description Constructor for TriggerInterface_CreditNote
     */
    public TriggerInterface_CreditNote() { 
    	System.debug('Calling TriggerInterface_CreditNote class!');
    }
    
    /**
     * @description Runnable interface for TriggerInterface_CreditNote
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_CreditNote
         * @param trig instance of TriggerInterface_CreditNote.Trig method 
         */ 
        void run(TriggerInterface_CreditNote.Trig trig);
    }
    
    /**
     * @description Inner class to fetch all the parameters related to CreditNote.
     */
    public class Trig {
        public List<blng__CreditNote__c> oldList;
        public List<blng__CreditNote__c> newList;
        public Map<Id,blng__CreditNote__c> oldMap;
        public Map<Id,blng__CreditNote__c> newMap;
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