/**
* Created By     :  Girikon(Arushi[IMCC-58])
* Created On     :  20/12/2021
* Modified By    :  Girikon(Arushi[IMCC-59])
* Modified On    :  27/12/2021
* @description   :  This trigger works on before event of Purchase_Data__c record
* Apex Test Class: IMCC_SyncBadgeNumbersBulkCtrl_Test(93%)
**/

trigger IMCC_PurchaseData_Trig on Purchase_Data__c (before insert, before update, after insert, after update) {
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_PurchaseData_Trig' LIMIT 1];
    if(trigger.isBefore && triggerConfiguration != null){
        if((trigger.isInsert && triggerConfiguration.Before_Insert__c) || (trigger.isUpdate && triggerConfiguration.Before_Update__c)){
            Set<Id> contactEditionMappingSet = new Set<Id>();
            List<Purchase_Data__c> purchaseDataList = new List<Purchase_Data__c>();
            
            for(Purchase_Data__c pdData : Trigger.New){
                if(trigger.isInsert){
                    contactEditionMappingSet.add(pdData.Contact_Edition_Mapping__c);
                    if(pdData.Quantity_Area__c != null){
                        purchaseDataList.add(pdData);
                    }
                }
                if(trigger.isUpdate && pdData.Quantity_Area__c != null){
                    purchaseDataList.add(pdData);
                }
            }
            if(!purchaseDataList.isEmpty())IMCC_PurchaseDataTriggerHandler.recalculateBadge(purchaseDataList,true);
            IMCC_PurchaseDataTriggerHandler.additionalBadge(Trigger.New, contactEditionMappingSet);
        }
    }
    if(trigger.isAfter && triggerConfiguration != null){
        if(trigger.isInsert && triggerConfiguration.After_Insert__c){
            IMCC_PurchaseDataTriggerHandler.notifyUserToAssignContractor(Trigger.NewMap, null);
            IMCC_ManageFormDataRecords.handleAfterInsertAfterUpdatePurchaseData(Trigger.New, null,true);
        }
        if(trigger.isUpdate && triggerConfiguration.After_Update__c){
            IMCC_PurchaseDataTriggerHandler.notifyUserToAssignContractor(Trigger.NewMap, Trigger.OldMap);
            IMCC_ManageFormDataRecords.handleAfterInsertAfterUpdatePurchaseData(Trigger.New, Trigger.OldMap,false);
        }
    }
}