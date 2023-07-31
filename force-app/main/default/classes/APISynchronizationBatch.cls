/**
* File         :   APISynchronizationBatch 
* Project      :   Order & Billing Plateform
* Created Date :   14th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   (97%) APISynchronization_Test (88%),TaxServiceUtils_Test (71%),OracleOrderHubAPIUtils_Test(70%),MuleSoftCRMCalloutUtils_Test(72%)
* ******************************************************************************************************
 @description : Batch to make API calls using API_Synchronization_Items Records  
*******************************************************************************************************
* Modification log :
* 1. Girikon (Ashish)   [OBP-81]  29 Sep 2021       :   Error Logging for Tax Callouts
* 2. Girikon (Ashish)   [OBP-341] 05 Oct 2021       :   Added logic to create API items for Order Hub 
* 3. Girikon (Ashish)   [IOM-521] 01 Feb 2022       :   Account Credit Status Update to MuleSoft
* 4. Girikon (Ashish)   [IOM-775] 23 Feb 2022       :   Amendment/Opportunity Data Update to MuleSoft
* 5. Girikon (Ansh)     [IOM-448] 23 Feb 2022       :   Amendment/Opportunity Data Update to MuleSoft
* 6. Girikon (Ashish)   [IOM-572] 23 Feb 2022       :   Amendment Request Data Update to MuleSoft
* 7. Girikon (Ashish)   [IE-10]   16 Aug 2022       :   Sync Payment Trans to OrderHub
* 8. Girikon (Deepak)   [GECI-1326] 31 March 2023   :   Stop batch requeue from finish method
* 9.Girikon(Ashish)    [GECI-916] 15 May 2023      :   Amendment process Changes to Allow Multiple Amendments for Order Hub
*/
public with sharing class APISynchronizationBatch implements Database.Batchable<sObject>,Database.stateful,Database.AllowsCallouts
{
    /****** FINAL CONSTANT VARIABLES  *****/
    public static final String BATCH_EXECUTION_ERRORS = 'Batch Execution errors';
    public static final String EXTERNAL_API_CALL = 'External Api Call';
    public static final String COMPLETED_WITH_ERRORS =  'Completed With Errors';
    public static final String API_SYNCHRONIZATION_BATCH =  'API Synchronization Batch';

    /****** PUBLIC Varibales *******/
    public set<Id> synchronizationTransIds;
    public Set<Id> setErroneousAPISyncTrans;
    public Set<Id> setAllAPISyncTrans;        
    public list<API_Synchronization_Item__c> syncItems;


    /**
    * @description APISynchronizationBatch this constructor is used to execute batch in front mode
    * @param syncTransIds api transaction ids
    */
    public APISynchronizationBatch(set<Id> syncTransIds)
    {
        synchronizationTransIds = new Set<Id>(syncTransIds);
        setAllAPISyncTrans = New Set<Id>();
        setErroneousAPISyncTrans = New Set<Id>();
        syncItems = new list<API_Synchronization_Item__c>(); 
    }

    /**
    * @description  This constructor is used to execute batch in background mode
    **/
    public APISynchronizationBatch()
    {  
        setAllAPISyncTrans = New Set<Id>();
        setErroneousAPISyncTrans = New Set<Id>();
        syncItems = new list<API_Synchronization_Item__c>();
    }

    /**
    * @description  This method is used to get the query and records in chunk
    * @param bc BatchableContext
    * @return Database.QueryLocator
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = APISynchronizationHelper.getAPISyncItemsQueryAndStartProcessing(this.synchronizationTransIds);
        return Database.getQueryLocator(query);
    }

    /**
    * @description : This method is used to make callouts for sync
    * @param bc BatchableContext
    * @param items line items to be processed
    **/
    public void execute(Database.BatchableContext bc, List<API_Synchronization_Item__c> items)
    {
        for(API_Synchronization_Item__c item: items) // Valid for one data in loop only
        {
            this.setAllAPISyncTrans.add(item.API_Synchronization_Transaction__c);
            try
            { 
                System.debug(logginglevel.DEBUG,'Processing Item : '+item.Id +' of Trans : '+item.API_Synchronization_Transaction__c); 

                if(APISynchronizationHelper.validateSyncItem(item))
                {
                    String calloutStatus = GlobalConstants.PROCESSING;
                    // ONE_SOURCE
                    if(item.API_Synchronization_Transaction__r.External_Tax_System__c == GlobalConstants.ONESOURCE && item.Type__c == GlobalConstants.TAX )
                    {   // Order || Invoice tax Calculation 
                        if(String.isNotBlank(item.Order__c) || String.isNotBlank(item.Invoice__c) )
                        {
                            calloutStatus = TaxServiceUtils.calculateTax(item);
                        }
                    }
                    // ORACLE
                    if(item.Type__c == GlobalConstants.POST_DOCUMENTS && String.isNotBlank(item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c))
                    {   // Invoice || Credit Note Oracle Sync
                        if(String.isNotBlank(item.Invoice__c) || String.isNotBlank(item.Credit_Note__c))
                        {
                            calloutStatus = OracleOrderHubAPIUtils.syncDocuments2OrderHub(item);
                        }
                    }
                    // Sync Payment OrderHub [IE-10]
                    if(item.Type__c == GlobalConstants.POST_PAYMENT_TRANSACTIONS && String.isNotBlank(item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c))
                    {   // Invoice || Credit Note Oracle Sync   
                        if(String.isNotBlank(item.Invoice__c) || String.isNotBlank(item.Credit_Note__c))
                        {                     
                            calloutStatus = OracleOrderHubAPIUtils.syncPaymentTransaction2OrderHub(item);  
                        }                      
                    }
                    // ORACLE Sync After Amendment Process [IOM-572]
                    //if(AmendmentUtils.amendTypeOrderHubAPITransMap.values().contains(item.Type__c) && (item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c == GlobalConstants.ORACLE || item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c == GlobalConstants.SAP) && String.isNotBlank(item.Amendment_Request__c) )
                     //[GECI-916]   
                    if(item.Type__c == GlobalConstants.AMENDED_DATA_SYNC_OH && (item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c == GlobalConstants.ORACLE || item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c == GlobalConstants.SAP) && String.isNotBlank(item.Amendment_Request__c) )
                    {                      
                        calloutStatus = OracleOrderHubAPIUtils.syncAfterAmendmentData2OrderHub(item);                
                    }
                    // IOM to CRM                    
                    // CRM Mule Soft - Account Hold Sync
                    if(item.Type__c == GlobalConstants.ACCOUNTING_CREDIT_STATUS || item.Type__c == GlobalConstants.ACCOUNT_ERP_NUMBER_UPDATE)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updateAccountCreditStatus(item);                            
                    }
                  	// CRM Mule Soft - Opportunity Closed Lost [IOM-448]
                    if(item.Type__c == GlobalConstants.OPPORTUNITY_CLOSED_LOST)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updateOppStageName(item);                            
                    }
                    // CRM Mule Soft - Amendment Request Approve/Reject [IOM-775]
                    if(item.Type__c == GlobalConstants.AMENDMENT_REQUEST_APPROVED_REJECTED || item.Type__c == GlobalConstants.CHANGE_REQUEST_COMPLETED)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updateAmendmentRequestStatus(item);
                    }
                    // CRM Mule Soft - opportunity Rejection [IOM-775]
                    if(item.Type__c == GlobalConstants.OPPORTUNITY_REJECTED)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updateOpportunityRejectionNotes(item);
                    }
                    // CRM Mule Soft - After Amendment Data Sync [IOM-572]
                    if(item.Type__c == GlobalConstants.AMENDED_DATA_SYNC)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updatedataIOMtoCRM(item); 
                    } 
                    // CRM Mule Soft - After Amendment Data Sync [GECI-247]
                    if(item.Type__c == GlobalConstants.OLI_START_END_AMOUNT_UPDATE)
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.updateOppProductsInCRM(item); 
                    } 
                    // CRM Mule Soft - After Amendment Data Sync [GECI-247]
                    if(item.Type__c == GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM )
                    {
                        calloutStatus = MuleSoftCRMCalloutUtils.syncERPDocumnetERPNo(item); 
                    } 

                    // Incase of Error
                    if(calloutStatus == GlobalConstants.ERROR)
                    {
                        this.setErroneousAPISyncTrans.add(item.API_Synchronization_Transaction__c);
                    }
                }
                else{
                    system.debug(logginglevel.DEBUG,item.API_Synchronization_Transaction__r.X3rd_Party_ERP_System__c + ' Synchronization is not valid for the Edition');
                    item.Error_Message__c = GlobalConstants.BLANK_STRING;
                    item.Status__c = GlobalConstants.PAUSED;
                    syncItems.add(item);
                }
            }catch(Exception e){

                item.Error_Message__c = e.getMessage();
                item.Status__c = GlobalConstants.ERROR;
                syncItems.add(item);
                this.setErroneousAPISyncTrans.add(item.API_Synchronization_Transaction__c);
                
                system.debug(logginglevel.DEBUG,'Error_Message__c --> '+item.Error_Message__c +' At Line' + e.getLineNumber());
                system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());

                HandleAllCustomException.logException(e,item.Id,API_SYNCHRONIZATION_BATCH);
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
        list<API_Synchronization_Transaction__c> syncTrans = new list<API_Synchronization_Transaction__c>();
        list<Interface_Error_Line__c> interfaceErrorLines = new list<Interface_Error_Line__c>();
        try {
            
            if(!this.setErroneousAPISyncTrans.isEmpty())
            {
                interfaceLogId = APISynchronizationHelper.createInterfaceLog(BATCH_EXECUTION_ERRORS,EXTERNAL_API_CALL); 
            }

            for(ID syncTranId:this.setAllAPISyncTrans)
            {
                API_Synchronization_Transaction__c syncTran = new API_Synchronization_Transaction__c();
                syncTran.Id = syncTranId;
                syncTran.Status__c  = this.setErroneousAPISyncTrans.contains(syncTranId)?COMPLETED_WITH_ERRORS:GlobalConstants.COMPLETED;
                syncTran.Interface_Log__c = this.setErroneousAPISyncTrans.contains(syncTranId)?interfaceLogId:null;
                syncTrans.add(syncTran);
            }

            if(Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable())
            {
                update syncTrans;
            }
            if(!this.syncItems.isEmpty() && Schema.sObjectType.API_Synchronization_Item__c.isUpdateable())
            {
                update syncItems;
            }

            for(API_Synchronization_Item__c item : [Select Id,Error_Message__c,Response_Code__c from API_Synchronization_Item__c where Status__c=: GlobalConstants.ERROR AND API_Synchronization_Transaction__c in:this.setErroneousAPISyncTrans ])
            {
                // Log Interface Error
                Interface_Error_Line__c errorLine       = new Interface_Error_Line__c();
                errorLine.Interface_Log__c              = interfaceLogId;
                errorLine.API_Synchronization_Item__c   = item.Id;
                errorLine.Error_Code__c                 = item.Response_Code__c;
                errorLine.Error_Message__c              = item.Error_Message__c;
                interfaceErrorLines.add(errorLine);
            }

            if(!interfaceErrorLines.isEmpty() && Schema.sObjectType.Interface_Error_Line__c.isCreateable())
            {
                insert interfaceErrorLines;
            }
            List<String> integrationUsers = GlobalConstants.getValue('Integration_Automation_Users').split(',');
            String userName = UserInfo.getName();
            if(integrationUsers.contains(userName)){APISynchronizationHelper.scheduleBatchForNextItems();}

            //Sending Email to Batch Owner and other user in CC when Batch Execution Fails
            // if(!setErroneousAPISyncTrans.isEmpty())
            // {
            //     //APISynchronizationHelper.sendEmailOnBatchFail(setErroneousAPISyncTrans); 
            // } 
        }
        catch(Exception e){
            system.debug(logginglevel.DEBUG,'Error in Finish --> '+e.getMessage() +' At Line' + e.getLineNumber()); system.debug(logginglevel.DEBUG,' Trace --> '+ e.getStackTraceString());
            HandleAllCustomException.logException(e,interfaceLogId,API_SYNCHRONIZATION_BATCH);
        }
    }
}