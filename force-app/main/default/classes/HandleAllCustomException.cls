/**
* File          :   HandleAllCustomException
* Project       :   Order & Billing Plateform
* Created Date  :   28th Sept 2021
* Created By    :   GIRIKON(Ashish)
* Test Class    :   HandleAllCustomException_Test (98%)
* *******************************************************************************************************
* @description : Handles all exceptions related to Apex Classes and Triggers designed and stores in Custom_Error_Log__c object as a record.
* *******************************************************************************************************
* Last Modified By : 
*/
public without sharing class HandleAllCustomException extends Exception 
{
    /**
    * @description  The method to logging exception in Custom_Error_Log__c object.
    * @param  e Exception
    * @param  relatedToId sObject Record Id
    * @param errorOn Error on / Details 
    */
    public static void logException(Exception e,string relatedToId, string errorOn)
    {
        String stackTrace = e.getStackTraceString().substringBefore('\n');
        String className = stackTrace.substringAfter('.').substringBefore('.'); 
        String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
        
        Custom_Error_Log__c customLog = new Custom_Error_Log__c();
        customLog.Line_Number__c = String.isNotBlank(String.valueof(e.getLineNumber())) ? String.valueof(e.getLineNumber()) : '';
        customLog.Message__c = String.isNotBlank(e.getMessage()) ? e.getMessage():'';
        customLog.StackTrace__c = String.isNotBlank(e.getStackTraceString()) ? e.getStackTraceString() : '';
        customLog.Type__c = String.isNotBlank(e.getTypeName()) ? e.getTypeName() : '';
        customLog.Method__c = String.isNotBlank(methodName) ? methodName : '';
        customLog.Apex_Class__c = String.isNotBlank(className) ? className : '';
        customLog.OwnerId = UserInfo.getUserId();
        customLog.On__c = errorOn;
        customLog.RecordID__c = relatedToId;  
        
        Database.insert(customLog,false);           
    }
/**
    * @description  The method to logging exception from LWC & Aura in Custom_Error_Log__c object.
    * @param  comp_type Component Type
    * @param  className LWC /Aura Component Name
    * @param  methodName methodName Type
    * @param  currcdId Record Id
    * @param  mesg Error Messg
    * @param  stackTrace Stacktrace    
    */
    @AuraEnabled
    public static void logUIException(String comp_type,String className,String methodName,Id currcdId,String mesg,String stackTrace)
    {
        
         System.debug('logUIException ***'+comp_type+'-'+classname+'-'+methodName+'-'+currcdId+'-'+mesg+stackTrace);
        
        Custom_Error_Log__c customLog = new Custom_Error_Log__c();

        customLog.StackTrace__c = String.isNotBlank(stackTrace) ? stackTrace:'';    
        customLog.Message__c = String.isNotBlank(mesg) ? mesg:'';
        customLog.Method__c = String.isNotBlank(methodName) ? methodName : '';
        customLog.Apex_Class__c = String.isNotBlank(className) ? className : '';
        customLog.OwnerId = UserInfo.getUserId();
        customLog.Component_Type__c = String.isNotBlank(comp_type) ? comp_type : '';
        customLog.RecordID__c = currcdId?.getSObjectType().getDescribe().getName();  
        
        Database.insert(customLog,false);           
    }
}