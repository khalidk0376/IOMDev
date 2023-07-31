/**
* File         :   IOM_AmendmentRequestUtils 
* Project      :   Order & Billing Plateform [IOM-574]
* Created Date :   18th DEC 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test(91%),IOM_AmendmentRequest_Test
* ******************************************************************************************************
 @description : Utility Class for IOM Amendment Request payload creation
*******************************************************************************************************
* Modification log : 
*/
public with sharing class IOM_AmendmentRequestUtils 
{
    private static final String  INTEGRATION_MAPPING_TYPE ='Amendment Request';
    private static final String  READY ='Ready';

    /**
    * @description  This method is used for genrate Dynamic JSON Payload for Amendment Request
    * @param  lsitAmendmentReq  List of IOM_Amendment_Request__c Objs    
    */
    public static void createSynTranForAmendmentRequest(List<IOM_Amendment_Request__c> lsitAmendmentReq)
    {
        List<IOM_Synchronization_Transaction__c> synchronizationTransactions = new List<IOM_Synchronization_Transaction__c> ();
        Map<Id,string> recordPayloadMap = new Map<Id,string>();

        Set<Id> amendmentReqIds = new Set<Id>();

        for(IOM_Amendment_Request__c amdReq:lsitAmendmentReq)
        {
            amendmentReqIds.add(amdReq.Id);
        }

        recordPayloadMap = generateAmendementRequestsPayload(amendmentReqIds);

        for(IOM_Amendment_Request__c amdReq:lsitAmendmentReq)
        {
            if(recordPayloadMap.containsKey(amdReq.Id))
            {
                IOM_Synchronization_Transaction__c ompSyncTrsans = new IOM_Synchronization_Transaction__c();

                ompSyncTrsans.IOM_Request_Body__c = recordPayloadMap.get(amdReq.Id);            
                ompSyncTrsans.IOM_CRM_Opportunity__c = amdReq.IOM_Opportunity__c;
                ompSyncTrsans.IOM_Type__c           = INTEGRATION_MAPPING_TYPE;
                ompSyncTrsans.IOM_Synchronization_Status__c = READY;
                ompSyncTrsans.IOM_Processing_Status__c      = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.IOM_SYNC_STATUS);

                synchronizationTransactions.add(ompSyncTrsans);
            }
        }

        if(!synchronizationTransactions.isEmpty() && Schema.sObjectType.IOM_Synchronization_Transaction__c.isCreateable())
        {
            insert synchronizationTransactions;
        }

        List<IOM_Synchronization_Transaction__c> ompSyncTransactions = new List<IOM_Synchronization_Transaction__c>();
        Set<Id> setIOMSyncIds = new Set<Id>();
        for(IOM_Synchronization_Transaction__c ompSync :synchronizationTransactions)
        {
            setIOMSyncIds.add(ompSync.Id);
        }

        for(IOM_Synchronization_Transaction__c ompSync : [SELECT Id,Name,IOM_Processing_Status__c,IOM_Request_Body__c FROM IOM_Synchronization_Transaction__c WHERE Id in: setIOMSyncIds WITH SECURITY_ENFORCED])
        {            
            // ompSync.IOM_Processing_Status__c = 'Queued';
            if(String.isNotBlank(ompSync.IOM_Request_Body__c))
            {
                ompSync.IOM_Request_Body__c = ompSync.IOM_Request_Body__c.Replace('[#SynchronizationRequestName#]',ompSync.Name);
            }
            ompSyncTransactions.add(ompSync);
        }
        if(!ompSyncTransactions.isEmpty() && Schema.sObjectType.IOM_Synchronization_Transaction__c.isUpdateable())
        {
            update ompSyncTransactions;
        }
    }
     /**
    * @description  This method is used for genrate Dynamic JSON Payload for Amendment Request
    * @param  amendmentReqIds  IOM_Amendment_Request__c Id
    * @return  Map<Id,String> JSON payload
    */
    
    private static Map<Id,string> generateAmendementRequestsPayload(Set<Id> amendmentReqIds)
    {
        Map<string,list<IOM_Integration_Mapping__mdt>> sObjectandIntDataMap = new Map<string,list<IOM_Integration_Mapping__mdt>> ();
        Map<string,string> recordQueryMap = new Map<string,string>();
        Map<Id,string> recordPayloadMap = new Map<Id,string>();

        List<IOM_Integration_Mapping__mdt> listIM = IOM_SendForOrderUtils.getIntegrationMappingRecords(INTEGRATION_MAPPING_TYPE);
        
        for(IOM_Integration_Mapping__mdt intMap : listIM)
        {
            if(string.isNotBlank(intMap.CRM_Object_Field__c))
            {
                string queryString = recordQueryMap.containsKey(intMap.CRM_Object__r.QualifiedApiName) ? recordQueryMap.get(intMap.CRM_Object__r.QualifiedApiName):'Id';

                if(!(','+queryString+',').contains(','+intMap.CRM_Object_Field__c+','))
                {
                    queryString += ',' + intMap.CRM_Object_Field__c;
                }
                recordQueryMap.put(intMap.CRM_Object__r.QualifiedApiName,queryString);
            }

            list<IOM_Integration_Mapping__mdt> exitingIntList = sObjectandIntDataMap.containsKey(intMap.CRM_Object__r.QualifiedApiName) ? sObjectandIntDataMap.get(intMap.CRM_Object__r.QualifiedApiName): new list<IOM_Integration_Mapping__mdt>();

            exitingIntList.add(intMap);

            sObjectandIntDataMap.put(intMap.CRM_Object__r.QualifiedApiName,exitingIntList);
        }

        map<string,object> payloadMap = new map<string,object> ();
        //list<map<string,object>> cildNodes = new list<map<string,object>>();
        // map<string,object> childPayloadMap ;  

        // Map<String,String> allErrorTypeMap = New Map<String,String>();

        for(string key :recordQueryMap.keySet())
        {
            list<IOM_Integration_Mapping__mdt> listOMPInt = sObjectandIntDataMap.get(key);
            string oppFilterField = listOMPInt.get(0).Record_Id_Filter_Field__c;
            string queryStr = 'Select '+ String.escapeSingleQuotes(recordQueryMap.get(key)) +' FROM '+String.escapeSingleQuotes(key)+' WHERE '+String.escapeSingleQuotes(oppFilterField)+' in:amendmentReqIds ';

            System.debug(LoggingLevel.Debug,key+' : QUERY --> ' +queryStr);
            if(oppFilterField == 'Id')
            {
                for(IOM_Amendment_Request__c amdReq : Database.query(queryStr))
                {
                    for(IOM_Integration_Mapping__mdt intMap:listOMPInt)
                    {
                        String value = (String.isNotBlank(intMap.Static_Value__c)?intMap.Static_Value__c:'');
                        if(String.isNotBlank(intMap.CRM_Object_Field__c)){
                            // System.debug(LoggingLevel.Debug, intMap.CRM_Object_Field__c);
                            String value2 = IOM_SendForOrderUtils.getSObjectValue(amdReq, intMap.CRM_Object_Field__c);
                            value += (value2==null?'':value2);
                        }
                        //allErrorTypeMap = validateOMPNode(value, intMap, allErrorTypeMap);
                        payloadMap.put(intMap.IOM_Node_Name__c,value);
                    }
                    recordPayloadMap.put(amdReq.Id, JSON.serialize(payloadMap));
                }
            }
        }
        return recordPayloadMap;
    }

    /**
    * @description  This method is used get IOM Amendment Category Details    
    * @return  List IOM Amendment Category Details
    */
    @AuraEnabled( cacheable=true )  
    public static List < IOM_Amendment_Category_Detail__mdt > fetchIOMAmdCatDetails() 
    {        
        return [ SELECT Id, IOM_Description__c,MasterLabel,IOM_New_Label__c FROM IOM_Amendment_Category_Detail__mdt WITH SECURITY_ENFORCED];
    }
}