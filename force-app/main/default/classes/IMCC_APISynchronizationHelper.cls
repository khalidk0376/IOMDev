/**
* File         :   IMCC_APISynchronizationHelper 
* Project      :   IMCC
* Created Date :   8th Sept 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test (100%)
* Coverage     :   100%
* ******************************************************************************************************
 @description : to support IMCC_APISynchronizationBatch batch class with methords to create query and make updates 
*******************************************************************************************************
* Modification log :
*/
public with sharing class IMCC_APISynchronizationHelper {
    /**
    * @description  This method is used for genrate Dynamic Query to process in batch 
    * @param  synchronizationTransIds  Api synchronization Trans Ids
    * @return  String APISyncItemsQuery
    */
    Public Static String getAPISyncItemsQueryAndStartProcessing(set<Id> synchronizationTransIds)
    {
      
        //Set<String> thirdParty = new Set<String>{ExpoCADAPIWrapper.MYS,ExpoCADAPIWrapper.EXPOCAD};
        
        List<Id> setProcessQueuedItems       = new List<Id>(); // API_Synchronization_Transactions with Status "Queued"
        List<Id> setProcessAllItems          = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue All"
        List<Id> setProcessErroneousItems    = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue for Erroneous records"    
        List<Id> setProcessSuccessfulItems   = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue for Successful records"
        
        String syncTransaQuerycp = 'Select Id,Status__c from IMCC_API_Synchronization_Transaction__c where Status__c in (\'Queued\',\'Requeue for Erroneous records\',\'Requeue All\',\'Requeue for Successful records\') '; 

        String syncTransaQuery = synchronizationTransIds != null ? syncTransaQuerycp+' And id in : synchronizationTransIds' : syncTransaQuerycp+ ' And (Request_Type__c = \'Asynchronous\' or Status__c != \'Queued\') ';
                
        /** DEBUG **/ System.debug(logginglevel.DEBUG,'syncTransaQuery : '+syncTransaQuery);
        
        // get API_Synchronization_Transaction ready to be pocessed
        for(IMCC_API_Synchronization_Transaction__c apiSyncTr : Database.query(syncTransaQuery))
        {            
            switch on apiSyncTr.Status__c {
                when 'Queued'{
                    setProcessQueuedItems.add(apiSyncTr.Id);
                }
                when 'Requeue All'{
                    setProcessAllItems.add(apiSyncTr.Id);
                }
                when 'Requeue for Erroneous records'{
                    setProcessErroneousItems.add(apiSyncTr.Id);
                }
                when 'Requeue for Successful records'{
                    setProcessSuccessfulItems.add(apiSyncTr.Id);
                }             
            }
        }

        // Creating Query for API_Synchronization_Item to process in batch
        String fields = 'ID,Type__c,API_Call_Type__c,Request_Body__c,Status__c,Error_Message__c,';

        fields += 'IMCC_API_Synchronization_Transaction__c,IMCC_API_Synchronization_Transaction__r.Status__c,IMCC_API_Synchronization_Transaction__r.Type__c,';

        fields += 'Asset__c,Edition__c';
        
        String condition = ' where Status__c Not In (\'Paused\') And ( '; 
        string filter='';
        
        if(!setProcessQueuedItems.isEmpty()) // Process -  Queued 
        {
            filter += ' Or (  IMCC_API_Synchronization_Transaction__c in (\''+String.join(setProcessQueuedItems,'\',\'')+'\') And Status__c = \'Queued\') ';
        }
        
        if(!setProcessAllItems.isEmpty()) // Process - Error ; Queued ; Re-Queued
        {
            filter += ' Or (  IMCC_API_Synchronization_Transaction__c in (\''+String.join(setProcessAllItems,'\',\'')+'\') ) ';
        }

        if(!setProcessErroneousItems.isEmpty()) // Process - Error
        {
            filter += ' Or (  IMCC_API_Synchronization_Transaction__c in (\''+String.join(setProcessErroneousItems,'\',\'')+'\') And Status__c = \'Error\') ';
        }

        if(!setProcessSuccessfulItems.isEmpty()) // Process - Completed
        {
            filter += ' Or (  IMCC_API_Synchronization_Transaction__c in (\''+String.join(setProcessSuccessfulItems,'\',\'')+'\') And Status__c = \'Completed\') ';
        }
        filter = String.isNotBlank(filter) ? filter.removeStart(' Or') :' IMCC_API_Synchronization_Transaction__c = null ';

        String query = 'Select '+fields+' from IMCC_API_Synchronization_Item__c '+condition+filter + ' ) ORDER BY Edition__c,Asset__c';
        if(Test.isRunningTest())
        {
            query+= ' limit 10 ';
        }
        System.debug(logginglevel.DEBUG,' IMCC_API_Synchronization_Item query :' + query );

        map<Id,IMCC_API_Synchronization_Transaction__c> mapAPITrs = New map<Id,IMCC_API_Synchronization_Transaction__c>();
        
        
        for(IMCC_API_Synchronization_Item__c item :database.query(query))
        {
            mapAPITrs.put(item.IMCC_API_Synchronization_Transaction__c, new IMCC_API_Synchronization_Transaction__c (Id=item.IMCC_API_Synchronization_Transaction__c,Status__c = 'Processing'));
            
        }

        if(!mapAPITrs.isEmpty() && Schema.sObjectType.IMCC_API_Synchronization_Transaction__c.isUpdateable())
        {
            update mapAPITrs.values();
        }

        return query;
    }
    
    /**
    * @description  This method is used to validate Editions data before callouts
    * @param  item API Synchronization Item     
    * @return  Boolean Status
    */
    public Static Boolean validateSyncItem(IMCC_API_Synchronization_Item__c item)
    {
        Boolean allvalid = false;
        // Asset validation
        if(item.Type__c == 'Purchase Data' && String.isNotBlank(item.Asset__c) && String.isNotBlank(item.Edition__c)) {
            allvalid = true;
        }
        return allvalid;
    }
    /**
    * @description  Calling from Batch class to insert context and logType.
    * @param  context
    * @param  logType
    * @return  ID
    */
    public static Id createInterfaceLog(String context, String logType)
    { 
        String interfaceLofId;
        if(String.isNotBlank(Context) && String.isNotBlank(LogType)){
            Interface_Log__c  interfaceLof = New Interface_Log__c();
            interfaceLof.Context__c=Context;
            interfaceLof.Log_Type__c=LogType;
            if(Schema.sObjectType.Interface_Log__c.isCreateable())
            {
                insert interfaceLof ;  
            }    
            interfaceLofId = interfaceLof.Id;
        }
        return interfaceLofId;
    }

     /**
    * @description  This method is used to update API_Synchronization_Item__c
    * @param item API Synchronization Item
    */
    public Static void updateSyncItemStatus(IMCC_API_Synchronization_Item__c item)
    {
        if(item != null && Schema.sObjectType.API_Synchronization_Item__c.isUpdateable())
        {
            Boolean isSaveAttachment = ((item.Response_Code__c!=null && item.Response_Code__c.length()>255) || (item.Response_Body__c!=null && item.Response_Body__c.length()>131072) || (item.Request_Body__c!=null && item.Request_Body__c.length()>131072));
            String body = (isSaveAttachment?((item.Request_Body__c!=null?item.Request_Body__c:'') + '\n\n' + (item.Response_Code__c!=null?item.Response_Code__c:'') + '\n\n' + (item.Response_Body__c!=null?item.Response_Body__c:'')):'');
            item.Response_Code__c = (item.Response_Code__c!=null?item.Response_Code__c.left(255):'');
            item.Response_Body__c = (item.Response_Body__c!=null?item.Response_Body__c.left(131072):'');
            item.Request_Body__c = (item.Request_Body__c!=null?item.Request_Body__c.left(131072):'');
            update item;            
            if(isSaveAttachment){createResponseAttchment(item.Id, body);}
        }
    }

    /**
    * @description  Insert Attachment for Response Body 
    * @param  parentId
    * @param  jsonResponse    
    */
    public static void createResponseAttchment(Id parentId, String jsonResponse)
    {
        Attachment att = new Attachment();
        att.ParentId = parentId;
        att.ContentType = 'text/plain';
        att.Name = 'TextResponse.txt';
        att.Body = Blob.valueof(jsonResponse);
        Database.insert(att, false);
    }
    
    /**
    * @description  This method is used to re-Schedule the batch if more items are Queued
    * @return  String jobid
    */
    public Static String scheduleBatchForNextItems()
    {        
        string jobId;
        string strCountQuery = 'Select count() from IMCC_API_Synchronization_Transaction__c where  Request_Type__c = \'Asynchronous\' And Status__c in (\'Queued\',\'Requeue for Erroneous records\',\'Requeue All\',\'Requeue for Successful records\')';
        Integer pendingTrsCount =  Database.countQuery(strCountQuery);
        if(pendingTrsCount>0)
        {
            IMCC_APISynchronizationBatch obj = new IMCC_APISynchronizationBatch();
            jobId = System.scheduleBatch(obj,'IMCC_APISynchronization_Batch_'+ Math.random()*1000+' - '+Datetime.now(),1,1);
        }
        return jobId;
    }
}