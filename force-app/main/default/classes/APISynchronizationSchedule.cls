/**
* File         :   APISynchronizationSchedule 
* Project      :   Order & Billing Plateform
* Created Date :   31 march 2023
* Created By   :   Girikon(Deepak)
* Test Class   :   APISynchronizationSchedule_Test
* Coverage     :   100%
* *******************************************************************************************************
* @description : to process record using APISynchronizationBatch after specified frequency(GECI-1326)
* *******************************************************************************************************
* Modification log :   
*/
public without sharing class APISynchronizationSchedule implements Schedulable {
    /**
    * @description : implement execute method for Schedulable interface.
    * @param  sc
    */
    public void execute(SchedulableContext sc)
    {
        List<String> integrationUsers = GlobalConstants.getValue('Integration_Automation_Users').split(',');
        
        Map<Id,API_Synchronization_Transaction__c> mapAPISyncTrans = new Map<Id,API_Synchronization_Transaction__c>([SELECT Id FROM API_Synchronization_Transaction__c WHERE Status__c=:GlobalConstants.Queued AND Request_Type__c=:GlobalConstants.ASYNCHRONOUS AND LastModifiedBy.Name NOT IN:integrationUsers WITH SECURITY_ENFORCED]);
        if(!mapAPISyncTrans.isEmpty()){
            APISynchronizationBatch obj = new APISynchronizationBatch(mapAPISyncTrans.keySet());
            Database.executeBatch(obj,1);
        }
    }
}

/*
Integer interval = 5;
Integer count = (60/interval);
for(Integer i = 0; i < count; i++){
	String sch = '0 ' + String.valueOf(i*interval).leftPad(2,'0') + ' * * * ?';
	APISynchronizationSchedule obj = new APISynchronizationSchedule();
	System.schedule('API Synchronization Processing Job - ' + String.valueOf(i*interval).leftPad(2,'0'), sch, obj);
}
*/