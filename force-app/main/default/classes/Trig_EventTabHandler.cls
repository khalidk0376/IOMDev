/**
* Modified By: Girikon(Aishwarya)
* Created On:          22/9/2021
* @description  :      This handler class is called through the trigger trig_EventTab and used to check duplicate sequence of Tabs
* Created/Modified By: Girikon(Arushi[IMCC-1346])
* Modified On   :      30/04/2022
* @description  :      if a tab sequence is selected by another tab under different grouping the system gives an error  
* Methods:             dupSeqBeforeInsertHandler, dupSeqBeforeUpdateHandler
* Test Class:          Trig_EventTabHandler_Test(88%) 
**/

public class Trig_EventTabHandler {
    public static void dupSeqBeforeInsertHandler(List<Event_Tabs__c> listEvtTab)
    {
        try
        {
            Set<id> eventSet = new Set<id>();
            Map<String, List<Decimal>> mapEvntSetEventTabs = new Map<String, List<Decimal>>();
            Map<String, List<String>> mapEvntSetEventTabs2 = new Map<String, List<String>>();
            List<Event_Setting__c> evntSetLst;
            List<Event_Tabs__c> evntTabLst;
            
            for(Event_Tabs__c evtTab: listEvtTab){
                eventSet.add(evtTab.Event_Setting__c);
            }
            if(Event_Setting__c.SObjectType.getDescribe().isAccessible()){
                evntSetLst = [Select id, Name from Event_Setting__c where Id in : eventSet];
            }
            if(Event_Tabs__c.SObjectType.getDescribe().isAccessible()){
                evntTabLst = [select id,name,Sequence__c,ExtTabId__c,Event_Setting__c,Tab_Group__c from Event_Tabs__c where Event_Setting__r.Id in : evntSetLst];
            }
            if(!evntTabLst.isEmpty()){
                for(Event_Tabs__c evntTab : evntTabLst)
                {
                    if(mapEvntSetEventTabs.containsKey(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c))
                    {
                        mapEvntSetEventTabs.get(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c).add(evntTab.Sequence__c);
                    } 
                    else{
                        mapEvntSetEventTabs.put(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c,new List<Decimal>{evntTab.Sequence__c});
                    }
                    if(evntTab.ExtTabId__c!=null && evntTab.ExtTabId__c!=''){
                        if(mapEvntSetEventTabs2.containsKey(evntTab.Event_Setting__c))
                        {
                            mapEvntSetEventTabs2.get(evntTab.Event_Setting__c).add(evntTab.ExtTabId__c);
                        } 
                        else{
                            mapEvntSetEventTabs2.put(evntTab.Event_Setting__c,new List<String>{evntTab.ExtTabId__c});
                        }
                    }
                } //end of for loop
            }
            for(Event_Tabs__c evtTab: listEvtTab)
            {
                if(mapEvntSetEventTabs.containsKey(evtTab.Event_Setting__c +'_'+ evtTab.Tab_Group__c))
                {
                    if(mapEvntSetEventTabs.get(evtTab.Event_Setting__c +'_'+ evtTab.Tab_Group__c).contains(evtTab.Sequence__c))
                    {
                        evtTab.addError(System.Label.Duplicate_Tab_Sequence_number_error_message);
                    }
                }

                if(evtTab.ExtTabId__c!=null && evtTab.ExtTabId__c!=''){
                    if(mapEvntSetEventTabs2.containsKey(evtTab.Event_Setting__c))
                    {
                        if(mapEvntSetEventTabs2.get(evtTab.Event_Setting__c).contains(evtTab.ExtTabId__c))
                        {
                            evtTab.addError('You cannot put the same External Tab Id present in same event tab. Please choose a different External Tab Id.');
                        }
                    }
                }
            } //end of for loop
        }
        catch(exception e){
            HandleAllCustomException.logException(e,'Event_Tabs__c', 'Before Update');
        }
    }
   
    public static void dupSeqBeforeUpdateHandler(List<Event_Tabs__c> listEvtTab, Map<Id,Event_Tabs__c> oldListEvtTabMap)
    {
        try
        {
            Set<id> eventSet = new Set<id>();
            Map<String, List<Decimal>> mapEvntSetEventTabs = new Map<String, List<Decimal>>();
            Map<String, List<String>> mapEvntSetEventTabs2 = new Map<String, List<String>>();
            List<Event_Setting__c> evntSetLst;
            List<Event_Tabs__c> evntTabLst;
            for(Event_Tabs__c evtTab: listEvtTab){
                eventSet.add(evtTab.Event_Setting__c);
            }
            
            if(Event_Setting__c.SObjectType.getDescribe().isAccessible()){
                evntSetLst = [Select id, Name from Event_Setting__c where Id in : eventSet];
            }
            if(Event_Tabs__c.SObjectType.getDescribe().isAccessible()){
                evntTabLst = [select id,name,Sequence__c,ExtTabId__c,Event_Setting__c,Tab_Group__c from Event_Tabs__c where Event_Setting__r.Id in : evntSetLst];
            }
            if(!evntTabLst.isEmpty()){
                for(Event_Tabs__c evntTab : evntTabLst){
                    if(mapEvntSetEventTabs.containsKey(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c)) {
                        mapEvntSetEventTabs.get(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c).add(evntTab.Sequence__c);
                    }
                    else{
                        mapEvntSetEventTabs.put(evntTab.Event_Setting__c +'_'+ evntTab.Tab_Group__c,new List<Decimal>{evntTab.Sequence__c});
                    }
                    
                    if(evntTab.ExtTabId__c!=null && evntTab.ExtTabId__c!=''){
                        if(mapEvntSetEventTabs2.containsKey(evntTab.Event_Setting__c)) {
                            mapEvntSetEventTabs2.get(evntTab.Event_Setting__c).add(evntTab.ExtTabId__c);
                        }
                        else{
                            mapEvntSetEventTabs2.put(evntTab.Event_Setting__c,new List<String>{evntTab.ExtTabId__c});
                        }
                    }
                } //end of for loop
            }
            for(Event_Tabs__c evtTab: listEvtTab){
                if(mapEvntSetEventTabs.containsKey(evtTab.Event_Setting__c +'_'+ evtTab.Tab_Group__c))
                {
                    if(evtTab.Sequence__c != oldListEvtTabMap.get(evtTab.Id).Sequence__c)
                    {
                        if(mapEvntSetEventTabs.get(evtTab.Event_Setting__c +'_'+ evtTab.Tab_Group__c).contains(evtTab.Sequence__c)){
                            evtTab.addError(System.Label.Duplicate_Tab_Sequence_number_error_message);
                        }  
                    }
                }

                if(evtTab.ExtTabId__c!=null && evtTab.ExtTabId__c!=''){
                    if(mapEvntSetEventTabs2.containsKey(evtTab.Event_Setting__c))
                    {
                        if(evtTab.ExtTabId__c != oldListEvtTabMap.get(evtTab.Id).ExtTabId__c)
                        {
                            if(mapEvntSetEventTabs2.get(evtTab.Event_Setting__c).contains(evtTab.ExtTabId__c)){
                                evtTab.addError('You cannot put the same External Tab Id present in same event tab. Please choose a different External Tab Id.');
                            }  
                        }
                    }
                }
            } //end of for loop
        }
        catch(exception e){
            HandleAllCustomException.logException(e,'Event_Tabs__c', 'Before Update');
        }
    }   
}