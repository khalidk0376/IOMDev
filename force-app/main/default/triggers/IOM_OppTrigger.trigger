/**
* File			: 	IOM_OppTrigger
* Project       :   Informa Order Management
* Created By	: 	Suresh(Girikon)
* Created Date	: 	27th Dec 2021
* Test Class   :    IOM_ObjectValidation_Test(100%)
* ***************************************************************************
* @description : Trigger to call validation class
*****************************************************************************
* Last Modified By :
*/
trigger IOM_OppTrigger on Opportunity (before delete) {

    if(!Boolean.valueOf(IOM_GlobalConstantsData.getValue(IOM_GlobalConstantsData.DISABLE_IOM_TRIGGER)))
    {
        switch on Trigger.OperationType  
        {
            when BEFORE_DELETE
            {
                System.debug(LoggingLevel.Debug,'BEFORE_DELETE------>' + Trigger.OperationType );
                IOM_ObjectValidation.oppValidate(Trigger.old, Trigger.oldMap);
            }        
        }
    }
}