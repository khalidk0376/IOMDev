/**
* File:         OpportunityBillToAccount_Trig
* Project:      GAP
* Created Date: 24 Feb 2020
* Created By:   Garima Gupta
* Test Class:   OpportunityBillToAccount_Trig_Test  [94%]
*******************************************************************************************************
* @description : Sharing Class to update the Bill to Account on opportunity.
*******************************************************************************************************
* Modification log :
* 1. Girikon (Ashish)  [16 Feb 2021 (IOM-839)]  ERP Payment Term Code to be sent to OrderHub from opp
* 2. Girikon (Ansh)    [15 Feb 2021 (IOM-838)]  Update Invoice to be issued before(in Days) field value on opportunity
* 3. Girikon (Ashish)  [07 Oct 2022 (IE-317)]   Set Default PriceBook Id From Lable {Migrated from Process Builder}        
* 4. Girikon (Ansh)    [18th May 2023 (GECI-1672)] update Legacy CRM Instance field value on the opportunity
*/
public with sharing class OpportunityBillToAccount_Trig implements TriggerInterface_Opportunity.Runnable {
    /**
    * @description [Call Interface Class to fetch the new list of opportunity]
    * @param trig TriggerInterface_Opportunity [fetch the trigger new list]
    */
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if(trig.isBefore && trig.isInsert){
            if(trig.newList !=null){
                setDefaultFieldValues(trig.newList);
                setDataFromEdition(trig.newList);
                setLegacyCRM(trig.newList);
            }
        }
        if(trig.isBefore && (trig.isInsert || trig.isUpdate))
        {
            updatePaymentTerm(trig);
        }
       /* if(trig.isAfter && trig.isUpdate)
        {
            updatePaymentTermQuote(trig);
        }*/
    }
    
    /**
    * @description [this method is used to update Invoice to be issued before(in Days) field value on the opportunity]
    * @param lstOpportunity [list of opportunity]
    */
    private static void setDataFromEdition (List<Opportunity> lstOpportunity){
        Set<Id> edIds = new Set<Id>();
        for(Opportunity opp : lstOpportunity)
        {
            if(String.isNotBlank(opp.Default_Edition__c)){
                edIds.add(opp.Default_Edition__c);
            }
        }
        Map<Id,Edition__c> mapOfed = new Map<Id,Edition__c>([SELECT Id,Invoice_to_be_issued_before__c FROM Edition__c WHERE Id in:edIds WITH SECURITY_ENFORCED]);
        
        for(Opportunity opp : lstOpportunity){
            if(String.isNotBlank(opp.Default_Edition__c) && mapOfed.containsKey(opp.Default_Edition__c)){
                opp.Invoice_to_be_issued_before_in_Days__c = mapOfed.get(opp.Default_Edition__c).Invoice_to_be_issued_before__c;
            }
        }
    }

    /**
    * @description [this method is used to update Legacy CRM Instance field value on the opportunity] GECI-1672
    * @param lstOpportunity [list of opportunity]
    */
    public static void setLegacyCRM(List<Opportunity> lstOpportunity){
        Set<String> legacyCRMInstances = new Set<String>();
        for (Opportunity opp : lstOpportunity) {
            if (opp.Legacy_CRM_Instance__c != null) {
                legacyCRMInstances.add(opp.Legacy_CRM_Instance__c);
            }
        }
    
        Map<String, CRM_Setting__mdt> crmSettings = getCRMSettings(legacyCRMInstances);
    
        for (Opportunity opp : lstOpportunity) {
            if (opp.Legacy_CRM_Instance__c != null && crmSettings.containsKey(opp.Legacy_CRM_Instance__c)) {
                opp.Legacy_CRM_Org_URL__c = crmSettings.get(opp.Legacy_CRM_Instance__c).CRM_Domain__c;
            }
        }   
    }

    /**
    * @description [this method is used to get CRM Settings based on legacy CRM Instances values] GECI-1672
    * @param legacyCRMInstances [set of legacy CRM Instances]
    * @return Map<String, CRM_Setting__mdt>
    */
    public static Map<String, CRM_Setting__mdt> getCRMSettings(Set<String> legacyCRMInstances){
        Map<String, CRM_Setting__mdt> crmSettings = new Map<String, CRM_Setting__mdt>();
        for(CRM_Setting__mdt setting : [SELECT Legacy_CRM_Instance__c, CRM_Domain__c FROM CRM_Setting__mdt WHERE Legacy_CRM_Instance__c IN :legacyCRMInstances]) {
            crmSettings.put(setting.Legacy_CRM_Instance__c, setting);
        }
        return crmSettings;
    }

    /**
    * @description [this method is used to update Payment Term field value on Primary Quote]
    * @param lstOpportunity [list of opportunity]
    private void updatePaymentTermQuote(TriggerInterface_Opportunity.Trig trig){
        List<SBQQ__Quote__c> listQuotetoUpdate = new List<SBQQ__Quote__c>();
        map<Id,Opportunity> mapupdatedOppids = new map<Id,Opportunity>();
        for(Opportunity opp : trig.newList)
        {
            if(String.isNotBlank(opp.Invoice_to_be_issued_before_in_Days__c) && String.isNotBlank(opp.SBQQ__PrimaryQuote__c)
              && trig.oldMap.get(opp.Id).Invoice_to_be_issued_before_in_Days__c != opp.Invoice_to_be_issued_before_in_Days__c)
            {
                mapupdatedOppids.put(opp.SBQQ__PrimaryQuote__c,opp);
            }
        }
        for(SBQQ__Quote__c qt : [Select Id, SBQQ__PaymentTerms__c from SBQQ__Quote__c where Id IN : mapupdatedOppids.keySet() WITH SECURITY_ENFORCED]){
            string paymentTerm = mapupdatedOppids.get(qt.Id).Invoice_to_be_issued_before_in_Days__c;
            qt.SBQQ__PaymentTerms__c = paymentTerm !='0'?'Net '+paymentTerm:'Due on receipt';
            listQuotetoUpdate.add(qt);
        }
        if(!listQuotetoUpdate.isEmpty()){
            update listQuotetoUpdate;
        }
    }*/
    
    /**
    * @description [this method is used to update Default values]
    * @param lstOpportunity [list of opportunity]
    */
    private void setDefaultFieldValues ( List <Opportunity> lstOpportunity){
        for(Opportunity opp : lstOpportunity)
        {   // Bill To Account field value on the opportunity Account
            if(opp.AccountId!=Null && String.IsNotblank(opp.AccountId) && String.isBlank(opp.Bill_To_Account__c))
            {
                opp.Bill_To_Account__c = opp.AccountId;
            }
            // Set Default PriceBook Id From Lable - [IE-317] {Migrated from Process Builder}
            if(String.isBlank(opp.Pricebook2Id))
            {
                opp.Pricebook2Id = Label.PriceBookDefault_ID;
            }
        }
    }

 /**
    * @description [this method is used to update payment Term field value on the opportunity]
    * @param trig TriggerInterface_Opportunity [fetch the trigger new list]
    */    
    private void updatePaymentTerm(TriggerInterface_Opportunity.Trig trig)
    {
        set<Id> editionIds = new Set<Id>();
        for(Opportunity opp : trig.newList)
        {
            Opportunity oldOpp = trig.isUpdate ? trig.oldMap.get(opp.Id):new Opportunity();
            if((String.isNotBlank(opp.Payment_Schedule__c) 
                && oldOpp.Payment_Schedule__c != opp.Payment_Schedule__c)
                || (String.isNotBlank(opp.Default_Edition__c) 
                && oldOpp.Default_Edition__c != opp.Default_Edition__c))
            {
                editionIds.add(opp.Default_Edition__c);
            }    
        }
        if(!editionIds.isEmpty())
        {
            Map<String,string> editionPaymentCodeMap = getEditionPaymentTermCode(editionIds);           
            for(Opportunity opp : trig.newList)
            {
                string key = String.isNotBlank(opp.Payment_Schedule__c)?opp.Payment_Schedule__c+'#'+String.valueOf(opp.Default_Edition__c) : opp.Default_Edition__c;

                Opportunity oldOpp = trig.isUpdate ? trig.oldMap.get(opp.Id):new Opportunity();

                if((String.isNotBlank(opp.Payment_Schedule__c) 
                    && oldOpp.Payment_Schedule__c != opp.Payment_Schedule__c)
                    || (String.isNotBlank(opp.Default_Edition__c) 
                    && oldOpp.Default_Edition__c != opp.Default_Edition__c))
                {
                    opp.Payment_Term_Code__c = editionPaymentCodeMap.containsKey(key)? editionPaymentCodeMap.get(key):'';
                }    
            }
        }
    } 

    /**
    * @description [this method is used to get payment Term Code from edition]
    * @param editionIds Set of Edition Ids
    * @return edition Payment CodeMap <Edition Id, payment term Code>
    */
    public static Map<String,string> getEditionPaymentTermCode(set<Id> editionIds)
    {
        Map<String,string> editionPaymentCodeMap = new Map<String,string>();
        for(Payment_Term_Code__c ptc:[SELECT Payment_Term_Code__c,Payment_Split_Percentage__c,Edition__c,Edition__r.Payment_Schedule__c FROM Payment_Term_Code__c WHERE Edition__c IN:editionIds AND Edition__r.Payment_Schedule__c != null AND Payment_Split_Percentage__c != null WITH SECURITY_ENFORCED])
        {
            editionPaymentCodeMap.put(ptc.Payment_Split_Percentage__c+'#'+String.valueOf(ptc.Edition__c),ptc.Payment_Term_Code__c);
            // Add Edtion Default payment term
            if(ptc.Edition__r.Payment_Schedule__c == ptc.Payment_Split_Percentage__c)
            {
                editionPaymentCodeMap.put(ptc.Edition__c,ptc.Payment_Term_Code__c);
            }
        }
        return editionPaymentCodeMap;
    }
}