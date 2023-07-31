/**
* Created/Modified By: Girikon(Garima)
* Created On:          07/10/2021
* @description  :      This is a Trigger which is calling handler class to give file visibility to All Users so that communitu users can access it.
                       to community users
* Trigger:             Trig_SetFileVisibilityForPdfFloorplan      
**/

trigger Trig_SetFileVisibilityForPdfFloorplan on ContentDocumentLink (before insert){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'Trig_SetFileVisibilityForPdfFloorplan' LIMIT 1];
    if(triggerConfiguration != null && triggerConfiguration.Before_Insert__c){                                                    
        Trig_SetFileVisibility_Handler trigSetFileVisible = new Trig_SetFileVisibility_Handler();
        trigSetFileVisible.setFileVisibility(trigger.new);
    }
}