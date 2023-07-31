/**
* Modified By: Girikon(Keertiraj)
* Created On:          22/9/2021
* @description  :      This trigger calls the handler class Trig_EventTabHandler
* Test Class:          Trig_EventTabHandler_Test(88%) 
**/
trigger trig_EventTab on Event_Tabs__c (before insert, before update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'trig_EventTab' LIMIT 1];
    if(triggerConfiguration != null && (triggerConfiguration.Before_Insert__c || triggerConfiguration.Before_Update__c)){
        switch on trigger.operationType{
            when BEFORE_INSERT{
                Trig_EventTabHandler.dupSeqBeforeInsertHandler(trigger.new);
            }
            when BEFORE_UPDATE{
                Trig_EventTabHandler.dupSeqBeforeUpdateHandler(trigger.new, trigger.oldmap);
            }
        }
    }
}