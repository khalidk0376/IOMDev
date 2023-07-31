/**
* File         :   SynchronousAPICallController 
* Project      :   Order & Billing Plateform
* Created Date :   21 Sept 2021
* Created By   :   Girikon(Deepak)
* Test Class   :   SynchronousAPICallController_Test (96%)
* ******************************************************************************************************
* @description : For Creating Records to API Synchronization transaction and calling batch while showing status on UI
********************************************************************************************************
* Modification log :
*/
public with sharing class SynchronousAPICallController{
    public static final String NO_DATA = 'error:';
    public static final String JOB_ABORTED = 'Job Aborted';
    public static final Set<String> COMPLETE_STATUES  = new Set<String> {'Completed','Error','Paused'};
        
        /**
* @description : this method will fetch apex jobs and will update status,JobItemsProcessed,NumberOfErrors,TotalJobItems
* @param batchId batch Id
* @return AsyncApexJob
**/
        @AuraEnabled
        public static AsyncApexJob getJobs(String batchId) {
            AsyncApexJob apexJobs;
            Boolean isAccess = true;
            if(Schema.sObjectType.AsyncApexJob.isCreateable() || isAccess){
                apexJobs = [SELECT TotalJobItems,Status,NumberOfErrors,ExtendedStatus,JobItemsProcessed,Id,JobType,ApexClassId, CreatedDate FROM AsyncApexJob WHERE Id =: batchId];
            }
            return apexJobs;
        }
    
    /**
* @description : to Create API Sync Transaction Records for Order
* @param orderId order Id
* @param thirdParty account Id
* @return TransactionDetails
**/
    @AuraEnabled
    public static TransactionDetails createOrderTaxAPITransaction(Id orderId, String thirdParty){
        String aycnApiTrnsctnId;
        List<Order> lstOrder = new List<Order>();
        TransactionDetails tranDetail = new TransactionDetails();
        try{
            Map<String,Edition_Setting__mdt> mapES = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
            for(Order ord : [SELECT Id,Edition__c,Edition__r.Edition_Code__c,Edition__r.External_Relationship__c,Edition__r.External_Status__c,Edition__r.External_Tax_System__c,Legacy_CRM_Instance__c FROM Order WHERE Id =:orderId AND (Status =:GlobalConstants.DRAFT OR Tax_Status__c='Tax Required') AND Edition__r.External_Tax_System__c =:GlobalConstants.ONESOURCE AND Edition__c !=null WITH SECURITY_ENFORCED]){
                if(thirdParty == GlobalConstants.ONESOURCE && ord.Edition__r.External_Relationship__c && ord.Edition__r.External_Status__c==GlobalConstants.ACTIVE){
                    String key = ord.Edition__r.Edition_Code__c + '_' + ord.Legacy_CRM_Instance__c;
                    Boolean disableTaxCal =  (String.isNotBlank(key) && mapES.containsKey(key))?(mapES.get(key)?.Disable_Tax_Calculation__c):false;
                    if(!disableTaxCal){
                        lstOrder.add(ord);
                    }
                }
            }
            if(!lstOrder.isEmpty()){
                tranDetail = createTaxAPITransaction(lstOrder, 'Order');
            }
            if(lstOrder.isEmpty()){
                aycnApiTrnsctnId = NO_DATA + ('Tax Callout in not applicable for this record.');
                tranDetail.trasactionId = aycnApiTrnsctnId;
            }
			
        }
        catch(Exception e){
            //HandleAllCustomException.LogException(e,'','');
            System.debug(LoggingLevel.DEBUG, e.getMessage());
        }
        return tranDetail; 
    }
    
    /**
* @description : to Create API Sync Transaction Records for Invoice
* @param invoiceId order Id
* @param thirdParty account Id
* @return TransactionDetails
**/
    @AuraEnabled
    public static TransactionDetails createInvoiceTaxAPITransaction(Id invoiceId, String thirdParty){
        String aycnApiTrnsctnId;
        List<blng__Invoice__c> lstInvoice= new List<blng__Invoice__c>();
        Set<Id> setIdEditions = new Set<Id>();
        TransactionDetails tranDetail = new TransactionDetails();
        try{
            Map<String,Edition_Setting__mdt> mapES = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();
            for(blng__Invoice__c inv : [SELECT Id,blng__Order__r.Edition__r.Edition_Code__c,blng__Order__r.Legacy_CRM_Instance__c FROM blng__Invoice__c WHERE Id =:invoiceId AND blng__InvoiceStatus__c=:GlobalConstants.DRAFT WITH SECURITY_ENFORCED]){
                if(thirdParty == GlobalConstants.ONESOURCE){
                    String key = inv.blng__Order__r.Edition__r.Edition_Code__c + '_' + inv.blng__Order__r.Legacy_CRM_Instance__c;
                    Boolean disableTaxCal =  (String.isNotBlank(key) && mapES.containsKey(key))?(mapES.get(key)?.Disable_Tax_Calculation__c):false;
                    if(!disableTaxCal){
                        lstInvoice.add(inv);
                    }
                }
            }
            if(!lstInvoice.isEmpty()){
                tranDetail = createTaxAPITransaction(lstInvoice, 'Invoice');
            }
            if(lstInvoice.isEmpty()){
                aycnApiTrnsctnId = NO_DATA + ('Tax Callout in not applicable for this record.');
                tranDetail.trasactionId = aycnApiTrnsctnId;
            }
			
        }
        catch(Exception e){
            //HandleAllCustomException.LogException(e,'','');
            System.debug(LoggingLevel.DEBUG, e.getMessage());
        }
        return tranDetail; 
    }
    
    /**
* @description : to Create API Sync Transaction Records for Tax
* @param listSObj
* @param objectName object Name
* @return TransactionDetails
**/
    private static TransactionDetails createTaxAPITransaction(List<SObject> listSObj, String objectName){
        String aycnApiTrnsctnId;
        Set<Id> apiSyncTranSet = new Set<Id>();
        TransactionDetails tranDetail = new TransactionDetails();
        if(listSObj.isEmpty()){aycnApiTrnsctnId = NO_DATA + (objectName=='Invoice'?'Invoice is not in Draft status.':'Either Order is not in Draft status Or Tax Calculation Setting is not enabled on Edition.');}
        if(!listSObj.isEmpty())
        {
            aycnApiTrnsctnId = null;
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.type = 'Update';
            obj.startedFrom = objectName;
            obj.listSObject = listSObj;
            obj.requestType = GlobalConstants.SYNCHRONOUS;
            obj.externalTaxSystem = GlobalConstants.ONESOURCE;
            obj.apiCallType = 'POST';
            obj.itemType = 'Tax';
            aycnApiTrnsctnId = CreateApiSyncRecords.insertAllAPISyncItem(obj);
            if(String.isBlank(aycnApiTrnsctnId)){aycnApiTrnsctnId = NO_DATA + 'A tax callout request already created.';}
        }
        
        if(String.isNotBlank(aycnApiTrnsctnId) && !aycnApiTrnsctnId.startsWith(NO_DATA))
        {
            apiSyncTranSet.add(aycnApiTrnsctnId);
            APISynchronizationBatch batch = new APISynchronizationBatch(apiSyncTranSet);
            Id batchId = database.executebatch(batch,1);
            API_Synchronization_Transaction__c apisyctransaction= new API_Synchronization_Transaction__c(Id=aycnApiTrnsctnId);
            apisyctransaction.JobId__c = batchId;
            if(Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable())
            {
                update apisyctransaction;
            }
            tranDetail.batchId = batchId;
            tranDetail.trasactionId = aycnApiTrnsctnId;
            tranDetail.interfaceLogId = apisyctransaction.Interface_Log__c;
        }
        tranDetail.trasactionId = aycnApiTrnsctnId;
        return tranDetail; 
    }
    
    /**
* @description : TransactionDetails class
*/
    public class TransactionDetails{
        /**
* @description : batch Id
*/
        @AuraEnabled
        public Id batchId {get;set;}
        
        /**
* @description : trasaction Id
*/
        @AuraEnabled 
        public String trasactionId {get;set;} 
        
        /**
* @description : interface Log Id
*/
        @AuraEnabled  
        public Id interfaceLogId {get;set;} 
    } 
    
    /**
* @description : to get API Synchronization Transaction detail
* @param txnId API Synchronization Transaction Id
* @return Transaction Details
**/
    @AuraEnabled
    public static API_Synchronization_Transaction__c getTransactionDetail(String txnId){
        API_Synchronization_Transaction__c tranDetail = getTransactionSOQL(txnId);
        boolean hasErrorOrQueued = false;
        for(API_Synchronization_Item__c item : tranDetail.API_Synchronization_Items__r){
            if(item.Status__c == GlobalConstants.ERROR){hasErrorOrQueued = true;}
            if(item.Status__c == GlobalConstants.QUEUED && tranDetail.External_Tax_System__c == GlobalConstants.ONESOURCE){hasErrorOrQueued = true;}
        }
        if((tranDetail.Status__c == APISynchronizationBatch.COMPLETED_WITH_ERRORS || tranDetail.Status__c == GlobalConstants.PROCESSING) && !hasErrorOrQueued && Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable()){
            API_Synchronization_Transaction__c tran = new API_Synchronization_Transaction__c(Id=txnId,Status__c=GlobalConstants.COMPLETED);
            update tran;
            tranDetail.Status__c = GlobalConstants.COMPLETED; 
        }
        return tranDetail; 
    }
    
    /**
* @description : to get API Synchronization Transaction detail
* @param txnId API Synchronization Transaction Id
* @return Transaction Details
**/
    private static API_Synchronization_Transaction__c getTransactionSOQL(String txnId){
        API_Synchronization_Transaction__c tranDetail = new API_Synchronization_Transaction__c();
        try{
            if(!String.isBlank(txnId)){
                tranDetail = [SELECT Id, Status__c, Interface_Log__c, JobId__c,External_Tax_System__c, 
                              (SELECT Status__c FROM API_Synchronization_Items__r)
                              FROM API_Synchronization_Transaction__c Where Id=:txnId WITH SECURITY_ENFORCED];
            }
        }
        catch(Exception ex){
            //HandleAllCustomException.LogException(ex,'','');
            System.debug(LoggingLevel.DEBUG, ex.getMessage());
        }
        return tranDetail;
    }
}