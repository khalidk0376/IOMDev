/**
* File: TriggerInterface_ContentVersion
* Project:      
* Created Date: 29/11/2020
* Created By: Raider Data Services
* Test Class: 
* Coverage: 
* *******************************************************************************************************
* @description  Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History: 
*/
public with sharing class TriggerInterface_ContentDocument {
    /**
     * @description Constructor for TriggerInterface_ContentDocument
     */
    public TriggerInterface_ContentDocument() {
        System.debug('Calling TriggerInterface_ContentDocument class!');
    }
    /**
     * @description Runnable interface for TriggerInterface_ContentDocument
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_ContentDocument
         * @param trig instance of TriggerInterface_ContentDocument.Trig method 
         */ 
        void run(TriggerInterface_ContentDocument.Trig trig);
    }  
    /**
     * @description Inner class to fetch all the parameters related to Invoice.
     */
    public class Trig {
        public List<ContentDocument> oldList;
        public List<ContentDocument> newList;
        public Map<Id,ContentDocument> oldMap;
        public Map<Id,ContentDocument> newMap;
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