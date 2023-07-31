trigger IMCC_trgCreateFormData on Form_Allocation__c (after update) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgCreateFormData' LIMIT 1];
    if(trigger.isUpdate && trigger.isAfter && (triggerConfiguration != null && triggerConfiguration.After_Update__c)){
        IMCC_FormDataHandler.handleAfterFormAllocUpdate(Trigger.New, Trigger.oldMap);
    }
}