/**
* File         :   APISynchronizationTransaction_Trig 
* Project      :   Order & Billing Plateform
* Created Date :   20th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   APISynchronizationTransaction_Trig_Test
* Coverage     :   85%
***********************************************************************************************
* @description : This class will execute the batch which will sync the API Sync Transaction records.
***********************************************************************************************
* Modification log :
* 1. Girikon (Deepak)   [GECI-1326] 31 March 2023   :   Stop batch for queued transaction from trigger
*/
public with sharing class APISynchronizationTransaction_Trig implements TriggerInterface_APISyncTransaction.Runnable,Queueable
{
   
    public static final String REQUEUE_FOR_ERRONEOUS_RECORDS    = 'Requeue for Erroneous records';
    public static final String REQUEUE_FOR_SUCCESSFUL_RECORDS   = 'Requeue for Successful records';
    public static final String COMPLETED_WITH_ERRORS   = 'Completed With Errors';
    public static final String API_SYNCHRONIZATION_BATCH   = 'APISynchronizationBatch';    
    public static final String AFTER_UPDATE = 'After Update';

    public static final Set<String> VALID_PROCESSING_STATUES  = new Set<String> {'Holding','Queued','Preparing','Processing'};  

    public Set<Id> apiTransIdsForQueable;


    /**
    * @description [This method is for running the Trigger on API_Synchronization_Transaction__c using the interface class on After insert and After Update.]
    * @param trig
    */
    public void run(TriggerInterface_APISyncTransaction.Trig trig){
        Set<Id> apiTransIds = new Set<Id>();
        Set<Id> apiTransIdsNonIntegartionUser = new Set<Id>();
        String triggerOn;
        try {
            triggerOn = AFTER_UPDATE;
            List<String> integrationUsers = GlobalConstants.getValue('Integration_Automation_Users').split(',');
            String userName = UserInfo.getName();
            for(API_Synchronization_Transaction__c apiSyncTran : trig.newList)
            {        
                API_Synchronization_Transaction__c oldTrans =  trig.oldMap.get(apiSyncTran.Id);
                if(trig.isAfter && trig.isUpdate && oldTrans.Status__c != apiSyncTran.Status__c && (((integrationUsers.contains(userName) && apiSyncTran.Status__c == GlobalConstants.QUEUED)) ||(apiSyncTran.Status__c == REQUEUE_FOR_ERRONEOUS_RECORDS && oldTrans.Status__c == COMPLETED_WITH_ERRORS) || ((oldTrans.Status__c == COMPLETED_WITH_ERRORS || oldTrans.Status__c == GlobalConstants.COMPLETED) && apiSyncTran.Status__c == REQUEUE_FOR_SUCCESSFUL_RECORDS) || ((oldTrans.Status__c == COMPLETED_WITH_ERRORS || oldTrans.Status__c == GlobalConstants.COMPLETED || oldTrans.Status__c == GlobalConstants.PAUSED) && apiSyncTran.Status__c == GlobalConstants.REQUEUE_ALL)))
                {
                    apiTransIds.add(apiSyncTran.Id);
                } 
                
                if(trig.isAfter && trig.isUpdate && oldTrans.Status__c != apiSyncTran.Status__c && (!integrationUsers.contains(userName) && apiSyncTran.Status__c == GlobalConstants.QUEUED)){
                    apiTransIdsNonIntegartionUser.add(apiSyncTran.Id);
                }     
            }
            if(!apiTransIdsNonIntegartionUser.isEmpty()){ if(System.isBatch()){ System.enqueueJob(new APISynchronizationTransaction_Trig(apiTransIdsNonIntegartionUser));}else{Database.executeBatch(new APISynchronizationBatch(apiTransIdsNonIntegartionUser),1);}}
            if(!apiTransIds.isEmpty()){
                Set<Id> jobIds = new Set<Id>();
                for(API_Synchronization_Transaction__c tran: [SELECT JobId__c FROM API_Synchronization_Transaction__c WHERE Status__c =: GlobalConstants.PROCESSING AND Request_Type__c=: GlobalConstants.SYNCHRONOUS WITH SECURITY_ENFORCED]){
                    jobIds.add(tran.JobId__c);
                }
                Map<Id,AsyncApexJob> synchronousBatches = new Map<Id,AsyncApexJob>([SELECT Id FROM AsyncApexJob WHERE Status IN : VALID_PROCESSING_STATUES AND (Id IN:jobIds OR CreatedBy.Name NOT IN:integrationUsers)]);

                Boolean isExecuting = (([SELECT COUNT() FROM AsyncApexJob WHERE Status IN :VALID_PROCESSING_STATUES AND Id NOT IN:synchronousBatches.keySet() AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = :API_SYNCHRONIZATION_BATCH )]) == 0) ? false : true ;

                if(!isExecuting){
                    if(System.isBatch()){ System.enqueueJob(new APISynchronizationTransaction_Trig(apiTransIds));}
                    else{Database.executeBatch(new APISynchronizationBatch(apiTransIds),1);}                
                }
            }
        }
        catch (Exception e){System.debug(logginglevel.DEBUG,'Exception : '+e.getMessage());
            HandleAllCustomException.LogException(e,'',triggerOn);  
        }       
    }

    /**
    * @description [This method is constructor for APISynchronizationTransaction_Trig]
    */
    public APISynchronizationTransaction_Trig(){
        System.debug(LoggingLevel.DEBUG, 'APISynchronizationTransaction_Trig');
    }

    /**
    * @description [This method is constructor for APISynchronizationTransaction_Trig]
    * @param apiTransIds
    */
    public APISynchronizationTransaction_Trig(Set<Id> apiTransIds){
        this.apiTransIdsForQueable = apiTransIds;
    }

    /**
    * @description [This method is to implement execute method for queable class]
    * @param context
    */
    public void execute(QueueableContext context) {
        Database.executeBatch(new APISynchronizationBatch(this.apiTransIdsForQueable),1);
    }
}