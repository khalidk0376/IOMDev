/**
* @description  Class to Assign Visibiliy based on User Type And Product Type.
* Created/Modified By: Girikon(Aishwarya)
* Methods:             assignTabToUsers, relatedData
* Apex Class:          IMCC_AssignTabs_Test(100%) 
**/
public without sharing class IMCC_AssignTabs {
    /**
    * @description  to Assign Visibiliy based on User Type.
    * @param  listUserTypes
    * @param recordId
    * @param fieldName  
    */
    @AuraEnabled
    public static void assignTabToUsers(List<String> listUserTypes, String recordId, String fieldName){
        try{
            Set<String> setUserTypes = new Set<String>(listUserTypes);
            List<Tab_User_Type__c> listTabUserType = relatedData(fieldName, recordId);
            List<Tab_User_Type__c> listTabUSerToInsert = new List<Tab_User_Type__c>();
            List<Tab_User_Type__c> listTabUSerToDelete = new List<Tab_User_Type__c>();
            
            for(Tab_User_Type__c tabUserType : listTabUserType){
                if(setUserTypes.contains(tabUserType.User_Type__c)){
                    setUserTypes.remove(tabUserType.User_Type__c);
                }
                else{
                    listTabUSerToDelete.add(tabUserType);
                }
            }

            if(!listTabUSerToDelete.isEmpty() && Schema.sObjectType.Tab_User_Type__c.isDeletable()){
                delete listTabUSerToDelete;
            }
            
            if(!setUserTypes.isEmpty()){
                for(String str : setUserTypes){
                    Tab_User_Type__c tabUType = new Tab_User_Type__c();
                    tabUType.User_Type__c = str;
                    tabUType.put(fieldName, recordId);
                    listTabUSerToInsert.add(tabUType);
                }
                if(!listTabUSerToInsert.isEmpty() && Schema.sObjectType.Tab_User_Type__c.isCreateable()){
                    Database.insert(listTabUSerToInsert,false);
                }
            }
        }    
        catch (Exception e) {
            System.debug(Logginglevel.Debug,'Exception hit ' +e.getMessage());
            HandleAllCustomException.logException(e,'Tab_User_Type__c', 'After Insert');
        } 
    }
    
    /**
    * @description  Get Related Tab User Types.
    * @param  fieldName
    * @param  recordId    
    * @return List<Tab_User_Type__c>
    */
    @AuraEnabled
    public static List<Tab_User_Type__c> relatedData(String fieldName, String recordId){
        List<Tab_User_Type__c> listTabUserType = new List<Tab_User_Type__c>();
        try{
            if(String.isNotBlank(fieldName)){
                String strQuery = 'SELECT Id, User_Type__c FROM Tab_User_Type__c where '+String.escapeSingleQuotes(fieldName)+'=:recordId';
                listTabUserType = Database.query(strQuery);
            }
            
        } 
        catch (Exception e) {
            HandleAllCustomException.logException(e,'Tab_User_Type__c', 'relatedData');
        } 
        return listTabUserType;
    }
    
}