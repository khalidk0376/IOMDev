/**
 * Raider Data Services, TT
 * @description Handler Class for CreditNoteTrigger to populate Credit Note Number on Credit Note
 * based on UniqueSequence Prefix and LastNumber.
 * Date: Date : 10/01/2019
 * LastModified By : Raider Data Services, TT
 * Last Modified Date : 02/12/2020
 */
public with sharing class CreditNotePostingHandler_Trig implements TriggerInterface_CreditNote.Runnable {
     // constants
    public static final String CREDIT_NOTE_POSTING_STATUS = 'Posted';
    public static final String STATUS_FIELD = 'blng__Status__c';
    
    /**
     * @description Trigger handler method for Credit Note based on the event called, the processing is dispatched accordingly
     * @param trig TriggerInterface_CreditNote.Trig instance.
     */
    public void run(TriggerInterface_CreditNote.Trig trig){
		// detect the correct event and dispatch accordingly
        Set<Id> setofInvIds = new Set<Id>();
        if(trig.isBefore && trig.isInsert){
            for(blng__CreditNote__c crdNote : (List<blng__CreditNote__c>) trig.newList){
                if(crdNote.blng__RelatedInvoice__c != null){
                    setofInvIds.add(crdNote.blng__RelatedInvoice__c);
                }
            }
            if(!setofInvIds.isEmpty()){
                updateCreditNoteField(trig.newList ,setofInvIds);
            }
        }
      
	}
    
    /**
     * @description Method to stamp Contract Number from related Invoice.
     * @param crdNoteLst List of affected Credit Notes.
     * @param setofInvIds Set of related Invoice Ids for affected Credit Notes.
     */
    public void updateCreditNoteField(List<blng__CreditNote__c> crdNoteLst, Set<Id> setofInvIds){
        //map of related Invoices.
        Map<id, blng__Invoice__c> mapOfInvs;
        if(Schema.sObjectType.blng__Invoice__c.isAccessible()){
            mapOfInvs = new Map<id, blng__Invoice__c>([Select id, Contract_Number__c,blng__Order__c from blng__Invoice__c where id=: setofInvIds]);
        }
        
        for(blng__CreditNote__c crdNote : crdNoteLst){
            //get related invoice from map
            blng__Invoice__c inv = mapOfInvs.get(crdNote.blng__RelatedInvoice__c);
            if(inv.Contract_Number__c != null){
                //stamp Contract Number from Invoice to Credit Note.
                crdNote.Contract_Number__c = inv.Contract_Number__c; 
            }
            if(inv.blng__Order__c!=null){
                crdNote.Order__c = inv.blng__Order__c;
            }
        }
    }
}