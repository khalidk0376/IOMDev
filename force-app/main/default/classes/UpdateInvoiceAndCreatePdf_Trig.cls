/**
* File:         UpdateInvoiceAndCreatePdf_Trig
* Project:      Greenfield
* Created Date: 1/21/2020
* Created By:   Yash Gupta
* Modified By:  Yash Gupta (1/22/2020)
* Test Class:   UpdateInvoiceAndCreatePdf_Trig_Test (100%)
* *******************************************************************************************************
* @description : This class is used to update the invoice field i.e "" on the basis of product type and change request status as per ticket IML2R-244.
* *******************************************************************************************************
* History:      
*/

public with sharing class UpdateInvoiceAndCreatePdf_Trig implements TriggerInterface_ChangeRequest.Runnable {
    /**
    * @description [Call Interface Class to fetch all the parameters or events from Change_Request__c object]
    * @param trig [fetch the trigger parameters]
    */
    public void run(TriggerInterface_ChangeRequest.Trig trig) {
        if(trig.isAfter && trig.isInsert){
            Set<Id> setIds = new Set<Id>();
            for(Change_Request__c ochangeRequest : trig.newList){
                if(ochangeRequest.Amended_Opportunity__c == null){
                    setIds.add(ochangeRequest.Id);
                }
            }
            if(!setIds.isEmpty()){
                System.enqueueJob(new CalloutActionSubmitChange(setIds));
            }
        }
    }
}