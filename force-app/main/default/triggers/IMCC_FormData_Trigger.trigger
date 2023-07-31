/**
* Created/Modified By    : Girikon(Deepak)
* Created On             : 06-06-2022
* @description           : This trigger is for form data overall status
* Test Class             : FBUtils
* Code Coverage          : 100%
* Modified by 
**/
trigger IMCC_FormData_Trigger on Form_Data__c (before insert, before update, after update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_FormData_Trigger' LIMIT 1];
    if(triggerConfiguration != null && (triggerConfiguration.Before_Insert__c || triggerConfiguration.Before_Update__c || triggerConfiguration.After_Update__c)){   
        IMCC_FormData_Trigger_Handler.updateFormDataOverallStatus(Trigger.new, Trigger.oldMap, Trigger.isAfter);
    }
}