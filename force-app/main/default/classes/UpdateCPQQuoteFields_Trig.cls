/**
* File			: 	UpdateCPQQuoteFields_Trig
* Project       :   Informa Order Management
* Created By	: 	Girikon(Deepak)
* Created Date	: 	03rd Feb 2022
* Test Class   :    UpdateCPQQuoteFields_Trig_Test(100%)
* ***************************************************************************
* @description : Utility Class for Updating fields on Quote
*****************************************************************************
* Modification log :
* 1. Girikon (Ansh) [15 Feb 2021 (IOM-838)]  Update Payment Term field value on Quote
*/
public with sharing class UpdateCPQQuoteFields_Trig implements TriggerInterface_SBQQ_Quote.Runnable{
    /**
* @description  This method is execute Trigger
* @param trig Order TriggerInterface    
*/
    public void run(TriggerInterface_SBQQ_Quote.Trig trig) {
        if (trig.isBefore && trig.isInsert) {
            Set<Id> oppIds = new Set<Id>();  
            for(SBQQ__Quote__c qt : trig.newList){
                if(String.isNotBlank(qt.SBQQ__Opportunity2__c)){
                    oppIds.add(qt.SBQQ__Opportunity2__c);
                }
            }
            
            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id,Billing_Contact__c,Bill_To_Account__c FROM opportunity where Id IN:oppIds]);
            
            for(SBQQ__Quote__c qt : trig.newList){
                Opportunity opp = oppMap.get(qt.SBQQ__Opportunity2__c);
                if(String.isNotBlank(opp.Billing_Contact__c)){
                    qt.Billing_Contact__c = opp.Billing_Contact__c;
                    qt.Bill_To_Contact__c = opp.Billing_Contact__c;
                }
                if(String.isNotBlank(opp.Bill_To_Account__c)){
                    qt.Bill_To_Account__c = opp.Bill_To_Account__c;
                }
                //qt.SBQQ__OrderBy__c = 'Name';
            }
            /*if(trig.newList !=null){
                paymentTermUpdate(trig.newList);
            }*/
        }
        if(trig.isAfter && trig.isUpdate)
        {
            updatePaymentTermOrder(trig);
        }
    }
    /**
* @description [this method is used to update payment terms field value on the quote]
* @param lstQuote [list of quote]

    private static void paymentTermUpdate (List<SBQQ__Quote__c> lstQuote){
        Set<Id> oppIds = new Set<Id>();
        for(SBQQ__Quote__c qt : lstQuote)
        {
            if(String.isNotBlank(qt.SBQQ__Opportunity2__c)){
                oppIds.add(qt.SBQQ__Opportunity2__c);
            }
        }
        Map<Id,Opportunity> mapOfopp = new Map<Id,Opportunity>([SELECT Id,Invoice_to_be_issued_before_in_Days__c FROM Opportunity WHERE Id in:oppIds WITH SECURITY_ENFORCED]);
        
        for(SBQQ__Quote__c qt : lstQuote){
            if(String.isNotBlank(qt.SBQQ__Opportunity2__c) && mapOfopp.containsKey(qt.SBQQ__Opportunity2__c)){
                if(mapOfopp.get(qt.SBQQ__Opportunity2__c).Invoice_to_be_issued_before_in_Days__c != null){
                    //qt.SBQQ__PaymentTerms__c = 'Net'+mapOfopp.get(qt.SBQQ__Opportunity2__c).Invoice_to_be_issued_before_in_Days__c;
                    qt.SBQQ__PaymentTerms__c = 'Net '+mapOfopp.get(qt.SBQQ__Opportunity2__c).Invoice_to_be_issued_before_in_Days__c;
                } 
            }
        }
    }*/
    
    /**
* @description [this method is used to update Payment Term field value on Primary Quote]
* @param lstOpportunity [list of opportunity]
*/
    private void updatePaymentTermOrder(TriggerInterface_SBQQ_Quote.Trig trig){
        List<Order> listOrdertoUpdate = new List<Order>();
        map<Id,SBQQ__Quote__c> mapupdatedqtids = new map<Id,SBQQ__Quote__c>();
        for(SBQQ__Quote__c qt : trig.newList)
        {
            if(String.isNotBlank(qt.SBQQ__PaymentTerms__c) && trig.oldMap.get(qt.Id).SBQQ__PaymentTerms__c != qt.SBQQ__PaymentTerms__c)
            {
                mapupdatedqtids.put(qt.Id,qt);
            }
        }
        for(Order o : [Select Id, SBQQ__PaymentTerm__c,SBQQ__Quote__c from order where SBQQ__Quote__c IN : mapupdatedqtids.keySet() WITH SECURITY_ENFORCED]){
            o.SBQQ__PaymentTerm__c = mapupdatedqtids.get(o.SBQQ__Quote__c).SBQQ__PaymentTerms__c;
            listOrdertoUpdate.add(o);
        }
        if(!listOrdertoUpdate.isEmpty()){
            update listOrdertoUpdate;
        }
    }
}