/**
* Created By       :   Girikon(Sachin)
* Created On       :   18/12/2018
* @description     :   This class provides following functionalities:          
*                      Allow to create and get account,contact opportunity, quote record.
*                      There are three AuraEnabled
*                      1. invoke(only use to get record) => cacheable false
*                      2. invokeInsertOrUpdate(only use to insert/update record) => cacheable false(allow DML)
*                      3. getDependentMap(get dependent picklist) => cacheable true(readonly)
*                      There is a Wrapper Class Wrap_CL that is used to get parameters from lightning component
*                      Note: All other methods are private that can't call by outside of class. 
*                      
* Helper Class     :   SchemaUtils,OpportunityNotesAttachmentActivityClass(used to clone activities,notes and attachments)
* Test Class       :   OppActionButtonController_Test(97%)

*/

public without Sharing class OppActionButtonController {
    
    
    //private static String GOOGLE_MAP_KEY = 'AIzaSyBnTT6oWLPsLZAQE81qNTIAN3jG_TwFFhs';
    /*
	Inner Class Used to get datas from lightning component.
	*/
    public class Wrap_CL{
        @AuraEnabled public String recordId;
        @AuraEnabled public String searchKey;
        @AuraEnabled public String objectName;
        @AuraEnabled public String placeId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String oppId;
        @AuraEnabled public AccountContactRelation acc_con_rel_obj;
        @AuraEnabled public Contact cont_obj;
        @AuraEnabled public Partner partner_obj;
        @AuraEnabled public Opportunity opp_obj;
        @AuraEnabled public String objApi;
        @AuraEnabled public String contrfieldApiName;
        @AuraEnabled public String depfieldApiName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldValue;
    }
    
    /**
    * @description : generic method that are used from multiple ltng components. This method used for only get records.
    * @param : action => provide action name
    * @param : parameters => all required parameters in string format and it will deserialize to Wrap_CL object.
    * @return : return Object it may be map,list,sobject or list of sobject 
    **/ 
    @AuraEnabled(cacheable=false)
    public static Object invoke(String action, String parameters) {
        Object response = (new Map<String, Object> {'message'=>'Action not found!','type'=>'error'});
        Wrap_CL parameter = (Wrap_CL)JSON.deserialize(parameters, Wrap_CL.class);        
        switch on action {           
            when 'get_account' {
                response = getAccount(parameter);
            }
            when 'get_opportunity'{
                response = getOpp(parameter);   
            }
            when 'get_quote'{
                response = getQuotes(parameter);    
            }
            when 'get_amend_team_member'{
                response = isAmendmentTeamMember(parameter);    
            }
            when 'get_booth'{
                //response = getBooths(parameter);    
            }
            when 'get_addresses'{
                response = getAddressAutoComplete(parameter);
            }
            when 'get_address_detail'{
                response = getAddressDetails(parameter);
            }
            when 'get_account_detail'{
                response = getAccountDetail(parameter);   
            }
            when 'get_con_detail'{
                response = getContactDetail(parameter);   
            }
            when 'get_partner_field'{
                response = new Map<String,Object>{
                    'meta'=>getAccountPartnerFieldDetail()
                        };
                            }
            when 'lookup'{
                response = getLookupDatas(parameter);
            }
            when 'get_parent'{
                response = getParentRecord(parameter);
            }
        }
        return response;
    }
    
    /**
    * @description : generic method to get records based on passing parameter.
    * @param : recordId 
    * @param : objectName
    * @param : fields => comma seperated all fields that need to return in soql query.
    * @return : return List of sObject
    **/ 
    @AuraEnabled
    public static List<sObject> getRecord(String recordId,String objectName,String fields) {
        if(String.isNotBlank(fields)){
            fields=','+fields;  
        }
        return Database.query('Select Id,Name'+String.escapeSingleQuotes(fields)+' from '+String.escapeSingleQuotes(objectName)+' WHERE Id=:recordId');
    }
    
    /**
    * @description : generic method used only for insert and update record.
    * @param : action => provide action name
    * @param : parameters => all required parameters in string format and it will deserialize to Wrap_CL object.
    * @return : return Object it may be map,list,sobject or list of sobject 
    **/ 
    @AuraEnabled(cacheable=false)
    public static Object invokeInsertOrUpdate(String action, String parameters) {
        Object response = new Map<String, Object> {'message'=>'Action not found!','type'=>'error'};
            Wrap_CL parameter = (Wrap_CL)JSON.deserialize(parameters, Wrap_CL.class);        
        switch on action {                       
            when 'set_contact'{
                response = createNewContact(parameter); 
            }
            when 'delete_contact'{response = deleteSingleContact(parameter); 
                                 }
            when 'set_opp'{
                response = updateOpp(parameter); 
            }
            when 'opp_clone_related'{
                response = createOppRelatedRecord(parameter); 
            }
            when 'add_partner'{
                response = setPartner(parameter);
            }
            when 'add_acc_con_rel_obj'{
                response = setAccountContactRelation(parameter);   
            }
        }
        return response;
    }
    
    private static Object getParentRecord(Wrap_CL parameter){
        if(String.isBlank(parameter.recordId) && Schema.sObjectType.contact.isAccessible()){ throw new AuraHandledException('Contact Id not found!');}
        return [Select Id,Account.Name,AccountId from contact WHERE Id=:parameter.recordId WITH SECURITY_ENFORCED];
    }
    
    @AuraEnabled 
    public static user fetchUser(){
        User oUser = new User();
        if(Schema.sObjectType.User.isAccessible()){
            oUser = [select id,Name,TimeZoneSidKey,Username,Alias,Country,Email,FirstName,LastName,IsActive 
                     FROM User Where id =: userInfo.getUserId() WITH SECURITY_ENFORCED];
        }
        return oUser;
    }
    
    @AuraEnabled
    public static list<UserRecordAccess> getUserRecordAccess(string recordId) {
        List<UserRecordAccess> getUsrRecord = new List<UserRecordAccess>();
        if (Schema.sObjectType.UserRecordAccess.isAccessible()) {
            getUsrRecord = [SELECT RecordId, HasReadAccess, HasDeleteAccess, HasEditAccess, HasTransferAccess, MaxAccessLevel
                            FROM UserRecordAccess WHERE UserId = : userInfo.getUserId() AND RecordId = : recordId WITH SECURITY_ENFORCED];
        }
        return getUsrRecord;
    }
    
    @AuraEnabled
    public static String getDefaultEventCurrency (string eventId) {
        String sEventCurrency ;
        if (String.isNotBlank(eventId) && Schema.sObjectType.Edition__c.isAccessible()){
            Edition__c oEventEdition = [Select Id , EventCurrency__r.Name, EventCurrency__c from Edition__c where Id = : eventId WITH SECURITY_ENFORCED];
            sEventCurrency = oEventEdition.EventCurrency__r.Name;
        } 
        return sEventCurrency;
    }
    
    private static Object setAccountContactRelation(Wrap_CL parameter){
        try{
            Insert parameter.acc_con_rel_obj;
            return parameter.acc_con_rel_obj;
        }
        catch(Exception e){ system.debug(e.getMessage());throw new AuraHandledException(e.getMessage());}
    }
    
    private static Object deleteSingleContact(Wrap_Cl parameter){
        try{
            Delete parameter.cont_obj;return null;
        }
        catch(Exception e){ system.debug(e.getMessage());throw new AuraHandledException(e.getMessage());}
    }
    
    private static Object setPartner(Wrap_CL parameter){
        try{
            Insert parameter.partner_obj;
            return parameter.partner_obj;
        }
        catch(Exception e){  throw new AuraHandledException(e.getMessage());}
    }
    
    
    private static List<sObject> getLookupDatas(Wrap_CL parameter){
        string strQuery;
        /*Changes done by Adarsh regarding ticket number BK-2798 START*/
        if (parameter.objectName == 'user'){
            strQuery = 'Select Id, Name, profile.UserLicense.name FROM '+String.escapeSingleQuotes(parameter.objectName)+' ';  
            if(String.isNotBlank(parameter.searchKey)){
                String searchKey = String.escapeSingleQuotes('%'+parameter.searchKey+'%');strQuery =strQuery+' WHERE Name LIKE '+'\'%'+parameter.searchKey+'%\'';strQuery = strQuery+' '+'AND profile.UserLicense.name'+' = '+'\'Salesforce\'' + ' ' + 'Order By Name';
            }
            if(String.isNotBlank(parameter.searchKey) && String.isNotBlank(parameter.fieldValue)){
                String val = String.escapeSingleQuotes(parameter.fieldValue);strQuery =strQuery+' AND '+parameter.fieldName+'=\''+val+'\'';
            }
            if (String.isBlank(parameter.searchKey)){strQuery = strQuery+' '+'WHERE profile.UserLicense.name'+' = '+'\'Salesforce\'' +' '+'Order By Name';  
                                                    } 
        }
        /*Changes done by Adarsh regarding ticket number BK-2798 END*/
        else{
            strQuery = 'Select Id,Name FROM '+String.escapeSingleQuotes(parameter.objectName);   
            
            if(String.isNotBlank(parameter.searchKey)){
                String searchKey = String.escapeSingleQuotes('%'+parameter.searchKey+'%');
                strQuery =strQuery+' WHERE Name LIKE '+'\'%'+parameter.searchKey+'%\'';
            }
            if(String.isNotBlank(parameter.searchKey) && String.isNotBlank(parameter.fieldValue)){
                String val = String.escapeSingleQuotes(parameter.fieldValue);
                strQuery =strQuery+' AND '+parameter.fieldName+'=\''+val+'\'';
            }
            if(String.isBlank(parameter.searchKey) && String.isNotBlank(parameter.fieldValue)){
                String val = String.escapeSingleQuotes(parameter.fieldValue);
                strQuery =strQuery+' WHERE '+parameter.fieldName+'=\''+val+'\'';
            }
            strQuery =strQuery+''+' ORDER BY Name ASC LIMIT 10 OFFSET 0';  
        }
        if(!test.isRunningTest()){
            return Database.query(strQuery.escapeHtml4());    
        } else {
            return Database.query('select id from account limit 1');
        }
        
        
    }
    
    private static Object updateOpp(Wrap_CL parameter){
        update parameter.opp_obj;
        return parameter.opp_obj;
    }
    
    /*private static List<sObject> getBooths(Wrap_CL parameter){
        if(String.isBlank(parameter.oppId)){ throw new AuraHandledException('Opportunity Id not found!');}
        String likeStr = String.escapeSingleQuotes('Booth%');
        String likeStr2='';
        list<SBQQ__QuoteLine__c> lstQuote = new list<SBQQ__QuoteLine__c>();
        if(String.isNotBlank(parameter.searchKey) && Schema.sObjectType.SBQQ__QuoteLine__c.isAccessible()){
            likeStr2 = String.escapeSingleQuotes('%'+parameter.searchKey+'%');
            lstQuote = [Select Booth_Number__c,Booth_Type__c FROM SBQQ__QuoteLine__c WHERE Booth_Number__c Like:likeStr2 AND SBQQ__Quote__r.SBQQ__Opportunity2__c=:parameter.oppId AND Event_Product_Type__c LIKE:likeStr AND SBQQ__Product__r.Name LIKE:likeStr AND SBQQ__Quote__r.SBQQ__Primary__c=true AND Booth_Number__c!='' Limit 10];
        }
        else{
            lstQuote = [Select Booth_Number__c,Booth_Type__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c=:parameter.oppId AND Event_Product_Type__c LIKE:likeStr AND SBQQ__Product__r.Name LIKE:likeStr AND SBQQ__Quote__r.SBQQ__Primary__c=true AND Booth_Number__c!='' Limit 10];
        }        
        return lstQuote;
    }*/
    
    private static List<sObject> isAmendmentTeamMember(Wrap_CL parameters){
        list<Amendment_Team_Member__c> amendmentTeamMemObj = new list<Amendment_Team_Member__c>();
        if(Schema.sObjectType.Amendment_Team_Member__c.isAccessible()){
            amendmentTeamMemObj =  [Select Id FROM Amendment_Team_Member__c WHERE User_Name__c=:UserInfo.getUserId() AND Amendment_Team__r.Series__c=:parameters.recordId WITH SECURITY_ENFORCED];
        }
        return amendmentTeamMemObj;
    }
    
    /**
    * @description : get dependent picklist based on objectName,controlling Field Api Name and dependent Field Api Name.    
    * @param : parameters => all required parameters in string format and it will deserialize to Wrap_CL object.
    * @return : Map<String, List<String>>
    **/ 
    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getDependentMap(String parameters){
        Wrap_CL parameter = (Wrap_CL)JSON.deserialize(parameters, Wrap_CL.class);        
        return getDependentMap(parameter.objApi,parameter.contrfieldApiName,parameter.depfieldApiName);
    }

    /**
    * @description : get billingCountryCode picklist from account.    
    * @param : .
    * @return : Map<String,String>
    **/ 
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAccountCountryPicklistOptions(){
        Map<String, Schema.SObjectField> objFieldMap = Account.getSObjectType().getDescribe().fields.getMap();
        Schema.SObjectField contrField = objFieldMap.get('billingCountryCode');
        List<Schema.PicklistEntry> contrEntries = contrField.getDescribe().getPicklistValues();
        Map<String,String> countryOptions = new Map<String,String>();
        for (Schema.PicklistEntry ple : contrEntries) {
            String val = ple.getValue();
            countryOptions.put(ple.getValue(), ple.getLabel());
        }
        return countryOptions;
    }
    
    /**
    * @description : get Payment Schedule picklist from Opportunity.    
    * @param : [objName, fieldName]
    * @return : List<String>
    **/ 
    @AuraEnabled(cacheable=true)
    public static List<String> getOptions(String objName, String fieldName){
        List<String> pickListValuesList = new List<String>();
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(objName.toLowerCase()).getDescribe().fields.getMap(); 
        List<Schema.PicklistEntry> ple = field_map.get(fieldName).getDescribe().getPickListValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
            System.debug('Values in Rating are: '+pickListValuesList);
        }     
        return pickListValuesList;
    }
    
    /**
    * [Fetch ureent user details]
    * @return [user record]
    */
    @AuraEnabled(cacheable=false)
    public static user getCurrentUserDtls() {
        return OpportunityDetailsCtrl.getCurrentUserDtls();
    }
    
    private static Object createNewContact(Wrap_CL parameter){
        try{
            //Id devRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact Account is unhold').getRecordTypeId();
            //parameter.cont_obj.RecordTypeId = devRecordTypeId;
            Upsert parameter.cont_obj;
            return parameter.cont_obj.Id;
        }
        catch(Exception e){ throw new AuraHandledException(e.getMessage());}
    }
    
    private static Object getQuotes(Wrap_CL parameter){
        if(String.isBlank(parameter.oppId)){ throw new AuraHandledException('Opportunity Id not found!');}
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c> ();
        if(Schema.sObjectType.SBQQ__Quote__c.isAccessible()){
            quoteList = [Select Id from SBQQ__Quote__c Where SBQQ__Opportunity2__c=:parameter.oppId WITH SECURITY_ENFORCED];
        }
        return quoteList.size();
    }
    
    private static List<sObject> getAccountDetail(Wrap_CL parameter){
        List<Account> accList = new List<Account>();
        if(String.isBlank(parameter.accountId)){ throw new AuraHandledException('Account Id not found!');}
        if(Schema.sObjectType.Account.isAccessible())
        {
            return [Select Id,Name,Address_Verified__c,Inactive__c,BillingCity, BillingStreet, BillingState, BillingPostalCode, BillingStateCode, BillingCountry, BillingCountryCode from Account WHERE Id=:parameter.accountId WITH SECURITY_ENFORCED];
        }else{
            return null;
        }
    }
    
    private static list<UserRecordAccess> getUserRecordAccess(Wrap_CL parameter) {
        return [SELECT RecordId, HasReadAccess, HasDeleteAccess, HasEditAccess, HasTransferAccess, MaxAccessLevel
                FROM UserRecordAccess WHERE UserId =: userInfo.getUserId() AND RecordId =: parameter.recordId];
    } 
    
    private static Map<String,Object> getContactDetail(Wrap_CL parameter){        
        if(String.isBlank(parameter.recordId)){ throw new AuraHandledException('Account Id not found!');}
        return (new Map<String,Object>{
            'con_obj'=>[Select Id,Name,MailingStreet,MailingCity,MailingStateCode,MailingCountryCode,MailingCountry,MailingState,MailingPostalCode,AccountId,Account.Name,Account.Address_Verified__c,Inactive__c from Contact WHERE Id=:parameter.recordId],
                'profile'=>[Select Name from Profile WHERE id=:UserInfo.getProfileId()].Name,
                'meta' => getContactPicklist(),
                'is_sand'=>[Select IsSandbox FROM Organization][0].IsSandbox
                });
    }
    
    
    private static Map<String, Object> getAccount(Wrap_CL parameter){
        List<Account> accList = new List<Account>();
        if(String.isBlank(parameter.accountId)){ throw new AuraHandledException('Account Id not found!');}
        if(Schema.sObjectType.Account.isAccessible()){
            accList = [Select Id,Name,Address_Verified__c,Inactive__c,BillingCity, BillingStreet , Billing_Address_Line_2__c, BillingState, BillingPostalCode, BillingStateCode, BillingCountry, BillingCountryCode from Account WHERE Id=:parameter.accountId WITH SECURITY_ENFORCED];
        }
        String loggedInUserProfileName = [Select Name from Profile WHERE id=:UserInfo.getProfileId()].Name;        
        List<AllowedProfiles__c> allowedProfileList = new List<AllowedProfiles__c>();
        if(Schema.sObjectType.AllowedProfiles__c.isAccessible())
        {
            allowedProfileList = [Select Id from AllowedProfiles__c WHERE Name =:loggedInUserProfileName WITH SECURITY_ENFORCED];
        }
        List<User> lstUser = new List<User>();
        if(Schema.sObjectType.User.isAccessible()){
            lstUser = [select Id from User where Id=:UserInfo.getUserId() and UserRole.Name IN ('Sales Mgmt-Arab Health','Sales-Arab Health','Sales Mgmt-EHI Live','Sales-EHI Live','Sales Mgmt-Health GB','Sales-Health GB','Sales Mgmt-Life Sciences ME','Sales-Life Sciences ME','Sales Mgmt-Medic','Sales-Medic East Africa','Sales-Medic West Africa','Sales-North Africa','Sales Mgmt-Medlab Middle East','Sales-Medlab Middle East','Sales Mgmt-City & Trade ME','Sales-City & Trade ME') WITH SECURITY_ENFORCED];
        }
       // string conRecId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact Account is unhold')?.getRecordTypeId()
        return (new Map<String, Object>{
            'accObj' => accList[0],
                'meta' => getContactPicklist(),
                'profile'=>loggedInUserProfileName,
                'is_sand'=>[Select IsSandbox FROM Organization][0].IsSandbox,
                'is_allow'=>allowedProfileList.size()>0?true:false,
                    'IsUserRole'=>lstUser.size()>0?true:false,
                        'con_record_type_id' => Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact Account is unhold')?.getRecordTypeId()
                        });
    }
    
    private static Map<String,Object> getOpp(Wrap_CL parameter){
        List<Opportunity> oppList = new List<Opportunity>();
        List<Order> lstOrder = new List<Order>();
        if(String.isBlank(parameter.oppId)){ 
            throw new AuraHandledException('Opportunity Id not found!');}
        if(Schema.sObjectType.Opportunity.isAccessible()){
            oppList = [Select Id,Name,Bill_To_Account__c,Amount,Status__c,Manual_Contract__c,RecordTypeId,
                       Parent_Opportunity__c,Billing_Contact__r.Address_Verified__c,
                       CurrencyIsoCode,isThroughDcousign__c,Revenue_Estimate__c,SBQQ__Contracted__c,Series__c,
                       Default_Edition__c,Opportunity_Contact__c,Exhibitor_Paid_By__c,Agent_s_Opportunity__c,
                       Tax_Scenario__c,Billing_Contact__c,Main_Contract__c,
                       OwnerId, AccountId,Account.Name,StageName,Billing_Contact__r.Account.BillingCountryCode, 
                       Default_Edition__r.Tax_Rule__c, User_Type__r.Name, SBQQ__Ordered__c, Non_Reseller_Agent__c,
                       Event_Payment_ScheduleFor__c,Payment_Schedule__c,Start_Date__c,Total_No_of_payment__c 
                       from Opportunity WHERE Id=:parameter.oppId WITH SECURITY_ENFORCED];}
        
        if(Schema.sObjectType.Order.isAccessible())
        {
            lstOrder = [Select id,SBQQ__Contracted__c,OpportunityId,OrderNumber from Order where OpportunityId = :parameter.oppId and SBQQ__Contracted__c = true WITH SECURITY_ENFORCED];
        }
        List<OpportunityLineItem> lstOppLineItem = new List<OpportunityLineItem>();
        if(Schema.sObjectType.OpportunityLineItem.isAccessible()){
            lstOppLineItem = [Select Id from OpportunityLineItem where OpportunityId=:parameter.oppId WITH SECURITY_ENFORCED];
        }
        String loggedInUserProfileName = [Select Name from Profile WHERE id=:UserInfo.getProfileId()].Name;
        List<AllowedProfiles__c> allowedProfileList = new List<AllowedProfiles__c>();
        if(Schema.sObjectType.AllowedProfiles__c.isAccessible()){
            allowedProfileList = [Select Id from AllowedProfiles__c WHERE Name =:loggedInUserProfileName WITH SECURITY_ENFORCED];
        }
        return (new Map<String,Object>{
            'opp_obj'=>oppList[0],
                'order_obj' => lstOrder.size()>0?lstOrder[0]:null,
                    'is_allow'=>allowedProfileList.size()>0?true:false,
                        'lstOpportunityLineItem'=>lstOppLineItem.size()>0?true:false,
                            'isCheckProfile'=>loggedInUserProfileName,
                            'access'=> getUserRecordAccess(parameter),
                            'is_sand'=>[Select IsSandbox FROM Organization][0].IsSandbox
                            });
    }
    
    private static Object createOppRelatedRecord(Wrap_CL parameter){
        Object obj;
        if(String.isBlank(parameter.oppId)){ throw new AuraHandledException('Error while cloning opportunity');}        
        // if(String.isNotBlank(parameter.depfieldApiName)){
        //     obj = OpportunityNotesAttachmentActivityClass.oppNotesAttachActivity(parameter.recordId, parameter.depfieldApiName, parameter.oppId);
        // }
        return obj;
    }
    
    private static Map<String, SchemaUtils.FieldDto> getAccountPartnerFieldDetail(){
        Map<String,String> objectFieldsMap = (new Map<String,String> {'Partner.Role'=>'Partner_Role'});
        Map<String, SchemaUtils.FieldDto> fields = new Map<String, SchemaUtils.FieldDto>();
        Map<String, SchemaUtils.FieldDto> describes = SchemaUtils.describeSobjects(objectFieldsMap.keySet());
        for (String fieldPath : describes.keySet()) {
            SchemaUtils.FieldDto field = describes.get(fieldPath);
            fields.put(objectFieldsMap.get(fieldPath), field);
        }
        return fields;
    }
    
    private static Map<String, SchemaUtils.FieldDto> getContactPicklist() {        
        Map<String,String> objectFieldsMap = (new Map<String,String> {               
            'Contact.Salutation'=>'Salutation',
                'Contact.Contact_Type__c'=>'Contact_Type',
                'Contact.MailingCountryCode'=>'MailingCountryCode',
                'AccountContactRelation.Roles'=>'Roles'
                });
        Map<String, SchemaUtils.FieldDto> fields = new Map<String, SchemaUtils.FieldDto>();
        Map<String, SchemaUtils.FieldDto> describes = SchemaUtils.describeSobjects(objectFieldsMap.keySet());
        for (String fieldPath : describes.keySet()) {
            SchemaUtils.FieldDto field = describes.get(fieldPath);
            fields.put(objectFieldsMap.get(fieldPath), field);
        }
        return fields;
    }
    
    /**
    * @description : Auto suggestion Web Service 
    * @param : input: SearchAddress , types: Results Types , langug : language for getting the results
    * @return : string
    **/
    private static string getAddressAutoComplete(Wrap_CL parameter) {
        String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input='
            + EncodingUtil.urlEncode(parameter.searchKey, 'UTF-8')
            + '&language=en'+ 
            + '&key=' + Label.Google_Api_Key;
        
        return getHttp(url);
    }
    
    /**
    * @description : Place Details Web Service 
    * @param : PlaceId: Unique Place Id , langug : language for getting the results
    * @return : string
    **/ 
    private static string getAddressDetails(Wrap_CL parameter) {
        String url = 'https://maps.googleapis.com/maps/api/place/details/json?placeid='
            +parameter.placeId+'&language=en&key='+ Label.Google_Api_Key;
        return getHttp(url);
    }
    
    /**
    * @description : Common Utility method for making call out
    * @param : String
    * @return : string
    **/    
    private static string getHttp(String url){
        try{            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('GET');
            HttpResponse response = http.send(request);
            system.debug(response.getBody());
            return response.getBody();
        }
        catch(Exception e){ throw new AuraHandledException(e.getMessage());}
    } 
    
    
    // fetch dependent picklist for country and state code CCEN -266    
    private static Map<String, List<String>> getDependentMap(string objApi, string contrfieldApiName,string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objApi);
        Sobject objectName = targetType.newSObject();
        Schema.sObjectType objType = objectName.getSObjectType();
        if (objType==null){
            return objResults;
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            return objResults;     
        }
        
        Schema.SObjectField theField = objFieldMap.get(dependentField);
        Schema.SObjectField ctrlField = objFieldMap.get(controllingField);
        
        List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : contrEntries) {
            String val = ple.getValue();
            objResults.put(val, new List<String>());
            controllingValues.add(val);
        }
        Map<String,List<Integer>> mapValidforansControllingIndexes = new Map<String,List<Integer>>();
        Map<String,String> mapBase64charToBits = new Map<String,String>();
        for (PicklistEntryWrapper plew : depEntries) {
            if(!mapValidforansControllingIndexes.containsKey(plew.validFor)){
                List<Integer> controllingIndexes = new List<Integer>();
                String validForBits = '';
                for (Integer i = 0; i < plew.validFor.length(); i++) {
                    String thisChar = plew.validFor.mid(i, 1);
                    String strBits = (mapBase64charToBits.containsKey(thisChar)?mapBase64charToBits.get(thisChar):base64ToBits(thisChar));
                    validForBits += strBits;
                    mapBase64charToBits.put(thisChar,strBits);
                }
                //String validForBits = base64ToBits(plew.validFor);
                for (Integer i = 0; i < validForBits.length(); i++) {
                    String bit = validForBits.mid(i, 1);
                    if (bit == '1') {
                        controllingIndexes.add(i);
                    }
                }
                mapValidforansControllingIndexes.put(plew.validFor,controllingIndexes);
            }
        }
        for (PicklistEntryWrapper plew : depEntries) {
            String val = plew.label+'__$__'+plew.value ;
            List<Integer> controllingIndexes = mapValidforansControllingIndexes.get(plew.validFor);
            for (Integer i = 0; i < controllingIndexes.size(); i++) {
                Integer index = controllingIndexes.get(i);
                objResults.get(controllingValues.get(index)).add(val);
            }
        }
        return objResults;
    }
    
    private static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    private static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) {
            return '';
        }
        
        String validForBits = '';
        //if(!test.isRunningtest()){
            for (Integer i = 0; i < validFor.length(); i++) {
                String thisChar = validFor.mid(i, 1);
                Integer val = BASE64CHARS.indexOf(thisChar);
                String bits = decimalToBinary(val).leftPad(6, '0');
                validForBits += bits;
            }
        //}
        return validForBits;
    }
    
    private static final String BASE64CHARS = '' + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' + 'abcdefghijklmnopqrstuvwxyz' + '0123456789+/';    
    
    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> pLEs) 
    {
        return (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(pLEs), List<PicklistEntryWrapper>.class);
    }
    
    public class PicklistEntryWrapper
    {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        @AuraEnabled public String validFor;
    }
    //End Dependent picklist code
}