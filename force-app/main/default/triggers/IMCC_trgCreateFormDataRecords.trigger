trigger IMCC_trgCreateFormDataRecords on Forms_Permission__c(after insert, after update) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgCreateFormDataRecords' LIMIT 1];
    if(triggerConfiguration != null && (triggerConfiguration.After_Insert__c || triggerConfiguration.After_Update__c)){      
        IMCC_ManageFormDataRecords.handleAfterInsert(trigger.New);
    }
}