/**
 * Created By       :   Girikon(Sachin)
 * Created On       :   Feb 24,2020 
 * @description     :   This controller defined auraEnabled action that called from each lwc component
 * Test Class       :   CommonController_Test(100%)
 * Modified by      :   
 **/

public with sharing class CommonController {
    
    /**
     * @description [Check user access]
     * @param  recordId [Record Id to check access permission]
     * @return          [List of UserRecordAccess]
     */
    @AuraEnabled(cacheable=true)
    public static list<UserRecordAccess> getUserRecordAccess(string recordId) {
        List<UserRecordAccess> getUsrRecord = new List<UserRecordAccess>();
        if (Schema.sObjectType.UserRecordAccess.isAccessible()) {
            getUsrRecord = [SELECT RecordId, HasReadAccess, HasDeleteAccess, HasEditAccess, HasTransferAccess, MaxAccessLevel
                            FROM UserRecordAccess
                            WHERE UserId = : userInfo.getUserId() 
                            AND RecordId = : recordId ];
        }
        return getUsrRecord;
    }
    
    /**
     * @description [This method will get the list of order on the basis of param account Id and Ordernumber]
     * @param  recordId [Account Record Id]
     * @return          [List of Order]
     */
    @AuraEnabled(cacheable=true)
    public static list<Order> getOrderList(String recordId) {
        List<Order> getOrderRecord = new List<Order>();
        if (Schema.sObjectType.Order.isAccessible()) {
            getOrderRecord = [SELECT Id, AccountId, Account.Name, Opportunity.AccountId
                              FROM Order 
                              WHERE OrderNumber!=null 
                              AND (AccountId = : recordId OR Opportunity.AccountId = : recordId)];
        }
        return getOrderRecord;
    }

    /**
     * @description [Get record count]
     * @param  objectName [Pass object api name]
     * @param  condtion [pass if any]
     * @return  Integer [record count]
     */
    @AuraEnabled(cacheable=true)
    public static Integer getRecordCount(String objectName,String condtion){
        if(condtion!=''){
            condtion = ' WHERE '+condtion; 
        }
        return Database.countQuery('Select count() from '+objectName+condtion);
    }

    /**
     * @description [This method used to check field update permission]
     * @param       [objectName api name, fieldName fieldApiName]     
     * @return      [List of Online_Booth_Contract_Review_Team_Member__c]
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isUpdateable(String objectName,String fieldName){
        SObjectType sObjectTypeObj = Schema.getGlobalDescribe().get(objectName);
        Boolean isUpdate = false;
        if(sObjectTypeObj.getDescribe().isUpdateable()){
            isUpdate = sObjectTypeObj.getDescribe().fields.getMap().get(fieldName).getDescribe().isUpdateable();
        }
        return isUpdate;
    }

    /**
     * @description [This method used to check field insert permission]
     * @param       [objectName api name, fieldName fieldApiName]     
     * @return      [List of Online_Booth_Contract_Review_Team_Member__c]
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isCreateable(String objectName,String fieldName){
        SObjectType sObjectTypeObj = Schema.getGlobalDescribe().get(objectName);
        Boolean isUpdate = false;
        if(sObjectTypeObj.getDescribe().isUpdateable()){
            isUpdate = sObjectTypeObj.getDescribe().fields.getMap().get(fieldName).getDescribe().isCreateable();
        }
        return isUpdate;
    }
    
    /**
    * getDeclinedOptions get all option of declined reason fields of online booth capture.
    * @return   return description
    */
    /*@AuraEnabled(cacheable=true)
    public static Map<String, SchemaUtils.FieldDto> getDeclinedOptions(){
        Map<String,String> objectFieldsMap = new Map<String,String> {               
            'Online_Booth_Capture__c.Reason_Of_Declined__c'=>'Reason_Of_Declined'
        };
        Map<String, SchemaUtils.FieldDto> fields = new Map<String, SchemaUtils.FieldDto>();
        Map<String, SchemaUtils.FieldDto> describes = SchemaUtils.describeSobjects(objectFieldsMap.keySet());
        for (String fieldPath : describes.keySet()) {
            SchemaUtils.FieldDto field = describes.get(fieldPath);
            fields.put(objectFieldsMap.get(fieldPath), field);
        }
        return fields;
    }*/

}