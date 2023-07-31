/**
* File         :   IOM_SendForOrderUtils 
* Project      :   Order & Billing Plateform
* Created Date :   08th Nov 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test(91%)
* **************************************************************************************************
@description : Utility Class for IOM Order payload creation
**************************************************************************************************
* Modification log : 
* 1. 13th Nov 2021 - Girikon(Suresh) [IOM-524]  - Updated code for Mulesoft Callout
* 2. 16th Nov 2021 - Girikon(Ashish) [IOM-515]  - Updated code for Mulesoft Callout Status
* 3. 2nd June 2022 - Girikon(Ansh)   [IOM-1642] - Added method validateOliDate
* 4. 21st Nov 2022 - Girikon(Ashish) [GECI-57]  - Added Interface for payload Override
* 5. 20th Jab 2023 - Girikon(Ansh) [GECI-577] - Modify Postal Code validation
*/
public with sharing class IOM_SendForOrderUtils 
{    
    @TestVisible private static String testIntegrationMappingRecords ='';
    
    private static final String  INTEGRATION_MAPPING_TYPE ='Opportunity Sync';
    private static final String  OPPORTUNITY_PRODUCTS_ERROR_MESSAGE ='Opportunity Product End Date can not be smaller than Start Date';
    private static final String POSTAL_CODE_ERROR_MESSAGE = 'BillingPostalCode missing';
    private static final String OVERRIDE_CLASS_NAME = 'IOM_SendForOrder_Override';
    public static String countryCode = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.COUNTRIESWITHOUTPOSTALCODE);
    public static string countryAndpostalcode = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.COUNTRIESWITHPOSTALCODE);
    public static string requiredpostalcode = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.REQUIREDPOSTALCODE);
    
    /**
    * @description  This method is used for genrate Dynamic Query to process in batch 
    * @param  opportunitiesIds  Opportunities Ids
    * @return  String APISyncItemsQuery
    */
    Public Static String getQuery(Set<Id> opportunitiesIds)
    {
        String filterStageName = IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.OPPORTUNITY_FILTER_STAGE);
        
        string query = 'SELECT Id,Name FROM Opportunity WHERE StageName = \''+filterStageName+'\' AND Id IN: opportunitiesIds';
        return query;
    }
    
