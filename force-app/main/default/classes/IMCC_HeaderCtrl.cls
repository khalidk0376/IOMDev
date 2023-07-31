/**
* Created By        :    Girikon(Garima)
* Created On:          16/9/2021
* Modified By      :  Girikon(Mukesh)
* Modified On      :   15 Dec, 2021
* @description  :      This class provides following functionalities:
*                      It will fetch all Edition Details and Tabs to be shown on Header. Also it will fetch the Custom Tab content which will
reflect when customer clicks on any Custom Tab
* Modified By      :  Girikon(Arushi)
* Modified On      :   15 Jan, 2022
* @description  :      As an Ops User , I Should be able to  set visibility for each tab in an event based on user type
                       & product type so that I can provide the right access for the portal users.
* Methods:             fetchUserTabDetails, fetchEventTabDetails
* Modified By      :  IBM(Srikanth)
* Modified On      :   16 Sept, 2022, ,[Aishwarya Kumar IMCC-4936 16 Dec 2022]
* @description  :      For all Auraenabled methods added try-catch block and threw Aura exception.
* Apex Class:          IMCC_HeaderCtrl 
* Apex Test Class:     IMCC_HeaderCtrl_Test (88%)
**/

public without sharing class IMCC_HeaderCtrl {
    
    /**
    * @description : to fetch Edition Detail and Tabs based on Contact Edition Mapping
    * @param eventCode
    * @param accountId
    * @param tabId
    * @return : WrapperUserTabDetails
    **/
    @AuraEnabled
    public static WrapperUserTabDetails fetchUserTabDetails(String eventCode, String accountId, String tabId){
        WrapperUserTabDetails wrapUserData = new WrapperUserTabDetails();        
        try
        {
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
            //User u = [SELECT id,Name,ContactId FROM User WHERE Id =: UserInfo.getUserId() WITH SECURITY_ENFORCED];           
            
            wrapUserData.tabGroup = [SELECT Id, Sequence__c, Display_Always__c, Type__c, Name FROM Tab_Group__c WHERE Display_Always__c=true WITH SECURITY_ENFORCED ORDER BY Sequence__c ASC];
            List<Contact_Edition_Mapping__c> conEdMapLst = new List<Contact_Edition_Mapping__c>();

            conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
            // IMCC-4936 updating First_Login_Date_Time__c field on CEM
            Contact_Edition_Mapping__c currentCEM = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
            if(currentCEM.Id != null && currentCEM.First_Login_Date_Time__c == null){
                update new Contact_Edition_Mapping__c(Id=currentCEM.Id,First_Login_Date_Time__c=System.Now());
            }
            
            //[SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Contact__c =: u.ContactId AND Account__c =: accountId AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c =: eventCode WITH SECURITY_ENFORCED];   
            Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
            
            if(!conEdMapLst.isEmpty()){
                wrapUserData.havingCEMRecords = true;
                wrapUserData.accountName = conEdMapLst[0].Account__r.Name;
                wrapUserData.userRole = conEdMapLst[0].Role__c;
                List<Edition__c> editionLst = [SELECT id,Name,End_Date__c,Edition_Image_URL__c,Venue__c,Start_Date__c,Edition_Description__c,Background_Colour__c,Text_Colour__c,Show_Hours__c,FaceBook__c,LinkedIn__c,Twitter__c,YouTube__c,Event_Setting__c FROM Edition__c WHERE Id =: conEdMapLst[0].Edition__c AND Edition_Status__c='Confirmed' WITH SECURITY_ENFORCED];
                if(!editionLst.isEmpty()){
                    wrapUserData.edition = editionLst[0];
                }

                //Added regarding IMCC-288 (to show tab content based on Booth/Product Type)
                List<Purchase_Data__c> purchaseLst = [SELECT id,Contact_Edition_Mapping__c,Purchase_Status__c,Booth_Product_Type__c,Transaction_Status__c FROM Purchase_Data__c WHERE Contact_Edition_Mapping__c IN:cemIds AND Transaction_Status__c = 'Active' AND Purchase_Status__c = 'Active' WITH SECURITY_ENFORCED];
                Set<String> boothPrdctType = new Set<String>();
                for(Purchase_Data__c purchaseData : purchaseLst){
                    boothPrdctType.add(purchaseData.Booth_Product_Type__c);
                }

                List<Tab_User_Type__c> listTabuserTypes = [SELECT Id,Name,Event_Tab__c,Event_Tab__r.Tab_Subtitle__c,Event_Tab__r.Icon__c,Event_Tab__r.Tab_Group__c,Event_Tab__r.Tab_Group__r.Name,Event_Tab__r.Tab_Code__c,Event_Tab__r.Tab_Type__c,Event_Tab__r.Event_Setting__c,Event_Tab__r.Name,Event_Tab__r.Tab_Title__c,Event_Tab__r.Is_Tab_Active__c,Event_Tab__r.Is_Tab_Visible__c,Event_Tab__r.Sequence__c,Event_Tab__r.Standard_Tab_Type__c,Event_Tab__r.Floorplan_Type__c,User_Type__c,Event_Tab__r.Booth_Product_Types__c, Event_Tab__r.Role__c FROM Tab_User_Type__c WHERE User_Type__c =:conEdMapLst[0].Access_Type__c AND Event_Tab__r.Event_Setting__c =:editionLst[0].Event_Setting__c AND Event_Tab__r.Is_Tab_Active__c = true and Event_Tab__r.Is_Tab_Visible__c = true WITH SECURITY_ENFORCED Order By Event_Tab__r.Sequence__c];

                wrapUserData.userTypeEventTabs = new List<Tab_User_Type__c>();
                for(Tab_User_Type__c tut : listTabuserTypes){
                    Boolean isAccess = false;
                    
                    if(String.isBlank(tut.Event_Tab__r.Booth_Product_Types__c)){
                        if(String.isBlank(tut.Event_Tab__r.Role__c)){
                            isAccess = true;
                        }
                        else{
                            for(String roleType : tut.Event_Tab__r.Role__c.split(';')){
                                if(conEdMapLst[0].Role__c == roleType){
                                    isAccess = true;
                                }
                            }
                        }
                    }
                    else{             
                        for(String boothType : tut.Event_Tab__r.Booth_Product_Types__c.split(';')){
                            if(boothPrdctType.contains(boothType)){
                                if(String.isBlank(tut.Event_Tab__r.Role__c)){
                                    isAccess = true;
                                }
                                else{
                                    for(String roleType : tut.Event_Tab__r.Role__c.split(';')){
                                        if(conEdMapLst[0].Role__c == roleType){
                                            isAccess = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(isAccess){
                        wrapUserData.userTypeEventTabs.add(tut);
                    }
                }
                
                Set<String> setEventTabIds = new Set<String>();
                for(Tab_User_Type__c tus :wrapUserData.userTypeEventTabs){
                    setEventTabIds.add(tus.Event_Tab__c);
                }
                            
                List<Tab_Context__c> listTabCon = [SELECT Id, Event_Tab__c, Event_Tab__r.Name,Event_Tab__r.Tab_Title__c,Event_Tab__r.Tab_Code__c, Publish_Changes__c, Last_Published_Number__c,Booth_Product_Type__c FROM Tab_Context__c WHERE Event_Tab__c IN:setEventTabIds AND Publish_Changes__c = true WITH SECURITY_ENFORCED];
                if(!listTabCon.isEmpty()){
                    wrapUserData.listTabContextForNew = new List<Tab_Context__c>();
                    for(Tab_Context__c tc : listTabCon){
                        Boolean isAccess = false;
                        if(String.isBlank(tc.Booth_Product_Type__c)){
                            isAccess = true;
                        }
                        else{
                            for(String boothType : tc.Booth_Product_Type__c.split(';')){
                                if(boothPrdctType.contains(boothType)){
                                    isAccess = true;
                                }
                            }
                        }
                        if(isAccess){
                            wrapUserData.listTabContextForNew.add(tc);
                        }
                    }
                }
                
                if(String.isNotBlank(tabId)){
                    List<Tab_Context__c> evntTabContextLst = [SELECT id,Name,Booth_Product_Type__c,Event_Tab__r.Name,Event_Tab__r.Tab_Code__c,Event_Tab__r.Tab_Type__c,Event_Tab__r.Is_Tab_Active__c,Event_Tab__r.Layout_Type__c,Header__c,Section_1__c,Section_2__c,Section_3__c FROM Tab_Context__c WHERE Event_Tab__r.Tab_Code__c =: tabId WITH SECURITY_ENFORCED];
                    wrapUserData.tabContextLst = new List<Tab_Context__c>(); 
                    for(Tab_Context__c tc : evntTabContextLst){
                        Boolean isAccess = false;
                        if(String.isBlank(tc.Booth_Product_Type__c)){
                            isAccess = true;
                        }
                        else{
                            for(String boothType : tc.Booth_Product_Type__c.split(';')){
                                if(boothPrdctType.contains(boothType)){
                                    isAccess = true;
                                }
                            }
                        }
                        if(isAccess){
                            wrapUserData.tabContextLst.add(tc);
                        }
                    }                   
                }
            }  
            else {
                wrapUserData.havingCEMRecords = false;
            }      
        }    
        catch (Exception e) {
            System.debug(LoggingLevel.DEBUG,'Exception hit ' +e.getMessage());
          //  HandleAllCustomException.logException(e,'Edition__c', 'After Insert');
             String stackTrace = e.getStackTraceString().substringBefore('\n');
             String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return wrapUserData;
    }

    /**
    * @description : wrapper Event Tabs, Tab Context and Tab Group
    **/
    public class WrapperUserTabDetails
    {
        @AuraEnabled public List<Tab_User_Type__c> userTypeEventTabs;
        @AuraEnabled public Edition__c edition;
        @AuraEnabled public String accountName;
        @AuraEnabled public List<Tab_Context__c> tabContextLst;
        @AuraEnabled public List<Tab_Context__c> listTabContextForNew;
        @AuraEnabled public List<Tab_Group__c> tabGroup;
        @AuraEnabled public Boolean havingCEMRecords ;
        @AuraEnabled public String userRole;

    }
}