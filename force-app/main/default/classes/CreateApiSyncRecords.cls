/**
* File         :   CreateApiSyncRecords 
* Project      :   Order & Billing Plateform
* Created Date :   21 Sept 2021
* Created By   :   Girikon(Deepak)
* Test Class   :   SynchronousAPICallController_Test(93%),CreditNotesOrderHub_Trig_Test(80&) -(95%),CreateAPISyncItemsforAccount_Trig_Test(70-90%),APISynchronization_Test(70%),AmendmentUtils_Test(70%)
* ******************************************************************************************************
* @description : For Creating Records to API Synchronization transaction and its associated API Synchronization Items.
********************************************************************************************************
* Modification log :
    1. Girikon (Suresh) [OBP-342] 28 Sep 2021 : Create a functionality to POST the created Credit Notes into the Order Hub
    2. Girikon (Ashish) [OBP-423] 12 Oct 2021 : control Item Status as a pram 
    3. Girikon (Ashish) [IOM-521] 01 Feb 2022 : Account Credit Status Update to MuleSoft
    4. Girikon (Ashish) [IOM-775] 23 Feb 2022 : Amendment/Opportunity Data Update to MuleSoft
    5. Girikon (Ashish) [IE-10]   10 Aug 2022 : Added Logic for INV payment Tras
    6. Girikon (Ashish) [IE-150]  09 SEP 2022 : Added Logic for CN payment Tras
*/
public with sharing class CreateApiSyncRecords{
   
    /**
    * @description  map objet name and edition field name
    */
    private static Map<String,String> sobjNameEditionFieldName = new Map<String,String>{'Order' => 'Edition__c', 'blng__Invoice__c' => '', 'blng__CreditNote__c' => '','account' => ''};

    /**
    * @description  Wrapper Class For creating Api Sync Records
    */
    public class ApiSyncRecordsWrapper
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
        /**
        * @description For third Party Relation Name.
        */
        public String thirdPartyERPSystem;
        /**
        * @description For third Party Relation Name.
        */
        public String externalTaxSystem;
        /**
        * @description to include one extra item in trasnsaction for Amendment Complete Tras;
        */
        public Boolean addAmendmentCompleteApiItem = false;
    }

    /**
    * @description  Creation of All API Sync items and their transactions records.
    * @param  apiSyncWrap
    * @return  Id API Transaction
    */
    public static Id insertAllAPISyncItem(ApiSyncRecordsWrapper apiSyncWrap)
    {
        List<API_Synchronization_Transaction__c> lstApiSyncTran = new List<API_Synchronization_Transaction__c>();
        List<API_Synchronization_Item__c> lstApiSyncItem = new List<API_Synchronization_Item__c>();
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
                    String editionId = OneSourceAPIWrapper.getSObjectValue(sobj, editionFieldName);
                    editionIds.add(editionId);
                    apiSyncWrap.sobjIdEditionId.put(sobjId, editionId);
                }
            }
            apiSyncWrap.editionValidations = new Map<Id,Boolean>(fieldsValidationOnEdition(editionIds));
            if(!apiSyncWrap.listSObject.isEmpty())
            {
                lstApiSyncItem = insertAPISyncItems(apiSyncWrap);
            }
            API_Synchronization_Transaction__c apiSyncTran = new API_Synchronization_Transaction__c();            
            for(API_Synchronization_Item__c item : lstApiSyncItem){
                if((String.isNotBlank(item.Invoice__c) || String.isNotBlank(item.Credit_Note__c) || (String.isNotBlank(item.Order__c) || String.isNotBlank(item.Account__C) || String.isNotBlank(item.Opportunity__c) || String.isNotBlank(item.Amendment_Request__c) )&& GlobalConstants.QUEUED.equalsIgnoreCase(item.Status__c)))
                {
                    checkAllStatus = true;
                }                
            }
            apiSyncWrap.transactionStatus = (checkAllStatus?GlobalConstants.QUEUED:GlobalConstants.PAUSED);
            apiSyncTran.Status__c = GlobalConstants.PAUSED;

            apiSyncTran.External_Tax_System__c = apiSyncWrap.externalTaxSystem;
            apiSyncTran.X3rd_Party_ERP_System__c = apiSyncWrap.thirdPartyERPSystem;
            apiSyncTran.Started_From__c = apiSyncWrap.startedFrom;
            apiSyncTran.Type__c = apiSyncWrap.type;
            apiSyncTran.Request_Type__c = (apiSyncWrap.requestType==GlobalConstants.SYNCHRONOUS?GlobalConstants.SYNCHRONOUS:GlobalConstants.ASYNCHRONOUS);
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
    public static List<API_Synchronization_Item__c> insertAPISyncItems(ApiSyncRecordsWrapper apiSyncWrap)
    {
        final string NOTES = 'blng__Notes__c';

        List<API_Synchronization_Item__c> lstApiSyncItem = new List<API_Synchronization_Item__c>();
        Map<Id,Edition__c> mapEdition = new Map<Id,Edition__c>();
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
        Set<String> setStatuses = new Set<String>{GlobalConstants.PAUSED,GlobalConstants.QUEUED,GlobalConstants.PROCESSING};
        Set<String> existingItems = new Set<String>();
        
        List<API_Synchronization_Item__c> existingAPIItems = [SELECT Id,Invoice__c,Order__c,Credit_Note__c,Account__c,Opportunity__c,Amendment_Request__c FROM API_Synchronization_Item__c WHERE (Invoice__c IN:sObjectIds OR Order__c IN:sObjectIds OR Credit_Note__c IN:sObjectIds OR Account__c IN:sObjectIds OR Amendment_Request__c IN:sObjectIds OR Opportunity__c IN:sObjectIds) AND Status__c IN:setStatuses AND Type__c=:apiSyncWrap.itemType WITH SECURITY_ENFORCED];
        for(API_Synchronization_Item__c item : existingAPIItems){
            if(String.isNotBlank(item.Invoice__c)){existingItems.add(item.Invoice__c);}
            if(String.isNotBlank(item.Order__c)){existingItems.add(item.Order__c);}
            if(String.isNotBlank(item.Credit_Note__c)){existingItems.add(item.Credit_Note__c);}
            if(String.isNotBlank(item.Account__c)){existingItems.add(item.Account__c);}
            if(String.isNotBlank(item.Opportunity__c)){existingItems.add(item.Opportunity__c);}
            if(String.isNotBlank(item.Amendment_Request__c)){existingItems.add(item.Amendment_Request__c);}
        }
        
        for(SObject sobj : apiSyncWrap.listSObject)
        {
            Id sobjId = Id.valueOf(String.valueOf(sobj.get('Id')));
            String sobjIdStartString = String.valueOf(sobjId).left(3);
            String objectName = apiSyncWrap.sobjIdSobjName.get(sobjIdStartString);
            API_Synchronization_Item__c apiSyncItems = new API_Synchronization_Item__c();
            apiSyncItems.External_Tax_System__c = apiSyncWrap.externalTaxSystem;
            apiSyncItems.X3rd_Party_ERP_System__c = apiSyncWrap.thirdPartyERPSystem;
            apiSyncItems.API_Call_Type__c = apiSyncWrap.apiCallType;
            apiSyncItems.Type__c = apiSyncWrap.itemType;

            if(objectName == 'blng__Invoice__c' && !existingItems.contains(sobjId)){
                apiSyncItems.Invoice__c = sobjId;
                apiSyncItems.Status__c =  String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : GlobalConstants.QUEUED;
                lstApiSyncItem.add(apiSyncItems);
                // Add Logic to create API Syc Items for Payment Transactions [IE-10]
                if(sobj.isSet(NOTES) && (string)sobj.get(NOTES) == GlobalConstants.POST_PAYMENT_TRANSACTIONS)
                {
                    API_Synchronization_Item__c apiSyncItem2 = new API_Synchronization_Item__c();
                    apiSyncItem2 =  (API_Synchronization_Item__c)JSON.deserialize(JSON.serialize(apiSyncItems), Sobject.class);
                    apiSyncItem2.Type__c = GlobalConstants.POST_PAYMENT_TRANSACTIONS;
                    lstApiSyncItem.add(apiSyncItem2);
                }
            }

            if(objectName == 'Order' && !checkEditionStatus(apiSyncWrap.sobjIdEditionId.get(sobjId),mapEdition) && !existingItems.contains(sobjId)){
                apiSyncItems.Order__c = sobjId;
                apiSyncItems.Edition__c = apiSyncWrap.sobjIdEditionId.get(sobjId);
                apiSyncItems.Status__c = (apiSyncWrap.editionValidations.get(apiSyncWrap.sobjIdEditionId.get(sobjId))?GlobalConstants.QUEUED:GlobalConstants.PAUSED);
                lstApiSyncItem.add(apiSyncItems);
            }

            //This is for CreditNotes OBP-342
            if(objectName == 'blng__CreditNote__c' && !existingItems.contains(sobjId)){
                apiSyncItems.Credit_Note__c = sobjId;
                apiSyncItems.Status__c = String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : GlobalConstants.QUEUED;
                lstApiSyncItem.add(apiSyncItems);
                // Add Logic to create API Syc Items for Payment Transactions [IE-150]
                if(sobj.isSet(NOTES) && (string)sobj.get(NOTES) == GlobalConstants.POST_PAYMENT_TRANSACTIONS)
                {
                    API_Synchronization_Item__c apiSyncItem2 = new API_Synchronization_Item__c();
                    apiSyncItem2 =  (API_Synchronization_Item__c)JSON.deserialize(JSON.serialize(apiSyncItems), Sobject.class);
                    apiSyncItem2.Type__c = GlobalConstants.POST_PAYMENT_TRANSACTIONS;
                    lstApiSyncItem.add(apiSyncItem2);
                }
            }

            //This is for Account IOM-521
            if(objectName == 'Account' && !existingItems.contains(sobjId)){
                apiSyncItems.Account__c = sobjId;
                apiSyncItems.Status__c = String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : GlobalConstants.QUEUED;
                lstApiSyncItem.add(apiSyncItems);
            }
            // Amendment Request  Approved/Rejected [IOM-775]
            if(objectName == 'Change_Request__c' && !existingItems.contains(sobjId)){
                apiSyncItems.Amendment_Request__c = sobjId;
                apiSyncItems.Type__c = sobj.isSet('Comments__c')? (String)sobj.get('Comments__c'):apiSyncWrap.itemType;
                apiSyncItems.Status__c = String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : GlobalConstants.QUEUED;
                lstApiSyncItem.add(apiSyncItems);
                // Add Amendment Completed Item [IOM-572]
                if(apiSyncWrap.addAmendmentCompleteApiItem){
                    API_Synchronization_Item__c apiSyncItem2 = new API_Synchronization_Item__c();
                    apiSyncItem2 =  (API_Synchronization_Item__c)JSON.deserialize(JSON.serialize(apiSyncItems), Sobject.class);
                    apiSyncItem2.Type__c = GlobalConstants.CHANGE_REQUEST_COMPLETED;
                    lstApiSyncItem.add(apiSyncItem2);
                }
            }
            // For Opportunity  [IOM-775]
            if(objectName == 'Opportunity' && !existingItems.contains(sobjId)){
                apiSyncItems.Opportunity__c = sobjId;
                apiSyncItems.Status__c = String.isNotBlank(apiSyncWrap.itemStatus) ? apiSyncWrap.itemStatus : GlobalConstants.QUEUED;
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
    public static Id insertAllRecords(List<API_Synchronization_Transaction__c> lstApiSyncTran, List<API_Synchronization_Item__c> lstApiSyncItem, ApiSyncRecordsWrapper apiSyncWrap)
    {
        Id apiSyncTranId;
        if(!lstApiSyncTran.isEmpty() && !lstApiSyncItem.isEmpty())
        {
            if(Schema.sObjectType.API_Synchronization_Transaction__c.isCreateable())
            {
                insert lstApiSyncTran;
            }
            apiSyncTranId = lstApiSyncTran[0].Id;
            
            for(API_Synchronization_Item__c apiSyncItm : lstApiSyncItem)
            {
                apiSyncItm.API_Synchronization_Transaction__c = lstApiSyncTran[0].Id;
            }

            if(Schema.sObjectType.API_Synchronization_Item__c.isCreateable())
            {
                insert lstApiSyncItem;
            }

            if(Schema.sObjectType.API_Synchronization_Transaction__c.isUpdateable())
            {
                lstApiSyncTran[0].Status__c = apiSyncWrap.transactionStatus;
                update lstApiSyncTran;
            }
        }
        return apiSyncTranId;
    }

    /**
    * @description  Check if edition completed or cancelled.
    * @param  editionId
    * @param  mapEdition
    * @return boolean edition status
    */
    public static boolean checkEditionStatus(Id editionId, Map<Id,Edition__c> mapEdition)
    {
        Edition__c ed = mapEdition.get(editionId);
        String labelVal = ',Completed,Cancelled,Cancelled by Finance,';
        String editionStatus = ((ed.Edition_Status__c == null || ed.Edition_Status__c == '')?'':(','+ed.Edition_Status__c+','));
        return (editionStatus==''?false:labelVal.contains(editionStatus));
    }

    /**
    * @description  This method is for evaluating all condition which must be checked on edition record before inserting data in API Sync Objects ofr syncronisation with MYS.
    * @param  editionIds
    * @return  allEditionValidation
    */
    
    public static Map<Id,Boolean> fieldsValidationOnEdition(Set<Id> editionIds)
    {
        Map<Id,Boolean> allEditionValidation = new Map<Id,Boolean>();
        for(Edition__c edition : [SELECT Id,External_Relationship__c,External_Status__c,External_Tax_System__c FROM Edition__c WHERE id IN:editionIds WITH SECURITY_ENFORCED])
        {
            allEditionValidation.put(edition.Id,false);
            if(edition.External_Tax_System__c == GlobalConstants.ONESOURCE && edition.External_Relationship__c == true && edition.External_Status__c == GlobalConstants.ACTIVE)
            {
                allEditionValidation.put(edition.Id,true);
            }
        }
        return allEditionValidation;
    }
}