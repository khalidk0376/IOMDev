/**
* File         :   IMCC_CreateApiSyncRecords 
* Project      :   IMCC
* Created Date :   8th Sept 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(96%)
* Coverage     :   96%
***********************************************************************************************
* @description : Batch to make API calls using IMCC_API_Synchronization_Items Records.
***********************************************************************************************
* Modification log :
*/
public with sharing class IMCC_CreateApiSyncRecords {
    /**
    * @description  map objet name and edition field name
    */
    private static Map<String,String> sobjNameEditionFieldName = new Map<String,String>{'Asset' => 'Edition__c'};

    /**
    * @description  Wrapper Class For creating Api Sync Records
    */
    public class IMCC_ApiSyncRecordsWrapper
    {
        /**
        * @description For edition Ids after validation check
        */
        public Map<Id,Boolean> editionValidations = New Map<Id,Boolean>();
        /** @description For sobj id and sobj name
        */
        public Map<String,String> sobjIdSobjName = New Map<String,String>();
        /** @description For sobj id and Edition Id
        */
        public Map<String,String> sobjIdEditionId = New Map<String,String>();
        /**
        * @description For checking the record is for update,Create or GET
        */
        public String type;
        /**
        * @description For Checking where this trigger is started from
        */
        public String startedFrom;
        /**
        * @description list of sobject
        */
        public List<SObject> listSObject = New List<SObject>();
        /**
        * @description list of sobject
        */
        public Map<Id,SObject> mapSObjectOld = New Map<Id,SObject>();
        /**
        * @description For checking whether the record is created for direct sync or can take some time.
        */
        public String requestType;
        /**
        * @description For api Call Type
        */
        public String apiCallType;
        /**
        * @description For item Type
        */
        public String itemType;
        /**
        * @description For All item Status
        */
        public String itemStatus;
        /**
        * @description For checking the transaction status
        */
        public String transactionStatus;
    }

    /**
    * @description  Creation of All API Sync items and their transactions records.
    * @param  apiSyncWrap
    * @return  Id API Transaction
    */
    public static Id insertAllAPISyncItem(IMCC_ApiSyncRecordsWrapper apiSyncWrap)
    {
        List<IMCC_API_Synchronization_Transaction__c> lstApiSyncTran = new List<IMCC_API_Synchronization_Transaction__c>();
        List<IMCC_API_Synchronization_Item__c> lstApiSyncItem = new List<IMCC_API_Synchronization_Item__c>();
        Id syncTranId;
        String triggerOn;
        Boolean checkAllStatus = false;
        try{
            Set<Id> editionIds = new Set<Id>();
            for(SObject sobj : apiSyncWrap.listSObject)
            {
                Id sobjId = Id.valueOf(String.valueOf(sobj.get('Id')));
                String sobjIdStartString = String.valueOf(sobjId).left(3);
                if(!apiSyncWrap.sobjIdSobjName.containsKey(sobjIdStartString)){
                    String sObjName = sobjId.getSObjectType().getDescribe().getName();
                    apiSyncWrap.sobjIdSobjName.put(sobjIdStartString, sObjName);
                }
                String objectName = apiSyncWrap.sobjIdSobjName.get(sobjIdStartString);
                String editionFieldName = (sobjNameEditionFieldName.containsKey(objectName)?sobjNameEditionFieldName.get(objectName):'');
                if(String.isNotBlank(editionFieldName)){
                    String editionId = (String)sobj.get(editionFieldName);
                    editionIds.add(editionId);
                    apiSyncWrap.sobjIdEditionId.put(sobjId, editionId);
                }
            }
            apiSyncWrap.editionValidations = new Map<Id,Boolean>(fieldsValidationOnEdition(editionIds));
            if(!apiSyncWrap.listSObject.isEmpty())
            {
                lstApiSyncItem = insertAPISyncItems(apiSyncWrap);
            }
            IMCC_API_Synchronization_Transaction__c apiSyncTran = new IMCC_API_Synchronization_Transaction__c();            
            for(IMCC_API_Synchronization_Item__c item : lstApiSyncItem){
                if(String.isNotBlank(item.Asset__c) && 'Queued'.equalsIgnoreCase(item.Status__c))
                {
                    checkAllStatus = true;
                }                
            }
            apiSyncWrap.transactionStatus = (checkAllStatus?'Queued':'Paused');
            apiSyncTran.Status__c = 'Paused';
            
            apiSyncTran.Started_From__c = apiSyncWrap.startedFrom;
            apiSyncTran.Type__c = apiSyncWrap.type;
            apiSyncTran.Request_Type__c = (apiSyncWrap.requestType==''?'Synchronous':'Asynchronous');
            lstApiSyncTran.add(apiSyncTran);

            syncTranId =  insertAllRecords(lstApiSyncTran, lstApiSyncItem, apiSyncWrap);            
        }
        catch(Exception e) 
        {
            triggerOn = apiSyncWrap.type;
            //HandleAllCustomException.LogException(e,'',triggerOn);
            System.debug(LoggingLevel.DEBUG, triggerOn);
            System.debug(logginglevel.DEBUG,'Error in Finish --> '+e.getMessage() +' At Line' + e.getLineNumber());
        }
        return syncTranId;
    }

    /**
    * @description  Creation of All API Sync items if triggered from Account Edition object.
    * @param  apiSyncWrap
    * @return  lstApiSyncItem
    */
    public static List<IMCC_API_Synchronization_Item__c> insertAPISyncItems(IMCC_ApiSyncRecordsWrapper apiSyncWrap)
    {

        List<IMCC_API_Synchronization_Item__c> lstApiSyncItem = new List<IMCC_API_Synchronization_Item__c>();
        Map<Id,Edition__c> mapEdition = new Map<Id,Edition__c>();
        //map of Validated Editions
        if(Schema.sObjectType.Edition__c.isAccessible())
        {
            mapEdition = new Map<Id,Edition__c>([SELECT Id,Edition_Status__c FROM Edition__c WHERE Id In:apiSyncWrap.editionValidations.keySet()]);
        }        
        Set<Id> sObjectIds = new Set<Id>();
        for(SObject sobj : apiSyncWrap.listSObject)
        {
            Id sobjId = Id.valueOf(String.valueOf(sobj.get('Id')));           
            sObjectIds.add(sobjId);
        }
        Set<String> setStatuses = new Set<String>{'Paused','Queued','Processing'};
        Set<String> existingItems = new Set<String>();
        
        List<IMCC_API_Synchronization_Item__c> existingAPIItems = [SELECT Id,Asset__c FROM IMCC_API_Synchronization_Item__c WHERE Asset__c IN:sObjectIds AND Status__c IN:setStatuses AND Type__c=:apiSyncWrap.itemType WITH SECURITY_ENFORCED];

        for(IMCC_API_Synchronization_Item__c item : existingAPIItems){
            if(String.isNotBlank(item.Asset__c)){existingItems.add(item.Asset__c);}
        }
        
        for(SObject sobj : apiSyncWrap.listSObject)
        {
            Id sobjId = Id.valueOf(String.valueOf(sobj.get('Id')));
            String sobjIdStartString = String.valueOf(sobjId).left(3);
            String objectName = apiSyncWrap.sobjIdSobjName.get(sobjIdStartString);
            IMCC_API_Synchronization_Item__c apiSyncItems = new IMCC_API_Synchronization_Item__c();
            apiSyncItems.API_Call_Type__c = apiSyncWrap.apiCallType;
            apiSyncItems.Type__c = apiSyncWrap.itemType;

            if(objectName == 'Asset' && !existingItems.contains(sobjId)){
                apiSyncItems.Asset__c = sobjId;
                apiSyncItems.Edition__c = (String)sobj.get('Edition__c');
                if(apiSyncWrap.mapSObjectOld.containsKey(sobjId)){
                    Asset oldData = (Asset)apiSyncWrap.mapSObjectOld.get(sobjId);
                    apiSyncItems.Old_Data__c = JSON.serialize(oldData);
                }
                apiSyncItems.Request_Body__c = JSON.serialize(sobj);
                apiSyncItems.Status__c =  String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : 'Queued';
                lstApiSyncItem.add(apiSyncItems);
            }
        }
        return lstApiSyncItem;
    }

    /**
    * @description  Insert All API Sync Records.
    * @param  lstApiSyncTran
    * @param  lstApiSyncItem
    * @param  apiSyncWrap
    * @return apiSyncTranId
    */
    public static Id insertAllRecords(List<IMCC_API_Synchronization_Transaction__c> lstApiSyncTran, List<IMCC_API_Synchronization_Item__c> lstApiSyncItem, IMCC_ApiSyncRecordsWrapper apiSyncWrap)
    {
        Id apiSyncTranId;
        if(!lstApiSyncTran.isEmpty() && !lstApiSyncItem.isEmpty())
        {
            //insertion of IMCC_API_Synchronization_Transaction__c records
            if(Schema.sObjectType.IMCC_API_Synchronization_Transaction__c.isCreateable())
            {
                insert lstApiSyncTran;
            }
            apiSyncTranId = lstApiSyncTran[0].Id; //IMCC_API_Synchronization_Transaction__c Id
            
            for(IMCC_API_Synchronization_Item__c apiSyncItm : lstApiSyncItem)
            {
                apiSyncItm.IMCC_API_Synchronization_Transaction__c = lstApiSyncTran[0].Id;
            }
            //insertion of IMCC_API_Synchronization_Item__c records
            if(Schema.sObjectType.IMCC_API_Synchronization_Item__c.isCreateable())
            {
                insert lstApiSyncItem;
            }
            //updation of IMCC_API_Synchronization_Transaction__c records
            if(Schema.sObjectType.IMCC_API_Synchronization_Transaction__c.isUpdateable())
            {
                lstApiSyncTran[0].Status__c = apiSyncWrap.transactionStatus;
                update lstApiSyncTran;
            }
        }
        return apiSyncTranId;
    }

    /**
    * @description  This method is for evaluating all condition which must be checked on edition record before inserting data in API Sync Objects ofr syncronisation with MYS.
    * @param  editionIds
    * @return  allEditionValidation
    */
    
    public static Map<Id,Boolean> fieldsValidationOnEdition(Set<Id> editionIds)
    {
        Map<Id,Boolean> allEditionValidation = new Map<Id,Boolean>();
        //list of edition
        for(Edition__c edition : [SELECT Id FROM Edition__c WHERE id IN:editionIds WITH SECURITY_ENFORCED])
        {
            allEditionValidation.put(edition.Id,true);
        }
        return allEditionValidation;
    }
}