/**
 * File: TriggerInterface_CreditNoteLine
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
public with sharing class TriggerInterface_CreditNoteLine {
    /**
     * @description TriggerInterface_CreditNoteLine Constructor for interface class 
     */
    public TriggerInterface_CreditNoteLine() { 
    	System.debug('Calling TriggerInterface_CreditNoteLine class!');
    }
    
    /**
     * @description Runnable interface for TriggerInterface_CreditNoteLine
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_CreditNoteLine
         * @param trig instance of TriggerInterface_CreditNoteLine.Trig method 
         */  
        void run(TriggerInterface_CreditNoteLine.Trig trig);
    }
    
    /**
     * @description Inner class to fetch all the parameters related to CreditNoteLine.
     */
    public class Trig {
        public List<blng__CreditNoteLine__c> oldList;
        public List<blng__CreditNoteLine__c> newList;
        public Map<Id,blng__CreditNoteLine__c> oldMap;
        public Map<Id,blng__CreditNoteLine__c> newMap;
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