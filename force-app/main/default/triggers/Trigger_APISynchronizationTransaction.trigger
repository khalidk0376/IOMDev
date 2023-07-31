/*
* File :         Trigger_APISynchronizationTransaction
* Project      :   Order & Billing Plateform
* Created Date :   14th Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class:   APISynchronizationTransaction_Trig_Test (96%)
*********************************************************************************************
* @description : Generic trigger on API_Synchronization_Transaction__c which should call from Trigger app for alteration of  any API Sync Transaction record.
*********************************************************************************************
*/
trigger Trigger_APISynchronizationTransaction on API_Synchronization_Transaction__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
    TriggerInterface_APISyncTransaction.Trig trig = new TriggerInterface_APISyncTransaction.Trig();
    trig.isBefore = trigger.isBefore;
    trig.isAfter = trigger.isAfter;
    trig.isInsert = trigger.isInsert;
    trig.isUpdate = trigger.isUpdate;
    trig.isDelete = trigger.isDelete;
    trig.isUnDelete = trigger.isUnDelete; 
    
    TriggerInterfaceHelper.initTriggerMapAndList('API_Synchronization_Transaction__c');
    List<Trigger__c> listTriggers = TriggerInterfaceHelper.listTriggers;
    Map<String,Map<Id,Map<String,String>>> mapTriggerRecordtypes = TriggerInterfaceHelper.mapTriggerRecordtypes;
    
    for (Trigger__c t : listTriggers) 
    { 
        Boolean runTrigger = false;
        System.debug(LoggingLevel.DEBUG, 'runTrigger=='+runTrigger);
        if (t.Object__c == 'API_Synchronization_Transaction__c') 
        {
            if ((trigger.isBefore && trigger.isInsert && t.Before_Insert__c)
             || (trigger.isBefore && trigger.isUpdate && t.Before_Update__c)
             || (trigger.isBefore && trigger.isDelete && t.Before_Delete__c)
             || (trigger.isAfter && trigger.isInsert && t.After_Insert__c)
             || (trigger.isAfter && trigger.isUpdate && t.After_Update__c)
             || (trigger.isAfter && trigger.isDelete && t.After_Delete__c)
             || (trigger.isAfter && trigger.isUnDelete && t.After_UnDelete__c)) 
             {
                trig.oldList = new List<API_Synchronization_Transaction__c>();
                trig.newList = new List<API_Synchronization_Transaction__c>();
                trig.oldMap = new Map<Id,API_Synchronization_Transaction__c>();
                trig.newMap = new Map<Id,API_Synchronization_Transaction__c>();
                trig.triggerSize = 0;
                for (Integer i=0; i<Trigger.size; i++) 
                {
                    sObject conObj =(trigger.isDelete ? trigger.old : trigger.new)[i];
                    if (t.Run_for_Recordypes__c == 'All' || (mapTriggerRecordtypes.containsKey(t.Name) && mapTriggerRecordtypes.get(t.Name).containsKey(String.valueOf(conObj.get('RecordtypeId'))))) 
                    {
                        trig.triggerSize++;
                        if (trigger.isUpdate || trigger.isDelete) 
                       {
                            trig.oldList.add(trigger.old[i]);
                            trig.oldMap.put(trigger.old[i].Id, trigger.old[i]);
                        }
                        if (trigger.isInsert || trigger.isUpdate || trigger.isUnDelete)
                        {
                            trig.newList.add(trigger.new[i]);
                        }
                        if (trigger.isUpdate || (trigger.isInsert && trigger.isAfter))
                        {
                            trig.newMap.put(trigger.new[i].Id, trigger.new[i]);
                        }
                    }
                }
                if (trig.triggerSize > 0) 
                {
                    trig.mapRtIdsToParams = mapTriggerRecordtypes.get(t.Name);
                    Type runnableType = Type.forName(t.Name);
                    if (runnableType != null) 
                    {
                        TriggerInterface_APISyncTransaction.Runnable runnableClass;
                        try 
                        {
                            runnableClass = (TriggerInterface_APISyncTransaction.Runnable) runnableType.newInstance();
                        } 
                        catch(Exception e) 
                        {
                            system.debug(LoggingLevel.DEBUG, '********** Trigger Class ' + t.Name + ' has an incorrect interface **********');
                        }
                        if (runnableClass != null) 
                        {
                            String executionType = (trigger.isBefore ? 'Before ' : 'After ') + (trigger.isInsert ? 'Insert' : '') + (trigger.isUpdate ? 'Update' : '') + (trigger.isDelete ? 'Delete' : '') + (trigger.isUnDelete ? 'UnDelete' : '');
                            if (!TriggerInterfaceHelper.triggerAlreadyRan.contains(t.Name + ':' + executionType)) 
                            {
                                if (!Test.isRunningTest() && (t.Recursive_Execution_Allowed__c == null || !t.Recursive_Execution_Allowed__c))
                                {
                                    TriggerInterfaceHelper.triggerAlreadyRan.add(t.Name + ':' + executionType);
                                }
                                system.debug(LoggingLevel.DEBUG, '********** TriggerInterface_APISyncTransaction (' + executionType + ') Start: ' + t.Name + ' **********');
                                Datetime startTime = Datetime.now();
                                runnableClass.run(trig);
                                DateTime endTime = Datetime.now();
                                Long seconds = (endTime.getTime() - startTime.getTime())/1000;
                                system.debug(LoggingLevel.DEBUG, '********** TriggerInterface_APISyncTransaction (' + executionType + ') Finished in ' + seconds + ' seconds: ' + t.Name + ' **********');
                                if (seconds > 10)
                                {
                                    system.debug(LoggingLevel.DEBUG, '********** Long running trigger **********');
                                }
                            }
                        }
                    } 
                    else 
                    {
                        system.debug(LoggingLevel.DEBUG, '********** Trigger Class ' + t.Name + ' not found **********');
                    }
                }
            }
        }
    }    
}