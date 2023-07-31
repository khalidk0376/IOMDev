/**
* File         :   CreditNotesOrderHub_Trig 
* Project      :   Order & Billing Plateform 
* Created Date :   28th Sept 2021
* Created By   :   Girikon(Suresh)  
* Test Class   :   CreditNotesOrderHub_Trig_Test(100%)
* ******************************************************************************************************
 @description : Create a functionality to POST the created Credit Notes into the Order Hub
*******************************************************************************************************
* Modification log :   
* 1. Girikon (Ashish) [OBP-423]  12 Oct 2021 : control Item Status from Global Constant
* 2. Girikon (Ashish) [IOM-1687] 14 JUN 2022 : Set Sync Control From Edition
*/
public with sharing class CreditNotesOrderHub_Trig implements TriggerInterface_CreditNote.Runnable {
    
    private static final String ORDER_HUB_SYNC_STATUS = 'Order_Hub_Sync_Status';
    private static final String POSTED = 'Posted';

    /**
     * @description Trigger handler method for Credit Note based on the event called, the processing is dispatched accordingly
     * @param trig TriggerInterface_CreditNote.Trig instance.
     */
    public void run(TriggerInterface_CreditNote.Trig trig)
    {
        if(trig.isAfter && trig.isUpdate){
            createApiSyncRecords(trig);

            /** CRM DATA SYNC CALLOUT ITEMS RECORDS CREATION*/ //[GECI-1721]
            createCRMApiSyncRecords(trig);
        }
        
        if(trig.isBefore && (trig.isUpdate)){            
            setSyncRequired(trig);
        }
    }

     /**
     * @description To Set Sync Required On Credit Note for OrderHub
     * @param trig TriggerInterface_CreditNote.Trig instance.
    */
    private static void setSyncRequired(TriggerInterface_CreditNote.Trig trig)
    {
        Set<Id> invIds = new Set<Id>();
        for(blng__CreditNote__c credN : trig.newList)
        {
            invIds.add(credN.blng__RelatedInvoice__c);
        }

        Map<Id,blng__Invoice__c> invMap = new Map<Id,blng__Invoice__c>([SELECT Id,blng__Order__r.Edition__r.Invoice_Posting__c FROM blng__Invoice__c WHERE Id IN:invIds]);

        for(blng__CreditNote__c credN : trig.newList)
        {
            Boolean isSyncEnabled = String.isNotBlank(credN.blng__RelatedInvoice__c) && invMap.ContainsKey(credN.blng__RelatedInvoice__c) ? invMap.get(credN.blng__RelatedInvoice__c).blng__Order__r.Edition__r.Invoice_Posting__c : false;

            blng__CreditNote__c oldCN = trig.isUpdate ? trig.oldMap.get(credN.Id):new blng__CreditNote__c();
            //System.debug(trig.isUpdate + 'New Val : '+credN.blng__Status__c+' Old val: '+oldCN.blng__Status__c);	
            if(isSyncEnabled == true && credN.blng__Status__c == POSTED && credN.blng__Status__c != oldCN.blng__Status__c)
            {
                credN.ERPSync_Status__c = GlobalConstants.SYNC_REQUIRED;
            }
        }
    }

    /**
     * @description To Create Api Records for Credit Note Posting To OrderHub
     * @param trig TriggerInterface_CreditNote.Trig instance.
     */
    private static void createApiSyncRecords(TriggerInterface_CreditNote.Trig trig)
    {
        Map<String,List<blng__CreditNote__c>> finalCreditNoteListMap = new Map<String,List<blng__CreditNote__c>>();

        Set<Id>invIds = new Set<Id>();
        for(blng__CreditNote__c credN : trig.newList)
        {
            invIds.add(credN.blng__RelatedInvoice__c);
        }

        Map<Id,blng__Invoice__c> invoiceMap = new Map<Id,blng__Invoice__c>([SELECT Id,blng__Order__r.Edition__c,blng__Order__r.Legacy_CRM_Instance__c,blng__Order__r.Edition__r.Edition_Code__c,blng__Order__r.Edition__r.X3rd_Party_ERP_System__c FROM blng__Invoice__c Where Id IN:invIds]);

        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();

        for(blng__CreditNote__c cred : trig.newList)
        {
            // System.debug('Inside Credit Note Process-'+cred.Id);
            if(cred.ERPSync_Status__c == GlobalConstants.SYNC_REQUIRED && cred.ERPSync_Status__c != trig.oldMap.get(cred.Id).ERPSync_Status__c)
            {
                String key = invoiceMap.containsKey(cred.blng__RelatedInvoice__c) ? invoiceMap.get(cred.blng__RelatedInvoice__c).blng__Order__r.Edition__r.Edition_Code__c+'_'+invoiceMap.get(cred.blng__RelatedInvoice__c).blng__Order__r.Legacy_CRM_Instance__c :'';

                Boolean syncPaymentTrans =  String.isNotBlank(key) && mapEditionSt.containsKey(key) ?(mapEditionSt.get(key)?.Sync_Payment_Transaction__c):false;
                
                string x3rdPartyERP = String.isNotBlank(cred.blng__RelatedInvoice__c) && invoiceMap.containsKey(cred.blng__RelatedInvoice__c) ?invoiceMap.get(cred.blng__RelatedInvoice__c).blng__Order__r.Edition__r.X3rd_Party_ERP_System__c:GlobalConstants.ORACLE;            
                x3rdPartyERP = String.isNotBlank(x3rdPartyERP)?x3rdPartyERP:GlobalConstants.ORACLE;

                blng__CreditNote__c newCN = new blng__CreditNote__c(Id=cred.Id);            
                newCN.blng__Notes__c = syncPaymentTrans?GlobalConstants.POST_PAYMENT_TRANSACTIONS:cred.blng__Notes__c;
                //Added Logic for POST_PAYMENT_TRANSACTIONS
                List<blng__CreditNote__c> cnList = finalCreditNoteListMap.containsKey(x3rdPartyERP)?finalCreditNoteListMap.get(x3rdPartyERP): new List<blng__CreditNote__c>();
                
                cnList.add(newCN);
                finalCreditNoteListMap.put(x3rdPartyERP,cnList);
            }
        }
       
        for(String x3rdPartyERP : finalCreditNoteListMap.keySet())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.Type = 'Post Credit Note';
            obj.startedFrom = 'Credit Note';
            obj.requestType = GlobalConstants.ASYNCHRONOUS; 
            obj.thirdPartyERPSystem = x3rdPartyERP;
            obj.itemType = GlobalConstants.POST_DOCUMENTS; 
            obj.apiCallType = GlobalConstants.POST;
            obj.listSObject = finalCreditNoteListMap.get(x3rdPartyERP);
            obj.transactionStatus = GlobalConstants.QUEUED;
            obj.itemStatus = GlobalConstants.getValue(ORDER_HUB_SYNC_STATUS); // pause till API ready
            CreateApiSyncRecords.insertAllAPISyncItem(obj);	
        }
        
    } 

    /**
    *   @description - Create Api Sync Records for CRM to sync ERP No  - [GECI-1721]
    *   @param trig
    */
    private static void createCRMApiSyncRecords(TriggerInterface_CreditNote.Trig trig)
    {
        List<blng__CreditNote__c> credNtList = new List<blng__CreditNote__c>();
        for(blng__CreditNote__c cred : trig.newList)
        {            
            if(cred.ERPSync_Status__c == 'Synced' && String.isNotBlank(cred.ERPReference__c) && cred.ERPReference__c != trig.oldMap.get(cred.Id).ERPReference__c ){
                credNtList.add(cred);
            }
        }

        if(!credNtList.isEmpty()){
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();            
            obj.type = 'Update';
          	obj.startedFrom = 'Credit Note';
            obj.listSObject = credNtList;
            obj.requestType = GlobalConstants.ASYNCHRONOUS;            
            obj.apiCallType = GlobalConstants.POST;
            obj.itemType = GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM;
            obj.itemStatus = GlobalConstants.QUEUED; 
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
}