/**
* File:         TriggerInterface_Contact
* Created By:   Girikon(Ashish)
* Test Class:   ContactFieldUpdate_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
*/
public class TriggerInterface_Contact 
{
    /*
    * Description: Runnable interface for TriggerInterface_Contract
    */
    public interface Runnable {
        void run(TriggerInterface_Contact.Trig trig);
    }      
    /*
    * Description: Inner class to fetch all the parameters related to Contact.
    */
    public class Trig {
        public List<Contact> oldList;
        public List<Contact> newList;
        public Map<Id,Contact> oldMap;
        public Map<Id,Contact> newMap;
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