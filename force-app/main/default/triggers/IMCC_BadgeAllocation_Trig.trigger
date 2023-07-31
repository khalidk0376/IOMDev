/**
* Created By     :  Girikon(Shiv[IMCC-4279])
* Created On     :  05/09/2022
* @description   :  This trigger works on after insert or after update event of Badge_Allocation__c record
Unlimited Badges checkbox is checked on Badge_Allocation_c then Unlimited Badges checkbox will be checked on purchase Data 
on after insert or after update of Badge Allocation. 
* Apex Test Class: IMCC_BadgeAllocationTriggerHandler_Test(100%)
**/

trigger IMCC_BadgeAllocation_Trig on Badge_Allocation__c (after insert, after update) {
    Triggers_Configuration__mdt triggerConfiguration = IMCC_UtilityMethods.getTriggerConfiguration('IMCC_BadgeAllocation_Trig');

    if(Trigger.isAfter && triggerConfiguration != null){
        if((Trigger.isInsert && triggerConfiguration.After_Insert__c) || (Trigger.isUpdate && triggerConfiguration.After_Update__c)){
            IMCC_BadgeAllocationTriggerHandler.handleAfterInsertAfterUpdateBadgeAllocation(Trigger.NewMap, Trigger.oldMap);
        }
    }
}