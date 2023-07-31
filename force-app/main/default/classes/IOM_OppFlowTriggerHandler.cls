/**
* File         :   IOM_OppFlowTriggerHandler 
* Project      :   Order & Billing Plateform
* Created Date :   08th Nov 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   IOM_SendForOrder_Test(100%)
* ******************************************************************************************************
 @description : Apex class to call batch class
********************************************************************************************************
* Modification log :
* 1.
*/
public class IOM_OppFlowTriggerHandler {
     
    /**
    * @description  This invocable method is calling batch class
    * @param oppIds List of Opportunity Id
    **/
    @InvocableMethod(label='Get Opportunity')
    public static void callApex(List<Id> oppIds) {
        Set<Id> listoppIds = new Set<Id>();
        listoppIds.addAll(oppIds);
        //call batch class here
        Database.executeBatch(new IOM_SendForOrderBatch(listoppIds),1);
    }
     
}