/**
* Created By     :  Girikon(Arushi[IMCC-763])
* Created On     :  28/03/2022
* @description   :  On a new customer username creation in Salesforce, currently there are extra characters created along with the email in the username. This will need to be removed for the ease of use from customer's side. 
* Apex Test Class: IMCC_UserTriggerHandler_Test(100%)
**/
trigger IMCC_User_Trig on User(before insert, before update, after update){
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_User_Trig' LIMIT 1];
    if(Trigger.isBefore && triggerConfiguration != null && (triggerConfiguration.Before_Insert__c || triggerConfiguration.Before_Update__c)){                                                       
        IMCC_UserTriggerHandler.insertUpdateCommunityUserDetails(Trigger.New, Trigger.isUpdate);
    }
    
    if(Trigger.isAfter && triggerConfiguration != null && triggerConfiguration.After_Update__c){                                                       
        IMCC_UserTriggerHandler.sendEmailToActiveUser(Trigger.NewMap, Trigger.oldMap);
    }
}