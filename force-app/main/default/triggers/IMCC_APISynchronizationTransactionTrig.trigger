/**
* File         :   IMCC_APISynchronizationTransactionTrig 
* Project      :   IMCC
* Created Date :   8th Sept 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(100%)
* Coverage     :   100%
***********************************************************************************************
* @description : This trigger will execute the batch which will process the IMCC API Sync Transaction records.
***********************************************************************************************
* Modification log :
*/
trigger IMCC_APISynchronizationTransactionTrig on IMCC_API_Synchronization_Transaction__c (after update) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_APISynchronizationTransactionTrig' LIMIT 1];
    // if IsAfter is True and triggerConfiguration.After_Update__c and isUpdate is True
    if(triggerConfiguration != null && Trigger.isAfter && Trigger.isUpdate && triggerConfiguration.After_Update__c){
        IMCC_APISynchronizationTransactionHelper.handleAfterUpdate(trigger.new, trigger.oldMap);
    }
}