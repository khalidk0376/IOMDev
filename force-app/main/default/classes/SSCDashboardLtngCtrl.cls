/****
Created By    : Sachin CHaudhary
Created On    : 18/02/2020
@description  : This is common class for SSC Dashboard.
Test Class    : SSCDashboardLtngCtrl_Test - 86%
*****/

public with sharing class SSCDashboardLtngCtrl {

    /*
    * @description [This method is used to fetch record of SSC Team Member.]
    * @param       Nothing
    * @return      [List of SSC_Team_Member__c]
    */
    @AuraEnabled(cacheable=true)
    public static list<Action_Team_Member__c> getSSCTeamMember() {
        List<Action_Team_Member__c> getActionTeamRecord = new List<Action_Team_Member__c>();
            getActionTeamRecord = [SELECT Id, Name, Action_Team__c, Action_Team__r.Name, Action_Team__r.Series__c,Action_Team__r.Series__r.Name, Action_Team_Member__c, Action_Team_Member__r.Name 
                                FROM Action_Team_Member__c 
                                WHERE Action_Team_Member__c = : userInfo.getUserId()];
     
        return getActionTeamRecord;
    }
    
    /*
    * @description [This method is used to fetch record of Operation Team Member.]
    * @param       Nothing
    * @return      [List of Operations_Team_Member__c]
    */
    // @AuraEnabled(cacheable=true)
    // public static list<Operations_Team_Member__c> getOperationTeamMember() {
    //     List<Operations_Team_Member__c> getOperationTeamRecordList = new List<Operations_Team_Member__c>();
    //         getOperationTeamRecordList = [SELECT Id,Operations_Team__r.Series__c 
    //                                       FROM Operations_Team_Member__c
    //                                       WHERE User_Name__c = : userInfo.getUserId()];
    //     return getOperationTeamRecordList;
    // }

    /**
    *  @description [isSSCBrazilUser() Method query on user object to check is logged in user role is 'SSC-Brazil']
    *  @param     n/a
    *  @return   [return true if logged in user role is 'SSC-Brazil' otherwize false]
    */
    @AuraEnabled(cacheable=true)     
    public static Boolean isSSCBrazilUser(){
        Boolean isBrazilUser = false;
        List<User> userList = new List<User>();
        if(Schema.sObjectType.User.isAccessible())
        {
            userList = [Select Id from User Where Id=:UserInfo.getUserId() AND UserRole.Name='SSC-Brazil'];
        }
        if(userList.size()>0){
            isBrazilUser = true;
        }
        return isBrazilUser;
    }
  
    /**
    *  @description [getProductBrasilCondition() This method is used to fetch the product brazil table data on the basis od opportunity Id]
    *  @param     Opportunity Id
    *  @return   [return Map of Sting and sObject]
    */
    @AuraEnabled(cacheable=true)
    public static Object getProductBrasilCondition(String oppId){
        return new Map<String,Object>{
            'isShowProductHeader' => isShowProductHeader(oppId),
            'isShowProductAgg_brasil' =>isVisible('001',oppId),
            'isShowProductAgg_brasil1' =>isVisible('002',oppId),
            'isShowProductAgg_brasil2' =>isVisible('003',oppId),
            'isShowProductAgg_brasil3' =>isVisible('004',oppId),
            'isShowProductAgg_brasil4' =>isVisible('005',oppId),
            'isShowProductAgg_brasil5' =>isVisible('006',oppId),
            'isShowProductAgg_brasil6' =>isVisible('007',oppId),
            'isShowProductAgg_brasil7' =>isVisible('008',oppId),
            'isShowProductAgg_brasil8' =>isVisible('009',oppId),
            'isShowProductAgg_brasil10' =>isVisible('010',oppId),
            'isShowProductAgg_brasil11' =>isVisible('011',oppId),
            'isShowProductAgg_brasil12' =>isVisible('012',oppId),
            'isShowProductAgg_brasil13' =>isVisible('013',oppId),
            'isShowProductAgg_brasil14' =>isVisible('014',oppId),
            'isShowProductAgg_brasil15' =>isVisible('015',oppId),
            'isShowProductAgg_brasil16' =>isVisible('016',oppId),
            'isShowProductAgg_brasil17' =>isVisible('017',oppId),
            'isShowProductAgg_brasil18' =>isVisible('018',oppId),
            'isShowProductAgg_brasil19' =>isVisible('019',oppId),
            'isShowProductAgg_brasil20' =>isVisible('020',oppId),
            'isShowProductAgg_brasil21' =>isVisible('021',oppId),
            'isShowProductAgg_brasil22' =>isVisible('022',oppId),
            'isShowProductAgg_brasil23' =>isVisible('023',oppId),
            'isShowProductAgg_brasil24' =>isVisible('024',oppId),
            'isShowProductAgg_brasil25' =>isVisible('025',oppId),
            'isShowProductAgg_brasil26' =>isVisible('026',oppId)
        };
    }
    
    /**
    *  @description [isVisible() This method is used to fetch the list of Quote Line on the basis of codetype and opportunity id]
    *  @param     Code Type and Opportunity Id
    *  @return   [return boolean value]
    */
    @TestVisible
    private static Boolean isVisible(String codeType,String oppId){
        Boolean isVisible = true;
        List<SObject> objList = new List<SObject>();
        if(Schema.sObjectType.SBQQ__QuoteLine__c.isAccessible())
        {
            objList = [SELECT id 
                                 From SBQQ__QuoteLine__c 
                                 WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c=:oppId 
                                 AND SBQQ__Quote__r.SBQQ__Primary__c=true];
        }
        
        if(objList.size()==0){
            isVisible = false;
        }
        return isVisible;
    }
    
    /**
    *  @description [isShowProductHeader() This method is used to fetch the list of Quote Line on the basis of primary checkbox]
    *  @param     N/A
    *  @return   [return boolean value]
    */
  @TestVisible
    private static Boolean isShowProductHeader(String oppId){
        boolean isShowProductHeader = false;
        List<SObject> objList = [SELECT id 
                                 From SBQQ__QuoteLine__c 
                                 WHERE SBQQ__Quote__r.SBQQ__Opportunity2__c=:oppId 
                                 AND SBQQ__Quote__r.SBQQ__Primary__c=true];
        if(objList.size()>0){ isShowProductHeader = false;}
        else{
            isShowProductHeader = true;
        }
        return isShowProductHeader;
    }

    /**
     * @description [Get data from aggrement custom object based on opp id. this method used on pending contract tab on SSC Dashboard]
     * @param  opportunity Id and search key
     * @return   [return List of sObject]
     */
    @AuraEnabled(cacheable=true)
    public static List<SObject> getAgreements(String oppId,String searchValue){
        List<SObject> agreementList;
        if(searchValue=='' && Schema.sObjectType.Agreement__c.isAccessible()){ agreementList = [Select Name,Opportunity__r.Name,LastModifiedDate 
                                              FROM Agreement__c 
                                              WHERE Opportunity__c=:oppId];
        } else{
            agreementList = [Select Name,Opportunity__r.Name,LastModifiedDate 
                             FROM Agreement__c
                             WHERE Opportunity__c=:oppId 
                             AND (Name like:String.escapeSingleQuotes(searchValue) OR Opportunity__r.Name like:String.escapeSingleQuotes(searchValue))];
        }
        return agreementList;
    }
    
    /**
    * approveContract Approved contract
    * @param  oppObj Pass opportunity Object
    */
    @AuraEnabled(cacheable=false)
    public static void approveContract(Opportunity oppObj){
        oppObj.Approved_Rejected_At__c = System.now();
        try{
            upsert oppObj;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
    * getRejectionOptions get all option of rejection response fields
    * @return   return description
    */
    @AuraEnabled(cacheable=true)
    public static Map<String, SchemaUtils.FieldDto> getRejectionOptions(){
        Map<String,String> objectFieldsMap = new Map<String,String> {               
            'Opportunity.Rejection_Reason__c'=>'Rejection_Reason'
                };
                    Map<String, SchemaUtils.FieldDto> fields = new Map<String, SchemaUtils.FieldDto>();
        
        Map<String, SchemaUtils.FieldDto> describes = SchemaUtils.describeSobjects(objectFieldsMap.keySet());
        for (String fieldPath : describes.keySet()) {
            SchemaUtils.FieldDto field = describes.get(fieldPath);
            fields.put(objectFieldsMap.get(fieldPath), field);
        }
        return fields;
    }
    
    /**
    * getRejectionOptions get all option of rejection response fields
    * @param  sChangedValueJson Pass Updated Opportunity Id
    * @return   return void
    */
    @AuraEnabled(cacheable=false)
    public static string approveRejectAmmendedOpportunit(String sOppId, string sAction, string sSSCNotes, string sReason){
        List<Change_Request__c> listChangeRequest = new List<Change_Request__c>();
        if(Schema.sObjectType.Change_Request__c.isAccessible())
        {
            listChangeRequest = [Select Id, Account__c, Account__r.Name, Name, Edition__c,Edition__r.Name, Opportunity__c,  Opportunity__r.Name, Amended_Opportunity__c,Amended_Opportunity__r.Name,Change_Request_Status__c 
                                                     From Change_Request__c
                                                     Where Amended_Opportunity__c=:sOppId 
                                                     order by LastModifiedDate DESC 
                                                     limit 1];
        }
        Change_Request__c changeRequest = new Change_Request__c();
        if(!listChangeRequest.isEmpty()){ changeRequest=listChangeRequest[0]; }
        Opportunity toUpdateOpportunity = new Opportunity();
        if(Schema.sObjectType.Opportunity.isAccessible())
        {
            toUpdateOpportunity = [Select Id,StageName,Rejection_Reason__c,Approved_Rejected_By__c,SBQQ__PrimaryQuote__c , Approved_Rejected_At__c
                                           from Opportunity 
                                           where Id=:sOppId];
        }
        if(sAction=='Approve'){
            changeRequest.Change_Request_Status__c='Completed';
            toUpdateOpportunity.Approved_Rejected_By__c=UserInfo.getUserId();
            toUpdateOpportunity.Approved_Rejected_At__c=System.now();
        } else if(sAction=='Reject'){
            changeRequest.Change_Request_Status__c='Rejected';
            toUpdateOpportunity.StageName='Customize';
            toUpdateOpportunity.Status__c = 'Accounting Rejected';
            toUpdateOpportunity.Approved_Rejected_By__c=UserInfo.getUserId();            
            toUpdateOpportunity.Approved_Rejected_At__c=System.now();
            //toUpdateOpportunity.SSC_Notes__c=sSSCNotes;
            toUpdateOpportunity.Rejection_Reason__c=sReason;
        }
        try{
            if(!test.isRunningTest() && Schema.sObjectType.Opportunity.isUpdateable() && Schema.sObjectType.Change_Request__c.isUpdateable())
            { 
                update toUpdateOpportunity; 
                update changeRequest; 
            }
            return toUpdateOpportunity.SBQQ__PrimaryQuote__c;
        }
        catch(Exception e){
            system.debug('e.getMessage(): '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }        
    }
    
    /**
    * getPickListValuesIntoList get all option of rejection response fields
    * @param  sChangedValueJson Pass Updated Opportunity Id
    * @return   return void
    */
    @auraEnabled (cacheable=true)
    public static List<String> getPickListValuesIntoList(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Opportunity.Rejection_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }
        return pickListValuesList;        
    }
    
}