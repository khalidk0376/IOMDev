/**
* File:         OpportunityRecordTypeUpdate_Trig
* Project:      GAP
* Created Date: 23/10/2019
* Created By:   Sachin Chaudhary
* Test Class:   OpportunityRecordTypeUpdate_Trig_Test
* Test Coverage: 100%
* *******************************************************************************************************
* @description : Sharing Class to update the Record Type on opportunity.
* *******************************************************************************************************
* Modified By: Girikon(Prashant)-[IML2R-2018] (27th March 2020)
*/

public with sharing class OpportunityRecordTypeUpdate_Trig implements TriggerInterface_Opportunity.Runnable {
    
    /*
* @description [Variable Declarations]
*/
    Set<String> setOpportunityEdition = new Set<String>();
    Map<String,Edition__c> mapEditionAndSeries = new Map<String,Edition__c>();
    
    /*
* @description [Call Interface Class to fetch the new list and old map of opportunity]
* @param TriggerInterface_Opportunity [fetch the trigger new list and old map]
*/
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if(trig.newList !=null && trig.oldMap !=null)
        {
            if (Trig.isBefore && (Trig.isInsert || Trig.isupdate))             
            {
                BeforeInsertAndUpdateOpportunity(trig.newList);
            }
        }
    }
    
    /*
* @description [this method is used to Update Opportunity name on before Insert Condition]
* @param lstOpportunity [list of opportunity]
* @param oldMapOpportunity [Map of opportunity id and opportunity]
*/
    public void BeforeInsertAndUpdateOpportunity( List <Opportunity> lstOpportunity)
    {
            for(Opportunity opp : lstOpportunity)
            {
                if (opp.StageName == 'Closed Won' && opp.Status__c != 'Amended') 
                {
                    string closedWonRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity Closed Won').getRecordTypeId();
                    opp.RecordTypeID = closedWonRecordTypeId;
                }
                else if(opp.StageName != 'Closed Won' && opp.Status__c != 'Amended'){
                // [IML2R-2018] : Changed the Record Type from 'Opportunity Account Unhold' to 'Opportunity'.
                    string accountUnholdRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Opportunity').getRecordTypeId();
                    opp.RecordTypeID = accountUnholdRecordTypeId;
                }
            }
    }
}