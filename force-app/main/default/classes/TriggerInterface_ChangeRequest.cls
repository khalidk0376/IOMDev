/**
* File:         TriggerInterface_ChangeRequest
* Project:      Greenfield
* Created Date: 1/21/2020
* Created By:   Yash Gupta
* Test Class:   
* Coverage:     
*
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:       
*/

public with sharing class TriggerInterface_ChangeRequest {

    /*
    * Description: Constructor for TriggerInterface_ChangeRequest
    */
    public TriggerInterface_ChangeRequest() { 
        System.debug('Calling TriggerInterface_ChangeRequest class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_ChangeRequest
    */
    public interface Runnable {
        void run(TriggerInterface_ChangeRequest.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to opportunity.
    */
    public class Trig {
        public List<Change_Request__c> oldList;
        public List<Change_Request__c> newList;
        public Map<Id,Change_Request__c> oldMap;
        public Map<Id,Change_Request__c> newMap;
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