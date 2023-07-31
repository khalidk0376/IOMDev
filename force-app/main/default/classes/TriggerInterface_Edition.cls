/**
* File:         TriggerInterface_Edition
* Project:      GreenField
* Created Date: 6th Feb 2020
* Created By:   Girikon(Prashant)
* Test Class:   EditionPdOrderInvoiceCreation_Trig_Test
* Coverage:     100%
*
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:  
*/
public with sharing class TriggerInterface_Edition {
    /**
     * @description Constructor for TriggerInterface_Edition
     */
    public TriggerInterface_Edition() {
        System.debug('Calling TriggerInterface_Edition class!');
    }
    /**
     * @description Runnable interface for TriggerInterface_Edition
     */
    public interface Runnable {
        /**
         * @description Run Method Trig of TriggerInterface_Edition
         * @param trig instance of TriggerInterface_Edition.Trig method 
         */ 
        void run(TriggerInterface_Edition.Trig trig);
    }  
    /**
     * @description Inner class to fetch all the parameters related to Edition.
     */
    public class Trig {
        public List<Edition__c> oldList;
        public List<Edition__c> newList;
        public Map<Id,Edition__c> oldMap;
        public Map<Id,Edition__c> newMap;
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