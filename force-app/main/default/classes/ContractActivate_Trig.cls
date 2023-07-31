/**
* File:         ContractActivate_Trig
* Project:      IML2R
* Created Date: 01/09/2020
* Created By:   Sachin Caudhary
* Test Class:   ContractActivate_Trig_Test
* Test Coverage: 100%
* *******************************************************************************************************
* @description : This class is mainly used to activate Contract and update Opportunity's Main Contract and Contract Number.
*/

public with sharing class ContractActivate_Trig implements TriggerInterface_Contract.Runnable {

    /*
    * @description [Variable Declarations]
    */
    Map<Contract,id> mapOpptyContract = new Map<Contract,id>();
    set<id> contractIdsSet = new set<id>();
    
    /*
    * @description [Call Interface Class to fetch the new list and old map of Contract]
    * @param TriggerInterface_Contract [fetch the trigger new list and old map]
    */
    public void run(TriggerInterface_Contract.Trig trig) {
        if(trig.isAfter && trig.isInsert){
            contractActivate(trig.newList);
        }
    }
    
    /*
    * @description [this method is used to Update Legal Entity]
    * @param lstContract [list of Contract]
    */
    public void contractActivate ( List <Contract> lstContract)
    {
        for(Contract objCon : lstContract){
            if(objCon.SBQQ__Quote__c !=null && objCon.Primary_Quote__c ==true){
                contractIdsSet.add(objCon.id);
            }
            if(objCon.SBQQ__Opportunity__c != NULL){
                mapOpptyContract.put(objCon, objCon.SBQQ__Opportunity__c);
            }
        }
        
        // Activating Contract at insertion time
        if(!contractIdsSet.isEmpty()){
            List<Contract> lstToUpdateContract = new List<Contract>();
            Contract oContract ;
            for(Id id : contractIdsSet ){
                oContract = new Contract();
                oContract.id = id;
                oContract.Status = 'Activated';
                lstToUpdateContract.add(oContract);
            }
            if(!lstToUpdateContract.isEmpty() && Schema.sObjectType.Contract.isUpdateable()){
                update lstToUpdateContract;
            }
        }
        
        // Update Current Contract to Opportunity's Main Contract and Contract Number
        if(!mapOpptyContract.isEmpty()){
            List<Opportunity> lstToUpdateOppty =  new List<Opportunity>();
            Opportunity oOpportunity ;
            for(Contract oContract:mapOpptyContract.keySet()){
                oOpportunity = new Opportunity();
                oOpportunity.Id = mapOpptyContract.get(oContract);
                oOpportunity.Main_Contract__c = oContract.Id;
                oOpportunity.Contract_Number__c = oContract.ContractNumber;
                lstToUpdateOppty.add(oOpportunity);
            }
            if(!lstToUpdateOppty.isEmpty() && Schema.sObjectType.Opportunity.isUpdateable()){
                update lstToUpdateOppty;
            }
        }
    }
}