/**
* @description  This method is used for genrate Dynamic Payload for IOM
* @param  opportunityId  Opportunity Id
* @return String IOM_Synchronization_Transaction__c Record Id
*/
    Public Static String createIOMOrderpayload(Id opportunityId)
    {
       string className = IOM_GlobalConstantsData.getValue(OVERRIDE_CLASS_NAME);
       IOM_Interfaces.SendForOrderoverride overrideOBJ;
        // Set orverride Object Instance
        if(String.isNotBlank(className)){
            overrideOBJ = (IOM_Interfaces.SendForOrderoverride)Type.forName(className).newInstance();
        }      

        Map<string,list<IOM_Integration_Mapping__mdt>> sObjectandIntDataMap = new Map<string,list<IOM_Integration_Mapping__mdt>> ();
        
        Map<string,string> opportunityQueryMap = new Map<string,string>();

        Map<string,string> payloadObjectNodeGroupMap = new Map<string,string>();
        
        List<IOM_Integration_Mapping__mdt> listIM = getIntegrationMappingRecords(INTEGRATION_MAPPING_TYPE);

        Set<string> setRecordFilterValueFields = new Set<string>();
        
        for(IOM_Integration_Mapping__mdt intMap : listIM)
        {
            string recordFilterObjectField = String.isNotBlank(intMap.Record_Id_Filter_Field__c)?intMap.Record_Id_Filter_Field__c:'Id';

            String recordFilterValueField =String.isNotBlank(intMap.Filter_Field_Value__c)?intMap.Filter_Field_Value__c:'Id';

            string key =  intMap.CRM_Object__r.QualifiedApiName+'-'+recordFilterObjectField+'-'+recordFilterValueField;

            if(string.isNotBlank(intMap.CRM_Object_Field__c))
            {
                string queryString = opportunityQueryMap.containsKey(key) ? opportunityQueryMap.get(key):'Id';
                
                if(!(','+queryString+',').containsIgnoreCase(','+intMap.CRM_Object_Field__c+','))
                {
                    queryString += ',' + intMap.CRM_Object_Field__c;
                }
                opportunityQueryMap.put(key,queryString);
            }
            
            list<IOM_Integration_Mapping__mdt> exitingIntList = sObjectandIntDataMap.containsKey(key) ? sObjectandIntDataMap.get(key): new list<IOM_Integration_Mapping__mdt>();
            
            exitingIntList.add(intMap);
            
            sObjectandIntDataMap.put(key,exitingIntList);

            payloadObjectNodeGroupMap.put(key,intMap.CRM_Object__r.QualifiedApiName.removeEnd('__c')); //Override if Req
            setRecordFilterValueFields.add(recordFilterValueField);
        }

        // new overRide Node
        string tansKey = 'Account_Translated_FieldSet__c-Account__c-AccountId';
        if(payloadObjectNodeGroupMap.containsKey(tansKey))
        {
            payloadObjectNodeGroupMap.put(tansKey,'Translations');
        }
        if(overrideOBJ != null)  // get value from Interface
        {
            payloadObjectNodeGroupMap = overrideOBJ.overrideGroupNodeLabel(payloadObjectNodeGroupMap);
        }
        
        map<string,object> payloadMap = new map<string,object> ();
        list<map<string,object>> cildNodes = new list<map<string,object>>();
        // set Default Nodes
        payloadMap.put('OpportunityContactRole',cildNodes);
        map<string,object> childPayloadMap ;
        
        List<String> listcountryAndpostalcode = countryAndpostalcode.split(',');
        
        List<String> listpostalcode = new List<String>();
        
        for(String e : listcountryAndpostalcode){
            listpostalcode.add(e.substringAfter('#'));
        }
        Map<String,String> allErrorTypeMap = New Map<String,String>();
        

        // --------- For Opportunity -----
        string oppKey = 'Opportunity-Id-Id';

        string oppQueryFields = opportunityQueryMap.get(oppKey);
        for(string filterField : setRecordFilterValueFields)
        {
            if(!(','+oppQueryFields+',').containsIgnoreCase(','+filterField+','))
            {
                oppQueryFields += ',' + filterField;
            }
        }

        list<IOM_Integration_Mapping__mdt> listIOMIntOpp = sObjectandIntDataMap.get(oppKey);        
        string oppQueryStr = 'Select '+ String.escapeSingleQuotes(oppQueryFields) +' FROM Opportunity WHERE Id =:opportunityId ';
        
        System.debug(LoggingLevel.Debug,oppKey+' : QUERY --> ' +oppQueryStr);

        Opportunity opp = (Opportunity) Database.query(oppQueryStr);
        for(IOM_Integration_Mapping__mdt intMap:listIOMIntOpp)
        {
            String value = (String.isNotBlank(intMap.Static_Value__c)?intMap.Static_Value__c:'');
            if(String.isNotBlank(intMap.CRM_Object_Field__c)){
                // System.debug(LoggingLevel.Debug, intMap.CRM_Object_Field__c);
                String value2 = getSObjectValue(opp, intMap.CRM_Object_Field__c);
                value += (value2==null?'':value2);
            }
            payloadMap.put(intMap.IOM_Node_Name__c,value);
            for(String postalcode : listpostalcode){
                if(!payloadMap.containsKey(postalcode)){
                    allErrorTypeMap = validateIOMNode(value, intMap, allErrorTypeMap);
                }
            }
        }
        allErrorTypeMap = validatePostalCode(allErrorTypeMap,payloadMap,listIOMIntOpp);


        // --------- Child Records -------
        for(string key :opportunityQueryMap.keySet())
        {
            List<string> keyPrams =key.split('\\-');
            if(keyPrams.get(0) != 'Opportunity')
            { // CHILD RECORDS    [Opportunity Products / Opportunity Contact Roles] 
                
                list<IOM_Integration_Mapping__mdt> listIOMInt = sObjectandIntDataMap.get(key);            
                string queryStr = 'Select '+ String.escapeSingleQuotes(opportunityQueryMap.get(key)) +' FROM '+String.escapeSingleQuotes(keyPrams.get(0))+' WHERE '+String.escapeSingleQuotes(keyPrams.get(1))+' = \''+ getSObjectValue(opp,keyPrams.get(2)) +'\'';
                
                System.debug(LoggingLevel.Debug,key+' : QUERY --> ' +queryStr);
                cildNodes = new list<map<string,object>>();
                /**--P1 Violation --- To set data for all child records of Opportunity dynamically we need  this Soql in for loop , but the avrage number of quries will around 2-5 according to no of child objects used in CRM for IOM payload  
                **/
                for(sobject oppChild: Database.query(queryStr))
                {
                    childPayloadMap = new map<string,object> ();
                    for(IOM_Integration_Mapping__mdt intMap:listIOMInt)
                    {
                        String value = (String.isNotBlank(intMap.Static_Value__c)?intMap.Static_Value__c:'');
                        if(String.isNotBlank(intMap.CRM_Object_Field__c)){
                            String value2 = getSObjectValue(oppChild, intMap.CRM_Object_Field__c);
                            value += (value2==null?'':value2);
                        }
                        
                        childPayloadMap.put(intMap.IOM_Node_Name__c,value);
                        for(String postalcode : listpostalcode){
                            if(!childPayloadMap.containsKey(postalcode)){
                                allErrorTypeMap = validateIOMNode(value, intMap, allErrorTypeMap);
                            }
                        }
                    }
                    if(keyPrams.get(0) == 'OpportunityLineItem'){
                        allErrorTypeMap = validateOliDate(allErrorTypeMap,childPayloadMap);
                    }
                    cildNodes.add(childPayloadMap);
                    allErrorTypeMap = validatePostalCode(allErrorTypeMap,payloadMap,listIOMInt);
                }
                payloadMap.put(payloadObjectNodeGroupMap.get(key),cildNodes);
            }
        }
        
        if(overrideOBJ != null){  // get value from Interface
            payloadMap = overrideOBJ.overridePayloadJSON(opportunityId,payloadMap);
        }
        // Update Opportunity & IOM Synchronization Transaction
        String iomSyncTrnsId = createIOMSynchronizationData(opportunityId,JSON.serialize(payloadMap),allErrorTypeMap);
        
        System.debug(LoggingLevel.Debug,iomSyncTrnsId +' --> : PAYLOAD -' + JSON.serializePretty(payloadMap));
        return iomSyncTrnsId;
    }
    
    /**
* @description   This method is used to get sboject field value
* @param  obj SObject
* @param  fieldName field name
* @return  SObject field value
*/
    public static string getSObjectValue(SObject obj, String fieldName)
    {
        String value;
        List<String> fieldSplit = fieldName.split('\\.');
        if(1 == fieldSplit.size()){
            if(obj != null && obj.get(fieldSplit[0]) != null){value = String.valueOf(obj.get(fieldSplit[0]));}
        }
        else{
            String firstNodeName = fieldSplit.remove(0);
            String nodeName = String.join(fieldSplit,'.');
            if(obj != null && obj.getSObject(firstNodeName) != null){ value = getSObjectValue(obj.getSObject(firstNodeName),nodeName); }
        }
        return value;
    }
    
    /**
    * @description   This method is used create SynchronizationData Record & Update Status on Opp
    * @param  oppId Opportunity Id
    * @param  payload JSON payload
    * @param  allErrorTypeMap Error Map
    * @return String IOM_Synchronization_Transaction__c Record Id
    */
    private static string createIOMSynchronizationData(Id oppId,String payload,Map<String,String> allErrorTypeMap)
    {
        Boolean isValidPayload = true;
        String finalErrorMessage = IOM_GlobalConstantsData.BLANK_STRING;
        
        System.debug(LoggingLevel.Debug, 'ERROR MAP -'+JSON.serializePretty(allErrorTypeMap));
        
        if(allErrorTypeMap.containsKey(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR)
           && String.isNotBlank(allErrorTypeMap.get(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR)))
        {
            isValidPayload = false;
            finalErrorMessage += 'Missing Required Fields '+allErrorTypeMap.get(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR);
        }
        
        if(allErrorTypeMap.containsKey(IOM_GlobalConstantsData.DATA_TYPE_ERROR)
           && String.isNotBlank(allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_TYPE_ERROR)))
        {
            isValidPayload = false;    
            finalErrorMessage += (String.isNotBlank(finalErrorMessage)?',':'')+'Incorrect Data Types on Fields '+allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_TYPE_ERROR);
        }
        
        if(allErrorTypeMap.containsKey(IOM_GlobalConstantsData.DATA_LEN_ERROR)
           && String.isNotBlank(allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_LEN_ERROR)))
        {
            isValidPayload = false;
            finalErrorMessage += (String.isNotBlank(finalErrorMessage)?',':'')+' Maximum Allowed Data Length Exceded On Fields '+allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_LEN_ERROR);
        }
        //IOM-1642
        if(allErrorTypeMap.containsKey(IOM_GlobalConstantsData.CUSTOM_ERROR)
           && String.isNotBlank(allErrorTypeMap.get(IOM_GlobalConstantsData.CUSTOM_ERROR))){
               isValidPayload = false;
               finalErrorMessage += (String.isNotBlank(finalErrorMessage)?',':'')+allErrorTypeMap.get(IOM_GlobalConstantsData.CUSTOM_ERROR);  // Check Message              
           }
        
        Opportunity opp = new Opportunity(Id=oppId);
        opp.IOM_Validation_Error_Message__c  = finalErrorMessage;
        opp.IOM_Validation_Status__c = IOM_GlobalConstantsData.ERROR;
        opp.IOM_Ready_For_Ordering__c = null;
        opp.IOM_Sync_Status__c = null;
        
        IOM_Synchronization_Transaction__c iomSyncTrsans = new IOM_Synchronization_Transaction__c();
        if(isValidPayload)
        {
            opp.IOM_Sync_Status__c = 'Ready';
            opp.IOM_Validation_Status__c = IOM_GlobalConstantsData.SUCCESS;
            opp.IOM_Validation_Error_Message__c  = 'N/A';
            
            iomSyncTrsans.IOM_Request_Body__c = payload;            
            iomSyncTrsans.IOM_CRM_Opportunity__c = oppId;
            iomSyncTrsans.IOM_Synchronization_Status__c = 'Ready';
            iomSyncTrsans.IOM_Processing_Status__c      = 'Paused';
            iomSyncTrsans.IOM_Type__c       = INTEGRATION_MAPPING_TYPE;
            
            if(Schema.sObjectType.IOM_Synchronization_Transaction__c.isCreateable())
            {
                insert iomSyncTrsans;
            }
        }
        
        if(Schema.sObjectType.Opportunity.isUpdateable())
        {
            update opp;
        }
        return iomSyncTrsans.Id;
    }
    
