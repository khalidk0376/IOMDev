/**
* Created/Modified By: Girikon(Garima)
* Created On:          9/9/2021
* @description  : This class provides following functionalities:
*                      It will fetch all the accounts related to login user from Contact Edition Mapping to be selected by login user.
*                      Also it will fetch the edition details to show on footer and header.
* Methods:             fetchAccountFromEditionMapping, getEditionDetails
* Modified By      :  IBM(Srikanth),[Aishwarya Girikon 27 March 2023 IMCC-5042]
* Modified On      :   16 Sept, 2022
* @description  :      For all Auraenabled methods added try-catch block and threw Aura exception.
* Apex Class:          IMCC_AccountSelectionCtrl 
* Apex Test Class:     IMCC_AccountSelectionCtrl_Test (93%)
**/
public without sharing class IMCC_AccountSelectionCtrl { 
    
    /**
    * @description : to fetch Active Account Data from Contact Edition Mapping
    * @param eventcode 
    * @return : List<Account>
    **/
    @AuraEnabled
    public static List<Account> fetchAccountFromEditionMapping(String eventcode){
        Set<id> accId = new Set<id>();
        try{
            id userId = UserInfo.getUserId();
            User u = [select id, contactId from User where id = : userId WITH SECURITY_ENFORCED];
            
            id getContactId = u.contactId; 
            List<Contact_Edition_Mapping__c> conEdMapLst = new List<Contact_Edition_Mapping__c>();
            if(String.isNotBlank(getContactId)){
                string strQuery='SELECT Id,Account__c, Contact__c,Primary_Contact_Edition_Mapping__c,Edition__r.Edition_Code__c FROM Contact_Edition_Mapping__c WHERE Contact__c =\''+ String.escapeSingleQuotes(getContactId)+'\'';
                strQuery +=' AND Edition__r.Edition_Code__c != null';
                strQuery +=' AND Relationship_Status__c = \'Active\'';
                if(string.isNotBlank(eventcode)){
                    strQuery +=' AND Edition__r.Edition_Code__c =\''+String.escapeSingleQuotes(eventcode)+'\'';
                }

                conEdMapLst = Database.query(strQuery);
            }
            //add primary contact edition mapping record 
            /*List<Id> ids = new List<Id>();
            for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
                if(String.isNotBlank(conEdMap.Primary_Contact_Edition_Mapping__c)){
                    ids.add(conEdMap.Primary_Contact_Edition_Mapping__c);
                }
            }
            if(!ids.isEmpty()){
                conEdMapLst.add([SELECT Account__c FROM Contact_Edition_Mapping__c WHERE Id IN:ids WITH SECURITY_ENFORCED]);
            }*/
            for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
                accId.add(conEdMap.Account__c);            
            }
        }
        catch(Exception e){
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';          
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return [Select id,Name,BillingCountry from Account where id IN : accId AND Inactive__c=false WITH SECURITY_ENFORCED];        
    }

    /**
    * @description : to fetch Active Account Data from Contact Edition Mapping, Mukesh Gupta[27 dec, 2021, IMCC-662]
    * @param eventcode
    * @return : Map<String,Object>     
    **/
    @AuraEnabled
    public static Map<String,Object> fetchAccounts(String eventcode){
        Map<String,Object> mapReturn = new Map<String,Object>();
        try{
        
        Set<id> accId = new Set<id>();
        List<Account> accLst = new List<Account>();
        User u = [SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED];        
        Id getContactId = u.contactId;
        List<Contact_Edition_Mapping__c> conEdMapLst = new List<Contact_Edition_Mapping__c>();
        if(String.isNotBlank(getContactId)){
            String strQuery='SELECT Id,Account__c,Account__r.Name,Primary_Contact_Edition_Mapping__c, Contact__c,Edition__r.Edition_Code__c,Edition__r.Name,Edition__r.Customer_Center_Status__c,isTestUser__c FROM Contact_Edition_Mapping__c WHERE Contact__c =\''+ String.escapeSingleQuotes(getContactId)+'\'';
            strQuery +=' AND Edition__r.Edition_Code__c != null';
            strQuery +=' AND Relationship_Status__c = \'Active\'';
            if(string.isNotBlank(eventcode)){
                strQuery +=' AND Edition__r.Edition_Code__c =\''+String.escapeSingleQuotes(eventcode)+'\'';
            }
            conEdMapLst = Database.query(strQuery+' WITH SECURITY_ENFORCED');
            for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
                accId.add(conEdMap.Account__c);            
            }
        }
        //add primary contact edition mapping record 
        /*List<Id> ids = new List<Id>();
        for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
            if(String.isNotBlank(conEdMap.Primary_Contact_Edition_Mapping__c)){
                ids.add(conEdMap.Primary_Contact_Edition_Mapping__c);
            }
        }
        if(!ids.isEmpty()){
            conEdMapLst.add([SELECT Account__c FROM Contact_Edition_Mapping__c WHERE Id IN:ids WITH SECURITY_ENFORCED]);
        }*/        

        if(!accId.isEmpty()){
            accLst  = [SELECT Id,Name,BillingCountry FROM Account WHERE Id IN : accId AND Inactive__c=false WITH SECURITY_ENFORCED ORDER BY Name ASC];
        }
        mapReturn.put('acc',accLst);
        mapReturn.put('cem',conEdMapLst);   
        
    } catch(exception ex){
        String stackTrace = ex.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
    return mapReturn;
    }

    /**
    * @description : to get Edition Details to show on Header and Footer
    * @param eventcode
    * @return : RecordDataTableWrapper
    **/
    @AuraEnabled
    public static RecordDataTableWrapper getEditionDetails(String eventcode) {
        RecordDataTableWrapper objDT =  new RecordDataTableWrapper();
        try{
        if(string.isNotBlank(eventCode))
        {   
            List<Edition__c> edLst;
            //Instagram__c add custom field in query by Mukesh[20 Dec, 2021]
            
            edLst = [SELECT id,Name,End_Date__c,Edition_Image_URL__c,Venue__c,Start_Date__c,Edition_Description__c,Background_Colour__c,Text_Colour__c,Show_Hours__c,FaceBook__c,LinkedIn__c,Twitter__c,YouTube__c,Instagram__c FROM Edition__c WHERE Edition_Code__c =:eventcode AND Edition_Status__c='Confirmed' WITH SECURITY_ENFORCED];
            
            if(edLst!=null && edLst.size()>0)
            {
                objDT.event = edLst[0];
                objDT.editionWeb = [Select Edition__c,Website_Label__c,Website_Link__c,Sequence__c from Edition_Websites__c where Edition__c =: objDT.event.Id Order By Sequence__c asc];
                List<Show_Timing__c> showTimingOnlineList = [SELECT Id,Show_Date__c,Show_Hours__c,Edition__c,Sort_order__c FROM Show_Timing__c 
                                                           WHERE Edition__c =: edLst[0].Id AND Show_Type__c ='Live' order by Sort_order__c ASC ];
                if(showTimingOnlineList.size() > 0){
                    System.debug(LoggingLevel.Debug, '--showTimingOnlineList[0]-'+showTimingOnlineList[0]);
                    objDT.showTimingOnlineLst = showTimingOnlineList;
                }
                List<Show_Timing__c> showTimingLiveList = [SELECT Id,Show_Date__c,Show_Hours__c,Edition__c,Sort_order__c FROM Show_Timing__c 
                                                           WHERE Edition__c =: edLst[0].Id AND Show_Type__c ='Online' order by Sort_order__c ASC ];
                if(showTimingLiveList.size() > 0){
                    System.debug(LoggingLevel.Debug, '--showTimingLiveList[0]-'+showTimingLiveList[0]);
                    objDT.showTimingLiveLst = showTimingLiveList;
                }              
            }
        }    
    }catch(exception ex){
        String stackTrace = ex.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
        
        return objDT;
    }
    
    /**@description Wrapper Class For Edition Details*/
    public class RecordDataTableWrapper {
        /**@description editionWeb*/
        @AuraEnabled
        public List<Edition_Websites__c> editionWeb{get;set;}
        /**@description event*/
        @AuraEnabled
        public Edition__c event{get;set;}
        /**@description showTimingOnlineLst*/
        @AuraEnabled
        public List<Show_Timing__c> showTimingOnlineLst{get;set;}
        /**@description showTimingLiveLst*/
        @AuraEnabled
        public List<Show_Timing__c> showTimingLiveLst{get;set;}
    }
    
    /**
    * @description : to get Events associated with selected Account when user logging in from non branded page.
    * @param accountId
    * @return : List<Edition__c>
    **/
    @AuraEnabled
    public static List<Edition__c> fetchEventFromEditionMapping(String accountId){
        Set<id> evtIds = new Set<id>();
        try{
            User u = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED];
            
            Id getContactId = u.ContactId;
            if(getContactId!=null && String.isNotBlank(accountId)){
                string strQuery = 'SELECT Id, Account__c, Contact__c, Edition__r.Edition_Code__c FROM Contact_Edition_Mapping__c WHERE Contact__c = \''+ String.escapeSingleQuotes(getContactId)+'\'';
                strQuery +=' AND Edition__r.Edition_Code__c != null';
                strQuery +=' AND Relationship_Status__c = \'Active\'';
                strQuery +=' AND Account__c = \''+ String.escapeSingleQuotes(accountId)+'\' WITH SECURITY_ENFORCED';
                
                List<Contact_Edition_Mapping__c> conEdMapLst = Database.query(strQuery);
                
                for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
                    evtIds.add(conEdMap.Edition__c);
                }
            }
        }
        catch(exception ex){
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }      
        return [SELECT Id,Name,Start_Date__c,End_Date__c,Edition_Code__c,Venue__c,Edition_Status__c,Customer_Center_Status__c
         FROM Edition__c WHERE Id IN : evtIds AND Edition_Status__c = 'Confirmed' 
         AND (Customer_Center_Status__c = 'Active' OR Customer_Center_Status__c = 'In Progress') WITH SECURITY_ENFORCED ORDER BY Name ASC];
    }
    

    /**
    * @description : to get Events associated with selected Account when user logging in from non branded page.
    * @param accountId
    * @return : List<Edition__c>
    **/
    @AuraEnabled
    public static Map<String,Object> fetchEventList(String accountId){
        Map<String,Object> returnMap; 
        try{
        Set<id> evtIds = new Set<id>();
        User u = [SELECT Id, ContactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED];
        
        Id getContactId = u.ContactId;
        List<String> accessType = new List<String>();
        List<String> cemId = new List<String>();
        List<String> eventSettingId = new List<String>();
        Boolean checkTestUser = false;
        Set<string> setTestUserEvents = new Set<string>();
        List<Contact_Edition_Mapping__c> conEdMapLst = new List<Contact_Edition_Mapping__c>();
        if(String.isNotBlank(getContactId)){
            //check is user secondary
            String strQuery = 'SELECT Id, Access_Type__c,Primary_Contact_Edition_Mapping__c,Primary_Contact_Edition_Mapping__r.Completed_Purchase_Summaries__c, Account__c, Contact__c, Edition__c, Edition__r.Edition_Code__c,Completed_Purchase_Summaries__c,Edition__r.Company_Profile_Submission_Due_Date__c,Edition__r.Due_Date__c,Edition__r.Event_Setting__c,isTestUser__c,Role__c FROM Contact_Edition_Mapping__c WHERE Contact__c = \''+ String.escapeSingleQuotes(getContactId)+'\'';
            strQuery +=' AND Edition__r.Edition_Code__c != null';
            strQuery +=' AND Relationship_Status__c = \'Active\'';
            strQuery +=' AND Account__c = \''+ String.escapeSingleQuotes(accountId)+'\' WITH SECURITY_ENFORCED';
            
            conEdMapLst = Database.query(strQuery);

            //List<String> isSecondaryMap = new List<String>();
            for(Contact_Edition_Mapping__c conEdMap :conEdMapLst){
                evtIds.add(conEdMap.Edition__c);            
                accessType.add(conEdMap.Access_Type__c);
                cemId.add(conEdMap.Id);
                if(String.isNotBlank(conEdMap.Primary_Contact_Edition_Mapping__c)){
                    cemId.add(conEdMap.Primary_Contact_Edition_Mapping__c);
                }
                eventSettingId.add(conEdMap.Edition__r.Event_Setting__c);
                //IMCC-5042 checking if Login user is a Test User
                if(conEdMap.isTestUser__c == true){
                    checkTestUser = true;
                    setTestUserEvents.add(conEdMap.Edition__c);
                }
            }
        }
        
        Map<Id,Forms_Permission__c> formMap = new Map<Id,Forms_Permission__c>([SELECT Id FROM Forms_Permission__c WHERE (Form_Allocation__r.Feature_Category__c='Form' OR Form_Allocation__r.Feature_Category__c='Manual') AND Tab_User_Type__r.User_Type__c IN:accessType AND Is_Active__c=true AND Form_Allocation__r.Form_Status__c='Visible' WITH SECURITY_ENFORCED]);
        List<Form_Data__c> formDatas = new List<Form_Data__c>();
        
        formDatas = [SELECT Id,Status1__c,Edition__c,Edition__r.Name,
                    Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c 
                    FROM Form_Data__c WHERE Contact_Edition_Mapping__c IN:cemId AND 
                    Edition__c IN:evtIds AND Forms_Permission__r.Form_Allocation__r.Form_Status__c = 'Visible' AND
                    Forms_Permission__c IN:formMap.keySet() AND Forms_Permission__r.Form_Allocation__r.Form_Heading__c='Mandatory' AND 
                    Is_Active__c=true AND Not_Applicable__c=false WITH SECURITY_ENFORCED];
        //Due_Date__c => Badge Submission due date
        
        List<Edition__c> edlist;
        //IMCC-5042
        if(checkTestUser == true){
            edlist = [SELECT Id,Name,Start_Date__c,End_Date__c,Edition_Code__c,Venue__c,Edition_Status__c,Customer_Center_Status__c,Event_Setting__c,Company_Profile_Submission_Due_Date__c,Due_Date__c FROM Edition__c WHERE (Id IN : setTestUserEvents AND Edition_Status__c = 'Confirmed' AND Customer_Center_Status__c = 'In Progress') OR (Id IN : evtIds AND Edition_Status__c = 'Confirmed' AND Customer_Center_Status__c = 'Active') WITH SECURITY_ENFORCED ORDER BY Name ASC];
        }
        else{
            edlist = [SELECT Id,Name,Start_Date__c,End_Date__c,Edition_Code__c,Venue__c,Edition_Status__c,Customer_Center_Status__c,Event_Setting__c,Company_Profile_Submission_Due_Date__c,Due_Date__c FROM Edition__c WHERE Id IN : evtIds AND Edition_Status__c = 'Confirmed' AND Customer_Center_Status__c = 'Active' WITH SECURITY_ENFORCED ORDER BY Name ASC];
        }
        List<Purchase_Summary__c> pslist = [SELECT Id,Event_Setting__c,Is_Active__c,Purchase_Summary_Type__c,Event_Tab__c FROM Purchase_Summary__c WHERE Event_Setting__c IN : eventSettingId WITH SECURITY_ENFORCED ORDER BY Name ASC];

        List<String> standardTabTypes = new List<String>{'Badge Registration','Virtual Event'};
        List<Tab_User_Type__c> tabUserTypeList = [SELECT Id,Event_Tab__r.Standard_Tab_Type__c,Event_Tab__r.Tab_Code__c,Event_Tab__r.Event_Setting__c,User_Type__c FROM Tab_User_Type__c WHERE Event_Tab__r.Event_Setting__c =:eventSettingId AND Event_Tab__r.Is_Tab_Active__c = true AND Event_Tab__r.Is_Tab_Visible__c = true AND Event_Tab__r.Standard_Tab_Type__c IN:standardTabTypes  WITH SECURITY_ENFORCED];

        List<AggregateResult> listVirtualPdAggr = [SELECT Booth_Product_Type__c, Count(Id),Edition__c  FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:cemId AND (Booth_Number__c = '' OR Booth_Number__c = null) AND Booth_Product_Type__c != 'Lead Retrieval' AND Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' WITH SECURITY_ENFORCED Group BY Booth_Product_Type__c,Edition__c];

        List<Purchase_Data__c> listPdBadges = [SELECT Id,Edition__c FROM Purchase_Data__c WHERE Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' AND Contact_Edition_Mapping__c IN:cemId AND Booth_Product_Type__c != 'Lead Retrieval' WITH SECURITY_ENFORCED];

        returnMap = new Map<String,Object>{
            'eventList' => edlist,
            'formData' =>formDatas,
            'cemList' =>conEdMapLst,
            'pslist' =>pslist,
            'listVirtualPdAggr' =>listVirtualPdAggr,
            'listPdBadges' =>listPdBadges,
            'tabUserTypeList' => tabUserTypeList
        };
    }catch(exception ex){

        String stackTrace = ex.getStackTraceString().substringBefore('\n');
        String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
        throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
    }
        return returnMap;

    }

    /**
    * @description : to get Edition name for the eventcode
    * @param eventcode
    * @return : Edition Name
    */
    @AuraEnabled
    public static string getEditionName(string eventcode){
        String editionName = '';
        List<Edition__c> listEdition = new List<Edition__c>();
        try{
            if(string.isNotBlank(eventCode) && Edition__c.SObjectType.getDescribe().isAccessible()){
                listEdition = [SELECT id,Name,Edition_Code__c FROM Edition__c WHERE Edition_Code__c =:eventcode limit 1];
                System.debug(LoggingLevel.Debug, 'listEdition: '+listEdition);
            }
            if(!listEdition.isEmpty()){
                editionName = listEdition[0].Name;
                System.debug(LoggingLevel.Debug, 'editionName: '+editionName);
            }
        }
        catch(exception ex){
            String stackTrace = ex.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():''; 
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return editionName;      
    }
}