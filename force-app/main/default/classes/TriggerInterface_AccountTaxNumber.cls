/**
* File:         TriggerInterface_AccountTaxNumber
* Created By:   Girikon(Ansh) -
* Test Class:   TaxCategoryUpdate_Trig_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Interface Class to provide Trigger values. 
* *******************************************************************************************************
*/
public class TriggerInterface_AccountTaxNumber 
{
	/*
    * Description: Runnable interface for TriggerInterface_AccountTaxNumber
    */
    public interface Runnable {
        void run(TriggerInterface_AccountTaxNumber.Trig trig);
    }      
    /*
    * Description: Inner class to fetch all the parameters related to Account Tax Number.
    */
    public class Trig {
        public List<Account_Tax_Number__c> oldList;
        public List<Account_Tax_Number__c> newList;
        public Map<Id,Account_Tax_Number__c> oldMap;
        public Map<Id,Account_Tax_Number__c> newMap;
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