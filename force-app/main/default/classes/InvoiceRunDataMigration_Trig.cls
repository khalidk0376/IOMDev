/**
* File         :   InvoiceRunDataMigration_Trig 
* Project      :   GECI
* Created Date :   27-05-2023
* Created By   :   Girikon(Deepak)
* Test Class   :   InvoiceRunDataMigration_Trig_Test (97%)
* ******************************************************************************************************
@description : to handle sequencing of Invoice Schedulers based on Target Date While Data Migration. 
*******************************************************************************************************
* Modification log :
*/
public with sharing class InvoiceRunDataMigration_Trig implements TriggerInterface_InvoiceRun.Runnable 
{
    /** 
    *   @description [Call Interface Class to fetch the new list and old map of InvoiceRun]
    *   @param trig [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_InvoiceRun.Trig trig){
        try{
            //Set of Billing Invoice Scheduler Ids
            Set<Id> invoiceSchedulerIds = new Set<Id>();
             //Map of Billing Ivoice Run Id for Billing Invoice Scheduler Id
            Map<Id,Id> mapInvSCIdAndInvRunId = new Map<Id,Id>();

            for(blng__InvoiceRun__c run : trig.newList){
                //Process Only If Billing Ivoice Run status is Completed Or Completed with errors
                if((run.blng__Status__c == 'Completed' || run.blng__Status__c == 'Completed with errors') && run.blng__Status__c != trig.oldMap.get(run.Id).blng__Status__c){
                    invoiceSchedulerIds.add(run.blng__InvoiceScheduler__c);
                    mapInvSCIdAndInvRunId.put(run.blng__InvoiceScheduler__c, run.Id);
                }
            }

            if(!invoiceSchedulerIds.isEmpty()){
                //Get Billing Invoice Schedulers Detail
                List<blng__InvoiceScheduler__c> listInvoiceSchedulers = [SELECT Id,DM_Temp_Invoice_Scheduler__c,DM_Temp_Invoice_Scheduler__r.DM_Invoice_Scheduler_Group__c,DM_Temp_Invoice_Scheduler__r.Invoice_Target_Date__c,DM_Temp_Invoice_Scheduler__r.Sequence__c,DM_Temp_Invoice_Scheduler__r.Status__c,DM_Temp_Invoice_Scheduler__r.DM_Invoice_Scheduler_Group__r.Invoice_Batch__c FROM blng__InvoiceScheduler__c WHERE Id IN:invoiceSchedulerIds WITH SECURITY_ENFORCED];

                //Map of Billing Invoice Schedulers
                Map<Id,blng__InvoiceScheduler__c> mapInvoiceSchedulers = new Map<Id,blng__InvoiceScheduler__c>();
                //Set of Data Migration Invoice Scheduler Group Ids
                Set<Id> groupIds = new Set<Id>();

                if(!listInvoiceSchedulers.isEmpty()){
                    for(blng__InvoiceScheduler__c invSc : listInvoiceSchedulers){
                        //Check If Billing Invoice Scheduler is part of Data Migration Run and only then process further
                        if(String.isNotBlank(invSc.DM_Temp_Invoice_Scheduler__c)){
                            mapInvoiceSchedulers.put(invSc.Id, invSc);
                            groupIds.add(invSc.DM_Temp_Invoice_Scheduler__r.DM_Invoice_Scheduler_Group__c);
                        }
                    }
                }

                //Map of Data Migration Invoice Scheduler records for a Data Migration Invoice Scheduler Group and Sequence
                Map<String,DM_Temp_Invoice_Scheduler__c> mapDMTempInvoiceSchedulerOnTempKey = new Map<String,DM_Temp_Invoice_Scheduler__c>();
                if(!groupIds.isEmpty()){
                    //Get Data Migration Invoice Scheduler records for Data Migration Invoice Scheduler Groups
                    List<DM_Temp_Invoice_Scheduler__c> listDMInvoiceSchedulers = [SELECT Id,DM_Invoice_Scheduler_Group__c,Invoice_Target_Date__c,Sequence__c,Status__c FROM DM_Temp_Invoice_Scheduler__c WHERE DM_Invoice_Scheduler_Group__c IN:groupIds WITH SECURITY_ENFORCED];

                    //Create Map of Data Migration Invoice Scheduler records for a Data Migration Invoice Scheduler Group and Sequence
                    for(DM_Temp_Invoice_Scheduler__c dmInvSc : listDMInvoiceSchedulers){
                        //Key based on Data Migration Invoice Scheduler Group Id and Data Migration Invoice Scheduler Sequence number
                        String key = dmInvSc.DM_Invoice_Scheduler_Group__c + '_' + String.valueOf(dmInvSc.Sequence__c);
                        mapDMTempInvoiceSchedulerOnTempKey.put(key,dmInvSc);
                    }
                }

                //Map of Data Migration Invoice Scheduler records for update
                Map<Id,DM_Temp_Invoice_Scheduler__c> mapDmTempInvScforUpdate = new Map<Id,DM_Temp_Invoice_Scheduler__c>();
                //List of Billing Invoice Scheduler for Insert
                List<blng__InvoiceScheduler__c> listInvScInsert = new List<blng__InvoiceScheduler__c>();

                if(!mapInvoiceSchedulers.isEmpty()){
                    //Loop on Billing Invoice Scheduler ids related to Data Migration Run
                    for(Id invScId : mapInvoiceSchedulers.keySet()){
                        //Billing Invoice Scheduler Record
                        blng__InvoiceScheduler__c invSc = mapInvoiceSchedulers.get(invScId);

                        //Billing Invoice Run Id for Billing Invoice Scheduler
                        Id invRunId = mapInvSCIdAndInvRunId.get(invScId);

                        //Billing Invoice Run Record
                        blng__InvoiceRun__c run = trig.newMap.get(invRunId);

                        //Data Migration Invoice Scheduler record Id for Billing Invoice Scheduler
                        Id dmTempInvoiceSchedulerId = invSc.DM_Temp_Invoice_Scheduler__c;

                        //Data Migration Invoice Scheduler Group Id
                        Id groupId = invSc.DM_Temp_Invoice_Scheduler__r.DM_Invoice_Scheduler_Group__c;

                        //Current Sequence of Data Migration Invoice Scheduler record processed
                        Integer currentSequence = Integer.valueOf(invSc.DM_Temp_Invoice_Scheduler__r.Sequence__c);

                        //Invoive Batch name for Data Migration Invoice Scheduler Group
                        String batch = invSc.DM_Temp_Invoice_Scheduler__r.DM_Invoice_Scheduler_Group__r.Invoice_Batch__c;

                        //Billing Invoice Run Status
                        String runStatus = run.blng__Status__c;

                        //Update Staus of Data Migration Invoice Scheduler record. 
                        //Set in Completed if Billing Invoice Run is Completed and set it to Error if Billing Invoice Run is Completed with errors
                        DM_Temp_Invoice_Scheduler__c dmInvScUpd = new DM_Temp_Invoice_Scheduler__c(Id=dmTempInvoiceSchedulerId);
                        dmInvScUpd.Status__c = 'Completed';
                        if(runStatus == 'Completed with errors'){dmInvScUpd.Status__c = 'Error';}
                        mapDmTempInvScforUpdate.put(dmInvScUpd.Id,dmInvScUpd);

                        //If Current Billing Invoice Run is Completed only then schedule next Billing Invoice Scheduler
                        if(runStatus == 'Completed'){
                            //Next Sequence number to be proessed
                            Integer nextSequence = currentSequence + 1;

                            //Key based on Data Migration Invoice Scheduler Group Id and Data Migration Invoice Scheduler Sequence number
                            String key = groupId + '_' + String.valueOf(nextSequence);

                            //Check if Data Migration Invoice Scheduler record exist for next Sequence or not.
                            if(mapDMTempInvoiceSchedulerOnTempKey.containsKey(key)){
                                //Next Data Migration Invoice Scheduler record
                                DM_Temp_Invoice_Scheduler__c nextDMInvSc = mapDMTempInvoiceSchedulerOnTempKey.get(key);
                                
                                //Create Billing Invoice Scheduler for Next Data Migration Invoice Scheduler record
                                blng__InvoiceScheduler__c invSCInsert = createScheduler(nextDMInvSc, batch);
                                listInvScInsert.add(invSCInsert);
                            }
                        }
                    }
                }

                //Update Current Data Migration Invoice Scheduler records Status
                if(!mapDmTempInvScforUpdate.isEmpty()){update mapDmTempInvScforUpdate.values();}

                //Inser Billing Invoice Schedulers for Next Data Migration Invoice Scheduler records
                if(!listInvScInsert.isEmpty() && Schema.sObjectType.blng__InvoiceScheduler__c.isCreateable()){insert listInvScInsert;}
            }

            //Check if More Data Migration Invoice Scheduler records exist or not in Queued Status
            List<DM_Temp_Invoice_Scheduler__c> listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Queued' WITH SECURITY_ENFORCED];
            //if no Data Migration Invoice Scheduler records found in Queued Status then disable Billing Invoice Run Trigger
            if(listDMIncSC.isEmpty()){
                //disable Billing Invoice Run Trigger
                updateDMInvoiceRunTrigger(false);
            }
        } 
        catch(Exception e){
            System.debug(logginglevel.DEBUG,'Exception : '+e.getMessage());
            //Log any unhandled errors to Custom Error Log Object
            HandleAllCustomException.LogException(e,'','InvoiceRunDataMigration_Trig');  
        }
    }

    /**
    * @description [This method is used to invoke data migration invoice schedulers.]
    * @param setTargetDates Set of billing target dates
    * @param invoiceBatch Invoice batch Name
    */
    public static void invokeDataMigrationSchedulers(Set<Date> setTargetDates, String invoiceBatch){
        //Lis of billing target dates
        List<Date> listTargetDates = new List<Date>();
        //Add dates to list from set for sorting
        for(Date d : setTargetDates){
            listTargetDates.add(d);
        }
        //sort the dates
        listTargetDates.sort();

        //Insert Data Migration Invoice Scheduler Group
        DM_Invoice_Scheduler_Group__c incSCGroup = new DM_Invoice_Scheduler_Group__c(Invoice_Batch__c=invoiceBatch);
        if(Schema.sObjectType.DM_Invoice_Scheduler_Group__c.isCreateable()){
            insert incSCGroup;
        }

        //List of Data Migration Invoice Schedulers for Insert
        List<DM_Temp_Invoice_Scheduler__c> listDMIncSCInsert = new List<DM_Temp_Invoice_Scheduler__c>();
        Integer sequence = 1;
        for(Date d : listTargetDates){
            //Create Data Migration Invoice Scheduler record for each target date
            DM_Temp_Invoice_Scheduler__c dmInvSC = new DM_Temp_Invoice_Scheduler__c();
            dmInvSC.Sequence__c = sequence;
            dmInvSC.DM_Invoice_Scheduler_Group__c = incSCGroup.Id;
            dmInvSC.Invoice_Target_Date__c = d;
            dmInvSC.Status__c = 'Queued';
            listDMIncSCInsert.add(dmInvSC);
            sequence++;
        }
        //Insert Data Migration Invoice Scheduler records
        if(!listDMIncSCInsert.isEmpty() && Schema.sObjectType.DM_Temp_Invoice_Scheduler__c.isCreateable()){insert listDMIncSCInsert;}

        //Get first Data Migration Invoice Scheduler record in sequence for Data Migration Invoice Scheduler Group
        List<DM_Temp_Invoice_Scheduler__c> listDMIncSC = [SELECT Id,Invoice_Target_Date__c,Sequence__c FROM DM_Temp_Invoice_Scheduler__c WHERE DM_Invoice_Scheduler_Group__c =:incSCGroup.Id AND Sequence__c=1 AND Status__c='Queued' WITH SECURITY_ENFORCED];
        if(!listDMIncSC.isEmpty()){
            //Enable Billing Invoice Run Trigger
            updateDMInvoiceRunTrigger(true);

            //Data Migration Invoice Scheduler record
            DM_Temp_Invoice_Scheduler__c dmInvSC = listDMIncSC.get(0);

            //Create Billing Invoice Scheduler for first Data Migration Invoice Scheduler record
            blng__InvoiceScheduler__c invSC = createScheduler(dmInvSC, invoiceBatch);
            if(Schema.sObjectType.blng__InvoiceScheduler__c.isCreateable()){
                insert invSC;
            }
        }
    }

    /**
    * @description [This method is used to create invoice schedulers.]
    * @param dmInvSC Data Migration Invoice Scheduler record
    * @param invoiceBatch Invoice batch Name
    * @return blng__InvoiceScheduler__c
    */
    public static blng__InvoiceScheduler__c createScheduler(DM_Temp_Invoice_Scheduler__c dmInvSC, String invoiceBatch){
        blng__InvoiceScheduler__c invoiceScheduler = new blng__InvoiceScheduler__c();
        invoiceScheduler.Name = 'DM Target Date : ' + String.valueOf(dmInvSC.Invoice_Target_Date__c) + ' Batch : ' + invoiceBatch + ' Time :' + DateTime.now().addSeconds(70);
        invoiceScheduler.blng__InvoiceBatches__c = invoiceBatch;//Invoice batch
        invoiceScheduler.blng__TargetDate__c = dmInvSC.Invoice_Target_Date__c;//Target date from  Data Migration Invoice Scheduler
        invoiceScheduler.blng__Type__c = 'Once';//set to run only one time
        invoiceScheduler.blng__IncludeAllCurrencies__c = true;//to pick all currencies
        invoiceScheduler.DM_Temp_Invoice_Scheduler__c = dmInvSC.Id;//Data Migration Invoice Scheduler Id
        invoiceScheduler.blng__StartDateTime__c = DateTime.now().addSeconds(70);//Start date time on invoice scheduler
        return invoiceScheduler;
    }

    /**
    * @description [This method is used to Enable/Disable Trigger.]
    * @param triggerStatus
    */
    public static void updateDMInvoiceRunTrigger(Boolean triggerStatus){
        //Get Billing Invoice Run Trigger Record
        List<Trigger__c> listTrigger = [SELECT Id,Enabled__c FROM Trigger__c WHERE Trigger_Name_Unique__c ='InvoiceRunDataMigration_Trig' WITH SECURITY_ENFORCED];
        for(Trigger__c t : listTrigger){
            //Enable/Disable Billing Invoice Run Trigger Record
            t.Enabled__c = triggerStatus;
        }
        if(Schema.sObjectType.Trigger__c.isUpdateable()){
            update listTrigger;
        }
    }

    /**
    * @description [This method is used to stop all Data Migration Invoice Schedulers.]
    */
    public static void stopAllDataMigrationInvSc(){
        //Disable Billing Invoice Run Trigger
        updateDMInvoiceRunTrigger(false);
    }

    /**
    * @description [This method is used to resume a group of Migration Invoice Schedulers.]
    * @param groupId
    */
    public static void resumeGroup(String groupId){
        //Get latest Data Migration Invoice Scheduler record which is not completed sorted by sequence for Data Migration Invoice Scheduler Group
        List<DM_Temp_Invoice_Scheduler__c> listDMIncSC = [SELECT Id,Invoice_Target_Date__c,Sequence__c,DM_Invoice_Scheduler_Group__r.Invoice_Batch__c FROM DM_Temp_Invoice_Scheduler__c WHERE DM_Invoice_Scheduler_Group__c =:groupId AND Status__c!='Completed' WITH SECURITY_ENFORCED ORDER BY Sequence__c LIMIT 1];

        if(!listDMIncSC.isEmpty()){
            //Enable Billing Invoice Run Trigger
            updateDMInvoiceRunTrigger(true);

            //Data Migration Invoice Scheduler record
            DM_Temp_Invoice_Scheduler__c dmInvSC = listDMIncSC.get(0);

            //Create Billing Invoice Scheduler for latest Data Migration Invoice Scheduler record
            blng__InvoiceScheduler__c invSC = createScheduler(dmInvSC, dmInvSC.DM_Invoice_Scheduler_Group__r.Invoice_Batch__c);
            if(Schema.sObjectType.blng__InvoiceScheduler__c.isCreateable()){
                insert invSC;
            }
        }
    }

    /*
    Set<Date> setTargetDates = new Set<Date>();
    Date dt = date.newinstance(2022, 12, 17);
    setTargetDates.add(dt);
    dt = date.newinstance(2022, 11, 17);
    setTargetDates.add(dt);
    dt = date.newinstance(2023, 2, 17);
    setTargetDates.add(dt);
    dt = date.newinstance(2023, 1, 17);
    setTargetDates.add(dt);
    InvoiceRunDataMigration_Trig.invokeDataMigrationSchedulers(setTargetDates,'Batch 1');
    */
}