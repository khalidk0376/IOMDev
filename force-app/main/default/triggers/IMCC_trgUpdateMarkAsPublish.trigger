/**
* Created/Modified By: Aishwarya[IMCC-18]
* Created On    :      22/10/2021
* @description  :      This tab context trigger
* Apex Class    :      IMCC_trgUpdateMarkAsPublish 
* Apex Test Class:     IMCC_MarkAsPublishHandler_Test(100%)
**/
trigger IMCC_trgUpdateMarkAsPublish on Tab_Context__c (after insert, after update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgUpdateMarkAsPublish' LIMIT 1];
    if(triggerConfiguration != null && (triggerConfiguration.After_Insert__c || triggerConfiguration.After_Update__c)){                                                    
        IMCC_MarkAsPublishHandler.handleAfterUpdate(Trigger.New, Trigger.oldMap, trigger.isUpdate);
    }
}