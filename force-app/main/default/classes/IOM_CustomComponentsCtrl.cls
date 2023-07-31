/**
* File         :   IOM_CustomComponentsCtrl 
* Project      :   Order & Billing Plateform [GECI-445]
* Created Date :   16th Jan 2023
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_CustomComponentsCtrl_Test (94%)
* ************************************************************************************************
 @description : Apex to all Custom Components for UNLOCK PACKAGE
**************************************************************************************************
* Modification log :
* 1. 
*/
public with sharing class IOM_CustomComponentsCtrl 
{
    /**
    * @description getOpportunityRecord for - LWC [Iom_OppCustomPaymentSchedule]
    * @param  fields : Fields for opportunity query
    * @param  recordId : Opp Record Id
    * @return Opportunity : Opportunity Record Obj
    */
    @AuraEnabled
    public static Opportunity getOpportunityRecord(string fields ,String recordId)
    {
        return  Database.query('SELECT '+String.escapeSingleQuotes(fields)+' FROM Opportunity WHERE Id =:recordId LIMIT 1');
    }
}