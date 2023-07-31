/**
* File			: 	CreateAPISyncItemsforOpportunity_Trig
* Project       :   Informa Order Management [IOM-521]
* Created By	: 	Girikon(Ansh)
* Created Date	: 	02nd Feb 2022
* Test Class    :   CreateAPISyncItemsforOpp_Trig_Test(100%)
* **************************************************************************************
* @description : Utility Class for Creating API Synchronization Items On Opportunity Update
****************************************************************************************
* Last Modified By :
*/
public with sharing class CreateAPISyncItemsforOpportunity_Trig implements TriggerInterface_Opportunity.Runnable 
{
    /**
    * @description This method is execute Trigger
    * @param trig TriggerInterface_Opportunity [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Opportunity.Trig trig) 
    {
        if(trig.isAfter && trig.isUpdate)
        {
            insertAPISyncItemForCreditStatusChnage(trig.newList,trig.oldMap);
        }
    }
    /**
    * @description  This method is used to Update Opp StageName
    * @param newOppList new Order List
    * @param oldOppMap Old Order Map
    */
    private static void insertAPISyncItemForCreditStatusChnage(list<Opportunity> newOppList,Map<Id,Opportunity> oldOppMap)
    {
        List<Opportunity> oppList = New List<Opportunity>();
        for(Opportunity opp:newOppList)
        {
            if(opp.StageName != oldOppMap.get(opp.Id).StageName && opp.StageName == 'Closed Lost')
            {
                oppList.add(opp);
            }
        }
        
        if(!oppList.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Update';
            obj.startedFrom = 'Opportunity';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = null;
            obj.itemType = GlobalConstants.OPPORTUNITY_CLOSED_LOST; 
            obj.apiCallType = 'PUT';
            obj.listSObject = oppList;
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.QUEUED; // pause till API ready
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
}