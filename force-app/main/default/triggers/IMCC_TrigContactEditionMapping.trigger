/*
Created By  :   Girikon[Keertiraj IMCC-5]
Created On  :   5/10/2021
@Description:   Trigger on Contact Edition Mapping object for sending welcome email to contact edition mapping contacts.
Coverage    :   100%
Test Class  :   IMCC_ContactEdMapTriggerHandler_Test(100%)
*/

trigger IMCC_TrigContactEditionMapping on Contact_Edition_Mapping__c (after insert,after update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_TrigContactEditionMapping' LIMIT 1];
    if(trigger.isInsert && trigger.isAfter && triggerConfiguration != null && triggerConfiguration.After_Insert__c){
        IMCC_ContactEditionMappingTriggerHandler.handleAfterInsert(trigger.new);
    }

    if(triggerConfiguration != null && (trigger.isInsert && trigger.isAfter  && triggerConfiguration.After_Insert__c) || (trigger.isUpdate && trigger.isAfter  && triggerConfiguration.After_Update__c)){
        IMCC_ContactEditionMappingTriggerHandler.updatePurchaseData(trigger.newMap, trigger.oldMap);
    }
}