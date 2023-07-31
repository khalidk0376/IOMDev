/**
* File:         TriggerInterface_Contract
* Project:      GAP
* Created Date: 01/09/2020
* Created By:   Sachin Caudhary
* Test Class:   ContractAccountTaxNumber_Trig_Test
* Coverage:     100%
*
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
*/

public with sharing class TriggerInterface_Contract {

    /*
    * Description: Constructor for TriggerInterface_Contract
    */
    public TriggerInterface_Contract() { 
        System.debug('Calling TriggerInterface_Contract class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_Contract
    */
    public interface Runnable {
        void run(TriggerInterface_Contract.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to Contract.
    */
    public class Trig {
        public List<Contract> oldList;
        public List<Contract> newList;
        public Map<Id,Contract> oldMap;
        public Map<Id,Contract> newMap;
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