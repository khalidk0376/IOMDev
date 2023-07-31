/**
 * File: TriggerInterface_QuoteLine
 * Project:      
 * Created Date: 11/25/2019
 * Created By: Raider Data Services, TT
 * Test Class: 
 * Coverage: 
 * *******************************************************************************************************
 * @description Interface Class to provide Trigger values. 
 * *******************************************************************************************************
 * History:  
 */
public with sharing class TriggerInterface_QuoteLine {
   /**
    * @description Constructor for TriggerInterface_QuoteLine
    */
    public TriggerInterface_QuoteLine() {
    	System.debug('Calling TriggerInterface_QuoteLine class!');
    }
    
   /**
    * @description Runnable interface for TriggerInterface_QuoteLine
    */
    public interface Runnable {
       /**
        * @description Interface method 
		*/
        void run(TriggerInterface_QuoteLine.Trig trig);
    }  
    
   /**
    * @description Inner class to fetch all the parameters related to QuoteLine.
    */
    public class Trig {
        public List<SBQQ__QuoteLine__c> oldList;
        public List<SBQQ__QuoteLine__c> newList;
        public Map<Id,SBQQ__QuoteLine__c> oldMap;
        public Map<Id,SBQQ__QuoteLine__c> newMap;
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