/**
* File          :   OpportunityNameUpdate_Trig
* Project       :   GAP
* Created Date  :   12 Oct 2019
* Created By    :   Girikon(Sachin Chaudhary)
* @description  :   Sharing Class to update the Name on opportunity.
* Test Class    :   OpportunitynameUpdate_Trig_Test (88%)
* *******************************************************************************************************
* Modification log :
* 1. 28th Jan 2022 - Girikon(Ashish) [IOM-772] - Updated code to populate the Ship to Account lookup same as Bill To Account if the Ship to Account field is null
*
*/

public with sharing class OpportunityNameUpdate_Trig implements TriggerInterface_Opportunity.Runnable {

    /*
    * @description [Variable Declarations]
    */
    Set<String> setOpportunityEdition = new Set<String>();
    Map<String,Edition__c> mapEditionAndSeries = new Map<String,Edition__c>();
    
    /**
    * @description [Call Interface Class to fetch the new list and old map of opportunity]
    * @param trig TriggerInterface_Opportunity [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if(trig.newList !=null && trig.oldMap !=null){
            //OpportunityLegalEntityUpdate(trig.newList,trig.oldMap);
            if (Trig.isBefore && Trig.isInsert)             
            {
                beforeInsertOpportunity(trig.newList);
                OpportunityUpdateHandlerOnAmend_Trig.updateAmmendedOpp(trig.newList);
            }
            if (Trig.isBefore && Trig.isupdate)             
            {
                beforeUpdateOpportunity(trig.newList,trig.oldMap);
            }
        }
    }
    
    /**
    * @description [this method is used to Update Opportunity Fields on before Insert Condition]
    * @param lstOpportunity [list of new opportunity]    
    */
    public void beforeInsertOpportunity( List <Opportunity> lstOpportunity)
    {
        for(Opportunity opp : lstOpportunity)
        {
            if (opp.Is_Barter_Opportunity__c && !opp.Name.contains('BARTER-')) 
            {
                opp.Name = 'BARTER-' + opp.Name;
            }
            if(string.isBlank(opp.Ship_To_Account__c)) // Added for [IOM-772]
            {
                opp.Ship_To_Account__c = opp.Bill_To_Account__c;
            }
            if(opp.name.contains('Amendment'))
            {
                opp.Bill_To_Account__c = null;
                opp.Billing_Contact__c = null;
            }
        }
    }
    
    /**
    * @description [this method is used to Update Opportunity fields on Before update Condition]
    * @param lstOpportunity [list of opportunity]
    * @param oldOppMap [Map of opportunity id and opportunity]
    */
    public void beforeUpdateOpportunity( List <Opportunity> lstOpportunity, Map<Id , Opportunity> oldOppMap)
    {        
        for(Opportunity opp : lstOpportunity)
        {
            if (opp.Is_Barter_Opportunity__c != oldOppMap.get(opp.Id).Is_Barter_Opportunity__c && opp.Is_Barter_Opportunity__c && !oldOppMap.get(opp.Id).Name.contains('BARTER-')) 
            {
                opp.Name = 'BARTER-' + opp.Name;
            }
            // Added for [IOM-772]
            if(string.isBlank(opp.Ship_To_Account__c))
            {
                opp.Ship_To_Account__c = opp.Bill_To_Account__c;
            }
        }
    }
}