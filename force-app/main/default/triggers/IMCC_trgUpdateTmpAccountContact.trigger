/*
Created By    : Aishwarya[IMCC-90]
Test Class    : IMCC_StandContractorCtrl_Test()
Created/Modified By   :  01/02/2022
*/
trigger IMCC_trgUpdateTmpAccountContact on TempContact__c (after update) {
    Boolean ifApproved = false;
    Boolean ifRejected = false;
    Set<Id> approvedIds = new Set<Id>();
    Set<Id> rejectIds = new Set<Id>();
    Triggers_Configuration__mdt triggerConfiguration = [SELECT Before_Insert__c, Before_Update__c, Before_Delete__c, After_Insert__c, After_Update__c, After_Delete__c, After_Undelete__c
                                                        FROM Triggers_Configuration__mdt WHERE Trigger_Name__c = 'IMCC_trgUpdateTmpAccountContact' LIMIT 1];
    if(triggerConfiguration != null && triggerConfiguration.After_Update__c){
    for(TempContact__c tempcon :Trigger.New){
        if(trigger.oldMap.get(tempcon.Id).Contractor_Status__c != tempcon.Contractor_Status__c && tempcon.Contractor_Status__c == 'Approved'){
            approvedIds.add(tempcon.Id);
        }
        else if(trigger.oldMap.get(tempcon.Id).Contractor_Status__c != tempcon.Contractor_Status__c && tempcon.Contractor_Status__c == 'Rejected'){
            rejectIds.add(tempcon.Id);
        }
    }
    if(!approvedIds.isEmpty()){
        String msg = IMCC_ApproveContractorCtrl.approveStandContractor(approvedIds);
        if(msg!='Successfully  Approved!'){
            for(TempContact__c tc : Trigger.New){
                tc.addError(msg);
            }
        }
    }
    else if(!rejectIds.isEmpty()){
        IMCC_ApproveContractorCtrl.rejectContarctor(rejectIds);
        }
    }
}