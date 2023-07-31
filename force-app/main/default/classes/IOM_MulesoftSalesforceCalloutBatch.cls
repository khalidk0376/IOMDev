/**
* File         :   IOM_MulesoftSalesforceCalloutBatch 
* Project      :   Order & Billing Plateform
* Created Date :   06th Dec 2021
* Created By   :   Girikon(Suresh)
* Test Class   :   IOM_SendForOrder_Test(100%)
* ******************************************************************************************************
 @description : Batch to make callout on Mulesoft Endpoint
*******************************************************************************************************
* Modification log :
* 1. 
*/
public with sharing class IOM_MulesoftSalesforceCalloutBatch implements Database.Batchable<sObject>,Database.stateful,Database.AllowsCallouts {
	
    /****** FINAL CONSTANT VARIABLES  *****/
    // public static final String BATCH_EXECUTION_ERRORS = 'Batch Execution errors';


    /****** PUBLIC Varibales *******/
    public set<Id> synchronizationTransIds;
    public Set<Id> setErroneousAPISyncTrans;
    public Set<Id> setAllAPISyncTrans;        
    public list<IOM_Synchronization_Transaction__c> syncItems;


    /**
    * @description IOM_MulesoftSalesforceCalloutBatch this constructor is used to execute batch in front mode
    * @param syncTransIds IOM transaction ids
    */
    public IOM_MulesoftSalesforceCalloutBatch(set<Id> syncTransIds)
    {
        synchronizationTransIds = new Set<Id>(syncTransIds);
        setAllAPISyncTrans = New Set<Id>();
        setErroneousAPISyncTrans = New Set<Id>();
        syncItems = new list<IOM_Synchronization_Transaction__c>(); 
    }
    
    /**
    * @description  This method is used to get the query and records in chunk
    * @param bc BatchableContext
    * @return Database.QueryLocator
    **/
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = IOM_SendForOrderUtils.getAPISyncItemsQueryAndStartProcessing(this.synchronizationTransIds);
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description : This method is used to create payload from Opportunities
    * @param bc BatchableContext
    * @param items list of IOM_Synchronization_Transaction__c
    **/
    public void execute(Database.BatchableContext bc, List<IOM_Synchronization_Transaction__c> items)
    {
        for(IOM_Synchronization_Transaction__c item : items){
            this.setAllAPISyncTrans.add(item.Id);
            IOM_SendForOrderUtils.sendpayloaddata(item);
        }        
    }

    /**
    * @description  This Final method 
    * @param bc BatchableContext
    **/
    public void finish(Database.BatchableContext bc)
    {
        System.debug(LoggingLevel.Debug,'IOM_SendForOrderBatch [FINISH] ');
    }
}