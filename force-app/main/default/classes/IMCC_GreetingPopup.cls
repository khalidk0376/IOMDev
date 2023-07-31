/*
Created By    : Aishwarya[IMCC-13]
Test Class    : IMCC_GreetingPopup_Test()
Created/Modified By   :  11/10/2021
@description  : The purpose of this class is to populate Greeting popup and error popup on cummuity pages.
Modified By : Shiv Raghav (Ticket No - IMCC-2815 )
@description : Added null check as part of IMCC-2815 ticket
*/
public without sharing class IMCC_GreetingPopup 
{
    /**
    * @description : Get PopUp details on Cummunity pages. 
    * @param eventCode
    * @param accountId
    * @return : WrapperPopupDetail
    **/
    @AuraEnabled(cacheable = false)
    public static WrapperPopupDetail fetchPopupDetails(String eventCode, String accountId) 
    {
        WrapperPopupDetail popupDetails = new WrapperPopupDetail();

        try{
        
        //User u = [SELECT Id,Name,ContactId FROM User WHERE Id =: UserInfo.getUserId() WITH SECURITY_ENFORCED];
        Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);
        
        List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');
        Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');

        if(!conEdMapLst.isEmpty()){
            popupDetails.CEM = conEdMapLst[0];
        }
        
        Set<String> setProductTypes = new Set<String>();
        String slist = '';
        String boothProductType = '';
        List<Purchase_Data__c> listPurchaseData = [SELECT Id, Booth_Product_Type__c FROM Purchase_Data__c
         WHERE Contact_Edition_Mapping__c IN:cemIds  WITH SECURITY_ENFORCED];
        
        for(Purchase_Data__c booth : listPurchaseData){                
            if((booth.Booth_Product_Type__c!=null && booth.Booth_Product_Type__c!='') && boothProductType.indexOf('\''+booth.Booth_Product_Type__c+'\'')<0){
                boothProductType += boothProductType==''?String.escapeSingleQuotes(booth.Booth_Product_Type__c):'\',\''+String.escapeSingleQuotes(booth.Booth_Product_Type__c);
            }
        }
        //Added null check as part of IMCC-2815 ticket (!conEdMapLst.isEmpty())
        if(string.isNotBlank(eventCode) && !conEdMapLst.isEmpty()){
            popupDetails.popupText ='';
             
            Set<String> setEditionPopupId = new Set<String>();
            List<Tab_User_Type__c> listTabUserType =[SELECT Edition_Popup__c, User_Type__c FROM Tab_User_Type__c
             WHERE Edition_Popup__r.Edition__r.Edition_Code__c =:eventCode
              AND User_Type__c =:conEdMapLst[0].Access_Type__c WITH SECURITY_ENFORCED];
            
            for(Tab_User_Type__c tuser :listTabUserType){
                setEditionPopupId.add(tuser.Edition_Popup__c);
            }
        
            List<Edition_Popup__c> listEditionPopup = new List<Edition_Popup__c>();
            //Fetch edition popup data
            String squery;                                                                       
            if(Test.isRunningTest()){
                squery = 'Select Id, Booth_Product_Type__c, Edition__c, Is_Visible__c, Pop_Up_Text__c, Reset_Pop_up_Preferences__c FROM Edition_Popup__c WHERE Edition__r.Edition_Code__c=:eventCode AND ID IN: setEditionPopupId';
            }
            else{                
                squery = 'Select Id, Booth_Product_Type__c, Edition__c, Is_Visible__c, Pop_Up_Text__c, Reset_Pop_up_Preferences__c FROM Edition_Popup__c WHERE Is_Visible__c=true AND Id IN: setEditionPopupId AND (Booth_Product_Type__c=\'\' OR Booth_Product_Type__c Includes(\''+boothProductType+'\'))';
            }
            
            system.debug('================='+squery);
            listEditionPopup = Database.query(squery);

            if(!listEditionPopup.IsEmpty()){
                popupDetails.editionPopup = listEditionPopup[0];
                for(Edition_Popup__c edp :listEditionPopup){ 
                    popupDetails.popupText = popupDetails.popupText + '&nbsp;' + edp.Pop_Up_Text__c;
                }
            }            
        } 
        }catch(Exception e) {
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace); 

        }
        
        return popupDetails;
    }
    
    /**
    * @description : wrapper or Inner class with @AuraEnabled {get;set;} properties*  
    **/  
    public class WrapperPopupDetail
    {
        @AuraEnabled public Edition_Popup__c editionPopup{get;set;}
        @AuraEnabled public String popupText{get;set;}
        @AuraEnabled public Contact_Edition_Mapping__c CEM{get;set;}
        @AuraEnabled public List<Purchase_Data__c> purchaseDtls{get;set;}
         @AuraEnabled public String expocadEventCode{get;set;}
    }
    
    /**
    * @description : Get Stand details based on event code and account id. 
    * @param eventCode
    * @param accountId
    * @return : WrapperPopupDetail
    **/
    @AuraEnabled
    public static WrapperPopupDetail fetchStandDetails(String eventCode, String accountId){
        WrapperPopupDetail wrapBoothData = new WrapperPopupDetail();
        User u;
        if(User.SObjectType.getDescribe().isAccessible()){
            u = [Select id,Name,ContactId from User where Id =: UserInfo.getUserId()];
        }
        try{
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(eventCode, accountId);        
            List<Contact_Edition_Mapping__c> conEdMapLst = (List<Contact_Edition_Mapping__c>)mapCEMDetails.get('cemList');//[SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c FROM Contact_Edition_Mapping__c WHERE Contact__c =: u.ContactId AND Account__c =: accountId AND Relationship_Status__c = 'Active' AND Edition__r.Edition_Code__c =: eventCode WITH SECURITY_ENFORCED];   
            Set<Id> cemIds = (Set<Id>)mapCEMDetails.get('cemIds');
            if(!conEdMapLst.isEmpty()){
                wrapBoothData.expocadEventCode = conEdMapLst[0].Edition__r.Expocad_Event_Code__c;
                wrapBoothData.purchaseDtls = [SELECT Id,Name,Account__r.Name,
                    Contact_Edition_Mapping__c,Booth_Number__c,Booth_Product_Type__c,Purchase_Status__c,Exhibiting_Name__c,
                    Transaction_Status__c,Quantity_Area__c,Unit_of_Measurement__c FROM Purchase_Data__c WHERE Booth_Number__c != '' and Purchase_Status__c='Active' and Transaction_Status__c = 'Active' and Contact_Edition_Mapping__c IN:cemIds WITH SECURITY_ENFORCED];                    
            } 
                  
        }
        catch (Exception e) {
            System.debug('Exception hit ' +e.getMessage());
            //HandleAllCustomException.logException(e,'Purchase_Data__c', 'After Insert');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';  
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        return wrapBoothData;
    }
    
    /**
    * @description : Update marked as read checkbox on CEM. 
    * @param cemId
    * @return : String
    **/
    //public static Contact_Edition_Mapping__c updateMarkAsRead(String eventCode, String accountId)
    @AuraEnabled(cacheable=false) 
    public static string updateMarkAsRead(String cemId) 
    {
        String message ='';
        User u;
        if(User.SObjectType.getDescribe().isAccessible()){
            u = [Select id,Name,ContactId from User where Id =: UserInfo.getUserId()];
        }
        system.debug('===================1'+cemId);
        Contact_Edition_Mapping__c cem = new Contact_Edition_Mapping__c();
        cem.Id = cemId;
        cem.Popup_Marked_as_Read__c = true;
        try{
            if(Schema.sObjectType.Contact_Edition_Mapping__c.isUpdateable())
            {
                update cem;
                message = 'success';
            }
        }catch (Exception ex) {

            //HandleAllCustomException.logException(ex,'Contact_Edition_Mapping__c', 'After Insert');
            String mesg = String.isNotBlank(ex.getMessage()) ? ex.getMessage():'';  
            String stackTrace = ex.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace); 

        } 
        return message;
     }       
}