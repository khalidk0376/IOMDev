/**
 * Raider Data Services, RA
 * Project IML2R
 * Class OpportunityUpdateHandlerOnAmend_Trig
 * Test Class 
 * Test Coverage 
 * Date 10/02/2020
 * *******************************************************************************************************
 * @description This class is mainly used to update Amended opportunity with its new Version Number and Master contract previous Number.
 */
public with sharing class  OpportunityUpdateHandlerOnAmend_Trig {
	/**
     * @description update Ammended opportunity fields
     * @param lstOpp list of opportunitites.
     */
    public static void updateAmmendedOpp(List<Opportunity> lstOpp) {
        Map<Id,Opportunity> mapOfAmmendOpp = new Map<Id,Opportunity>();
        Map<Id,Contract> mapOfNewContracts ;
        Set<Id> setOfCntrIds =  new Set<Id>();
        for(Opportunity opp : lstOpp){
            if(opp.name.contains('Amendment')){
                mapOfAmmendOpp.put(opp.Id, Opp);
                setOfCntrIds.add(opp.SBQQ__AmendedContract__c);
            }
        }
        //get Contracts
        mapOfNewContracts = getRelContract(setOfCntrIds);
        //populate Ammended opportunity fields
        for(Opportunity opp : mapOfAmmendOpp.values()){
            if(mapOfNewContracts.get(opp.SBQQ__AmendedContract__c) != null &&
               mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__c != null &&
               mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.OpportunityId != null ){
                   if(mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_No_Version__c == null){
                       opp.Master_Contract_No_Version__c = 1;
                   }
                   else{
                       opp.Master_Contract_No_Version__c = mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_No_Version__c + 1;
                   }
                   if(mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_No_Previous__c == null &&
                      mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_Auto_Number__c != null){
                          opp.Master_Contract_No_Previous__c = mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_Auto_Number__c;
                      }
                   else{
                       opp.Master_Contract_No_Previous__c = mapOfNewContracts.get(opp.SBQQ__AmendedContract__c).SBQQ__Order__r.Opportunity.Master_Contract_No_Previous__c;
                   }
               }
        }
    }
    
    /**
     * @description get opportunity related Contracts. 
     * @param setOfCntrIds Set of Contract Ids
     * @return Map<Id,Contract> map of Contracts
     */
    public static Map<Id,Contract> getRelContract (Set<Id> setOfCntrIds){
        Map<Id,Contract> mapOfNewContracts ;
        if(setOfCntrIds.size() > 0 ){
            mapOfNewContracts = new Map<Id,Contract>([select Id,SBQQ__Order__c,SBQQ__Order__r.OpportunityId,
                                                      SBQQ__Order__r.Opportunity.Master_Contract_Auto_Number__c,
                                                      SBQQ__Order__r.Opportunity.Master_Contract_No_Version__c,
                                                      SBQQ__Order__r.Opportunity.Master_Contract_No_Previous__c
                                                      from Contract where id =: setOfCntrIds ]);
        }
        return mapOfNewContracts;
    }
}