/**
* @description   This method is used validate data before paylaod & create Error Map
* @param  allErrorTypeMap Error Map
* @param  payloadMap object data
* @param  listIOMInt list<IOM_Integration_Mapping__mdt>
* @return  Map<String,String>  Error Map
*/
    private static Map<String,String> validatePostalCode(Map<String,String> allErrorTypeMap,map<string,object> payloadMap,list<IOM_Integration_Mapping__mdt> listIOMInt){
        Map<String,String> postalcodeAndcountrycode = new Map<String,String>();
        List<String> listcountryAndpostalcode = countryAndpostalcode.split(',');
        
        for(String e : listcountryAndpostalcode){
            postalcodeAndcountrycode.put(e.substringAfter('#'),e.substringBefore('#'));
        }
        List<String> listcountryCode = requiredpostalcode.split(',');
        for(IOM_Integration_Mapping__mdt intmap : listIOMInt){
            if(intMap.Required__c == true && !payloadMap.isEmpty()){
                for(String postalcode : postalcodeAndcountrycode.keySet()){
                    if(listcountryCode.contains((String)payloadMap.get(postalcodeAndcountrycode.get(postalcode))) && payloadMap.containsKey(postalcode) && String.isBlank((String)payloadMap.get(postalcode))){
                        //string errorField = intMap.CRM_Object__r.QualifiedApiName+'.'+intMap.CRM_Object_Field__c;
                        string errorField = POSTAL_CODE_ERROR_MESSAGE;
                        
                        string finalErrorString = allErrorTypeMap.containsKey(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR) ? allErrorTypeMap.get(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR) :errorField;
                        
                        if(!(','+finalErrorString+',').contains(','+errorField+','))
                        {
                            finalErrorString += ','+errorField;
                        }
                        
                        allErrorTypeMap.put(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR, finalErrorString);
                    }
                }
            }
        }
        
        return allErrorTypeMap;
    }
    
    /**
    * @description   This method is used validate data before paylaod & create Error Map
    * @param  allErrorTypeMap Error Map
    * @param  childPayloadMap Child object data
    * @return  Map<String,String>  Error Map
    */
    private static Map<String,String> validateOliDate(Map<String,String> allErrorTypeMap,map<string,object> childPayloadMap){
        
        if(!childPayloadMap.isEmpty() && childPayloadMap.containsKey('StartDate') && childPayloadMap.containsKey('EndDate')
           && !String.isBlank((String)childPayloadMap.get('StartDate')) && !String.isBlank((String)childPayloadMap.get('EndDate')))
        {
            string startdate = (String)childPayloadMap.get('StartDate');
            string enddate = (String)childPayloadMap.get('EndDate');
            if(date.valueOf(startdate) > date.valueOf(enddate)){
                string errorStr = OPPORTUNITY_PRODUCTS_ERROR_MESSAGE;
                string fianlErrorString = allErrorTypeMap.containsKey(IOM_GlobalConstantsData.CUSTOM_ERROR) ? allErrorTypeMap.get(IOM_GlobalConstantsData.CUSTOM_ERROR) :errorStr;
                
                if(!(','+fianlErrorString+',').contains(','+errorStr+','))
                {
                    fianlErrorString += ','+errorStr;
                }
                
                allErrorTypeMap.put(IOM_GlobalConstantsData.CUSTOM_ERROR, fianlErrorString);
            }
        }
        return allErrorTypeMap;
    }
    
    /**
    * @description   This method is used validate data before paylaod & create Error Map
    * @param  value Opportunity Id
    * @param  intMap Metadata Record for integration details 
    * @param  allErrorTypeMap Error Map
    * @return  Map<String,String>  Error Map
    */
    
    private static Map<String,String> validateIOMNode(string value,IOM_Integration_Mapping__mdt intMap,Map<String,String> allErrorTypeMap)
    {
        Map<String,String> datatypeandregex = getRegExMap();
        
        // Check Required Data
        if(intMap.Required__c && String.isBlank(value))
        {
            string errorField = intMap.CRM_Object__r.QualifiedApiName+'.'+intMap.CRM_Object_Field__c;
            
            string fianlErrorString = allErrorTypeMap.containsKey(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR) ? allErrorTypeMap.get(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR) :errorField;
            
            if(!(','+fianlErrorString+',').contains(','+errorField+','))
            {
                fianlErrorString += ','+errorField;
            }
            
            allErrorTypeMap.put(IOM_GlobalConstantsData.REQUIRED_DATA_ERROR, fianlErrorString);
            System.debug(LoggingLevel.Debug,intMap.IOM_Node_Name__c+' : '+allErrorTypeMap);
            return allErrorTypeMap;
        }
        
        // validate Data type & Data Lengeth
        if(String.isNotBlank(value) && String.isNotBlank(intMap.CRM_Object_Field__c))
        {
            //System.debug(LoggingLevel.Debug,'Len Validate For -' + intMap.IOM_Node_Name__c +' :VAL -> '+value); 
            
            string errorField = intMap.CRM_Object__r.QualifiedApiName+'.'+intMap.CRM_Object_Field__c;
            // Check Data Type
            if(String.isNotBlank(intMap.IOM_Node_Type__c) 
               && datatypeandregex.containskey(intMap.IOM_Node_Type__c))
            {                    
                Pattern doublePattern = Pattern.compile(datatypeandregex.get(intMap.IOM_Node_Type__c));
                Matcher regxMatcher = doublePattern.matcher(value);
                if(!regxMatcher.matches())
                {                
                    string fianlErrorString = allErrorTypeMap.containsKey(IOM_GlobalConstantsData.DATA_TYPE_ERROR) ? allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_TYPE_ERROR) :errorField;
                    
                    if(!(','+fianlErrorString+',').contains(','+errorField+','))
                    {
                        fianlErrorString += ','+errorField;
                    }
                    //System.debug(LoggingLevel.Debug,'Adding val Type ER -' + intMap.IOM_Node_Name__c +' :VAL -> '+value + ' #ER :'+fianlErrorString); 
                    allErrorTypeMap.put(IOM_GlobalConstantsData.DATA_TYPE_ERROR , fianlErrorString);
                }
            }
            // Check Data Lengeth
            if(intMap.IOM_Node_Data_Length__c != null 
               && value.length() > intMap.IOM_Node_Data_Length__c)
            {
                string fianlErrorString = allErrorTypeMap.containsKey(IOM_GlobalConstantsData.DATA_LEN_ERROR) ? allErrorTypeMap.get(IOM_GlobalConstantsData.DATA_LEN_ERROR) :errorField;
                
                if(!(','+fianlErrorString+',').contains(','+errorField+','))
                {
                    fianlErrorString += ','+errorField;
                }
                
                allErrorTypeMap.put(IOM_GlobalConstantsData.DATA_LEN_ERROR, fianlErrorString);
            }
        }
        return allErrorTypeMap;
    }
    
    /**
    * @description   This method is used get Regular Expression map from Custom Meta data    
    * @return  Map<String,String>  map of Data types & Regular Expression for it 
    */
    private static Map<String,String> getRegExMap()
    {
        Map<String,String> dataTypeRegExMap =  new Map<String,String>();
        for(IOM_Global_Configuration_Data__mdt glData :[SELECT MasterLabel,IOM_Value__c FROM  IOM_Global_Configuration_Data__mdt WHERE Active__c = TRUE AND MasterLabel LIKE 'RegEx-%' WITH SECURITY_ENFORCED])
        {
            dataTypeRegExMap.put(glData.MasterLabel.substringAfter('RegEx-'),glData.IOM_Value__c);
        }
        return dataTypeRegExMap;
    }
    /**
    * @description   This method is used to get list of IOM_Integration_Mapping__mdt
    * @param  type  IOM_Integration_Mapping__mdt type
    * @return  List<IOM_Integration_Mapping__mdt>
    */
    public static  List<IOM_Integration_Mapping__mdt> getIntegrationMappingRecords(String type)
    {
        List<IOM_Integration_Mapping__mdt> listIM = new List<IOM_Integration_Mapping__mdt>();
        listIM = [SELECT Id,CRM_Object__c,CRM_Object__r.QualifiedApiName,CRM_Object__r.MasterLabel,CRM_Object_Field__c,IOM_Node_Data_Length__c,IOM_Node_Name__c,IOM_Node_Type__c,Required__c,Static_Value__c,Record_Id_Filter_Field__c,Filter_Field_Value__c FROM IOM_Integration_Mapping__mdt WHERE Active__c = TRUE AND Type__c=:type WITH SECURITY_ENFORCED];
        if(Test.isRunningTest())
        {
            listIM = String.isNotBlank(testIntegrationMappingRecords)? (List<IOM_Integration_Mapping__mdt>) JSON.deserialize(testIntegrationMappingRecords,List<IOM_Integration_Mapping__mdt>.class) : new List<IOM_Integration_Mapping__mdt>() ;
        }
        return listIM;
    }
    
    /**
* @description   This method is used to call HttpCallout method  
* @param  iomSyncobj IOM_Synchronization_Transaction__c Record 
* @return  string to check the result of the callout 
*/
    public static string sendpayloaddata(IOM_Synchronization_Transaction__c iomSyncobj){
        
        IOM_Synchronization_Transaction__c iom = new IOM_Synchronization_Transaction__c(id = iomSyncobj.Id);
        
        String calloutStatus = IOM_GlobalConstantsData.PROCESSING;
        
        string endpointSufix = IOM_GlobalConstantsData.getValue('IOM_'+iomSyncobj.IOM_Type__c.replaceAll('(\\s+)','_')+'_Endpoint');
        HttpResponse res = callMulesoftEndpoint(endpointSufix,'POST',iomSyncobj.IOM_Request_Body__c);
        
        //     If valid Response 
        if(res.getStatusCode() == 200 && String.isNotBlank(res.getBody()))
        {
            calloutStatus = IOM_GlobalConstantsData.SUCCESS;
            iom.IOM_Processing_Status__c = 'Completed';
            iom.IOM_Synchronization_Status__c = 'Complete';
        }else{
            calloutStatus = IOM_GlobalConstantsData.ERROR; 
            iom.IOM_Processing_Status__c = IOM_GlobalConstantsData.ERROR;            
        }
        iom.IOM_Response_Body__c = res.getBody();
        iom.IOM_Response_Code__c = res.getStatusCode();        
        if(Schema.sObjectType.IOM_Synchronization_Transaction__c.isUpdateable())
        {
            update iom;
        }        
        return calloutStatus;        
    }
    
    /**
* @description   This method is used to hit mulesoft endpoint and pass JSON data   
* @param  endpoint HTTP endpoint
* @param  method HTTP Methord [PUT/POST]
* @param  jsonBody Payload JSON
* @return  string to check the result of the callout 
*/
    private static HttpResponse callMulesoftEndpoint(String endPointURL,string method,String jsonBody){
        
        string headers = IOM_GlobalConstantsData.getValue('IOM_MuleSoft_Headers');
        HttpRequest request = new HttpRequest();
        System.debug(LoggingLevel.DEBUG,'endPointURL -> '+endPointURL);
        request.setEndpoint('callout:IOM_Mulesoft'+endPointURL);
        request.setTimeout(60000);
        request.setHeader('Content-Type', 'application/json');
        request.setMethod(method);
        List<String> listheaders = (String.isNotBlank(headers)?headers.split(','):new List<String>());
        for(String header : listheaders){
            request.setHeader(header.split('=').get(0), header.split('=').get(1));
        }
        if(method == 'PUT' || method == 'POST')
        {
            jsonBody = (String.isBlank(jsonBody)?'':jsonBody);
            request.setBody(jsonBody);
        }
        Http http = new Http();
        HttpResponse response = http.send(request);
        System.debug(LoggingLevel.DEBUG,'HttpResponse Code -> '+response.getStatusCode()+' : ' +response.getStatus());
        System.debug(LoggingLevel.DEBUG,'HttpResponse Reponse -> '+response.getBody());
        return response;
    }
    
    /**
* @description  This method is used for genrate Dynamic Query to process in batch 
* @param  synchronizationTransIds  Api synchronization Trans Ids
* @return  String APISyncItemsQuery
*/
    Public Static String getAPISyncItemsQueryAndStartProcessing(set<Id> synchronizationTransIds)
    {
        
        // Creating Query for IOM_Synchronization_Transaction to process in batch
        String fields = 'ID,Name,IOM_CRM_Opportunity__c,CurrencyIsoCode,IOM_Processing_Error_Message__c,';
        
        fields += 'IOM_Response_Body__c,IOM_Response_Code__c,IOM_Synchronization_Error_Message__c,IOM_Synchronization_Status__c,IOM_Type__c,';
        
        fields += 'IOM_Processing_Status__c,IOM_Request_Body__c ';
        
        String condition = ' where Id IN: synchronizationTransIds AND IOM_Processing_Status__c In (\'Queued\',\'Requeue\')'; 
        
        
        String query = 'Select Id from IOM_Synchronization_Transaction__c '+condition;
        
        System.debug(logginglevel.DEBUG,' IOM_Synchronization_Transaction__c query :' + query );
        
        map<Id,IOM_Synchronization_Transaction__c> mapAPITrs = New map<Id,IOM_Synchronization_Transaction__c>();        
        
        for(IOM_Synchronization_Transaction__c item :database.query(query))
        {
            mapAPITrs.put(item.Id,New IOM_Synchronization_Transaction__c (Id=item.Id,IOM_Processing_Status__c = IOM_GlobalConstantsData.PROCESSING));
        }
        
        if(!mapAPITrs.isEmpty() && Schema.sObjectType.IOM_Synchronization_Transaction__c.isUpdateable())
        {
            update mapAPITrs.values();
        }
        
        condition = ' where Id IN: synchronizationTransIds AND IOM_Processing_Status__c In (\'Processing\')';
        query = 'Select '+fields+' from IOM_Synchronization_Transaction__c '+condition;
        
        if(Test.isRunningTest())
        {
            query+= ' limit 1 ';
        }
        return query;
    }
}