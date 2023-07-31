/**
* File         :   IMCC_AssetTrigger 
* Project      :   IMCC
* Created Date :   16th feb 2022
* Created By   :   Girikon(Deepak)
* Test Class   :   IMCC_AssetTriggerHandler_Test(100%)
* Coverage     :   100%
***********************************************************************************************
* @description : This trigger will execute helper for Asset Trigger After Inser/Update. It will create or Update Contact Edition Mapping and Purchase Data For Asset
***********************************************************************************************
* Modification log :
* Modified By      :   Girikon(Deepak, Arushi[IMCC-4623])
* Modified On      :   13 Sept 2022
*/
trigger IMCC_AssetTrigger on Asset (after insert, after update, before insert, before update){
    Triggers_Configuration__mdt triggerConfiguration = IMCC_UtilityMethods.getTriggerConfiguration('IMCC_AssetTrigger');

    Triggers_Configuration__mdt triggerConfiguration2 = IMCC_UtilityMethods.getTriggerConfiguration('IMCC_AssetTrigger_Async');
    // if IsAfter is True and (triggerConfiguration.After_Insert__c and isInsert is True OR triggerConfiguration.After_Update__c and isUpdate is True)
    if(Trigger.isAfter && triggerConfiguration != null && ((triggerConfiguration.After_Insert__c && Trigger.isInsert) || (triggerConfiguration.After_Update__c && trigger.isUpdate))){
        IMCC_AssetTriggerHandler.createConEdiAndPurcData(trigger.new, trigger.oldMap, trigger.isUpdate);
    }
    // if isBefore is True and (triggerConfiguration.Before_Insert__c and isInsert is True OR triggerConfiguration.Before_Update__c and isUpdate is True)
    if(Trigger.isBefore && triggerConfiguration != null && ((triggerConfiguration.Before_Insert__c && trigger.isInsert) || (triggerConfiguration.Before_Update__c && trigger.isUpdate))){
        IMCC_AssetTriggerHandler.handleBefore(trigger.new, trigger.oldMap, trigger.isInsert);
    }
    // if IsAfter is True and (triggerConfiguration.After_Insert__c and isInsert is True OR triggerConfiguration.After_Update__c and isUpdate is True)
    if(Trigger.isAfter && triggerConfiguration2 != null && ((triggerConfiguration2.After_Insert__c && Trigger.isInsert) || (triggerConfiguration2.After_Update__c && trigger.isUpdate))){
        IMCC_AssetTriggerHandler.createAPISynRecords(trigger.new, trigger.oldMap, trigger.isUpdate);
    }
}