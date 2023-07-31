/**
* File:         HandleAllCustomException_Test
* Project:      Order & Billing Plateform
* Created Date: 28th OCT 2021
* Created By:   Ashish(Girikon)   
* *******************************************************************************************************
* @description : Test Class for HandleAllCustomException_Test
* *******************************************************************************************************
* Last Modified By : 
*/
@isTest
private with sharing class HandleAllCustomException_Test {
    
    @isTest
    private static void testException()
    {
        Test.startTest();
        try
        {
            integer i = 100/0;
            System.debug(logginglevel.DEBUG,'Integer OutPut'+i);
        }
        Catch(Exception e)
        {
            String errorOn = 'TEST Class Data';
            string compType = 'LWC';
            string classname = 'Test Class';
            string methodName = 'Test Method';
            
            string msg = 'List can not be null';
            string stacktrace = '';
            System.debug(logginglevel.DEBUG,'Go To Exception Class');
            HandleAllCustomException.logException(e,null,errorOn);
            HandleAllCustomException.logUIException(compType,classname,methodName,null,msg,stacktrace);
            Integer recordCount = Database.countQuery('SELECT Count() FROM Custom_Error_Log__c');
            System.assertEquals(2, recordCount,'Custom Error Record Not Found');
        }
        Test.stopTest();
    }
    
}