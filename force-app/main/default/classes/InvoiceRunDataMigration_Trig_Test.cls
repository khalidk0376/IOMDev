/**
* File:         InvoiceRunDataMigration_Trig_Test
* Project:      GECI
* Created Date: 27-05-2023
* Created By:   Girikon(Deepak)
* *********************************************************************************
* @description  : Code Covrage for InvoiceRunDataMigration_Trig(97%)
* *********************************************************************************
* Modification log -- 
*/ 
@IsTest
private class InvoiceRunDataMigration_Trig_Test {

    // Setting up the database for the test
    @testSetup 
    static void setup() 
    {
        // Trigger Record 
        //Create Trigger test record 
        Trigger__c trig = new Trigger__c(Name = 'InvoiceRunDataMigration_Trig' , Trigger_Name_Unique__c='InvoiceRunDataMigration_Trig',Enabled__c=false,Object__c='blng__InvoiceRun__c',Run_for_Recordypes__c='All',Description__c='to handle sequencing of Invoice Schedulers based on Target Date While Data Migration.',Execution_Order__c=20,After_Update__c=true);
        Insert trig;
    }

    @IsTest
    static void testMethod1() {
        Test.startTest();
        Set<Date> setTargetDates = new Set<Date>();
        Date dt = date.newinstance(2022, 12, 17);
        setTargetDates.add(dt);
        dt = date.newinstance(2023, 1, 17);
        setTargetDates.add(dt);
        dt = date.newinstance(2023, 2, 17);
        setTargetDates.add(dt);
        dt = date.newinstance(2023, 3, 17);
        setTargetDates.add(dt);
        InvoiceRunDataMigration_Trig.invokeDataMigrationSchedulers(setTargetDates,'Batch 1');

        List<DM_Invoice_Scheduler_Group__c> listGroups = [SELECT Id FROM DM_Invoice_Scheduler_Group__c];
        System.assertEquals(1,listGroups.size(),'Invoice Scheduler Group Not Created.');

        List<DM_Temp_Invoice_Scheduler__c> listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c];
        System.assertEquals(4,listDMIncSC.size(),'All DM Invoice Schedulers Not Created.');

        List<blng__InvoiceScheduler__c> listInvSc = [SELECT Id,blng__TargetDate__c FROM blng__InvoiceScheduler__c];
        System.assertEquals(1,listInvSc.size(),'More than one Invoice Schedulers Created.');

        blng__InvoiceRun__c run = new blng__InvoiceRun__c(blng__TargetDate__c=listInvSc.get(0).blng__TargetDate__c,blng__Status__c='Step 7 : Posting Invoices - Processing',blng__InvoiceScheduler__c=listInvSc.get(0).Id);
        insert run;
        
        List<blng__InvoiceRun__c> listRun = [SELECT Id,blng__Status__c FROM blng__InvoiceRun__c];
        System.debug(LoggingLevel.Debug, 'listRun==='+listRun);
        
        blng__BillingConfig__c disableBillingTrigger = new blng__BillingConfig__c(Name = 'DISABLE_TRIGGERS',
                                                                          blng__FieldType__c = 'Boolean',
                                                                          blng__Description__c = 'Disable triggers',
                                                                          blng__Category__c ='General',
                                                                          blng__BooleanValue__c = true);
        insert disableBillingTrigger;

        run.blng__Status__c = 'Completed';
        update run;
        
        disableBillingTrigger.blng__BooleanValue__c = false;
        update disableBillingTrigger;

        listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Completed'];
        System.assertEquals(1,listDMIncSC.size(),'More Than One DM Invoice Schedulers Completed.');

        listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Queued'];
        System.assertEquals(3,listDMIncSC.size(),'Queued Count is wrong.');

        listInvSc = [SELECT Id,blng__TargetDate__c FROM blng__InvoiceScheduler__c ORDER BY CreatedDate];
        System.assertEquals(2,listInvSc.size(),'More than Two Invoice Schedulers Created.');

        run = new blng__InvoiceRun__c(blng__TargetDate__c=listInvSc.get(1).blng__TargetDate__c,blng__Status__c='Started',blng__InvoiceScheduler__c=listInvSc.get(1).Id);
        insert run;

        run.blng__Status__c = 'Completed with errors';
        update run;

        listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Completed'];
        System.assertEquals(1,listDMIncSC.size(),'More Than One DM Invoice Schedulers Completed.');

        listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Error'];
        System.assertEquals(1,listDMIncSC.size(),'More Than One DM Invoice Schedulers in Error.');

        listDMIncSC = [SELECT Id FROM DM_Temp_Invoice_Scheduler__c WHERE Status__c='Queued'];
        System.assertEquals(2,listDMIncSC.size(),'Queued Count is wrong.');

        listInvSc = [SELECT Id,blng__TargetDate__c FROM blng__InvoiceScheduler__c ORDER BY CreatedDate];
        System.assertEquals(2,listInvSc.size(),'More than Two Invoice Schedulers Created.');
        
        InvoiceRunDataMigration_Trig.stopAllDataMigrationInvSc();
        InvoiceRunDataMigration_Trig.resumeGroup(listGroups.get(0).Id);
        Test.stopTest();
    }
}