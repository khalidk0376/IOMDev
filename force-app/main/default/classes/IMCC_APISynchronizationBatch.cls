/**
* File         :   IMCC_APISynchronizationBatch 
* Project      :   IMCC
* Created Date :   8th Sept 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(95%)
* Coverage     :   95%
***********************************************************************************************
* @description : Batch to make API calls using IMCC_API_Synchronization_Items Records.
***********************************************************************************************
* Modification log :
*/
public with sharing class IMCC_APISynchronizationBatch implements Database.Batchable<sObject>,Database.stateful {

    /****** FINAL CONSTANT VARIABLES  *****/
    public static final String BATCH_EXECUTION_ERRORS = 'IMCC Batch Execution errors';
    public static final String EXTERNAL_API_CALL = 'External Api/Internal Call';
    public static final String COMPLETED_WITH_ERRORS =  'Completed With Errors';
    public static final String API_SYNCHRONIZATION_BATCH =  'IMCC API Synchronization Batch';

    /****** PUBLIC Varibales *******/
    public set<Id> synchronizationTransIds;
    public Set<Id> setErroneousAPISyncTrans;
    public Set<Id> setAllAPISyncTrans;        
    public List<IMCC_API_Synchronization_Item__c> syncItems;

    /**
    * @description IMCC_APISynchronizationBatch this constructor is used to execute batch in front mode
    * @param syncTransIds api transaction ids
    */
    public IMCC_APISynchronizationBatch(set<Id> syncTransIds)
    {
        synchronizationTransIds = new Set<Id>(syncTransIds);
        setAllAPISyncTrans = New Set<Id>();
        setErroneousAPISyncTrans = New Set<Id>();
        syncItems = new List<IMCC_API_Synchronization_Item__c>(); 
    }

    /**
    * @description  This constructor is used to execute batch in background mode
    **/
    public IMCC_APISynchronizationBatch()
    {  
        setAllAPISyncTrans = New Set<Id>();
        setErroneousAPISyncTrans = New Set<Id>();
        syncItems = new List<IMCC_API_Synchronization_Item__c>();
    }

    /**
    * @description  This method is used to get the query and records in chunk
    * @param bc BatchableContext
    * @return Database.QueryLocator
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = IMCC_APISynchronizationHelper.getAPISyncItemsQueryAndStartProcessing(this.synchronizationTransIds);
        return Database.getQueryLocator(query);
    }

    /**
    * @description : This method is used to make callouts for sync
    * @param bc BatchableContext
    * @param items line items to be processed
    **/
    public void execute(Database.BatchableContext bc, List<IMCC_API_Synchronization_Item__c> items)
    {
        for(IMCC_API_Synchronization_Item__c item: items) // Valid for one data in loop only
        {
            this.setAllAPISyncTrans.add(item.IMCC_API_Synchronization_Transaction__c);
            try
            { 
                Id itemId = Id.valueOf(item.Id);
                System.debug(logginglevel.DEBUG,'Processing Item : '+itemId +' of Trans : '+item.IMCC_API_Synchronization_Transaction__c); 

                if(IMCC_APISynchronizationHelper.validateSyncItem(item))
                {
                    String calloutStatus = 'Processing';
                    // Asset
                    if(String.isNotBlank(item.Asset__c) && String.isNotBlank(item.Edition__c) && item.Type__c == 'Purchase Data'){
                        calloutStatus = IMCC_AssetTriggerHandler.createConEdiAndPurcData(item);
                    } 
                    // Incase of Error
                    if(calloutStatus == 'Error')
                    {
                        this.setErroneousAPISyncTrans.add(item.IMCC_API_Synchronization_Transaction__c);
                    }
                }
            }catch(Exception e){
                item.Error_Message__c = e.getMessage();
                item.Status__c = 'Error';
                syncItems.add(item);
                this.setErroneousAPISyncTrans.add(item.IMCC_API_Synchronization_Transaction__c);
                HandleAllCustomException.logException(e,item.Id,API_SYNCHRONIZATION_BATCH);
                
                System.debug(logginglevel.DEBUG,'Error_Message__c --> '+item.Error_Message__c +' At Line' + e.getLineNumber());
                System.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
            }
        }
    }

    /**
    * @description  This method is used to update final status on items and Transactions
    * @param bc BatchableContext
    **/
    public void finish(Database.BatchableContext bc)
    {
        Id interfaceLogId;
        List<IMCC_API_Synchronization_Transaction__c> syncTrans = new List<IMCC_API_Synchronization_Transaction__c>();
        List<Interface_Error_Line__c> interfaceErrorLines = new List<Interface_Error_Line__c>();
        try {
            
            if(!this.setErroneousAPISyncTrans.isEmpty())
            {
                interfaceLogId = IMCC_APISynchronizationHelper.createInterfaceLog(BATCH_EXECUTION_ERRORS,EXTERNAL_API_CALL); 
            }

            for(ID syncTranId : this.setAllAPISyncTrans)
            {
                IMCC_API_Synchronization_Transaction__c syncTran = new IMCC_API_Synchronization_Transaction__c();
                syncTran.Id = syncTranId;
                syncTran.Status__c  = this.setErroneousAPISyncTrans.contains(syncTranId)?COMPLETED_WITH_ERRORS:'Completed';
                syncTran.Interface_Log__c = this.setErroneousAPISyncTrans.contains(syncTranId)?interfaceLogId:null;
                syncTrans.add(syncTran);
            }

            if(Schema.sObjectType.IMCC_API_Synchronization_Transaction__c.isUpdateable())
            {
                update syncTrans;
            }
            if(!this.syncItems.isEmpty() && Schema.sObjectType.IMCC_API_Synchronization_Item__c.isUpdateable())
            {
                update syncItems;
            }

            for(IMCC_API_Synchronization_Item__c item : [SELECT Id,Error_Message__c,Response_Code__c FROM IMCC_API_Synchronization_Item__c WHERE Status__c='Error' AND IMCC_API_Synchronization_Transaction__c in:this.setErroneousAPISyncTrans ])
            {
                // Log Interface Error
                Interface_Error_Line__c errorLine       = new Interface_Error_Line__c();
                errorLine.Interface_Log__c              = interfaceLogId;
                errorLine.IMCC_API_Synchronization_Item__c   = item.Id;
                errorLine.Error_Code__c                 = item.Response_Code__c;
                errorLine.Error_Message__c              = item.Error_Message__c;
                interfaceErrorLines.add(errorLine);
            }

            if(!interfaceErrorLines.isEmpty() && Schema.sObjectType.Interface_Error_Line__c.isCreateable())
            {
                insert interfaceErrorLines;
            }

            IMCC_APISynchronizationHelper.scheduleBatchForNextItems();
        }
        catch(Exception e){
            System.debug(logginglevel.DEBUG,'Error in Finish --> '+e.getMessage() +' At Line' + e.getLineNumber()); System.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
            HandleAllCustomException.logException(e,interfaceLogId,API_SYNCHRONIZATION_BATCH);
        }
    }
}