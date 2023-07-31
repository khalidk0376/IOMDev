/**
* Created/Modified By    : Girikon(Garima)
* Created On             : 03-03-2022
* @description           : This trigger is for updating form data status after approval
* Test Class             : FBUtilTest
* Code Coverage          : 100%
* Modification Log-----  : [Aishwarya IMCC-1681 12 Apr 2022]
* Modified by 
**/
trigger Trig_UpdateStatusOnFormData on Form_Response_Entry__c (before insert,before update,after update, after delete, before delete){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'Trig_UpdateStatusOnFormData' LIMIT 1];
    if(triggerConfiguration != null && (triggerConfiguration.Before_Insert__c || triggerConfiguration.Before_Update__c || triggerConfiguration.After_Update__c || 
                                        triggerConfiguration.After_Delete__c || triggerConfiguration.Before_Delete__c))
    {                                                    
        if(Trigger.isAfter && Trigger.isUpdate){
            Trig_UpdateStatusOnFormData_Handler.updateFormDataStatus(Trigger.new, Trigger.oldMap,false);
            Trig_UpdateStatusOnFormData_Handler.sendFormResponseEmails(Trigger.newMap.keySet(),Trigger.oldMap,false);
        }
        if(Trigger.isAfter && Trigger.isDelete){
            Trig_UpdateStatusOnFormData_Handler.updateFormDataStatus(Trigger.old,null,true);
        }
        if(Trigger.isBefore && Trigger.isDelete){
            Trig_UpdateStatusOnFormData_Handler.sendFormResponseEmails(Trigger.oldMap.keySet(),Trigger.oldMap,true);
        }
        if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)){
            Trig_UpdateStatusOnFormData_Handler.updateFormResponseEntry(Trigger.new);
        }
    }
}