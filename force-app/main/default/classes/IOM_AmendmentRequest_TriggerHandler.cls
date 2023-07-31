/**
* File         :   IOM_AmendmentRequest_TriggerHandler 
* Project      :   Order & Billing Plateform
* Created Date :   27th Dec 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_AmendmentRequestUtils_Test(91%)
* ******************************************************************************************************
 @description : Utility Class for IOM AmendmentRequest payload creation
*******************************************************************************************************
* Modification log : 
*/
public class IOM_AmendmentRequest_TriggerHandler {
	
    /**
    * @description  This method used to perform After Insert Logic on IOM_Amendment_Request__c
    * @param  amendmentReqList list of IOM_Amendment_Request__c
    * @param  amendmentReqOldMap OldMap <Id and IOM_Amendment_Request__c>
    */
    public static void afterInsertHandle(List<IOM_Amendment_Request__c> amendmentReqList,Map<Id,IOM_Amendment_Request__c> amendmentReqOldMap)
    {
        IOM_AmendmentRequestUtils.createSynTranForAmendmentRequest(amendmentReqList);
    }
    /**
    * @description  This method used to perform After Update Logic on IOM_Amendment_Request__c
    * @param  amendmentReqList list of IOM_Amendment_Request__c
    * @param  amendmentReqOldMap OldMap <Id and IOM_Amendment_Request__c>
    */
    public static void afterUpdateHandle(List<IOM_Amendment_Request__c> amendmentReqList,Map<Id,IOM_Amendment_Request__c> amendmentReqOldMap)
    {
        //IOM_AmendmentRequestUtils.createSynTranForAmendmentRequest(amendmentReqList);
    }
}