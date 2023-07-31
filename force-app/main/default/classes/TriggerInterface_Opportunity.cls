/**
* File:         TriggerInterface_Opportunity
* Project:      GAP
* Created Date: 11/15/2019
* Created By:   Yash Gupta
* Test Class:   OpportunityAccountTaxNumber_Trig_Test
* Coverage:     100%
*
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:       Modified By Yash Gupta [11/27/2019], Increase code coverage.
*/

public with sharing class TriggerInterface_Opportunity {

    /*
    * Description: Constructor for TriggerInterface_Opportunity
    */
    public TriggerInterface_Opportunity() { 
        System.debug('Calling TriggerInterface_Opportunity class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_Opportunity
    */
    public interface Runnable {
        void run(TriggerInterface_Opportunity.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to opportunity.
    */
    public class Trig {
        public List<Opportunity> oldList;
        public List<Opportunity> newList;
        public Map<Id,Opportunity> oldMap;
        public Map<Id,Opportunity> newMap;
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