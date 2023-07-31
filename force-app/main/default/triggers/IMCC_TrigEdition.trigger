/*
Created By  :   Girikon[Keertiraj IMCC-122]
Created On  :   05/10/2021
@Description:   Trigger on Edition object for sending welcome email to contact edition mapping contacts.
Created/Modified By: Girikon(Arushi, Saurabh)
* Created On:          08/02/2022
* @description : (IMCC-69)As an Ops User , I Should be able to  choose the due submission date 
for stand design forms so the contractor and customer are aware of the deadline to complete this process.
(IMCC-68)As an  Ops User , I Should be able to  set a due date for an exhibitor to associate a contractor so that the 

Coverage    :   100%
Test Class  :   IMCC_EditionTriggerHandler_Test (100%)
*/

trigger IMCC_TrigEdition on Edition__c (before insert, before update, after insert, after update) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_TrigEdition' LIMIT 1];
    if(trigger.isBefore && trigger.isInsert && triggerConfiguration != null && triggerConfiguration.Before_Insert__c){
        IMCC_EditionTriggerHandler.handleBeforeInsert(trigger.new);
    }
    else if(trigger.isBefore && trigger.isUpdate && triggerConfiguration != null && triggerConfiguration.Before_Update__c){
        IMCC_EditionTriggerHandler.handleBeforeUpdate(trigger.new);
    }
    
    else if(trigger.isAfter){
        if(trigger.isInsert && triggerConfiguration != null && triggerConfiguration.After_Insert__c){
            IMCC_EditionTriggerHandler.notifyUserToAssignContractor(trigger.newMap, null);
        }
        if(trigger.isUpdate && triggerConfiguration != null && triggerConfiguration.After_Update__c){
            IMCC_EditionTriggerHandler.handleAfterUpdate(trigger.new, trigger.oldMap);
            IMCC_EditionTriggerHandler.notifyUserToAssignContractor(trigger.newMap, trigger.oldMap);
        } 
    }
}