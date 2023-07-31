/**
* Created By     :  Girikon(Arushi[IMCC-2026],[IMCC-4300])
* Created On     :  06/4/2022,16/Aug/2022
* @description   :  As an Ops user, I should be able to redirect to internal/external tab links in the portal from within the announcement description
* Apex Test Class: IMCC_AnnouncementHandler_Test(100%)
**/

trigger IMCC_AnnouncementTrig on Announcement__c (before insert, before update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_AnnouncementTrig' LIMIT 1];
    
    if(Trigger.isBefore && triggerConfiguration != null && ((triggerConfiguration.Before_Insert__c && Trigger.isInsert) || (triggerConfiguration.Before_Update__c && Trigger.isUpdate))){
        IMCC_AnnouncementHandler.checkEventTab(trigger.new);
    }
}