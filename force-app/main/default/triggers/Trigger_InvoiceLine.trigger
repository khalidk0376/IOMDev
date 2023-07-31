/**
 * Raider Data Services, TT
 * Created Date: 11/25/2019
 * *******************************************************************************************************
 * @description : Custom InvoiceLine trigger - All trigger code can be added to this component.
 * *******************************************************************************************************
 */

trigger Trigger_InvoiceLine on blng__InvoiceLine__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerInterface_InvoiceLine.Trig trig = new TriggerInterface_InvoiceLine.Trig();
    trig.isBefore = trigger.isBefore;
    trig.isAfter = trigger.isAfter;
    trig.isInsert = trigger.isInsert;
    trig.isUpdate = trigger.isUpdate;
    trig.isDelete = trigger.isDelete;
    trig.isUnDelete = trigger.isUnDelete; 
    
    TriggerInterfaceHelper.initTriggerMapAndList('blng__InvoiceLine__c');
    List<Trigger__c> listTriggers = TriggerInterfaceHelper.listTriggers;
    Map<String,Map<Id,Map<String,String>>> mapTriggerRecordtypes = TriggerInterfaceHelper.mapTriggerRecordtypes;
    
    //SObject so = Schema.getGlobalDescribe().get('blng__InvoiceLine__c').newSObject();
    //so.getSobjectType().getDescribe().fields.getMap().containsKey(fieldName);
    system.debug('testOpportunity');       
    for (Trigger__c t : listTriggers) {
           system.debug('testOpportunity'+t);    
        Boolean runTrigger = false;
        if (t.Object__c == 'blng__InvoiceLine__c') {
            if ((trigger.isBefore && trigger.isInsert && t.Before_Insert__c)
             || (trigger.isBefore && trigger.isUpdate && t.Before_Update__c)
             || (trigger.isBefore && trigger.isDelete && t.Before_Delete__c)
             || (trigger.isAfter && trigger.isInsert && t.After_Insert__c)
             || (trigger.isAfter && trigger.isUpdate && t.After_Update__c)
             || (trigger.isAfter && trigger.isDelete && t.After_Delete__c)
             || (trigger.isAfter && trigger.isUnDelete && t.After_UnDelete__c)) {
                trig.oldList = new List<blng__InvoiceLine__c>();
                trig.newList = new List<blng__InvoiceLine__c>();
                trig.oldMap = new Map<Id,blng__InvoiceLine__c>();
                trig.newMap = new Map<Id,blng__InvoiceLine__c>();
                trig.triggerSize = 0;
                for (Integer i=0; i<Trigger.size; i++) {
                    sObject accObj =(trigger.isDelete ? trigger.old : trigger.new)[i];
                    //if (!mapTriggerRecordtypes.containsKey(t.Name) || mapTriggerRecordtypes.get(t.Name).containsKey((trigger.isDelete ? trigger.old : trigger.new)[i].RecordtypeId)) {
                    if (t.Run_for_Recordypes__c == 'All' || (mapTriggerRecordtypes.containsKey(t.Name) && mapTriggerRecordtypes.get(t.Name).containsKey(String.valueOf(accObj.get('RecordtypeId'))))) {
                        trig.triggerSize++;
                        if (trigger.isUpdate || trigger.isDelete) {
                            trig.oldList.add(trigger.old[i]);
                            trig.oldMap.put(trigger.old[i].Id, trigger.old[i]);
                        }
                        if (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete){
                            trig.newList.add(trigger.new[i]);
                        }
                        if (trigger.isUpdate || (trigger.isInsert && trigger.isAfter)){
                            trig.newMap.put(trigger.new[i].Id, trigger.new[i]);
                        }
                    }
                }
                if (trig.triggerSize > 0) {
                    trig.mapRtIdsToParams = mapTriggerRecordtypes.get(t.Name);
                    Type runnableType = Type.forName(t.Name);
                    if (runnableType != null) {
                        TriggerInterface_InvoiceLine.Runnable runnableClass;
                        try {
                            runnableClass = (TriggerInterface_InvoiceLine.Runnable) runnableType.newInstance();
                        } catch(Exception e) {
                            system.debug('********** Trigger Class ' + t.Name + ' has an incorrect interface **********');
                        }
                        if (runnableClass != null) {
                            String executionType = (trigger.isBefore ? 'Before ' : 'After ') + (trigger.isInsert ? 'Insert' : '') + (trigger.isUpdate ? 'Update' : '') + (trigger.isDelete ? 'Delete' : '') + (trigger.isUnDelete ? 'UnDelete' : '');
                            if (!TriggerInterfaceHelper.triggerAlreadyRan.contains(t.Name + ':' + executionType)) {
                                if (!Test.isRunningTest() && (t.Recursive_Execution_Allowed__c == null || !t.Recursive_Execution_Allowed__c)){
                                    TriggerInterfaceHelper.triggerAlreadyRan.add(t.Name + ':' + executionType);
                                }
                                system.debug('********** Trigger_InvoiceLine (' + executionType + ') Start: ' + t.Name + ' **********');
                                Datetime startTime = Datetime.now();
                                runnableClass.run(trig);
                                DateTime endTime = Datetime.now();
                                Long seconds = (endTime.getTime() - startTime.getTime())/1000;
                                system.debug('********** Trigger_InvoiceLine (' + executionType + ') Finished in ' + seconds + ' seconds: ' + t.Name + ' **********');
                                if (seconds > 10){
                                    system.debug('********** Long running trigger **********');
                                }
                            }
                        }
                    } else {
                        system.debug('********** Trigger Class ' + t.Name + ' not found **********');
                    }
                }
            }
        }
    }
   
}