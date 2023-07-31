/**
* File         :   APISynchronizationHelper 
* Project      :   Order & Billing Plateform
* Created Date :   14th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   (89%) APISynchronization_Test(82%),TaxServiceUtils_Test(61%),OracleOrderHubAPIUtils_Test(62%),MuleSoftCRMCalloutUtils_Test(63%)
* ******************************************************************************************************
@description : to support APISynchronizationBatch batch class with methords to create query and make updates 
*******************************************************************************************************
* Modification log :
* 1. Girikon (Ashish)  [29 Sept 2021 (OBP-81)] Error Logging for Tax Callouts
* 2. Girikon (Ashish) [IOM-521] 01 Feb 2022 : Account Credit Status Update to MuleSoft
* 3. Girikon (Ashish) [IOM-775] 23 Feb 2022 : Amendment/Opportunity Data Update to MuleSoft
* 4. Girikon (Ashish)   [IE-10] 16 Aug 2022 : Sync Payment Trans to OrderHub Validity
* 5.Girikon(Ashish)    [GECI-916] 15 May 2023 :   Amendment process Changes to Allow Multiple Amendments for Order Hub
*/
public with sharing class APISynchronizationHelper {
    
    /**
    * @description  This method is used for genrate Dynamic Query to process in batch 
    * @param  synchronizationTransIds  Api synchronization Trans Ids
    * @return  String APISyncItemsQuery
    */
    Public Static String getAPISyncItemsQueryAndStartProcessing(set<Id> synchronizationTransIds)
    {
        List<Id> setProcessQueuedItems       = new List<Id>(); // API_Synchronization_Transactions with Status "Queued"
        List<Id> setProcessAllItems          = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue All"
        List<Id> setProcessErroneousItems    = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue for Erroneous records"    
        List<Id> setProcessSuccessfulItems   = new List<Id>(); // API_Synchronization_Transactions with Status "Requeue for Successful records"
        
        String syncTransaQuerycp = 'Select Id,Status__c from API_Synchronization_Transaction__c where Status__c in (\'Queued\',\'Requeue for Erroneous records\',\'Requeue All\',\'Requeue for Successful records\') '; 
        
        String syncTransaQuery = synchronizationTransIds != null ? syncTransaQuerycp+' And id in : synchronizationTransIds' : syncTransaQuerycp+ ' And (Request_Type__c = \'Asynchronous\' or Status__c != \'Queued\') ';
        
        /** DEBUG **/ System.debug(logginglevel.DEBUG,'syncTransaQuery : '+syncTransaQuery);
        
        // get API_Synchronization_Transaction ready to be pocessed
        for(API_Synchronization_Transaction__c apiSyncTr : Database.query(syncTransaQuery))
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
        String fields = 'ID,Type__c,API_Call_Type__c,Request_Body__c,Status__c,Error_Message__c,External_Tax_System__c,X3rd_Party_ERP_System__c,';
        
        fields += 'API_Synchronization_Transaction__c,API_Synchronization_Transaction__r.Status__c,API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c,API_Synchronization_Transaction__r.Type__c,API_Synchronization_Transaction__r.External_Tax_System__c,API_Synchronization_Transaction__r.Started_From__c,';
        
        fields += 'Edition__r.External_Tax_System__c,Edition__r.External_Status__c,Edition__r.External_Relationship__c,';
        
        fields += 'Invoice__c,Invoice__r.IM_Invoice_No__c,Invoice__r.ERP_Reference__c,Invoice__r.blng__Order__r.Opportunity.IM_Opportunity_No__c,Invoice__r.blng__Order__r.Opportunity.Legacy_CRM_Instance__c,';
        
        fields += 'Order__c,';
        
        fields += 'Amendment_Request__c,Amendment_Request__r.Actioned_By__r.Name,Amendment_Request__r.Actioned_Date_Time__c,Amendment_Request__r.LastModifiedBy.Name,Amendment_Request__r.Amended_Opportunity__c,Amendment_Request__r.Type_of_Change__c,Amendment_Request__r.Name,Amendment_Request__r.Change_Request_Status__c,Amendment_Request__r.CRM_Change_Request_No__c,Amendment_Request__r.IM_Opportunity_No__c,Amendment_Request__r.Legacy_CRM_Instance__c,Amendment_Request__r.Sales_Operations_Comments__c,Amendment_Request__r.Opportunity__c,Amendment_Request__r.ERP_Ref_Numbers__c,Amendment_Request__r.Amendment_Type__c,';
        
        fields += 'Opportunity__c,Opportunity__r.StageName,Opportunity__r.IM_Opportunity_No__c,Opportunity__r.Legacy_CRM_Instance__c,Opportunity__r.Rejection_Reason__c,Opportunity__r.Rejection_Notes__c,';
        
        fields += 'Account__c,Account__r.IM_Account_No__c,Account__r.Accounting_Credit_Hold__c,Account__r.Legacy_CRM_Instance__c,Account__r.Oracle_Number__c,Account__r.SAP_Number__c,';
        
        fields += 'Credit_Note__c,Credit_Note__r.IM_Credit_Note_No__c,Credit_Note__r.blng__Subtotal__c,Credit_Note__r.blng__RelatedInvoice__c,Credit_Note__r.blng__RelatedInvoice__r.blng__Subtotal__c,Credit_Note__r.ERPReference__c,Credit_Note__r.blng__RelatedInvoice__r.blng__Order__r.Opportunity.IM_Opportunity_No__c,Credit_Note__r.blng__RelatedInvoice__r.blng__Order__r.Opportunity.Legacy_CRM_Instance__c ';
        
        String condition = ' where Status__c Not In (\'Paused\',\'Completed with Financials\',\'Pending with Financials\') And ( '; 
        String filter='';
        
        if(!setProcessQueuedItems.isEmpty()) // Process -  Queued 
        {
            filter += ' Or (  API_Synchronization_Transaction__c in (\''+String.join(setProcessQueuedItems,'\',\'')+'\') And Status__c = \'Queued\') ';
        }
        
        if(!setProcessAllItems.isEmpty()) // Process - Error ; Queued ; Re-Queued
        {
            filter += ' Or (  API_Synchronization_Transaction__c in (\''+String.join(setProcessAllItems,'\',\'')+'\') ) ';
        }
        
        if(!setProcessErroneousItems.isEmpty()) // Process - Error
        {
            filter += ' Or (  API_Synchronization_Transaction__c in (\''+String.join(setProcessErroneousItems,'\',\'')+'\') And Status__c = \'Error\') ';
        }
        
        if(!setProcessSuccessfulItems.isEmpty()) // Process - Completed
        {
            filter += ' Or (  API_Synchronization_Transaction__c in (\''+String.join(setProcessSuccessfulItems,'\',\'')+'\') And Status__c = \'Completed\') ';
        }
        filter = String.isNotBlank(filter) ? filter.removeStart(' Or') :' API_Synchronization_Transaction__c = null ';
        
        String query = 'Select '+fields+' from API_Synchronization_Item__c '+condition+filter + ' ) ORDER BY Edition__c,Order__c,Invoice__c,Account__c';
        if(Test.isRunningTest())
        {
            query+= ' limit 1 ';
        }
        System.debug(logginglevel.DEBUG,' API_Synchronization_Item query :' + query );
        
        Map<Id,API_Synchronization_Transaction__c> mapAPITrs = new Map<Id,API_Synchronization_Transaction__c>();
        
        for(API_Synchronization_Item__c item :database.query(query))
        {
            mapAPITrs.put(item.API_Synchronization_Transaction__c,new API_Synchronization_Transaction__c (Id=item.API_Synchronization_Transaction__c,Status__c = GlobalConstants.PROCESSING));  
        }
        
        if(!mapAPITrs.isEmpty() && Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable())
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
    public Static Boolean validateSyncItem(API_Synchronization_Item__c item)
    {
        Boolean allvalid = false;
        // Order tax validation
        if(item.Type__c == GlobalConstants.Tax && String.isNotBlank(item.Order__c) 
           && item.External_Tax_System__c == GlobalConstants.ONESOURCE 
           && item.Edition__r.External_Tax_System__c == GlobalConstants.ONESOURCE 
           && item.Edition__r.External_Relationship__c)
        {
            allvalid = true;
        }
        // Invoice Tax
        if(item.Type__c == GlobalConstants.Tax && String.isNotBlank(item.Invoice__c) 
           && item.External_Tax_System__c == GlobalConstants.ONESOURCE )
        {
            allvalid = true;
        }
        // Invoice/Credit Note - Document Posting 
        if((item.Type__c == GlobalConstants.POST_DOCUMENTS || item.Type__c == GlobalConstants.POST_PAYMENT_TRANSACTIONS)
           && (String.isNotBlank(item.Invoice__c) || String.isNotBlank(item.Credit_Note__c))
           && String.isNotBlank(item.X3rd_Party_ERP_System__c))
        {
            allvalid = true;
        }
        
        // CRM Mule Soft - Account Hold Sync
        if(String.isNotBlank(item.Account__c) && (item.Type__c == GlobalConstants.ACCOUNTING_CREDIT_STATUS || item.Type__c == GlobalConstants.ACCOUNT_ERP_NUMBER_UPDATE))
        {
            allvalid = true;
        }
        // CRM Mule Soft - Amendment Request Approve/Reject [IOM-775] /After Amendment Doc Sync
        
        //if(String.isNotBlank(item.Amendment_Request__c) && (item.Type__c == GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED || item.Type__c == GlobalConstants.CHANGE_REQUEST_COMPLETED || item.Type__c == GlobalConstants.AMENDED_DATA_SYNC || AmendmentUtils.amendTypeOrderHubAPITransMap.values().contains(item.Type__c)))
        if(String.isNotBlank(item.Amendment_Request__c) && (item.Type__c == GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED || item.Type__c == GlobalConstants.CHANGE_REQUEST_COMPLETED || item.Type__c.contains( GlobalConstants.AMENDED_DATA_SYNC))) //[GECI-916]
        {
            allvalid = true;
        }
        // CRM Mule Soft - opportunity Rejection [IOM-775]
        if(String.isNotBlank(item.Opportunity__c) && (item.Type__c == GlobalConstants.OPPORTUNITY_REJECTED || item.Type__c == GlobalConstants.OPPORTUNITY_CLOSED_LOST))
        {
            allvalid = true;
        }
        // Order Start Date / End Date / Amount Update
        if(item.Type__c == GlobalConstants.OLI_START_END_AMOUNT_UPDATE && String.isNotBlank(item.Order__c) )
        {
            allvalid = true;
        }    // GECI-1721
        if(item.Type__c == GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM && (String.isNotBlank(item.Invoice__c)  || String.isNotBlank(item.Credit_Note__c)))
        {
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
            Interface_Log__c  interfaceLof = new Interface_Log__c();
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
    public Static void updateSyncItemStatus(API_Synchronization_Item__c item)
    {
        if(item != null && Schema.sObjectType.API_Synchronization_Item__c.isUpdateable())
        {
            Boolean isSaveAttachment = ((item.Response_Code__c!=null && item.Response_Code__c.length()>255) || (item.Response_Body__c!=null && item.Response_Body__c.length()>131072) || (item.Request_Body__c!=null && item.Request_Body__c.length()>131072));
            String body = (isSaveAttachment?((item.Request_Body__c!=null?item.Request_Body__c:'') + '\n\n' + (item.Response_Code__c!=null?item.Response_Code__c:'') + '\n\n' + (item.Response_Body__c!=null?item.Response_Body__c:'')):'');
            item.Response_Code__c = (item.Response_Code__c!=null?item.Response_Code__c.left(255):'');
            item.Response_Body__c = (item.Response_Body__c!=null?item.Response_Body__c.left(131072):'');
            item.Request_Body__c = (item.Request_Body__c!=null?item.Request_Body__c.left(131072):'');
            update item;            
            if(isSaveAttachment){APISynchronizationHelper.createResponseAttchment(item.Id, body);}
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
    * @description  This method is used to get callout details like username,passwords & End points for  diffrent Systems
    * @param  metaDataName metadata label name
    * @param thirdParty third party name
    * @return  API_Detail__mdt
    */
    public Static API_Detail__mdt getAPIDetails(String metaDataName, String thirdParty)
    {
        API_Detail__mdt apiMappings;      
        if(Schema.sObjectType.API_Detail__mdt.isaccessible())
        {
            apiMappings = [SELECT API_End_Point__c,API_Method__c,Headers__c FROM API_Detail__mdt WHERE API_3rd_Party_Name__c=:thirdParty AND DeveloperName =:metaDataName  LIMIT 1];
        }
        return apiMappings;
    }

    /**
    * @description  This method is used to re-Schedule the batch if more items are Queued
    * @return  String jobid
    */
    public Static String scheduleBatchForNextItems(){        
        String jobId;
        List<String> integrationUsers = GlobalConstants.getValue('Integration_Automation_Users').split(',');
        System.debug(LoggingLevel.DEBUG, integrationUsers);
        Map<Id,API_Synchronization_Transaction__c> mapTransactions = new Map<Id,API_Synchronization_Transaction__c>([SELECT Id FROM API_Synchronization_Transaction__c WHERE  Request_Type__c ='Asynchronous' AND (Status__c IN ('Requeue for Erroneous records','Requeue All','Requeue for Successful records') OR (Status__c='Queued' AND LastModifiedBy.Name IN:integrationUsers))]);
        if(!mapTransactions.isEmpty()){
            APISynchronizationBatch obj = new APISynchronizationBatch(mapTransactions.keySet());
            jobId = System.scheduleBatch(obj,'APISynchronization_Batch_'+ Math.random()*1000+' - '+Datetime.now(),2,1);
        }
        return jobId;
    }

    /**
    * @description  This method is used for get field value from Json String
    * @param  jsonString
    * @param  fieldname
    * @return  value     
    */
    public Static String getValueFromjson(String jsonString,String fieldname)
    {
        String val= '';
        if(String.isNotBlank(jsonString) && jsonString.contains(fieldname))
        {
            JSONParser parser = JSON.createParser(jsonString);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText().toLowercase() == fieldname.toLowercase()) {
                    // Get the value.
                    parser.nextToken();                    
                    val = parser.getText();
                }
            }
        }
        return val;
    }
    
    /**
    * @description -   to create  API Synchronization Transactions
    * @param oppList Opportunity Objects    
    * @return API Synchronization Transaction Id
    */
    @AuraEnabled
    public static String createOppTransactionRequests(list<Opportunity> oppList)
    {
        String apiTransId;
        if(!oppList.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Update';
            obj.startedFrom = 'Opportunity';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = null;
            obj.itemType = GlobalConstants.OPPORTUNITY_REJECTED;
            obj.apiCallType = 'POST';
            obj.listSObject = oppList;
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            apiTransId = CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
        return apiTransId;
    }
    
    /**
    * @description Custom Exception
    */
    public class CustomException extends Exception {} 
}