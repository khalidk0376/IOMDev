/**
* File         :   IOM_SendForOrderBatch 
* Project      :   Order & Billing Plateform
* Created Date :   08th Nov 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test(100%)
* ******************************************************************************************************
 @description : Batch to create payload for IOM Sync
********************************************************************************************************
* Modification log :
* 1.13th Nov 2021 - Girikon(Suresh) - Updated code to create IOM_Synchronization_Transaction__c data
*/
public with sharing class IOM_SendForOrderBatch implements Database.Batchable<sObject>,Database.stateful,Database.AllowsCallouts
{
    public Set<Id> opportunitiesIds;
    public Set<Id> iomSynchronizationTransactionIds;

    /**
    * @description  This Batch Contructor will take Opportunity Ids to create JSON payload
    * @param opportunitiesIds set of Opportunity Id
    **/
    public IOM_SendForOrderBatch(Set<Id> opportunitiesIds)
    {
        this.opportunitiesIds = opportunitiesIds;
        this.iomSynchronizationTransactionIds = new Set<Id>();
    }

    /**
    * @description  This method is used to get the query and records in chunk
    * @param bc BatchableContext
    * @return Database.QueryLocator
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = IOM_SendForOrderUtils.getQuery(opportunitiesIds);
        System.debug(LoggingLevel.Debug,'IOM_SendForOrderBatch [START] : QUERY --> ' +query);
        return Database.getQueryLocator(query);
    }

    /**
    * @description : This method is used to create payload from Opportunities
    * @param bc BatchableContext
    * @param opportunities list of Opprtunities for which the payloads will be created 
    **/
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities)
    {
        System.debug(LoggingLevel.Debug,'IOM_SendForOrderBatch [EXECUTE] ');
        for(Opportunity opp: opportunities)
        {
            string iomSyncId = IOM_SendForOrderUtils.createIOMOrderpayload(opp.Id);
            if(String.isNotBlank(iomSyncId))
            {                
                this.iomSynchronizationTransactionIds.add(iomSyncId);
            }
        }        
    }

    /**
    * @description  This Final method 
    * @param bc BatchableContext
    **/
    public void finish(Database.BatchableContext bc)
    {
        System.debug(LoggingLevel.Debug,'IOM_SendForOrderBatch [FINISH] ');

        List<IOM_Synchronization_Transaction__c> iomSyncTransactions = new List <IOM_Synchronization_Transaction__c>();
        
        for(IOM_Synchronization_Transaction__c iomSync : [SELECT Id,Name,IOM_Processing_Status__c,IOM_Request_Body__c FROM IOM_Synchronization_Transaction__c WHERE Id IN: this.IOMSynchronizationTransactionIds WITH SECURITY_ENFORCED])
        {            
            iomSync.IOM_Processing_Status__c = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.IOM_SYNC_STATUS);
            if(String.isNotBlank(iomSync.IOM_Request_Body__c))
            {
                iomSync.IOM_Request_Body__c = iomSync.IOM_Request_Body__c.Replace('[#SynchronizationRequestName#]',iomSync.Name);    
            }
            iomSyncTransactions.add(iomSync);
        }
        if(Schema.sObjectType.IOM_Synchronization_Transaction__c.isUpdateable())
        {
            update iomSyncTransactions;
        }
    }
}