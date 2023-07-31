/**
* File         :      Trigger_BLNG_InvoiceRun
* Project      :      IOM
* Created Date :      23-02-2022
* Created By   :      Girikon(Deepak)
* Test Class   :      InvoiceTaxCallout_Trig_Test
* Coverage     :      96%
* *******************************************************************************************************
* @description : Generic Trigger on blng__InvoiceRun__c 
* *******************************************************************************************************
*/
trigger Trigger_BLNG_InvoiceRun on blng__InvoiceRun__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    /**
    * Description: Calling TriggerInterface_InvoiceRun class for blng__InvoiceRun__c object.
    */
    TriggerInterface_InvoiceRun.Trig trig = new TriggerInterface_InvoiceRun.Trig();
    trig.isBefore = trigger.isBefore;
    trig.isAfter = trigger.isAfter;
    trig.isInsert = trigger.isInsert;
    trig.isUpdate = trigger.isUpdate;
    trig.isDelete = trigger.isDelete;
    trig.isUnDelete = trigger.isUnDelete; 

    /**
    * Description: Calling TriggerInterfaceHelper helper class for blng__InvoiceRun__c object.
    */
    TriggerInterfaceHelper.initTriggerMapAndList('blng__InvoiceRun__c');
    List<Trigger__c> listTriggers       =   TriggerInterfaceHelper.listTriggers;
    Map<String,Map<Id,Map<String,String>>> mapTriggerRecordtypes    =   TriggerInterfaceHelper.mapTriggerRecordtypes;
    for (Trigger__c t : listTriggers) 
    {
        if (t.Object__c == 'blng__InvoiceRun__c')
        {
            if ((trigger.isBefore && trigger.isInsert && t.Before_Insert__c)
             || (trigger.isBefore && trigger.isUpdate && t.Before_Update__c)
             || (trigger.isBefore && trigger.isDelete && t.Before_Delete__c)
             || (trigger.isAfter && trigger.isInsert && t.After_Insert__c)
             || (trigger.isAfter && trigger.isUpdate && t.After_Update__c)
             || (trigger.isAfter && trigger.isDelete && t.After_Delete__c)
             || (trigger.isAfter && trigger.isUnDelete && t.After_UnDelete__c))
            {
                trig.oldList = new List<blng__InvoiceRun__c>();
                trig.newList = new List<blng__InvoiceRun__c>();
                trig.oldMap = new Map<Id,blng__InvoiceRun__c>();
                trig.newMap = new Map<Id,blng__InvoiceRun__c>();
                trig.triggerSize = 0;
                for (Integer i=0; i<Trigger.size; i++)
                {
                    sObject sObj  =   (trigger.isDelete ? trigger.old : trigger.new)[i];
                    if (t.Run_for_Recordypes__c == 'All' || (mapTriggerRecordtypes.containsKey(t.Name) && mapTriggerRecordtypes.get(t.Name).containsKey(String.valueOf(sObj.get('RecordtypeId')))))
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
                        if (trigger.isUpdate || (trigger.isInsert && trigger.isAfter)){
                            trig.newMap.put(trigger.new[i].Id, trigger.new[i]);
                        }
                    }
                }
                if (trig.triggerSize > 0) 
                {
                    trig.mapRtIdsToParams   =   mapTriggerRecordtypes.get(t.Name);
                    Type runnableType       =   Type.forName(t.Name);
                    if (runnableType != null) 
                    {
                        TriggerInterface_InvoiceRun.Runnable runnableClass;
                        try 
                        {
                            runnableClass = (TriggerInterface_InvoiceRun.Runnable) runnableType.newInstance();
                        } 
                        catch(Exception e) {
                            System.debug(LoggingLevel.Debug, '********** Trigger Class ' + t.Name + ' has an incorrect interface **********');
                        }
                        if (runnableClass != null)
                        {
                            String executionType    =   (trigger.isBefore ? 'Before ' : 'After ') + (trigger.isInsert ? 'Insert' : '') + (trigger.isUpdate ? 'Update' : '') + (trigger.isDelete ? 'Delete' : '') + (trigger.isUnDelete ? 'UnDelete' : '');
                            if (!TriggerInterfaceHelper.triggerAlreadyRan.contains(t.Name + ':' + executionType))
                            {
                                if (!Test.isRunningTest() && (t.Recursive_Execution_Allowed__c == null || !t.Recursive_Execution_Allowed__c))
                                {
                                    TriggerInterfaceHelper.triggerAlreadyRan.add(t.Name + ':' + executionType);
                                }
                                System.debug(LoggingLevel.Debug, '********** Trigger_Booth (' + executionType + ') Start: ' + t.Name + ' **********');
                                Datetime startTime = Datetime.now();
                                runnableClass.run(trig);
                                DateTime endTime = Datetime.now();
                                Long seconds = (endTime.getTime() - startTime.getTime())/1000;
                                System.debug(LoggingLevel.Debug, '********** Trigger_Booth (' + executionType + ') Finished in ' + seconds + ' seconds: ' + t.Name + ' **********');
                                if (seconds > 10)
                                {
                                    System.debug(LoggingLevel.Debug, '********** Long running trigger **********');
                                }    
                            }
                        }
                    } else
                    {
                        System.debug(LoggingLevel.Debug, '********** Trigger Class ' + t.Name + ' not found **********');
                    }
                }
            }
        }
    }
}