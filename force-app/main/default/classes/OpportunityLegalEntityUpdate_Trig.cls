/**
* File:          OpportunityLegalEntityUpdate_Trig
* Project:       GAP
* Created Date:  12/10/2019
* Created By:    Sachin Chaudhary
* Modified By:   Trusha
* Modified Date: 01/13/2020 
* Test Class:   OpportunityLegalEntityUpdate_Trig_Test
* Test Coverage: 100%
* *******************************************************************************************************
* @description : Sharing Class to update the Legal Entity, Tax Jurisdiction on opportunity.
*/

public with sharing class OpportunityLegalEntityUpdate_Trig implements TriggerInterface_Opportunity.Runnable {

    /*
    * @description [Variable Declarations]
    */
    Set<String> setOpportunityEdition = new Set<String>();

    /**
    * @description [Call Interface Class to fetch the new list and old map of opportunity]
    * @param trig [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if(trig.isBefore && (trig.isInsert || trig.isUpdate)){
            opportunityLegalEntityUpdate(trig.newList);
        }
    }
    
    /**
    * @description [this method is used to Update Legal Entity & Tax Jurisdiction on affected Opportunities]
    * @param lstOpportunity [list of opportunity]
    */
    public void opportunityLegalEntityUpdate ( List <Opportunity> lstOpportunity) {
        for(Opportunity opp : lstOpportunity){
            if(opp.Default_Edition__c != null && opp.Legal_Entity__c == null){
                setOpportunityEdition.add(opp.Default_Edition__c);
            }
        }
        
        if(!setOpportunityEdition.isEmpty() &&  Schema.sObjectType.Edition__c.isAccessible()){
            Map<Id,Edition__c> mapEditionAndSeries = new  Map<Id,Edition__c>([SELECT Id, Part_of_Series__r.Legal_Entity__c FROM Edition__c WHERE ID IN: setOpportunityEdition]);
            for(Opportunity opp : lstOpportunity){
                if(mapEditionAndSeries.containsKey(opp.Default_Edition__c)){
                    //Updating Legal Entity on Opportunity.
                    opp.Legal_Entity__c = mapEditionAndSeries.get(opp.Default_Edition__c).Part_of_Series__r?.Legal_Entity__c;
                }
            }
        }
    }
}