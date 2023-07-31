/**
* Created By/Modified By     :  Girikon(Arushi[IMCC-2026],[IMCC-4300])
* Created On/Modified On     :  06/4/2022,16/Aug/2022
* @description      :   As an Ops user, I should be able to redirect to internal tab links in the portal from within the announcement description
* Apex Test Class   :   IMCC_AnnouncementHandler_Test(85%)
**/

public class IMCC_AnnouncementHandler {
    
    /**
    * @description : to check if Selected Event tab on Announcement belongs to Selected Edition of Announcement or not
    * @param newAnnouncements
    */
    public Static void checkEventTab(List<Announcement__c> newAnnouncements){
        Set<Id> eveSettingIdSet = new Set<Id>();
        Map<Id,Id> mapEditionEveSetting = new Map<Id,Id>();
        Map<Id,Set<Id>> mapeveSettingTabList = new Map<Id,Set<Id>>();
        
        for(Announcement__c annce : newAnnouncements){
            if(annce.Edition__c != null){
                eveSettingIdSet.add(annce.Edition__c);
            }
        }
        
        //map of edition as key and event setting as value
        if(!eveSettingIdSet.isEmpty()){
            for(Edition__c edition : [SELECT Id, Event_Setting__c FROM Edition__c WHERE Id=:eveSettingIdSet WITH SECURITY_ENFORCED]){
                 mapEditionEveSetting.put(edition.Id,edition.Event_Setting__c);
            } 
        }
        
        //map of event setting as key and its related event tabs list as values
        if(!mapEditionEveSetting.isEmpty()){
            for(Event_Tabs__c eveTab : [SELECT Id, Event_Setting__c FROM Event_Tabs__c WHERE Event_Setting__c IN:mapEditionEveSetting.Values() WITH SECURITY_ENFORCED]){
                Set<Id> eveTabList = (mapeveSettingTabList.ContainsKey(eveTab.Event_Setting__c)?mapeveSettingTabList.get(eveTab.Event_Setting__c):new Set<Id>());
                eveTabList.add(eveTab.Id);
                mapeveSettingTabList.put(eveTab.Event_Setting__c,eveTabList);
            }
        }
        
        for(Announcement__c annce : newAnnouncements){
            if(mapeveSettingTabList.containsKey(mapEditionEveSetting.get(annce.Edition__c)) && (annce.Event_Tab__c !=null && annce.Link_Type__c == 'Internal')){
                Set<Id> listEveTab = mapeveSettingTabList.get(mapEditionEveSetting.get(annce.Edition__c));
                //if listEveTab list does not contain the selected event tab then show the error 
                if(!listEveTab.contains(annce.Event_Tab__c)){
                    annce.addError(System.Label.Event_Tab_Other_Than_Event_Setting_Edition_Error_Message);
                }
            }
        }
    }
}