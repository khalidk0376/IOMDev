/**
* File         : EditionReQueueAPIItems_Trig
* Project      : Order & Billing Plateform
* Created Date : 5th October 2021
* Created By   : Girikon(Deepak)[OPB-401] 
* Test Class   : EditionReQueueAPIItems_Trig_Test
* Coverage     : 96%    
*
* *******************************************************************************************************
* @description : Class for  If API sync transaction is created in Paused state and user update the Edition then paused state API Sync Transaction should be Queued automatically.
* *******************************************************************************************************
* History:
*/

public with sharing class EditionReQueueAPIItems_Trig implements TriggerInterface_Edition.Runnable{
    /**
    * @description [Call Interface Class to fetch the new list and old map of Edition]
    * @param trig [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Edition.Trig trig){
        if(trig.isAfter && trig.isUpdate) 
        {
            getAllEditionsForApiSynchItems(trig.newList, trig.oldMap);
        }
    }

    /**
    * @description [method to get All Editions for checking if ApiSynch]
    * @param editionList 
    * @param oldEditionMap
    */
    private void getAllEditionsForApiSynchItems(List<Edition__c> editionList, Map<Id, Edition__c> oldEditionMap)
    {
        Set<Id> setEditionForApiSynchItemsids = new set<Id>();  
        for(Edition__c edition : editionList)
        {
            if(edition.External_Status__c == GlobalConstants.ACTIVE && edition.External_Relationship__c == true && edition.External_Tax_System__c == GlobalConstants.ONESOURCE)
            {   
                if(oldEditionMap.get(edition.Id).External_Relationship__c != edition.External_Relationship__c || oldEditionMap.get(edition.Id).External_Status__c != edition.External_Status__c || oldEditionMap.get(edition.Id).External_Tax_System__c != edition.External_Tax_System__c)
                {
                    setEditionForApiSynchItemsids.add(edition.Id); 
                }
            }  
        }

        if(!setEditionForApiSynchItemsids.isEmpty())
        {
            updateApiSynchItem(setEditionForApiSynchItemsids);
        }
    }


    /**
    * @description [method to update API sync Items to Paused state  (OBP-401)]
    * @param setEditionIdsForApiSynchItems
    */
    private void updateApiSynchItem(Set<Id> setEditionIdsForApiSynchItems)
    {
        List<API_Synchronization_Item__c> lstApiSynchItems = new List<API_Synchronization_Item__c>();
        Map<Id,API_Synchronization_Transaction__c> mapApiSynchTrans = new Map<Id,API_Synchronization_Transaction__c>();
        try
        {
            for(API_Synchronization_Item__c apiSynchItm : [SELECT Id,Status__c,API_Synchronization_Transaction__c FROM API_Synchronization_Item__c WHERE Edition__c IN:setEditionIdsForApiSynchItems AND Status__c=:GlobalConstants.PAUSED WITH SECURITY_ENFORCED])
            {
                apiSynchItm.Status__c = GlobalConstants.QUEUED;
                lstApiSynchItems.add(apiSynchItm);
                API_Synchronization_Transaction__c apiSyncTrans = new API_Synchronization_Transaction__c(Id=apiSynchItm.API_Synchronization_Transaction__c, Status__c = GlobalConstants.QUEUED);
                mapApiSynchTrans.put(apiSynchItm.API_Synchronization_Transaction__c,apiSyncTrans);
            }

            if(!lstApiSynchItems.isEmpty() && Schema.sObjectType.API_Synchronization_Item__c.isUpdateable())
            {
                update lstApiSynchItems;
            }

            if(!mapApiSynchTrans.isEmpty() && Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable())
            {
                update mapApiSynchTrans.values();
            }
        }
        catch(Exception e){System.debug(logginglevel.DEBUG,'Error in Finish --> '+e.getMessage() +' At Line' + e.getLineNumber());}
    }
}