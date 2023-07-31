/**
* File:         Trigger_Contact
* Created By:   Girikon(Ashish)
* Test Class:   ContactFieldUpdate_Test
* Coverage:     100%
* *******************************************************************************************************
* @description : Triggen on Contact that will run on before insert and before update.. 
* *******************************************************************************************************
*/
trigger Trigger_Contact on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    /**
* Description: Calling TriggerInterface_Contact class for Contact object.
*/
    TriggerInterface_Contact.Trig trig = new TriggerInterface_Contact.Trig();
    trig.isBefore = trigger.isBefore;
    trig.isAfter = trigger.isAfter;
    trig.isInsert = trigger.isInsert;
    trig.isUpdate = trigger.isUpdate;
    trig.isDelete = trigger.isDelete;
    trig.isUnDelete = trigger.isUnDelete; 
    
    /**
* Description: Calling TriggerInterfaceHelper helper class for Contact object.
*/
    TriggerInterfaceHelper.initTriggerMapAndList('Contact');
    List<Trigger__c> listTriggers = TriggerInterfaceHelper.listTriggers;
    Map<String,Map<Id,Map<String,String>>> mapTriggerRecordtypes = TriggerInterfaceHelper.mapTriggerRecordtypes;
    for (Trigger__c t : listTriggers) {
        Boolean runTrigger = false;
        if (t.Object__c == 'Contact') {
            if ((trigger.isBefore && trigger.isInsert && t.Before_Insert__c)
                || (trigger.isBefore && trigger.isUpdate && t.Before_Update__c)
                || (trigger.isBefore && trigger.isDelete && t.Before_Delete__c)
                || (trigger.isAfter && trigger.isInsert && t.After_Insert__c)
                || (trigger.isAfter && trigger.isUpdate && t.After_Update__c)
                || (trigger.isAfter && trigger.isDelete && t.After_Delete__c)
                || (trigger.isAfter && trigger.isUnDelete && t.After_UnDelete__c)) {
                    trig.oldList = new List<Contact>();
                    trig.newList = new List<Contact>();
                    trig.oldMap = new Map<Id,Contact>();
                    trig.newMap = new Map<Id,Contact>();
                    trig.triggerSize = 0;
                    for (Integer i=0; i<Trigger.size; i++) {
                        sObject accObj =(trigger.isDelete ? trigger.old : trigger.new)[i];
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
                            TriggerInterface_Contact.Runnable runnableClass;
                            try {
                                runnableClass = (TriggerInterface_Contact.Runnable) runnableType.newInstance();
                            } catch(Exception e) {
                                System.debug(logginglevel.DEBUG,'********** Trigger Class ' + t.Name + ' has an incorrect interface **********');
                            }
                            if (runnableClass != null) {
                                String executionType = (trigger.isBefore ? 'Before ' : 'After ') + (trigger.isInsert ? 'Insert' : '') + (trigger.isUpdate ? 'Update' : '') + (trigger.isDelete ? 'Delete' : '') + (trigger.isUnDelete ? 'UnDelete' : '');
                                if (!TriggerInterfaceHelper.triggerAlreadyRan.contains(t.Name + ':' + executionType)) {
                                    if (!Test.isRunningTest() && (t.Recursive_Execution_Allowed__c == null || !t.Recursive_Execution_Allowed__c)){
                                        TriggerInterfaceHelper.triggerAlreadyRan.add(t.Name + ':' + executionType);
                                    }
                                    //System.debug(logginglevel.DEBUG,'********** Trigger_Contact (' + executionType + ') Start: ' + t.Name + ' **********');
                                    Datetime startTime = Datetime.now();
                                    runnableClass.run(trig);
                                    DateTime endTime = Datetime.now();
                                    Long seconds = (endTime.getTime() - startTime.getTime())/1000;
                                    //System.debug(logginglevel.DEBUG,'********** Trigger_Contact (' + executionType + ') Finished in ' + seconds + ' seconds: ' + t.Name + ' **********');
                                    if (seconds > 10){
                                        System.debug(logginglevel.DEBUG,'********** Long running trigger **********');
                                    }    
                                }
                            }
                        } else {
                            System.debug(logginglevel.DEBUG,'********** Trigger Class ' + t.Name + ' not found **********');
                        }
                    }
                }
        }
    }
}