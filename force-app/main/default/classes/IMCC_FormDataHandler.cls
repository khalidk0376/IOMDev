/**
@description   IMCC_FormDataHandler
Created By    : Aishwarya[IMCC-]
Test Class    : IMCC_FormDataHandler_Test()
Created/Modified Date   :  21//11/2021
Code Coverage - 95%
*/

public without sharing class IMCC_FormDataHandler{

    /**
    * @description  handle Tab User Type After Insert.
    * @param  lstTabUserType
    */
    public static void handleAfterInsert(List<Tab_User_Type__c> lstTabUserType){
        Set<Id> setTabUserTypeIds = new Set<Id>();
        Set<String> setFormAlocIds = new Set<String>();
        Map<String,Id> setUTypeAndFormFormId = new Map<String,Id>();
        List<Forms_Permission__c> listFormPermissionToInsert = new List<Forms_Permission__c>();
        List<Forms_Permission__c> listFormPermissionToUpdate = new List<Forms_Permission__c>();
        List<Forms_Permission__c> listFormPermission = new List<Forms_Permission__c>();
        
        for(Tab_User_Type__c tUserType : lstTabUserType){
            setTabUserTypeIds.add(tUserType.Id);
            setFormAlocIds.add(tUserType.Form_Allocation__c);
        }
        
        if(!setFormAlocIds.isEmpty()){
            listFormPermission = [SELECT Id, Form_Allocation__c, User_Type1__c, Is_Active__c FROM Forms_Permission__c WHERE Form_Allocation__c IN:setFormAlocIds WITH SECURITY_ENFORCED];
            for(Forms_Permission__c fp : listFormPermission){
                String key = fp.User_Type1__c + '-' + fp.Form_Allocation__c;
                setUTypeAndFormFormId.put(key,fp.Id);
            }
        }
        
        for(Tab_User_Type__c tabUType : lstTabUserType){
            String key = tabUType.User_Type__c +'-'+ tabUType.Form_Allocation__c;
            if(!setUTypeAndFormFormId.containsKey(key))
            {
                // initialize form permission object
                Forms_Permission__c formPermission = new Forms_Permission__c();
                formPermission.Form_Allocation__c = tabUType.Form_Allocation__c;
                formPermission.User_Type1__c = tabUType.User_Type__c;
                formPermission.Tab_User_Type__c = tabUType.Id;
                formPermission.Is_Active__c = true;
                listFormPermissionToInsert.add(formPermission);
            }
            else{
                Forms_Permission__c formPermission = new Forms_Permission__c();
                formPermission.Id = setUTypeAndFormFormId.get(key);
                formPermission.Tab_User_Type__c = tabUType.Id;
                formPermission.Is_Active__c = true;
                listFormPermissionToUpdate.add(formPermission);
            }
        }
        try{
            if(!listFormPermissionToInsert.isEmpty() && Schema.sObjectType.Forms_Permission__c.isCreateable()){
                insert listFormPermissionToInsert; // Insert List
            }
            if(!listFormPermissionToUpdate.isEmpty() && Schema.sObjectType.Forms_Permission__c.isUpdateable()){
                update listFormPermissionToUpdate;
            }
        }catch(exception ex){ex.getMessage();}
     }
     
     /**
    * @description  handle Form Allocation After Update.
    * @param  listFormAllocNew
    * @param  mapOldFormAllocation
    */
    public static void handleAfterFormAllocUpdate(List<Form_Allocation__c> listFormAllocNew, Map<Id,Form_Allocation__c> mapOldFormAllocation){
        //List<Form_Allocation__c> listFormAlloc = new List<Form_Allocation__c>();
        Set<String> setFormAlocIds = new Set<String>();
        List<Forms_Permission__c> listFormPermission = new List<Forms_Permission__c>();
        
        for(Form_Allocation__c formAlloc : listFormAllocNew){
            if(formAlloc.Booth_Product_Types__c != mapOldFormAllocation.get(formAlloc.Id).Booth_Product_Types__c){
                setFormAlocIds.add(formAlloc.Id);
                //listFormAlloc.add(formAlloc);
            }
        }
        
        if(!setFormAlocIds.isEmpty()){
            listFormPermission = [SELECT Id, Form_Allocation__c, User_Type1__c FROM Forms_Permission__c WHERE Form_Allocation__c IN: setFormAlocIds];
        }
        
        try{
            if(!listFormPermission.isEmpty() && Schema.sObjectType.Forms_Permission__c.isUpdateable()){
                Database.update(listFormPermission,false);
            }
         }catch(exception ex){ex.getMessage();}
      }
     
    /**
    * @description  handle Tab User Type After Delete.
    * @param  lstTabUserType
    */
     public static void handleAfterDeleteTabUserType(List<Tab_User_Type__c> lstTabUserType){
        try{
            Set<Id> setFormAllocIds = new Set<Id>();
            List<Forms_Permission__c> listFormPermission = new List<Forms_Permission__c>();
            for(Tab_User_Type__c tUtype : lstTabUserType){
                setFormAllocIds.add(tUtype.Form_Allocation__c);
            }
            
            if(!setFormAllocIds.isEmpty()){
                listFormPermission = [SELECT Id FROM Forms_Permission__c WHERE Form_Allocation__c IN:setFormAllocIds AND Tab_User_Type__c=null WITH SECURITY_ENFORCED];
                for(Forms_Permission__c fp : listFormPermission){
                    fp.Is_Active__c = false;
                }
            }
            
            if(!listFormPermission.isEmpty() && Schema.sObjectType.Forms_Permission__c.isUpdateable()){
                update listFormPermission;
            }
        }catch(exception ex){ex.getMessage();}
     }

     /**
    * @description  handle Tab User Type Before update.
    * @param  lstTabUserType
    * @param  mapOldTabUserType
    */
    public static void handleBeforeUpdateTabUserType(List<Tab_User_Type__c> lstTabUserType, Map<Id,Tab_User_Type__c> mapOldTabUserType){
        for(Tab_User_Type__c tUtype : lstTabUserType){
            if(tUtype.User_Type__c != mapOldTabUserType.get(tUtype.Id).User_Type__c){
                tUtype.addError('Can not update user type.Please delete and insert entry for new user type.');
            }
        }
     }
}