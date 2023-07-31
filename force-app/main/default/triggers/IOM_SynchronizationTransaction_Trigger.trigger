/**
* File			: 	IOM_SynchronizationTransaction_Trigger
* Project       :   Order & Billing Plateform
* Created By	: 	Suresh(Girikon)
* Created Date	: 	11th Dec 2021
* Test Class   :    IOM_SendForOrder_Test(100%),IOM_AmendmentRequest_Test(80%)
* ***************************************************************************
* @description : Trigger to run mulesoft batch callout class
*****************************************************************************
* Last Modified By :
*/
trigger IOM_SynchronizationTransaction_Trigger on IOM_Synchronization_Transaction__c (after insert,after update) {
	if(!Boolean.valueOf(IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.DISABLE_IOM_TRIGGER)))
    {
        System.debug(LoggingLevel.Debug,'OMPSynchronization_Transaction ------>' + Trigger.OperationType );
        switch on Trigger.OperationType{
            when AFTER_INSERT
            {
                IOM_SynchronizationTransactionHelper.afterInsertHandle(Trigger.new,Trigger.oldMap);
            }
            when AFTER_UPDATE
            {
                IOM_SynchronizationTransactionHelper.afterUpdateHandle(Trigger.new,Trigger.oldMap);
            }        
        }
    }
}