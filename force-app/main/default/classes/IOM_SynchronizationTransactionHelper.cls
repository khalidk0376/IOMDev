/**
* File          :   IOM_SynchronizationTransactionHelper
* Project       :   Order & Billing Plateform
* Created By    :   Suresh(Girikon)
* Created Date  :   13th Dec 2021
* Test Class   :    IOM_SendForOrder_Test(100%),IOM_AmendmentRequest_Test(80%)
* ***************************************************************************
* @description : Helper class for trigger IOM_SynchronizationTransaction_Trigger
*****************************************************************************
* Last Modified By :
*/
public class IOM_SynchronizationTransactionHelper {
  
    /**
    * @description  This method used to perform After Insert Logic on IOM_Synchronization_Transaction
    * @param  ompSyncNewList list of IOM_Synchronization_Transaction__c
    * @param  ompSyncOldMap OldMap <Id and IOM_Synchronization_Transaction__c>
    */
    public static void afterInsertHandle(List<IOM_Synchronization_Transaction__c> ompSyncNewList,Map<Id,IOM_Synchronization_Transaction__c> ompSyncOldMap)
    {
        processIOMOpportunity(ompSyncNewList,ompSyncOldMap,true);
    }
    /**
    * @description  This method used to perform After Update Logic on IOM_Synchronization_Transaction
    * @param  ompSyncNewList list of IOM_Synchronization_Transaction__c
    * @param  ompSyncOldMap OldMap <Id and IOM_Synchronization_Transaction__c>
    */
    public static void afterUpdateHandle(List<IOM_Synchronization_Transaction__c> ompSyncNewList,Map<Id,IOM_Synchronization_Transaction__c> ompSyncOldMap)
    {

        /** Process IOM Opportunity MuleSoft Callout [IOM-524] */
        /** Process IOM Opportunity MuleSoft Retry  [IOM-515] */
        processIOMOpportunity(ompSyncNewList,ompSyncOldMap,false);

    }

    /**
    * @description  This method used to run Mulesoft callout batch
    * @param  ompSyncNewList list of IOM_Synchronization_Transaction__c
    * @param  ompSyncOldMap OldMap <Id and IOM_Synchronization_Transaction__c>
    * @param  isInsert Is Insert DML?
    */
    private static void processIOMOpportunity(List<IOM_Synchronization_Transaction__c> ompSyncNewList,Map<Id,IOM_Synchronization_Transaction__c> ompSyncOldMap,Boolean isInsert)
    {
        /** Sync IOM Records to mulesoft **/
        Set<Id> ompSyncTransIds = new Set<Id>();
        // Set<Id> crmOppIds = new Set<Id>();

        for(IOM_Synchronization_Transaction__c ompTrns : ompSyncNewList)
        {
            IOM_Synchronization_Transaction__c oldOmptran = isInsert ? new IOM_Synchronization_Transaction__c(): ompSyncOldMap.get(ompTrns.Id);

            if(ompTrns.IOM_Processing_Status__c != oldOmptran.IOM_Processing_Status__c &&
            (ompTrns.IOM_Processing_Status__c == 'Queued' || ompTrns.IOM_Processing_Status__c == 'Requeue'))
            {
               ompSyncTransIds.add(ompTrns.Id);               
            }
        }
        // Send callout to MuleSoft to process the JSON Palyload
        if(!ompSyncTransIds.isEmpty())
        {
            Database.executeBatch(new IOM_MulesoftSalesforceCalloutBatch(ompSyncTransIds),1);
        }
        /** IOM END */
    }
}