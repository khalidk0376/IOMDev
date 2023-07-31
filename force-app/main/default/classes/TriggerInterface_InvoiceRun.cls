/**
* File         :      TriggerInterface_InvoiceRun
* Project      :      IOM
* Created Date :      23-02-2022
* Created By   :      Girikon(Deepak)
* Test Class   :      InvoiceTaxCallout_Trig_Test
* Coverage     :      100%
* *******************************************************************************************************
* @description : Interface class for blng__InvoiceRun__c Trigger
* *******************************************************************************************************
*/
public with sharing class TriggerInterface_InvoiceRun {
    /**
     * @description Constructor for TriggerInterface_InvoiceRun
     */
    public TriggerInterface_InvoiceRun() {
        System.debug(LoggingLevel.DEBUG, 'Calling TriggerInterface_InvoiceRun class!');
    }

    /**
    * @description Runnable interface for TriggerInterface_InvoiceRun
    */
    public interface Runnable {
        /**
        * @description Run Method Trig of TriggerInterface_InvoiceRun
        * @param trig instance of TriggerInterface_InvoiceRun.Trig method 
        */ 
        void run(TriggerInterface_InvoiceRun.Trig trig);
    }  

    /**
    * @description Inner class to fetch all the parameters related to blng__InvoiceRun__c.
    */
    public class Trig {
        public List<blng__InvoiceRun__c> oldList;
        public List<blng__InvoiceRun__c> newList;
        public Map<Id,blng__InvoiceRun__c> oldMap;
        public Map<Id,blng__InvoiceRun__c> newMap;
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