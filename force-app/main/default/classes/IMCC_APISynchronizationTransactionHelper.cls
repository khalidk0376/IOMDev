/**
* File         :   IMCC_APISynchronizationTransactionHelper 
* Project      :   IMCC
* Created Date :   8th Sept 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(95%)
* Coverage     :   95%
***********************************************************************************************
* @description : This trigger helper will execute the batch which will process the IMCC API Sync Transaction records.
***********************************************************************************************
* Modification log :
*/
public with sharing class IMCC_APISynchronizationTransactionHelper {

    public static final String REQUEUE_FOR_ERRONEOUS_RECORDS    = 'Requeue for Erroneous records';
    public static final String REQUEUE_FOR_SUCCESSFUL_RECORDS   = 'Requeue for Successful records';
    public static final String API_SYNCHRONIZATION_BATCH   = 'IMCC_APISynchronizationBatch';    
    public static final String AFTER_UPDATE = 'After Update';

    public static final Set<String> VALID_PROCESSING_STATUES  = new Set<String> {'Holding','Queued','Preparing','Processing'}; 

    /**
    * @description [This method is for running the Trigger on IMCC_API_Synchronization_Transaction__c using the interface class on After insert and After Update.]
    * @param newList
    * @param oldMap
    */
    public static void handleAfterUpdate(List<IMCC_API_Synchronization_Transaction__c> newList, Map<Id,IMCC_API_Synchronization_Transaction__c> oldMap)
    {
        List<IMCC_API_Synchronization_Transaction__c> lstApiSyncTran = new List<IMCC_API_Synchronization_Transaction__c>();
        String triggerOn;
        try {
            for(IMCC_API_Synchronization_Transaction__c apiSyncTran : newList)
            {                
                if(oldMap.get(apiSyncTran.Id).Status__c != apiSyncTran.Status__c && (apiSyncTran.Status__c == 'Queued' || apiSyncTran.Status__c == REQUEUE_FOR_ERRONEOUS_RECORDS || apiSyncTran.Status__c == 'Requeue All' || apiSyncTran.Status__c == REQUEUE_FOR_SUCCESSFUL_RECORDS))
                {
                    triggerOn = AFTER_UPDATE;
                    lstApiSyncTran.add(apiSyncTran);
                }   
            }

            if(!lstApiSyncTran.isEmpty())
            {
                Set<Id> jobIds = new Set<Id>();
                for(IMCC_API_Synchronization_Transaction__c tran: [SELECT JobId__c FROM IMCC_API_Synchronization_Transaction__c WHERE Status__c ='Processing' AND Request_Type__c='Synchronous' WITH SECURITY_ENFORCED]){
                    jobIds.add(tran.JobId__c);
                }
                Map<Id,AsyncApexJob> synchronousBatches = new Map<Id,AsyncApexJob>([SELECT Id FROM AsyncApexJob WHERE Status IN : VALID_PROCESSING_STATUES AND Id IN:jobIds]);

                Boolean isExecuting = (([SELECT COUNT() FROM AsyncApexJob WHERE Status IN :VALID_PROCESSING_STATUES AND Id NOT IN:synchronousBatches.keySet() AND ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = :API_SYNCHRONIZATION_BATCH )]) == 0) ? false : true ;
                Integer batchSize = 1;
                if(Test.isRunningTest()){
                    batchSize = 10;
                }
                if(!isExecuting){
                    Database.executeBatch(new IMCC_APISynchronizationBatch(),batchSize);                 
                }
            }
        }
        catch (Exception e){System.debug(logginglevel.DEBUG,'Exception : '+e.getMessage());
            HandleAllCustomException.LogException(e,'',triggerOn);  
        }       
    }
}