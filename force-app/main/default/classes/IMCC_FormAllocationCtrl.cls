/*
* Created/Modified By: Girikon(Keertiraj)
* Created On:          03/11/2021
* @description : This class is used to send reminder emails to community users.                    
* Test Class: IMCC_FormAllocationCtrl_Test(85%)
*/

public without sharing class IMCC_FormAllocationCtrl {
    
    @AuraEnabled(cacheable=true)
    public static List<Form_Response_Entry__c> getFormSubmissions(Id formAllocId){
        List<Form_Response_Entry__c> formResponses = new List<Form_Response_Entry__c>();
        
        try{
            formResponses = [SELECT Id, Name, Status__c,Approval_Status__c, User__r.Name FROM Form_Response_Entry__c WHERE Form_Data__r.Forms_Permission__r.Form_Allocation__c=:formAllocId WITH SECURITY_ENFORCED];
        }
        catch(Exception e) { 
            //HandleAllCustomException.logException(ex,'Form_Allocation__c', 'Fetching Form Submissions');
            String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';          
            String stackTrace = e.getStackTraceString().substringBefore('\n');             
            throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);
        } 
        return formResponses;
    }
}