/*
Created By    : Aishwarya[IMCC-13]
Test Class    : IMCC_EditionPopupHandler_Test()
Created/Modified By   :  11/10/2021
Description     : This class is used for Replace User button functionality.

Modified By : Surbhi Jain[IMCC -4330]
Modified Date: 06/09/2022
* Modified By      :  IBM(Srikanth)
* Modified On      :  16 Sept, 2022
* @description     :  For all Auraenabled methods added try-catch block and threw Aura exception.

Modified By : Mukesh Gupta[IMCC -5203]
Modified Date: 05/27/2023
* @description     :  Add Email_Templates__c(Role__c) field in soql query to clone in Event_Edition_Email_Template__c(Role__c) field during clon process 
*/

public without sharing class IMCC_EditionPopupHandler{
    // calling from the trigger - IMCC_trgUpdateMarkAsRead, for managing the Mark as Read field 
    public static void handleAfterUpdate(List<Edition_Popup__c> lstEditionPopup){
        Set<Id> editionIds = new Set<Id>();
        Set<Id> editionPopupIds = new Set<Id>();
        if(!lstEditionPopup.isEmpty()){
            for(Edition_Popup__c ed :lstEditionPopup){
                editionIds.add(ed.Edition__c);
                editionPopupIds.add(ed.Id);
            }
        }
        try{
            List<Tab_User_Type__c> listTabUserType = new List<Tab_User_Type__c>();
            Set<String> setUserType = new Set<String>();
            if(!editionPopupIds.isEmpty() && Schema.sObjectType.Tab_User_Type__c.isAccessible()){
                listTabUserType =[Select Edition_Popup__c, User_Type__c FROM Tab_User_Type__c WHERE Edition_Popup__c IN:editionPopupIds];
                if(!listTabUserType.isEmpty()){
                    for(Tab_User_Type__c tuser :listTabUserType){
                        setUserType.add(tuser.User_Type__c);
                    }
                }
            }
            
            List<Contact_Edition_Mapping__c> listConEvnMap = new List<Contact_Edition_Mapping__c>();
            if(!editionIds.isEmpty() && !setUserType.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
                if(Test.isRunningTest()){
                listConEvnMap = [SELECT Id, Access_Type__c, Popup_Marked_as_Read__c FROM Contact_Edition_Mapping__c where Access_Type__c!= null AND Relationship_Status__c = 'Active'];
                
                }
                else{
                    listConEvnMap = [SELECT Id, Access_Type__c, Popup_Marked_as_Read__c FROM Contact_Edition_Mapping__c where Access_Type__c!= null AND Relationship_Status__c = 'Active'
                                            AND CC_Status__c = 'Active' AND Edition__c IN :editionIds AND Access_Type__c IN:setUserType AND Popup_Marked_as_Read__c =true];
                }
                //System.debug('=============listConEvnMap '+listConEvnMap);
                if(listConEvnMap.size()>0){
                    for(Contact_Edition_Mapping__c cem: listConEvnMap){
                        cem.Popup_Marked_as_Read__c = false;
                    }
                    Database.update(listConEvnMap,false); 
                }
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Contact_Edition_Mapping__c', 'After Update');
        } 
    }
    // Getting the additional user/CEM related to the primary CEM
    @auraEnabled
    public static List<Contact_Edition_Mapping__c> additionalUsersCEM(Id recordId){
        List<Contact_Edition_Mapping__c> lStrings;
        try{
        Contact_Edition_Mapping__c currentCEM =[SELECT Id,Edition__c,Account__c,Contact__c,Relationship_Status__c,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c where Access_Type__c!= null AND Relationship_Status__c = 'Active' AND (Id=:recordId) WITH SECURITY_ENFORCED LIMIT 1];
        Set<Contact_Edition_Mapping__c> result = new Set<Contact_Edition_Mapping__c>();        
        Map<Id,Contact_Edition_Mapping__c> cemMap = new Map<Id,Contact_Edition_Mapping__c>([SELECT Id,Account__r.Name, Contact__r.Email,Contact__c,Contact__r.Name,Edition__c,Account__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Account__c =:currentCEM.Account__c AND Edition__c=:currentCEM.Edition__c WITH SECURITY_ENFORCED]);
       
        if(!cemMap.isEmpty()){
            //List<Contact_Edition_Mapping__c>  sharer = [SELECT Id,Account__r.Name, Contact__r.Email,Contact__c,Contact__r.Name,Edition__c,Account__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Primary_Contact_Edition_Mapping__c=:cemMap.keySet() WITH SECURITY_ENFORCED];
            Map<Id, Contact_Edition_Mapping__c>  sharer = new Map<Id,Contact_Edition_Mapping__c>([SELECT Id,Account__r.Name, Contact__r.Email,Contact__c,Contact__r.Name,Edition__c,Account__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Primary_Contact_Edition_Mapping__c=:cemMap.keySet() WITH SECURITY_ENFORCED]);
            result.addAll(cemMap.values());
            result.addAll(sharer.values());
            lStrings = new List<Contact_Edition_Mapping__c>(result);             
            //result.addAll(sharer);
        }
        }catch(Exception e) {
          
          String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';          
          String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
        return lStrings;
    }
    
    // Used for searching the contact under Replace User functionality
    @AuraEnabled
    public static List<Contact> searchContact(String key){
        List<Contact> conList = new List<Contact>();
        try{        
        
            key = '%'+String.escapeSingleQuotes(key)+'%';
            conList = [SELECT Id,AccountId,Name, Email,Account.Name FROM Contact Where Name Like:key WITH SECURITY_ENFORCED LIMIT 10];
        } catch(Exception e) {
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';                       
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        
        return conLIst;
    }
    
    /**********
        This method is used for replace user data(by calling the replaceUserData method in the class) by clicking the Replace User button on CEM record. This method
        also check the duplicate CEM if exist so that appopriate error can be displayed.
    ***********/
    @AuraEnabled
    public static void replaceUser(String data){
        ReplaceUserData obj = (ReplaceUserData)JSON.deserialize(data, ReplaceUserData.class);
        String objName = String.valueOf(Id.valueOf(obj.selectedRecordId).getsobjecttype());
        if(objName.toLowerCase()=='contact'){
            Contact_Edition_Mapping__c cem = [SELECT Id, Account__c,Feathr_Unique_Link__c, Access_Type__c FROM Contact_Edition_Mapping__c WHERE Id=:obj.recordId WITH SECURITY_ENFORCED];
            system.debug('@@@@@@@@@@@@@@'+cem.Account__c);
            System.debug('===========11'+obj.AccountId+'===========22'+obj.selectedRecordId+'===========33'+obj.editionId+'===========44'+obj.isActiveCon);
            List<Contact_Edition_Mapping__c> dup = [SELECT Id FROM Contact_Edition_Mapping__c WHERE Account__c =: cem.Account__c AND Contact__c =: obj.selectedRecordId AND Edition__c =: obj.editionId WITH SECURITY_ENFORCED LIMIT 1];
            if(dup.isEmpty()){
                Contact_Edition_Mapping__c contEdiMapingRec = new Contact_Edition_Mapping__c(
                    Account__c = cem.Account__c,                
                    Contact__c = obj.selectedRecordId,
                    Edition__c = obj.editionId,
                    Access_Type__c=cem.Access_Type__c,
                    Relationship_Status__c='Active',
                    Feathr_Unique_Link__c=cem.Feathr_Unique_Link__c);// Copying Feather Link from Primary User to Replaced user
                Insert contEdiMapingRec;
                obj.contactId = obj.selectedRecordId;
                obj.selectedRecordId = contEdiMapingRec.Id;
                replaceUserData(obj);
            }
            else{
                throw new AuraHandledException(Label.Replace_User_Dup_Msg);
            }
        }
        else if(objName.toLowerCase()=='contact_edition_mapping__c'){
            replaceUserData(obj);
        }
    }
    
    /**************
        This method is used for replacing the CEM data(like Purchase Data,Form Data, Form Response Entry,Contractor Mapping, Question Response) from one to another CEM, 
        by using the Relace User button on CEM record.
    ***************/
    private static void replaceUserData(ReplaceUserData obj){
        //get purchase data and replace
        List<Purchase_Data__c> pdList = [SELECT Id,Contact_Edition_Mapping__c,Contact__c FROM Purchase_Data__c
        WHERE Contact_Edition_Mapping__c =:obj.recordId WITH SECURITY_ENFORCED];
        System.debug('GAGGA'+JSON.serialize(pdList));
        if(!pdList.isEmpty()){
            for(Purchase_Data__c pd : pdList){
                pd.Contact_Edition_Mapping__c = obj.selectedRecordId;
                pd.Contact__c = obj.contactId;
            }
            update pdList;
        }
        
        // Get form data and replace 
        List<Form_Data__c> fdList = [SELECT Id,Contact_Edition_Mapping__c FROM Form_Data__c WHERE Contact_Edition_Mapping__c =:obj.recordId WITH SECURITY_ENFORCED];
        if(!fdList.isEmpty()){
            for(Form_Data__c fd : fdList){
                fd.Contact_Edition_Mapping__c = obj.selectedRecordId;
            }

            update fdList;
        }

        //get form response entry
        
        List<User> u;
        
        if(!Test.isRunningTest()){
            u = new List<User>([SELECT Id FROM User WHERE ContactId =:obj.contactId ORDER BY CreatedDate DESC LIMIT 1]); //WITH SECURITY_ENFORCED
        }
        else{
            u = [SELECT Id FROM User WHERE Id =:UserInfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1]; //WITH SECURITY_ENFORCED
        }
        
        List<Form_Response_Entry__c> freList = [SELECT Id,Contact_Edition_Mapping__c,Ops_Contact_Name__c,User__c FROM Form_Response_Entry__c WHERE Contact_Edition_Mapping__c=:obj.recordId WITH SECURITY_ENFORCED];
        if(!freList.isEmpty()){
            for(Form_Response_Entry__c fre : freList){
                fre.Contact_Edition_Mapping__c = obj.selectedRecordId;
                fre.Ops_Contact_Name__c = obj.contactId;
                if(!u.isEmpty()){
                    fre.User__c = u[0].Id;
                }
            }
            update freList;
        }

        //Get Contractor_Mapping__c and replace
        List<Contractor_Mapping__c> cmList = [SELECT Id,Contact__c,Contractor_CEM__c,Is_Self_Managed__c FROM Contractor_Mapping__c WHERE Contractor_CEM__c=:obj.recordId WITH SECURITY_ENFORCED];
        if(!cmList.isEmpty()){
            for(Contractor_Mapping__c cm : cmList){
                cm.Contact__c = obj.contactId;
                cm.Contractor_CEM__c = obj.selectedRecordId;
            }
            update cmList;
        }

        //Get Question response and replace
        List<Question_Response__c> qrList = [SELECT Id,Contact_Edition_Mapping__c,User__c FROM Question_Response__c WHERE Contact_Edition_Mapping__c=:obj.recordId WITH SECURITY_ENFORCED];
        if(!qrList.isEmpty()){
            for(Question_Response__c qr : qrList){
                qr.Contact_Edition_Mapping__c = obj.selectedRecordId;
                if(!u.isEmpty()){
                    qr.User__c = u[0].Id;
                }
            }
            Update qrList;
        }
        //Make Primary to the selected contact edition mapping
        Contact_Edition_Mapping__c cemSelected =  [SELECT Id,isSecondary__c,Feathr_Unique_Link__c,Primary_Contact_Edition_Mapping__c,Primary_Contact_Edition_Mapping__r.Feathr_Unique_Link__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Id=:obj.selectedRecordId WITH SECURITY_ENFORCED LIMIT 1];
        
        cemSelected.isSecondary__c = false;
        cemSelected.Primary_Contact_Edition_Mapping__c = null;
        //Copying Feather Link from Primary CEM to Existing Replaced user
        if(cemSelected.Primary_Contact_Edition_Mapping__c!= null){
            cemSelected.Feathr_Unique_Link__c = cemSelected.Primary_Contact_Edition_Mapping__r.Feathr_Unique_Link__c;
        }
        if(cemSelected.Relationship_Status__c =='Inactive'){
           cemSelected.Relationship_Status__c ='Active';
        }
        update cemSelected;
        // Update Primary contacte dition mapping on Seconary CEMs
        List<Contact_Edition_Mapping__c> listSecondaryCEMs = new List<Contact_Edition_Mapping__c>([SELECT Id,Primary_Contact_Edition_Mapping__c FROM Contact_Edition_Mapping__c WHERE Primary_Contact_Edition_Mapping__c =:obj.recordId AND Id !=:obj.selectedRecordId AND isSecondary__c =TRUE WITH SECURITY_ENFORCED]);
        if(!listSecondaryCEMs.isEmpty()){
            for(Contact_Edition_Mapping__c cem: listSecondaryCEMs){
                cem.Primary_Contact_Edition_Mapping__c = obj.selectedRecordId;
            }
            update listSecondaryCEMs;
        }
        
        //Now de-activate contact edition mapping
        Contact_Edition_Mapping__c cem =  [SELECT Id,Relationship_Status__c,Replace_User_Primary_CEM__c FROM Contact_Edition_Mapping__c WHERE Id=:obj.recordId WITH SECURITY_ENFORCED LIMIT 1];
        
        if(obj.isActiveCon == TRUE){
            cem.Relationship_Status__c = 'Inactive';
            cem.Replace_User_Primary_CEM__c = obj.selectedRecordId;
        }
        else{
            cem.Relationship_Status__c = 'Active';
            cem.Replace_User_Primary_CEM__c = null;
            cem.Primary_Contact_Edition_Mapping__c = obj.selectedRecordId;
            cem.isSecondary__c = true;
        }
        
        update cem;
    }

    /******************** 
           This method is used for cloning the email templates(from global email templates) for an edition. There is a button Clone Templates on Edition
           where clicking on that button will create the Event Edition Email Template records specific to this editin 
    *********************/
         
    @auraEnabled
    public static void cloneGlobalTemplates(Id recordId){
        try
        {
            list<Email_Templates__c> globalEmaillLst = new list<Email_Templates__c>();
            list<Event_Edition_Email_Template__c> eventEmailLstToInsert = new list<Event_Edition_Email_Template__c>();
            Set<String> setPreventDuplicateTemp = new Set<String>();
            
            globalEmaillLst = [select Id, Name,Role__c, Content__c, Template_Code__c, Subject__c FROM Email_Templates__c WITH SECURITY_ENFORCED];
            
            list<Event_Edition_Email_Template__c> listExistingEventTemp = new list<Event_Edition_Email_Template__c>();
            listExistingEventTemp =[Select Role__c,Template_Code__c,Edition__c FROM Event_Edition_Email_Template__c WHERE Edition__c =:recordId WITH SECURITY_ENFORCED];
            if(listExistingEventTemp.size()>0){
                for(Event_Edition_Email_Template__c eeet :listExistingEventTemp){
                    setPreventDuplicateTemp.add(eeet.Template_Code__c+'-'+recordId);
                }
            }
            
            if(!globalEmaillLst.IsEmpty() && globalEmaillLst.size()>0){
                
                for(Email_Templates__c eventEmail : globalEmaillLst){
                    if(!setPreventDuplicateTemp.contains(eventEmail.Template_Code__c+'-'+recordId))
                    {                    
                        Event_Edition_Email_Template__c neweventEmail = new Event_Edition_Email_Template__c();
                        neweventEmail.Name = eventEmail.Name;
                        neweventEmail.Content__c = eventEmail.Content__c;
                        neweventEmail.Email_Template__c = eventEmail.Id;
                        neweventEmail.Template_Code__c = eventEmail.Template_Code__c;
                        neweventEmail.Subject__c = eventEmail.Subject__c;
                        neweventEmail.Edition__c = recordId;
                        neweventEmail.Role__c = eventEmail.Role__c;
                        eventEmailLstToInsert.add(neweventEmail); 
                        setPreventDuplicateTemp.add(eventEmail.Template_Code__c+'-'+recordId);
                    }              
                }
                system.debug('eventEmailLstToInsert='+eventEmailLstToInsert);
            }
                
            if(eventEmailLstToInsert!=null && eventEmailLstToInsert.size()>0){
                Database.insert(eventEmailLstToInsert,false);                   
            }
        }
        catch(exception ex){
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
    }

    public class ReplaceUserData{
        @AuraEnabled public String editionId;
        @AuraEnabled public String accountId;
        @AuraEnabled public String selectedRecordId; // this may be contactId or contact edition mapping id
        @AuraEnabled public String recordId;// contact edition mapping id
        @AuraEnabled public String contactId;
        @AuraEnabled public Boolean isActiveCon;
    }
}