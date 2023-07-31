/**
* File         :   IOM_AmendmentRequest_Trigger 
* Project      :   Order & Billing Plateform
* Created Date :   27th Dec 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_AmendmentRequestUtils_Test(91%)
* ******************************************************************************************************
 @description : Trigger On IOM_Amendment_Request__c
*******************************************************************************************************
* Modification log : 
*/
trigger IOM_AmendmentRequest_Trigger on IOM_Amendment_Request__c (after insert,after update) 
{
    if(!Boolean.valueOf(IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.DISABLE_IOM_TRIGGER)))
    {
        switch on Trigger.OperationType  
        {
            when AFTER_INSERT
            {
                System.debug(LoggingLevel.Debug,'AFTER_INSERT------>' + Trigger.OperationType );
                IOM_AmendmentRequest_TriggerHandler.afterInsertHandle(Trigger.new, Trigger.oldMap);
            }
            when AFTER_UPDATE
            {
                System.debug(LoggingLevel.Debug,'AFTER_UPDATE------>' + Trigger.OperationType );
                //IOM_AmendmentRequest_TriggerHandler.afterUpdateHandle(Trigger.new, Trigger.oldMap);
            }        
        }
    }
}