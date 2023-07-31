trigger IMCC_trgCreateFPRecords on Tab_User_Type__c (after insert, before update, after Delete) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgCreateFPRecords' LIMIT 1];
    if(trigger.isInsert && trigger.isAfter && (triggerConfiguration != null && triggerConfiguration.After_Insert__c)){
        IMCC_FormDataHandler.handleAfterInsert(Trigger.New);
    }
    if(trigger.isDelete && trigger.isAfter && (triggerConfiguration != null && triggerConfiguration.After_Delete__c)){
        IMCC_FormDataHandler.handleAfterDeleteTabUserType(Trigger.Old);
    } 
    if(trigger.isUpdate && trigger.isBefore && (triggerConfiguration != null && triggerConfiguration.Before_Update__c)){
        IMCC_FormDataHandler.handleBeforeUpdateTabUserType(Trigger.New, Trigger.oldMap);
    } 
}