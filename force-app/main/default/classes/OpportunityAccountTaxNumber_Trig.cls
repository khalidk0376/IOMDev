/**
* File:         OpportunityAccountTaxNumber_Trig
* Project:      GAP
* Created Date: 11/15/2019
* Created By:   Yash Gupta
* Test Class:   OpportunityAccountTaxNumber_Trig_Test
* Coverage:     87%
* *******************************************************************************************************
* @description : Sharing Class to update the account tax number on opportunity.
* *******************************************************************************************************
* History:      Modified By Yash Gupta [11/27/2019], Increase code coverage. Modified By Yash Gupta [1/22/2020], Increase code coverage. Modified By Yash Gupta [1/28/2020]
*/

public with sharing class OpportunityAccountTaxNumber_Trig implements TriggerInterface_Opportunity.Runnable {

    /*
    * @description [Variable Declarations]
    */
    Set<String> setAccountId = new Set<String>();
    Set<String> setDeaultEditionId = new Set<String>();
    Set<Boolean> setIsOneInvAcc = new Set<Boolean>();
    Set<Boolean> setIsOneInvEdition = new Set<Boolean>();
    Map<String,Account_Tax_Number__c> mapAccountTaxNumber = new Map<String,Account_Tax_Number__c>();
    
    /*
    * @description [Call Interface Class to fetch the new list and old map of opportunity]
    * @param TriggerInterface_Opportunity [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if(trig.isBefore && trig.isInsert){
            if(trig.newList !=null && trig.oldMap !=null){
                accounttaxnumberupdate(trig.newList,trig.oldMap);
            }
        }
    }
    
    /*
    * @description [this method is used to account tax number on the opportunity]
    * @param lstOpportunity [list of opportunity]
    * @param oldMapOpportunity [Map of opportunity id and opportunity]
    */
    public void accounttaxnumberupdate ( List <Opportunity> lstOpportunity , Map<Id , Opportunity> oldMapOpportunity){
        for(Opportunity opp : lstOpportunity){
            if(opp.AccountId!=Null){
                setAccountId.add(opp.AccountId);
                if(opp.Default_Edition__c!=null){
                    setDeaultEditionId.add(opp.Default_Edition__c);
                }
                
            }
        }
        
        if(setAccountId.size() > 0){
            List<Account_Tax_Number__c> lstAccountTaxNumber = [select Id, Status__c from Account_Tax_Number__c where Account__c IN: setAccountId AND Status__c = 'Valid' WITH SECURITY_ENFORCED ORDER BY LASTMODIFIEDDATE DESC];
            List<Account> lstAccount = [select id,One_Invoice_Per_Contract__c from Account Where Id IN : setAccountId WITH SECURITY_ENFORCED];
            if(lstAccount.size() > 0){setIsOneInvAcc.add(lstAccount.get(0).One_Invoice_Per_Contract__c);}
            if(setDeaultEditionId.size() > 0){
                List<Edition__c> lstEdition = [select id,One_Invoice_Per_Contract__c from Edition__c Where Id IN : setDeaultEditionId AND Edition_Status__c = 'Active' WITH SECURITY_ENFORCED];
                if(lstEdition.size() > 0){setIsOneInvEdition.add(lstEdition.get(0).One_Invoice_Per_Contract__c);}
            }
            
            for(Opportunity opp : lstOpportunity){
                if(lstAccountTaxNumber.size() == 1){
                    opp.Tax_Registration__c = lstAccountTaxNumber.get(0).Id;
                } else if(lstAccountTaxNumber.size() > 1){
                    opp.Tax_Registration__c = Null;
                }
                
                /**
                * @Description: Set Payment Schedule field to 100 on the basis of One Invoice Per Contract checkbox of account and defauld edition as per ticket IML2R-502.
                * Modified By:  Yash Gupta [1/22/2020]
                */
                if(setIsOneInvAcc.contains(true)){
                    opp.Payment_Schedule__c = '100';
                } else if(setIsOneInvEdition.contains(true)){
                    opp.Payment_Schedule__c = '100';
                }
            }
            
        }
    }
}