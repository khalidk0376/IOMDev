/**
* File:         CreateInvoiceSchedulerSchedulable_Test
* Project:      IOM
* Created Date: 22 October 2022
* Created By:   Girikon(Deepak)
* *********************************************************************************
* @description  : Code Covrage for CreateInvoiceSchedulerSchedulable(100%)
* *********************************************************************************
* Modification log -- 
*/ 
@IsTest
private class CreateInvoiceSchedulerSchedulable_Test {

    @IsTest
    static void testMethod1() {
        Test.startTest();
        CreateInvoiceSchedulerSchedulable obj = new CreateInvoiceSchedulerSchedulable(null);
        String sch = '0 0 23 * * ?'; 
        String jobID = system.schedule('IOM Invoice generation Scheduler', sch, obj);
        System.debug(LoggingLevel.Debug, 'jobId ==> '+jobId);
        Test.stopTest();
        System.assertEquals(1,[select id from blng__InvoiceScheduler__c].size(),'Error');
    }

    @IsTest
    static void testMethod2() {
        Test.startTest();
        CreateInvoiceSchedulerSchedulable obj = new CreateInvoiceSchedulerSchedulable('USD');
        String sch = '0 0 23 * * ?'; 
        String jobID = system.schedule('IOM Invoice generation Scheduler', sch, obj);
        System.debug(LoggingLevel.Debug, 'jobId ==> '+jobId);
        Test.stopTest();
        System.assertEquals(1,[select id from blng__InvoiceScheduler__c].size(),'Error');
    }
}