/*
Created By    : Aishwarya[IMCC-13]
Test Class    : IMCC_EditionPopupHandler_Test()
Created/Modified By   :  11/10/2021
*/

trigger IMCC_trgUpdateMarkAsRead on Edition_Popup__c (after update,before insert){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgUpdateMarkAsRead' LIMIT 1];
    Boolean ifExecute = false;
    List<Edition_Popup__c> listEdpForUpdate = new List<Edition_Popup__c>();
    if(trigger.isUpdate && triggerConfiguration != null && triggerConfiguration.After_Update__c)
    {
        for(Edition_Popup__c edp :Trigger.New)
        {
            if(edp.Reset_Pop_up_Preferences__c == true){
                ifExecute = true;
            }
        }
        if(ifExecute == true){
            IMCC_EditionPopupHandler.handleAfterUpdate(trigger.new);
            List<Edition_Popup__c> listEdpForUpdate = [SELECT Id, Reset_Pop_up_Preferences__c  FROM Edition_Popup__c WHERE Id IN :trigger.new WITH SECURITY_ENFORCED];
            for(Edition_Popup__c edp :listEdpForUpdate){
                edp.Reset_Pop_up_Preferences__c = false;
            }
            if(Schema.SObjectType.Edition_Popup__c.isUpdateable()){
                Database.update(listEdpForUpdate,false);
            }
        }
    }
    if(Trigger.isInsert && Trigger.isBefore && triggerConfiguration != null && triggerConfiguration.Before_Insert__c){
        for(Edition_Popup__c edp :Trigger.New){
            edp.Reset_Pop_up_Preferences__c = false;
        }       
    }
}