/*
* Created By    :   Girikon[Arushi IMCC-83]
* Created On    :   03/02/2021
* @description  :   Trigger on contractor Mapping object to update the task when it is completed.
* Modified By   :   Girikon(Arushi - [IMCC-91])
* Modified On   :   25 Feb, 2022
* @description  :   As a Customer, I should be able to submit the stand design for my booths, if I am decide to complete my stand submission process myself.
* Test Class    :   IMCC_ContractorMappingTrigHandler_Test (100%)
*/

trigger IMCC_ContractorMappingTrig on Contractor_Mapping__c (before insert,before update,after insert,after update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_ContractorMappingTrig' LIMIT 1];
    if(trigger.isBefore && triggerConfiguration != null && (triggerConfiguration.Before_Insert__c || triggerConfiguration.Before_Update__c)){
        //if(trigger.isInsert){
        //    IMCC_ContractorMappingTrigHandler.updateContractorStatus(trigger.new);  
        //}
        if(trigger.isUpdate){
            IMCC_ContractorMappingTrigHandler.updateContractorStatus(trigger.new);  
        }
    }
    if(trigger.isAfter && triggerConfiguration != null && (triggerConfiguration.After_Insert__c || triggerConfiguration.After_Update__c)){
        if(trigger.isInsert){
            IMCC_ContractorMappingTrigHandler.sendEmailAndPortalNotifications(trigger.new, null,true);
        }
        if(trigger.isUpdate){
            IMCC_ContractorMappingTrigHandler.updateTaskStatus(trigger.newMap, trigger.oldMap);
            IMCC_ContractorMappingTrigHandler.sendEmailAndPortalNotifications(trigger.new, trigger.oldMap,false);
        }
    } 
}