/**
* File:         TriggerInterface_Order
* Project:      GAP
* Created Date: 30 Dec 2019
* Created By:   Girikon(Ashish)
* Test Class:   
* Coverage:     100%
*
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:  
*/

public with sharing class TriggerInterface_Order {

    /*
    * Description: Constructor for TriggerInterface_Opportunity
    */
    public TriggerInterface_Order() { 
        System.debug('Calling TriggerInterface_Order class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_Order
    */
    public interface Runnable {
        void run(TriggerInterface_Order.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to opportunity.
    */
    public class Trig {
        public List<Order> oldList;
        public List<Order> newList;
        public Map<Id,Order> oldMap;
        public Map<Id,Order> newMap;
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