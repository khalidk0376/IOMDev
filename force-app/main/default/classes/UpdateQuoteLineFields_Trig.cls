/**
* File			: 	UpdateQuoteLineFields_Trig
* Project       :   Informa Order Management [IOM-1641]
* Created By	: 	Girikon(Ashish)
* Created Date	: 	27th Jun 2022
* Test Class   :    UpdateQuoteLineFields_Test(100%)
* ***************************************************************************
* @description : Utility Class for Updating all Fields updates on QuoteLines
*****************************************************************************
* Last Modified By :
*/
public with sharing class UpdateQuoteLineFields_Trig implements TriggerInterface_QuoteLine.Runnable
{
    /**
    * @description  This method is execute Trigger
    * @param trig QuoteLine TriggerInterface    
    */
    public void run(TriggerInterface_QuoteLine.Trig trig)
    {
        if(trig.isBefore && trig.isInsert) 
        {
            updateCRMLegacyOLINumber(trig);
        }
        if(trig.isAfter && trig.isUpdate) 
        {
            updateFieldsOnOLI(trig);
        }
    }

    /**
    * @description  This method is used to Update CRM Ref No on Amended QLI
    * @param trig 
    */
    private static void updateCRMLegacyOLINumber(TriggerInterface_QuoteLine.Trig trig)
    {
        set<Id> sourceQuoteIds = new Set<Id>();
        set<Id> upgradedSubscriptionIds = new Set<Id>();
        for(SBQQ__QuoteLine__c qli :trig.newList)
        {
            if(String.isNotBlank(qli.SBQQ__Source__c))
            {
                sourceQuoteIds.add(qli.SBQQ__Source__c);
            } //SBQQ__Subscription__c
        }
        Map<Id,SBQQ__QuoteLine__c> mapQLI = new Map<Id,SBQQ__QuoteLine__c>([SELECT Id,SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.CRM_OLI_Number__c,SBQQ__Quote__r.SBQQ__Type__c FROM SBQQ__QuoteLine__c WHERE Id IN:sourceQuoteIds]);

        for(SBQQ__QuoteLine__c qli :trig.newList)
        {
            if(String.isNotBlank(qli.SBQQ__Source__c) && mapQLI.ContainsKey(qli.SBQQ__Source__c))
            {
                qli.CRM_OLI_Number__c = mapQLI.get(qli.SBQQ__Source__c).SBQQ__UpgradedSubscription__r.SBQQ__QuoteLine__r.CRM_OLI_Number__c;
            }
        }
    }

    /**
    * @description  This method is used to Update Field values on OLI
    * @param trig 
    */
    private static void updateFieldsOnOLI (TriggerInterface_QuoteLine.Trig trig)
    {   
        map<Id,SBQQ__QuoteLine__c> updatedQLImap = new map<Id,SBQQ__QuoteLine__c>();

        for(SBQQ__QuoteLine__c qli :trig.newList)
        {
            SBQQ__QuoteLine__c oldQLI =  trig.isInsert ? new SBQQ__QuoteLine__c():trig.oldMap.get(qli.Id);

            if(qli.Booth_Size__c != oldQLI.Booth_Size__c)
            {
                updatedQLImap.put(qli.Id,qli);
            }
        }

        // get All opportunity Lines & update
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(OpportunityLineItem oli : [SELECT Id,Booth_Size__c,SBQQ__QuoteLine__c FROM OpportunityLineItem WHERE SBQQ__QuoteLine__c in:updatedQLImap.keySet() WITH SECURITY_ENFORCED])
        {
            oli.Booth_Size__c = updatedQLImap.get(oli.SBQQ__QuoteLine__c).Booth_Size__c;
            oliList.add(oli);
        }

        if(!oliList.isEmpty())
        {
            update oliList;
        }
    }
}