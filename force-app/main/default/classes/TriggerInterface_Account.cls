/**
* File:         TriggerInterface_Account
* Project:      Greenfield
* Created Date: 11/05/2019
* Created By:   Yash Gupta
* Test Class:   AccountCreditStatusHold_Trig_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
* History:     Modified by Yash Gupta [11/27/2019], Increase the code coverage.
*/

public with sharing class TriggerInterface_Account {

    /*
    * Description: Constructor for TriggerInterface_Account
    */
    public TriggerInterface_Account() { 
        System.debug('Calling TriggerInterface_Account class!');
    }
    
    /*
    * Description: Runnable interface for TriggerInterface_Account
    */
    public interface Runnable {
        void run(TriggerInterface_Account.Trig trig);
    }  
    
    /*
    * Description: Inner class to fetch all the parameters related to account.
    */
    public class Trig {
        public List<Account> oldList;
        public List<Account> newList;
        public Map<Id,Account> oldMap;
        public Map<Id,Account> newMap;
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