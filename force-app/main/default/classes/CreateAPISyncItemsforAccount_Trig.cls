/**
* File			: 	CreateAPISyncItemsforAccount_Trig
* Project       :   Informa Order Management [IOM-521]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	02nd Feb 2022
* Test Class    :   CreateAPISyncItemsforAccount_Trig(100%)
* **************************************************************************************
* @description : Utility Class for Creating API Synchronization Items On Account Update
****************************************************************************************
* Last Modified By :
*/
public with sharing class CreateAPISyncItemsforAccount_Trig implements TriggerInterface_Account.Runnable 
{

    public static final String RESTRICT_ERP_BACKUPDATE_ACCOUNT = 'Restrict ERP BackUpdate Account';

    /**
    * @description This method is execute Trigger
    * @param trig TriggerInterface_Account [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Account.Trig trig) 
    {
        if(trig.isAfter && trig.isUpdate)
        {
            insertAPISyncItemForCreditStatusChnage(trig.newList,trig.oldMap);
            insertAPISyncItemForOracleNoUpdate(trig.newList,trig.oldMap);
        }
    }
    /**
    * @description  This method is used to Create API Sync Items
    * @param newAccountList new Account List
    * @param oldAccountMap Old Account Map
    */
    private static void insertAPISyncItemForCreditStatusChnage(list<Account> newAccountList,Map<Id,Account> oldAccountMap)
    {
        List<Account> accountList = New List<Account>();
        for(Account acc:newAccountList)
        {
            if(acc.Accounting_Credit_Hold__c != oldAccountMap.get(acc.Id).Accounting_Credit_Hold__c)
            {
                accountList.add(acc);
            }
        }
        
        if(!accountList.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Update';
            obj.startedFrom = 'Account';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = null;
            obj.itemType = GlobalConstants.ACCOUNTING_CREDIT_STATUS; 
            obj.apiCallType = 'POST';
            obj.listSObject = accountList;
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
    /**
    * @description  This method is used to Create API Sync Items
    * @param newAccountList new Account List
    * @param oldAccountMap Old Account Map
    */
    private static void insertAPISyncItemForOracleNoUpdate(list<Account> newAccountList,Map<Id,Account> oldAccountMap)
    {
        List<Account> accountList = New List<Account>();
        List<String> listlegacyCRM = new List<String>();
        String legacyCRM = GlobalConstants.getValue(RESTRICT_ERP_BACKUPDATE_ACCOUNT);
        if(legacyCRM.contains(',')){
            listlegacyCRM = legacyCRM.split(',');
        }
        for(Account acc:newAccountList)
        {
            if(!listlegacyCRM.contains(acc.Legacy_CRM_Instance__c) && acc.Oracle_Number__c != oldAccountMap.get(acc.Id).Oracle_Number__c || acc.SAP_Number__c != oldAccountMap.get(acc.Id).SAP_Number__c)
            {
                accountList.add(acc);
            }
        }
        
        if(!accountList.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Update';
            obj.startedFrom = 'Account';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = null;
            obj.itemType = GlobalConstants.ACCOUNT_ERP_NUMBER_UPDATE;
            obj.apiCallType = 'POST';
            obj.listSObject = accountList;
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
}