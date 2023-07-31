public class TriggerInterface_OrderItem {
public interface Runnable {
        void run(TriggerInterface_OrderItem.Trig trig);
    }
    public class Trig {
        public List<OrderItem  > oldList;
        public List<OrderItem  > newList;
        public Map<Id,OrderItem  > oldMap;
        public Map<Id,OrderItem  > newMap;
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