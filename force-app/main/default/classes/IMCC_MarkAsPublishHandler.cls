/**
* Created/Modified By: Aishwarya[IMCC-18]
* Created On    :      22/10/2021
* @description  :      This class is used for handler class for tab context trigger
* Apex Class    :      IMCC_MarkAsPublishHandler 
* Apex Test Class:     IMCC_MarkAsPublishHandler_Test(83%)
**/
public without sharing class IMCC_MarkAsPublishHandler{
    /**
    * @description this method will change Last publish number
    * @param listTabContent
    * @param mapOldTabContent
    * @param isUpdate
    */
    public static void handleAfterUpdate(List<Tab_Context__c> listTabContent, Map<Id,Tab_Context__c> mapOldTabContent, Boolean isUpdate){
        Set<Id> tabContentIds = new Set<Id>();
        Set<Id> setEventTabIds = new Set<Id>();
        
        for(Tab_Context__c tab : listTabContent){
            if((!isUpdate || (isUpdate && mapOldTabContent.get(tab.id).Publish_Changes__c != tab.Publish_Changes__c)) && tab.Publish_Changes__c == true){
                tabContentIds.add(tab.Id);
            }
        }

        try{
            List<Tab_Context__c> listTabContextForUpdate = new List<Tab_Context__c>();
            List<Tab_Context__c> listTabContextResetPublishChanges = new List<Tab_Context__c>();
            
            if(!listTabContent.isEmpty() && Schema.sObjectType.Tab_Context__c.isAccessible()){
                listTabContextForUpdate = [SELECT Id,Last_Published_Number__c,Event_Tab__c FROM Tab_Context__c WHERE ID IN:tabContentIds];
                
                for(Tab_Context__c tabcontext : listTabContextForUpdate){
                    tabcontext.Last_Published_Number__c = (tabcontext.Last_Published_Number__c==null?0:tabcontext.Last_Published_Number__c) + 1;
                    setEventTabIds.add(tabcontext.Event_Tab__c);
                }
                Database.update(listTabContextForUpdate,false); 

                listTabContextResetPublishChanges = [SELECT Id FROM Tab_Context__c WHERE ID NOT IN:tabContentIds AND Event_Tab__c IN:setEventTabIds AND Publish_Changes__c=true];
                if(!listTabContextResetPublishChanges.isEmpty()){
                    for(Tab_Context__c tcon : listTabContextResetPublishChanges){
                        tcon.Publish_Changes__c = false;
                    }
                    Database.update(listTabContextResetPublishChanges,false);
                }
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Tab_Context__c', 'After Update');
        } 
    }
}