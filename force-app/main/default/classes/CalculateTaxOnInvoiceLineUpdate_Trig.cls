/**
* File         :   CalculateTaxOnInvoiceLineUpdate_Trig
* Project      :   Order & Billing Plateform
* Created Date :   21 Sept 2021
* Created By   :   Girikon(Deepak)
* Test Class   :   CalculateTaxOnInvoiceLineUpdate_Test(100%)
* ******************************************************************************************************
* @description : For Creating Records to API Synchronization After Invoice Line Tax Status is made Queued
********************************************************************************************************
* Modification log :
* 1. 10th Aug 2022 - Girikon(Ansh) [IE-28] - Updated code for Tax Callout
*/
public with sharing class CalculateTaxOnInvoiceLineUpdate_Trig implements TriggerInterface_InvoiceLine.Runnable{
    
    private static final String TAX_COMPLETE = 'Tax Complete';
    
    /**
* @description [This method is for running the Trigger on Invoice Line using the interface class on After Update.]
* @param trig
*/
    public void run(TriggerInterface_InvoiceLine.Trig trig){
        
        if(trig.isAfter && trig.isUpdate){
            Set<Id> invIds = new Set<Id>();
            for(blng__InvoiceLine__c invLine : trig.newList){
                if(invLine.blng__TaxStatus__c == 'Queued' && invLine.blng__TaxStatus__c != trig.oldMap.get(invLine.Id).blng__TaxStatus__c){
                    invIds.add(invLine.blng__Invoice__c);
                }
            }
            if(!invIds.isEmpty()){
                processInvoiceTax(invIds);
            }
        }
    }

    /**
    * @description [This method is used to process invoice tax.]
    * @param invIds
    */
    public static void processInvoiceTax(Set<Id> invIds){
        Map<Id,Id> mapOfOrdItemAndInvLineIds = new Map<Id,Id>();
        Set<Id> finalinvoiceIds = new Set<Id>();
        List<blng__InvoiceLine__c> listInvoiceLine = [SELECT Id,blng__OrderProduct__c,blng__Invoice__c,Edition__r.Edition_Code__c, blng__Invoice__r.blng__Order__r.Legacy_CRM_Instance__c FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN : invIds WITH SECURITY_ENFORCED];

        Map<String,Edition_Setting__mdt> mapES = InvoiceTaxApiSynchronization_Trig.getEditionSettingsMapOnEditionCodeLegacyCRM();

        for(blng__InvoiceLine__c invLine : listInvoiceLine){
            String key = invLine.Edition__r.Edition_Code__c + '_' + invLine.blng__Invoice__r.blng__Order__r.Legacy_CRM_Instance__c;
            Boolean disableTaxCal =  (String.isNotBlank(key) && mapES.containsKey(key))?(mapES.get(key)?.Disable_Tax_Calculation__c):false;
            if(!disableTaxCal){
                finalinvoiceIds.add(invLine.blng__Invoice__c);
            }else{
                mapOfOrdItemAndInvLineIds.put(invLine.blng__OrderProduct__c,invLine.blng__Invoice__c);
            }
        }

        if(!finalinvoiceIds.isEmpty()){
            CreateApiSyncRecords.ApiSyncRecordsWrapper obj = new CreateApiSyncRecords.ApiSyncRecordsWrapper();
            obj.type = 'Update';
            obj.startedFrom = 'Invoice';
            obj.listSObject = [SELECT Id FROM blng__Invoice__c WHERE Id IN:finalinvoiceIds WITH SECURITY_ENFORCED];
            obj.requestType = GlobalConstants.ASYNCHRONOUS;
            obj.externalTaxSystem = GlobalConstants.ONESOURCE;
            obj.apiCallType = 'POST';
            obj.itemType = 'Tax';
            CreateApiSyncRecords.insertAllAPISyncItem(obj);
        }

        if(!mapOfOrdItemAndInvLineIds.isEmpty()){
            cloneTaxLines(mapOfOrdItemAndInvLineIds);
        }
    }

    /**
    * @description [This method is used to clone tax lines from order product to invoice line.]
    * @param mapOfOrdItemAndInvLineIds Map
    */
    @TestVisible private static void cloneTaxLines(Map<Id,Id> mapOfOrdItemAndInvLineIds){
        String selects = '';
        List<Tax_Lines__c> taxlinestoInsert = new List<Tax_Lines__c>();
        Boolean invoicePostingAllowed = false;
        Map<Id,List<Tax_Lines__c>> taxlineMap = new Map<Id,List<Tax_Lines__c>>();
        Map<String, Schema.SObjectField> fields = Tax_Lines__c.getSObjectType().getDescribe().fields.getMap();
        List<String> selectFields = new List<String>();
        Set<blng__Invoice__c> setInvoice = new Set<blng__Invoice__c>();
        List<blng__Invoice__c> listInvoice = new List<blng__Invoice__c>();
        list<blng__InvoiceLine__c> listinvoiceItems = new list<blng__InvoiceLine__c>();
        list<Tax_Lines__c> dellistTaxLines = [Select Id from Tax_Lines__c where Invoice_Line__c IN : mapOfOrdItemAndInvLineIds.values() WITH SECURITY_ENFORCED];
        if (!dellistTaxLines.isEmpty() && Schema.sObjectType.Tax_Lines__c.isDeletable()) {
            delete dellistTaxLines;
        }
        for(Schema.SObjectField f : fields.values()){
            Schema.DescribeFieldResult fd  = f.getDescribe();
            if(fd.isCreateable()){
                selectFields.add(fd.getName());
            }
        }
        if (!selectFields.isEmpty()){
            for(string s:selectFields){
                selects += s + ',';  
            }
            if (selects.endsWith(',')){
                selects = selects.substring(0,selects.lastIndexOf(','));
            }
        }

        Set<Id> keys = new Set<Id>(mapOfOrdItemAndInvLineIds.keySet());
        System.debug(LoggingLevel.DEBUG, keys);

        List<Tax_Lines__c> taxlineList = Database.query('Select ' + selects + ' From Tax_Lines__c Where Order_Product__c IN : keys');
        for(Tax_Lines__c tl : taxlineList){
            if(!taxlineMap.containsKey(tl.Order_Product__c)){
                taxlineMap.put(tl.Order_Product__c, new List<Tax_Lines__c> {tl});
            }else{
                List<Tax_Lines__c> tlList = new List<Tax_Lines__c>();
                tlList = taxlineMap.get(tl.Order_Product__c);
                tlList.add(tl);
                taxlineMap.put(tl.Order_Product__c,tlList);
            }
        }
        for(blng__InvoiceLine__c invLine : [Select Id,blng__OrderProduct__c,blng__TaxPercentageApplied__c,blng__Invoice__c,blng__Invoice__r.blng__Order__r.Edition__r.Invoice_Posting__c,blng__OrderProduct__r.SBQQ__TaxAmount__c,blng__OrderProduct__r.blng__TaxPercentageApplied__c from blng__InvoiceLine__c where blng__OrderProduct__c IN: taxlineMap.keySet() WITH SECURITY_ENFORCED]){
            invoicePostingAllowed = invLine.blng__Invoice__r.blng__Order__r.Edition__r.Invoice_Posting__c;
            blng__Invoice__c inv = new blng__Invoice__c(Id = invLine.blng__Invoice__c);
            inv.Tax_Status__c = TAX_COMPLETE;
            inv.blng__TaxStatus__c = GlobalConstants.COMPLETED;
            inv.ERP_Sync_Status__c = invoicePostingAllowed ? GlobalConstants.SYNC_REQUIRED :null;
            invLine.Tax_Status__c = TAX_COMPLETE;
            invLine.blng__TaxStatus__c = GlobalConstants.COMPLETED;
            invLine.blng__TaxErrorMessage__c = GlobalConstants.BLANK_STRING;
            if(taxlineMap.get(invLine.blng__OrderProduct__c) != null){
                for(Tax_Lines__c t : taxlineMap.get(invLine.blng__OrderProduct__c)){
                    Tax_Lines__c tcopy = t.clone(false,true,false,false);
                    tcopy.Order_Product__c = null;
                    tcopy.Invoice_Line__c = invLine.Id;
                    taxlinestoInsert.add(tcopy);
                }
            }
            invLine.blng__TaxPercentageApplied__c = invLine.blng__OrderProduct__r.blng__TaxPercentageApplied__c;
            invLine.blng__TaxAmount__c = invLine.blng__OrderProduct__r.SBQQ__TaxAmount__c;
            listinvoiceItems.add(invLine);
            setInvoice.add(inv);
        }
        listInvoice.addAll(setInvoice);
        if (!listinvoiceItems.isEmpty() && Schema.sObjectType.blng__InvoiceLine__c.isUpdateable())
        {
            update listinvoiceItems;
        }
        if (!taxlinestoInsert.isEmpty() && Schema.sObjectType.Tax_Lines__c.isCreateable())
        {
            insert taxlinestoInsert;
        }
        if (!listInvoice.isEmpty() && Schema.sObjectType.blng__Invoice__c.isUpdateable())
        {
            update listInvoice;
        }
    }
}