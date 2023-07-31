/**
* Created/Modified By: Girikon(Garima)
* Created On:          19/10/2021
* @description  :      This class is used to fetch List of Ques Ans and How to List details on Customer Portal
* Methods:             fetchQuesAnsDetails,fetchHowToDetails,fetchContentVerId
* Apex Class:          IMCC_FAQCtrl 
* Apex Test Class:     IMCC_FAQCtrl_Test (91%)
* Modified By      :  IBM(Srikanth)
* Modified On      :   16 Sept, 2022
* @description  :      For all Auraenabled methods added try-catch block and threw Aura exception.
**/

/**
* @description : to fetch List of Ques Ans from Q_s_A_s_How_To__c object
* @param : eventcode, accountId,tabId
* @return : List<Q_s_A_s_How_To__c>
**/

public  without sharing class IMCC_FAQCtrl {
    @AuraEnabled
    public static List<Q_s_A_s_How_To__c> fetchQuesAnsDetails(String eventCode, String accountId, String tabId){
        User u;
        List<Q_s_A_s_How_To__c> fAqLst;
        if(User.SObjectType.getDescribe().isAccessible()){
            u = [Select id,Name,ContactId from User where Id =: UserInfo.getUserId()];
        }
        try{
            List<Contact_Edition_Mapping__c> conEdMapLst;
            if(Contact_Edition_Mapping__c.SObjectType.getDescribe().isAccessible()){
                conEdMapLst = [Select Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c from Contact_Edition_Mapping__c where Contact__c =: u.ContactId And Account__c =: accountId And Relationship_Status__c = 'Active' And Edition__r.Edition_Code__c =: eventCode];
            }
            if(!conEdMapLst.isEmpty()){
                if(String.isNotBlank(tabId)){
                    if(Q_s_A_s_How_To__c.SObjectType.getDescribe().isAccessible()){
                        fAqLst = [Select Id,Name,Active__c,Event_Tab__c,Type__c,Sequence__c,Question__c,Answer__c from Q_s_A_s_How_To__c where Event_Tab__r.Tab_Code__c =: tabId and Active__c = true and Type__c = 'FAQ' Order By Sequence__c]; 
                    }
                }
            }
            
        }       
        catch (Exception e) {
            System.debug('Exception hit ' +e.getMessage());
          //  HandleAllCustomException.logException(e,'Q_s_A_s_How_To__c', 'After Insert');
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return fAqLst;
    }
    
    /**
* @description : to fetch List of How To Details from Q_s_A_s_How_To__c object
* @param : eventcode, accountId,tabId
* @return : List<Q_s_A_s_How_To__c>
**/
    @AuraEnabled
    public static List<Q_s_A_s_How_To__c> fetchHowToDetails(String eventCode, String accountId, String tabId){
        User u;
        List<Q_s_A_s_How_To__c> howToLst;
        if(User.SObjectType.getDescribe().isAccessible()){
            u = [Select id,Name,ContactId from User where Id =: UserInfo.getUserId()];
        }
        try{
            List<Contact_Edition_Mapping__c> conEdMapLst;
            if(Contact_Edition_Mapping__c.SObjectType.getDescribe().isAccessible()){
                conEdMapLst = [Select Id,Name,Access_Type__c,Account__c,Account__r.Name,CC_Status__c,Contact__c,Edition__c,Relationship_Status__c from Contact_Edition_Mapping__c where Contact__c =: u.ContactId And Account__c =: accountId And Relationship_Status__c = 'Active' And Edition__r.Edition_Code__c =: eventCode];
            }
            if(!conEdMapLst.isEmpty()){
                if(String.isNotBlank(tabId)){
                    if(Q_s_A_s_How_To__c.SObjectType.getDescribe().isAccessible()){
                        howToLst = [Select Id,Name,Active__c,Event_Tab__c,Type__c,Sequence__c,HyperLink__c,Label__c from Q_s_A_s_How_To__c where Event_Tab__r.Tab_Code__c =: tabId and Active__c = true and Type__c = 'How to' Order By Sequence__c]; 
                    }
                }
            }
            
        }       
        catch (Exception e) {
            System.debug('Exception hit ' +e.getMessage());
            //HandleAllCustomException.logException(e,'Q_s_A_s_How_To__c', 'After Insert');
            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return howToLst;
    }
    
    /**
* @description : to fetch content version id 
* @param : howToId
* @return : String
**/
    @AuraEnabled
    public static String fetchContentVerId(String howToId){
        system.debug('howToId ' +howToId);
        String cntVerId;
        try{
            List<ContentDocumentLink> cntnDocLinkLst;
            if(String.isNotBlank(howToId)){
                if(ContentDocumentLink.SObjectType.getDescribe().isAccessible()){
                    cntnDocLinkLst = [SELECT Id, LinkedEntityId, ContentDocumentId, SystemModstamp, Visibility, ShareType FROM ContentDocumentLink where LinkedEntityId =: howToId Order By SystemModstamp desc ];
                    system.debug('cntnDocLinkLst ' +cntnDocLinkLst);
                }
            }
            if(cntnDocLinkLst.size()>0){
                List<ContentVersion> docmList = new List<ContentVersion>();
                if(ContentVersion.SObjectType.getDescribe().isAccessible()){
                    docmList = [select id FROM ContentVersion where contentdocumentid =: cntnDocLinkLst[0].ContentDocumentId and IsLatest = true];
                }
                if(docmList != null && docmList.size()>0){
                    cntVerId = docmList[0].Id;
                }
            }
        }catch(Exception e) {

            String stackTrace = e.getStackTraceString().substringBefore('\n');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():''; 
           throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);

        }
        return cntVerId;
    }
    
}