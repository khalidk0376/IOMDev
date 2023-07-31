/*
Created By: Hailey Niemand
Created On: 10/11/2020 
Description/Purpose: Triggers calls apex classes which are further call this class for initialization of record. It is only run for Opportunity Object. Custom object used 'Trigger' and 'TriggerRecordtype'
Methods: Runnable
Test Class:  
*/

public with sharing class TriggerInterface_SCAViolation {

    public interface Runnable {
		void run(TriggerInterface_SCAViolation.Trig trig);
    }
    
    public class Trig {
        public List<copado__Static_Code_Analysis_Violation__c> oldList;
        public List<copado__Static_Code_Analysis_Violation__c> newList;
        public Map<Id,copado__Static_Code_Analysis_Violation__c> oldMap;
        public Map<Id,copado__Static_Code_Analysis_Violation__c> newMap;
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