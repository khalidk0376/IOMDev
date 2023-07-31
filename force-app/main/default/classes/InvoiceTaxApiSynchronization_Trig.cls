/**
* File         :   InvoiceTaxApiSynchronization_Trig 
* Project      :   Order & Billing Plateform
* Created Date :   21st Sept 2021
* Created By   :   Girikon(Ashish)
* Test Class   :   InvoiceTaxApiSynchronization_Trig_Test (100%)
* ******************************************************************************************************
@description : to Create ApiSynchronization Trans & Items When Invoice is Updated 
*******************************************************************************************************
* Modification log :   
* 1. Girikon(Ashish)  05 Oct 2021 [OBP-341]  Added logic to create API items for Order Hub 
* 2. Girikon (Ashish) [OBP-423] 12 Oct 2021 : control Item Status from Global Constant
* 3. Girikon (Ashish) [IE-10]   16 Aug 2022 : Create API Sync Item for Payment Sync to OrderHub
* 4. Girikon (Deepak) [GECI-712]   2 Feb 2023 : Changed logic of Tax Requeue From Standard billing field to Custom tax status field.
*/
public with sharing class InvoiceTaxApiSynchronization_Trig implements TriggerInterface_Invoice.Runnable 
{
    private static final String TAX_COMPLETE = 'Tax Complete';
    private static final String STRING_UPDATE = 'Update';
    private static final String INVOICE = 'Invoice';
    private static final String POST_INVOICE = 'Post Invoice';
    private static final String POSTED = 'Posted';
    private static final String ORDER_HUB_SYNC_STATUS = 'Order_Hub_Sync_Status';
    
    /** 
*   @description [Call Interface Class to fetch the new list and old map of Invoice]
*   @param trig [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_Invoice.Trig trig)
    {
        /** ONE SOURCE TAX CALCULATION CALLOUT ITEMS RECORDS CREATION*/
        createTaxApiSyncRecords(trig);
        
        /** ORDER HUB [ORACLE] DATA SYNC CALLOUT ITEMS RECORDS CREATION*/
        createOrderHubApiSyncRecords(trig);

        /** CRM DATA SYNC CALLOUT ITEMS RECORDS CREATION*/ //[GECI-1721]
        createCRMApiSyncRecords(trig);
        
    }
    /**
*   @description Filter Invoice Records & Create Api Sync Records For Tax Calculation
*   @param trig
*/
    private static void createTaxApiSyncRecords(TriggerInterface_Invoice.Trig trig)
    {
        Set<Id> setInvoiceIds = new Set<Id>();
        for(blng__Invoice__c inv : trig.newList){
            if((inv.blng__InvoiceStatus__c == GlobalConstants.DRAFT && inv.blng__InvoiceStatus__c != trig.oldMap.get(inv.Id).blng__InvoiceStatus__c && !System.isBatch()) || (inv.Tax_Status__c == 'Tax Required' && inv.Tax_Status__c != trig.oldMap.get(inv.Id).Tax_Status__c))//GECI-712
            {
                setInvoiceIds.add(inv.Id);
            }
        }
        if(!setInvoiceIds.isEmpty()){
            CalculateTaxOnInvoiceLineUpdate_Trig.processInvoiceTax(setInvoiceIds);
        }
    }

    /**
    *   @description Filter Invoice Records & Create Api Sync Records for Order Hub
    *   @param trig
    */
    private static void createOrderHubApiSyncRecords(TriggerInterface_Invoice.Trig trig)
    {
        Map<String,List<blng__Invoice__c>> finalInvoiceListMap = new Map<String,List<blng__Invoice__c>>();
        Set<Id>orderIds = new Set<Id>();
        for(blng__Invoice__c inv : trig.newList)
        {
            orderIds.add(inv.blng__Order__c);
        }
        Map<Id,Order> orderMap = new Map<Id,Order>([SELECT Id,Edition__c,Legacy_CRM_Instance__c,Edition__r.Edition_Code__c,Edition__r.X3rd_Party_ERP_System__c FROM Order Where Id IN:orderIds]);

        // MAP of Edtion Code & Legacy CRM With Edition Settings
        Map<String,Edition_Setting__mdt> mapEditionSt = getEditionSettingsMapOnEditionCodeLegacyCRM();

        for(blng__Invoice__c inv : trig.newList)
        {
            if((inv.ERP_Sync_Status__c == GlobalConstants.SYNC_REQUIRED && inv.ERP_Sync_Status__c != trig.oldMap.get(inv.Id).ERP_Sync_Status__c) && (inv.Tax_Status__c == TAX_COMPLETE))
            {
                String key = String.isNotBlank(inv.blng__Order__c) && orderMap.containsKey(inv.blng__Order__c) ? orderMap.get(inv.blng__Order__c).Edition__r.Edition_Code__c+'_'+orderMap.get(inv.blng__Order__c).Legacy_CRM_Instance__c :'';

                Boolean syncPaymentTrans =  String.isNotBlank(key) && mapEditionSt.containsKey(key) ?(mapEditionSt.get(key)?.Sync_Payment_Transaction__c):false;
                
                string x3rdPartyERP = String.isNotBlank(inv.blng__Order__c) && orderMap.containsKey(inv.blng__Order__c) ?orderMap.get(inv.blng__Order__c).Edition__r.X3rd_Party_ERP_System__c:GlobalConstants.ORACLE;

                blng__Invoice__c newInv = new blng__Invoice__c(Id=inv.Id);
                //Added Logic for POST_PAYMENT_TRANSACTIONS
                newInv.blng__Notes__c = syncPaymentTrans?GlobalConstants.POST_PAYMENT_TRANSACTIONS:inv.blng__Notes__c;
				
                x3rdPartyERP = String.isNotBlank(x3rdPartyERP)?x3rdPartyERP:GlobalConstants.ORACLE;
                List<blng__Invoice__c> invList = finalInvoiceListMap.containsKey(x3rdPartyERP)?finalInvoiceListMap.get(x3rdPartyERP): new List<blng__Invoice__c>();
                invList.add(newInv);
                finalInvoiceListMap.put(x3rdPartyERP,invList);
            }
        }
        
        for(String x3rdPartyERP : finalInvoiceListMap.keySet())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.type = POST_INVOICE;
            obj.startedFrom = INVOICE;
            obj.listSObject = finalInvoiceListMap.get(x3rdPartyERP);
            obj.requestType = GlobalConstants.ASYNCHRONOUS;
            obj.thirdPartyERPSystem = x3rdPartyERP;
            obj.apiCallType = GlobalConstants.POST;
            obj.itemType = GlobalConstants.POST_DOCUMENTS;
            obj.itemStatus = GlobalConstants.getValue(ORDER_HUB_SYNC_STATUS); // pause till API ready
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }        
    }

    /**
    * @description to get Edition_Setting__mdt map grouped on Edition Code and Legacy CRM
    * @return Map<String,Edition_Setting__mdt>
    */
    public static Map<String,Edition_Setting__mdt> getEditionSettingsMapOnEditionCodeLegacyCRM(){
        List<Edition_Setting__mdt> listES = Edition_Setting__mdt.getAll().values();
        Map<String,Edition_Setting__mdt> mapES = new Map<String,Edition_Setting__mdt>();
        for(Edition_Setting__mdt es : listES){
            String key = es.Edition_Code__c + '_' + es.Legacy_CRM_Instance__c;
            mapES.put(key, es);
        }
        return mapES;
    }

    /**
    *   @description - Create Api Sync Records for CRM to sync ERP No  - [GECI-1721]
    *   @param trig
    */
    private static void createCRMApiSyncRecords(TriggerInterface_Invoice.Trig trig)
    {
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
        for(blng__Invoice__c inv : trig.newList)
        {
            if(inv.ERP_Sync_Status__c == 'Synced' && String.isNotBlank(inv.ERP_Reference__c) && inv.ERP_Reference__c != trig.oldMap.get(inv.Id).ERP_Reference__c )
            {
                invList.add(inv);
            }
        }

        if(!invList.isEmpty())
        {
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();            
            obj.type = 'Update';
            obj.startedFrom = INVOICE;
            obj.listSObject = invList;
            obj.requestType = GlobalConstants.ASYNCHRONOUS;            
            obj.apiCallType = GlobalConstants.POST;
            obj.itemType    = GlobalConstants.ERP_REF_NUMBER_BACK_UPDATE_TO_CRM;
            obj.itemStatus = GlobalConstants.QUEUED; 
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }
    }
}