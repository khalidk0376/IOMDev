public class TriggerInterface_SBQQ_Quote {
    public interface Runnable {
        void run(TriggerInterface_SBQQ_Quote.Trig trig);
    }
    public class Trig {
        public List<SBQQ__Quote__c > oldList;
        public List<SBQQ__Quote__c > newList;
        public Map<Id,SBQQ__Quote__c > oldMap;
        public Map<Id,SBQQ__Quote__c > newMap;
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