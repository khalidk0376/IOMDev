/**
* Created By       :   Girikon(Mukesh)
* Created On:          18/01/2022
* Modified By      :   Girikon(Mukesh,Arushi [IMCC-4511])
* Modified On      :   18/01/2022, 5/Sept/2022
* @description     :   This class use to fetch active Announcements that will visible on home page
* Methods          :   getAnnouncements()
* Apex Class       :   IMCC_HomeCtrl 
* Apex Test Class  :   IMCC_HomeCtrl_Test (96%)
**/
public without sharing class IMCC_HomeCtrl {
    
    /**
    * @description  get Announcements
    * @param eventCode
    * @param accountId
    * @return  Map<String, object>
    */
    @AuraEnabled(cacheable=false)
    public static Map<String, object> getAnnouncements(String eventCode,String accountId){
        List<Announcement__c> announcementList = new List<Announcement__c>();
        
        //get contact id of logged in user
        User userObj = [SELECT ContactId FROM User WHERE Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED];
        //get ContactEditionMapping map of logged in user
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        //get ContactEditionMapping of logged in user
        Contact_Edition_Mapping__c cem = (Contact_Edition_Mapping__c) mapCEMDetails.get('cem');
        //get ContactEditionMapping Ids of logged in user
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
        //commented for primary contact edition mapping logic implement [16 Jun 2022]
        //get User type/ access type, if you want to get booth product type then query on purchase data        
        // List<Purchase_Data__c> boothList = [SELECT Booth_Product_Type__c,User_Type__c FROM Purchase_Data__c 
        // WHERE Contact__c=:userObj.ContactId AND Edition__r.Edition_Code__c=:String.escapeSingleQuotes(eventCode) 
        // AND Account__c=:String.escapeSingleQuotes(accountId) AND Purchase_Status__c='Active' WITH SECURITY_ENFORCED];
        // System.debug(LoggingLevel.debug, '@@'+boothList);

        //Add on 16 Jun 2022
        //Purchase Data List of Logged in User
        try{
        List<Purchase_Data__c> boothList = [SELECT Booth_Product_Type__c,User_Type__c FROM Purchase_Data__c 
         WHERE Contact_Edition_Mapping__c IN :cemIds AND Purchase_Status__c='Active' AND Transaction_Status__c='Active' WITH SECURITY_ENFORCED];
            if(!boothList.isEmpty()){
                Set<String> userType = new Set<String>();
                String boothProductType = '';
                for(Purchase_Data__c booth : boothList){
                    if(booth.User_Type__c!=null && booth.User_Type__c!=''){
                        userType.add(booth.User_Type__c);
                    }
                    if((booth.Booth_Product_Type__c!=null && booth.Booth_Product_Type__c!='') && boothProductType.indexOf('\''+booth.Booth_Product_Type__c+'\'')<0){
                        boothProductType+= boothProductType==''?String.escapeSingleQuotes(booth.Booth_Product_Type__c):'\',\''+String.escapeSingleQuotes(booth.Booth_Product_Type__c);
                    }
                }
                System.debug(LoggingLevel.debug, 'userType: '+userType); 
                List<Id> announcementIds = new List<Id>();
                
                List<Tab_User_Type__c> listTabUserType =[SELECT Announcement__c FROM Tab_User_Type__c WHERE Announcement__c!=null AND Announcement__r.Edition__r.Edition_Code__c =:eventCode AND User_Type__c IN:userType WITH SECURITY_ENFORCED];
                for(Tab_User_Type__c tuser :listTabUserType){                
                    announcementIds.add(tuser.Announcement__c);
                }
                System.debug(LoggingLevel.debug, '@@@'+listTabUserType); 
                System.debug(LoggingLevel.debug, 'announcementIds: '+announcementIds);            
                System.debug(LoggingLevel.debug, 'boothProductType:: '+boothProductType);  
                
                //Query on Announcement where Id IN:announcementIds         
                announcementList = Database.query('SELECT Name, Title__c,Sub_Header_Text__c, Description__c,Announcement_Date__c,URL__c,URL_Label__c,Booth_Product_Types__c, '+
                ' Event_Tab__c,Link_Type__c,Event_Tab__r.Tab_Type__c,Event_Tab__r.Standard_Tab_Type__c,Event_Tab__r.Tab_Code__c,Expiration_Date__c FROM Announcement__c '+ 
                ' WHERE Id IN:announcementIds AND Is_Active__c=true AND Announcement_Date__c<=TODAY AND Expiration_Date__c>=TODAY'+
                ' AND (Booth_Product_Types__c=\'\' OR Booth_Product_Types__c includes(\''+boothProductType+'\')) WITH SECURITY_ENFORCED ORDER BY Announcement_Date__c DESC');
            }
        }
        catch(Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';                       
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        
        return new map<String, object>{
            'contactCEMId'=> userObj.ContactId +'_'+ cEM.Id,
            'announcementList'=> announcementList};
    }

    /**
    * @description  get TabContext
    * @param eventCode
    * @param accountId
    * @param tabId
    * @return  List<Tab_Context__c>
    */
    @AuraEnabled
    public static List<Tab_Context__c> getTabContext(String eventCode, String accountId,String tabId){
        
        List<Tab_Context__c> tcList  = new List<Tab_Context__c>();  
        try{   
            //get ContactEditionMapping map of logged in user
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
            //get ContactEditionMapping of logged in user
            List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
            //get ContactEditionMapping Ids of logged in user
            Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');

            if(!conEdMapLst.isEmpty())
            {
                //Purchase Data List of Logged in User
                List<Purchase_Data__c> purchaseLst = [SELECT id,Contact_Edition_Mapping__c,Purchase_Status__c,Booth_Product_Type__c,Transaction_Status__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN: cemIds AND Transaction_Status__c = 'Active' AND Purchase_Status__c = 'Active' WITH SECURITY_ENFORCED];
            
                String boothProductType = '';
                for(Purchase_Data__c booth : purchaseLst){                
                    if((booth.Booth_Product_Type__c!=null && booth.Booth_Product_Type__c!='') && boothProductType.indexOf('\''+booth.Booth_Product_Type__c+'\'')<0){
                        boothProductType+= boothProductType==''?String.escapeSingleQuotes(booth.Booth_Product_Type__c):'\',\''+String.escapeSingleQuotes(booth.Booth_Product_Type__c);
                    }
                }
                //query on Tab Context
                tcList  = Database.query('SELECT Id,Header__c FROM Tab_Context__c WHERE (Booth_Product_Type__c=\'\' OR Booth_Product_Type__c Includes(\''+boothProductType+'\')) AND Event_Tab__c!=null AND Event_Tab__r.Tab_Code__c =: tabId WITH SECURITY_ENFORCED');                        
            }
        }
        catch(Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';          
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        }
        return tcList;
    }

    /**
    * @description  get PurchaseSummary
    * @param eventCode
    * @param accountId
    * @return  Map<String,Object>
    */
    @AuraEnabled(cacheable=false)
    public static Map<String,Object> getPurchaseSummary(String eventCode, String accountId){
        Edition__c ed;
        List<Purchase_Summary__c> psl;
        Contact_Edition_Mapping__c cem;
        List<Contact_Edition_Mapping__c> pcem;
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        try{
         //get event setting
        ed = [SELECT Id,Event_Setting__c FROM Edition__c WHERE Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        
        //get Purchase summary list
        psl = [SELECT Id,Name,Is_Active__c,External_Link__c,External_Link_Label__c,Information_Label__c,Mark_This_Task_Helptext__c,
        Purchase_Summary_Type__c,Standard_Header_Text__c,Standard_Sub_Header_Text__c,Sub_Header_Notes__c,Sub_Header_Text__c,
        Event_Tab__c,Event_Tab__r.Standard_Tab_Type__c,Event_Tab__r.Tab_Type__c,Event_Tab__r.Tab_Code__c,Event_Tab__r.Floorplan_Type__c,Event_Tab__r.Is_Tab_Active__c,Event_Tab__r.Is_Tab_Visible__c FROM Purchase_Summary__c WHERE Event_Setting__c=:ed.Event_Setting__c WITH SECURITY_ENFORCED ORDER BY Order__c ASC];
        List<String> ids = new List<String>();
        for(Purchase_Summary__c ps : psl){
            ids.add(ps.Id);
        }
        
        List<String> types = getVideoTypes();
        
        //get ContentDocumentLink of purchase summary Id
        if(!ids.isEmpty()){            
            cdl = [SELECT LinkedEntityId,ContentDocument.FileType,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:ids AND ContentDocument.FileType IN:types WITH SECURITY_ENFORCED ORDER BY SystemModstamp DESC];
        }

        //get ContactEditionMapping map of logged in user
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);

        //get ContactEditionMapping of logged in user
        cem = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');

        //get list of ContactEditionMapping of primary ContactEditionMapping
        pcem =  [SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,
                                            CC_Status__c,Contact__c,Relationship_Status__c,Completed_Purchase_Summaries__c,      
                                            Primary_Contact_Edition_Mapping__c,Edition__c, Edition__r.Edition_Code__c,  
                                            Edition__r.Form_Setting__c,Edition__r.Event_Setting__c,
                                            Edition__r.Due_Date__c,Edition__r.Company_Profile_Submission_Due_Date__c,
                                            Edition__r.Contractor_Nomination_Due_Date__c,        
                                            Edition__r.Event_Type__c,Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c,
                                            Edition__r.Stand_Design_Completion_Due_Date__c
                                            FROM Contact_Edition_Mapping__c 
                                            WHERE Id =:cem.Primary_Contact_Edition_Mapping__c   WITH SECURITY_ENFORCED];
        }
        catch (Exception e) {
            System.debug(LoggingLevel.Debug, 'Exception hit ' +e.getMessage());
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 

        return new Map<String,Object>{
            'ps'=>psl,
            'cem'=>cem,
            'pcem'=>(!pcem.isEmpty()?pcem.get(0):null),
            'badges'=>getBadges(eventCode,accountId),
            've'=>getVirtualEvent(eventCode,accountId),
            'lr'=>getLeadRetrieval(eventCode,accountId),
            'media'=>cdl
        };
    }

    private static List<String> getVideoTypes(){
        List<String> fileTypes = new List<String>();
        fileTypes.add('MP4');
        fileTypes.add('MOV');
        fileTypes.add('WMV');
        fileTypes.add('AVI');
        fileTypes.add('AVCHD');
        fileTypes.add('FLV');
        fileTypes.add('F4V');
        fileTypes.add('SWF');
        fileTypes.add('MKV');
        fileTypes.add('WEBM');//These formats are best for videos embedded on your personal or business website
        fileTypes.add('HTML5');//These formats are best for videos embedded on your personal or business website
        return fileTypes;
    }

    /**
    * @description get Purchase Data
    * @param eventCode
    * @param accountId
    * @return List<Purchase_Data__c>
    */
    public static List<Purchase_Data__c> getBadges(String eventCode,String accountId){
        Set<Id> cemIds;
        try{
           //get ContactEditionMapping map of logged in user
           Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
           //get ContactEditionMapping Ids of logged in user
           cemIds = (Set<Id>)mapCEMDetails.get('cemIds');  
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return [SELECT Id,Booth_Number__c,Unlimited_Badges__c,Booth_Product_Type__c,Stand_Length__c,Stand_Width__c,Unit_of_Measurement__c,Total_Badges__c,Remaining_Badges__c,Submitted_Badge__c FROM Purchase_Data__c WHERE 
                Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' AND Account__c =:accountId AND 
                Contact_Edition_Mapping__c IN: cemIds AND Booth_Product_Type__c != 'Lead Retrieval' WITH SECURITY_ENFORCED];    
    }

    /**
    * @description get Virtual Event Data
    * @param eventCode
    * @param accountId
    * @return List<AggregateResult>
    */
    public static List<AggregateResult> getVirtualEvent(String eventCode,String accountId){
        //get ContactEditionMapping map of logged in user
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        //get ContactEditionMapping Ids of logged in user
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
        
        return [SELECT Booth_Product_Type__c, Count(Id)  FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN: cemIds 
                AND (Booth_Number__c = '' OR Booth_Number__c = null) AND Booth_Product_Type__c != 'Lead Retrieval' AND Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' AND Account__c =:accountId WITH SECURITY_ENFORCED Group BY Booth_Product_Type__c];    
    }

    private static List<AggregateResult> getLeadRetrieval(String eventCode,String accountId){
        //get ContactEditionMapping map of logged in user
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        //get ContactEditionMapping Ids of logged in user
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
        return [SELECT Booth_Product_Type__c, Count(Id)  FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN: cemIds 
                AND (Booth_Number__c = '' OR Booth_Number__c = null) AND Booth_Product_Type__c = 'Lead Retrieval' AND Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' AND Account__c =:accountId WITH SECURITY_ENFORCED Group BY Booth_Product_Type__c];    
    }

    /**
    * @description  update PurchaseSummary
    * @param type
    * @param cemId
    * @return String
    */
    @AuraEnabled
    public static String updatePurchaseSummary(String type,String cemId){
        String status;
        try{
            List<Contact_Edition_Mapping__c> cemList = new List<Contact_Edition_Mapping__c>();
            //get contactEditionMapping from cemId
            Contact_Edition_Mapping__c cem = [SELECT Id,Primary_Contact_Edition_Mapping__c,Primary_Contact_Edition_Mapping__r.Completed_Purchase_Summaries__c,Completed_Purchase_Summaries__c FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' AND Id=:cemId WITH SECURITY_ENFORCED];           
            //if - cem.Primary_Contact_Edition_Mapping__c is not blank set primary CEM complete purchase summary to status
            //else - CEM complete purchase summary to status
            if(String.isNotBlank(cem.Primary_Contact_Edition_Mapping__c)){
                status = cem.Primary_Contact_Edition_Mapping__r.Completed_Purchase_Summaries__c!=null?cem.Primary_Contact_Edition_Mapping__r.Completed_Purchase_Summaries__c:'';
            }
            else{
                status = cem.Completed_Purchase_Summaries__c!=null?cem.Completed_Purchase_Summaries__c:'';
            }    
            if((';'+status+';').indexOf(type)<0){
                status = status+ ';'+type;
                
            }
            //if - cem.Primary_Contact_Edition_Mapping__c is not blank then add primary CEM in cemList
            //else - add primary CEM in cemList
            if(String.isNotBlank(cem.Primary_Contact_Edition_Mapping__c)){
                Contact_Edition_Mapping__c c = new Contact_Edition_Mapping__c();        
                c.Id = cem.Primary_Contact_Edition_Mapping__c;
                c.Completed_Purchase_Summaries__c = status;
                cemList.add(c);
            }
            else{
                cem.Completed_Purchase_Summaries__c = status;
                cemList.add(cem);
            }
        
            Update cemList;
        }
        catch (Exception e) {
            System.debug(LoggingLevel.Debug, 'Exception hit ' +e.getMessage());
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        return status;
    }

    /**
    * @description  get EventSummary
    * @param eventCode
    * @param accountId
    * @return Map<String,Object>
    */
    @AuraEnabled(cacheable=false)
    public static Map<String,Object> getEventSummary(String eventCode, String accountId){
        System.debug(LoggingLevel.debug, 'accountId=='+ accountId);
        Contact_Edition_Mapping__c cem;
        List<Contact_Edition_Mapping__c> pcem;
        String ts;
        Object sd;
        try{
         //get event setting
        //Edition__c ed = new Edition__c();
        //ed = [SELECT Id,Event_Setting__c,Form_Setting__c FROM Edition__c WHERE Edition_Code__c=:eventCode WITH SECURITY_ENFORCED LIMIT 1];
        //System.debug(LoggingLevel.debug, 'Edition=='+ ed);
        User userObj = [SELECT ContactId FROM User WHERE Id=:UserInfo.getUserId() WITH SECURITY_ENFORCED]; 
        System.debug(LoggingLevel.debug, 'userObj=='+ userObj);
        /*
            Note:-
            1. Edition__r.Due_Date__c => Badge Submission due date
            2. Edition__r.Company_Profile_Submission_Due_Date__c => Virtual Event Submission due date
        */
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        
        cem = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
        
        pcem =  [SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,
                                            CC_Status__c,Contact__c,Relationship_Status__c,Completed_Purchase_Summaries__c,      
                                            Primary_Contact_Edition_Mapping__c,Edition__c, Edition__r.Edition_Code__c,  
                                            Edition__r.Form_Setting__c,Edition__r.Event_Setting__c,
                                            Edition__r.Due_Date__c,Edition__r.Company_Profile_Submission_Due_Date__c,
                                            Edition__r.Contractor_Nomination_Due_Date__c,        
                                            Edition__r.Event_Type__c,Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c,
                                            Edition__r.Stand_Design_Completion_Due_Date__c
                                            FROM Contact_Edition_Mapping__c 
                                            WHERE Id =:cem.Primary_Contact_Edition_Mapping__c   WITH SECURITY_ENFORCED];
        if(cem.Access_Type__c=='Contractor'){
            sd = IMCCStandContractorDataCTRL.getActiveDatas(accountId, eventCode).get('data');
        }
        else{
            sd = IMCCStandDesignCTRL.getActivePHDatas(accountId, eventCode).get('data');
        }
        ts = !pcem.isEmpty()?pcem[0].Completed_Purchase_Summaries__c:'';
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return new Map<String,Object>{ 
            'cem'=>cem,
            'pcem'=>pcem,
            'taskStatus'=>cem.Completed_Purchase_Summaries__c+';'+ts,
            'task'=>getActiveModule(cem),
            'form'=>getMandatoryDoc(cem,'Form'),
            'manual'=>getMandatoryDoc(cem,'Manual'),
            'badges'=>getBadgeList(eventCode,accountId),
            've'=>getVirtualEvent(eventCode,accountId),
            'sd'=>sd
        };
    }
    
    /**
    * @description  get tab user type
    * @param conEdMap
    * @return List<Tab_User_Type__c>
    */
    private static List<Tab_User_Type__c> getActiveModule(Contact_Edition_Mapping__c conEdMap){
        List<String> standardTabTypes = new List<String>();
        List<Purchase_Summary__c> psl = [SELECT Purchase_Summary_Type__c FROM Purchase_Summary__c WHERE (Purchase_Summary_Type__c='Badge' OR Purchase_Summary_Type__c='Virtual Event') AND Event_Setting__c=:conEdMap.Edition__r.Event_Setting__c AND Is_Active__c=true WITH SECURITY_ENFORCED LIMIT 10];
        for(Purchase_Summary__c ps: psl){
            if(ps.Purchase_Summary_Type__c=='Badge'){
                standardTabTypes.add('Badge Registration');
            }
            else if(ps.Purchase_Summary_Type__c=='Virtual Event'){
                standardTabTypes.add('Virtual Event');
            }
        }
        //standardTabTypes.add('Virtual Event');
        standardTabTypes.add('Forms');
        standardTabTypes.add('Manuals');
        standardTabTypes.add('Stand Design');
        standardTabTypes.add('Stand Contractors');
        
        List<Tab_User_Type__c> tutList = new List<Tab_User_Type__c>();        
        Set<Id> setIds = new Set<Id>();        

        setIds.add(conEdMap.Id);
        if(String.isNotBlank(conEdMap.Primary_Contact_Edition_Mapping__c)){
            setIds.add(conEdMap.Primary_Contact_Edition_Mapping__c);
        }
    
        List<Purchase_Data__c> purchaseLst = [SELECT id,Contact_Edition_Mapping__c,Purchase_Status__c,Booth_Product_Type__c,Transaction_Status__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:setIds AND Transaction_Status__c = 'Active' AND Purchase_Status__c = 'Active' WITH SECURITY_ENFORCED];
        Set<String> boothPrdctType = new Set<String>();
        for(Purchase_Data__c purchaseData : purchaseLst){
            boothPrdctType.add(purchaseData.Booth_Product_Type__c);
        }

        for(Tab_User_Type__c tut : [SELECT Id,Event_Tab__r.Booth_Product_Types__c,Event_Tab__r.Standard_Tab_Type__c,Event_Tab__r.Tab_Code__c FROM Tab_User_Type__c WHERE User_Type__c =: conEdMap.Access_Type__c AND Event_Tab__r.Event_Setting__c =: conEdMap.Edition__r.Event_Setting__c AND Event_Tab__r.Is_Tab_Active__c = true AND Event_Tab__r.Is_Tab_Visible__c = true AND Event_Tab__r.Standard_Tab_Type__c IN:standardTabTypes  WITH SECURITY_ENFORCED])
        {        
            Boolean isAccess = false;
            if(String.isBlank(tut.Event_Tab__r.Booth_Product_Types__c)){
                isAccess = true;
            }
            else{
                for(String boothType : tut.Event_Tab__r.Booth_Product_Types__c.split(';')){
                    if(boothPrdctType.contains(boothType)){
                        isAccess = true;
                    }
                }
            }
            if(isAccess){
                tutList.add(tut);
            }        
        }
        return tutList;
    }

    /**
    * @description  get Purchase data list of current logged in user
    * @param eventCode
    * @param accountId
    * @return List<Tab_User_Type__c>
    */
    private static List<Purchase_Data__c> getBadgeList(String eventCode,String accountId){
         //get ContactEditionMapping map of logged in user
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
         //get ContactEditionMapping Ids of logged in user
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');        

        return [SELECT Id FROM Purchase_Data__c WHERE Purchase_Status__c='Active' AND Transaction_Status__c = 'Active' AND Account__c =:accountId AND 
                Contact_Edition_Mapping__c IN: cemIds AND Booth_Product_Type__c != 'Lead Retrieval' WITH SECURITY_ENFORCED];    
    }
    
    /**
    * @description  get tab user type
    * @param conEdMap
    * @param types
    * @return List<sobject>
    */
    private static List<sobject> getMandatoryDoc(Contact_Edition_Mapping__c conEdMap, String types){
        
        //get form Permision 
        Map<Id,Forms_Permission__c> manDocMap  = new Map<Id,Forms_Permission__c>([SELECT Id FROM Forms_Permission__c WHERE Form_Allocation__r.Form_Setting__c=:conEdMap.Edition__r.Form_Setting__c AND Form_Allocation__r.Form_Heading__c='Mandatory' AND Form_Allocation__r.Feature_Category__c=:types AND Tab_User_Type__r.User_Type__c =:conEdMap.Access_Type__c AND Is_Active__c = true AND Form_Allocation__r.Form_Status__c = 'Visible' WITH SECURITY_ENFORCED]);
        
        Set<Id> setIds = new Set<Id>();
        setIds.add(conEdMap.Id);
        if(String.isNotBlank(conEdMap.Primary_Contact_Edition_Mapping__c)){
            setIds.add(conEdMap.Primary_Contact_Edition_Mapping__c);
        }
        List<sobject> fdl = [SELECT Id,Status1__c,Overall_Status__c,Submitted_Responses__c,Purchase_Data__c,Form_Name__c,Is_Viewed__c,Forms_Permission__r.Form_Allocation__c,Forms_Permission__r.Form_Allocation__r.Submission_Deadline__c,Forms_Permission__r.Form_Allocation__r.Form_Entry__c,Forms_Permission__r.Form_Allocation__r.Feature_Category__c,Forms_Permission__r.Form_Allocation__r.Form_Type__c,Forms_Permission__r.Form_Allocation__r.Form__c,Forms_Permission__r.Form_Allocation__r.Form_Url__c,Forms_Permission__r.Form_Allocation__r.Booth_Product_Types__c,Forms_Permission__r.Form_Allocation__r.Entry_Limit__c,Forms_Permission__r.Form_Allocation__r.Allow_Submissions_after_Due_date__c,(SELECT Id,Name,Purchase_Data__c,Status__c,Form_Unlock__c,Rejection_Reason__c FROM Form_Response_Entries__r) FROM Form_Data__c WHERE Contact_Edition_Mapping__c IN:setIds AND Forms_Permission__c IN:manDocMap.keySet() AND Is_Active__c=true AND Not_Applicable__c=false WITH SECURITY_ENFORCED];
        
        //List<sobject> updatedFDL = new List<sobject>();
        /*if(types.equals('Forms')){
            for(sobject fd : fdl){
                if(fd.get('Status1__c') != 'Submitted'  && (fd.get('Status1__c') != 'In Review' && fd.get('Status1__c') != 'Resubmitted')){
                   updatedFDL.add(fd);
                }
            }
        }
        else{
            updatedFDL.addAll(fdl);
        }*/
        return fdl;
    }

    /**
    * @description  get HTML
    * @param tabCode
    * @return String
    */
    @AuraEnabled
    public static String getHtml(String tabCode){
        String htmlCode = '';
        try{
          //get event tab list
          List<Event_Tabs__c> etlist = [SELECT Id,HTML_Content__c FROM Event_Tabs__c WHERE Tab_Code__c=:tabCode WITH SECURITY_ENFORCED];
          //if - etlist is not empty and HTML Content in etlist is empty
          //else if - etlist is not empty and HTML Content in etlist is not empty
          if(!etlist.isEmpty() && String.isBlank(etlist.get(0).HTML_Content__c)){
            //get ContentDocumentLink list and if not empty then add the value in htmlcode
            List<ContentDocumentLink> listCDL = [SELECT Id,ContentDocument.LatestPublishedVersion.VersionData FROM ContentDocumentLink WHERE LinkedEntityId=:etlist[0].Id WITH SECURITY_ENFORCED LIMIT 1];
            if(!listCDL.isEmpty()){
                htmlCode = listCDL.get(0).ContentDocument.LatestPublishedVersion.VersionData.toString();
            }
          }
        else if(!etlist.isEmpty()){htmlCode = etlist.get(0).HTML_Content__c;}
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return htmlCode;
    }

    /**
    * @description  get TabId
    * @param edcode
    * @param accountId
    * @return List<Event_Tabs__c>
    */
    @AuraEnabled
    public static Map<String,Object> getTabId(String edcode, String accountId){
        List<Event_Tabs__c> etl = new List<Event_Tabs__c>();
        List<Contact_Edition_Mapping__c> conEdMapLst;
        try{
           //get event setting
           List<Edition__c> edl = [SELECT Event_Setting__c FROM Edition__c WHERE Edition_Code__c =: edcode WITH SECURITY_ENFORCED];
           
           //get event tab list 
           if(!edl.isEmpty()){
            etl = [SELECT ExtTabId__c,Tab_Code__c,Tab_Type__c,Standard_Tab_Type__c FROM Event_Tabs__c WHERE Event_Setting__c=:edl[0].Event_Setting__c AND ExtTabId__c!=null AND ExtTabId__c!='' WITH SECURITY_ENFORCED];
          }
          //get current logged in user
          User u = [SELECT id,Name,ContactId FROM User WHERE Id =: UserInfo.getUserId() WITH SECURITY_ENFORCED]; 
          //get CEM list of current logged in user
          conEdMapLst = [SELECT Feathr_Unique_Link__c
            FROM Contact_Edition_Mapping__c WHERE Contact__c =: u.ContactId 
            AND Account__c =: accountId AND Relationship_Status__c = 'Active' 
            AND Edition__r.Edition_Code__c =: edcode WITH SECURITY_ENFORCED];
        }
        catch (Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return new Map<String,Object>{
            'tab' => etl,
            'cem' => conEdMapLst
        };
    }
}