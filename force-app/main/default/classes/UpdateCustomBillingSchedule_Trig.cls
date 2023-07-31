/**
* File         :   UpdateCustomBillingSchedule_Trig 
* Project      :   GECI
* Created Date :   4th Jan 2023
* Created By   :   IBM 
* Test Class   :   UpdateCustomBillingSchedule_Trig_Test (99%)
* ***************************************************************************************************
* @description : Trigger Handler class to Update Custom Billing Schedule as per story (GECI-11)
* ***************************************************************************************************
* Modification log :  
*/
public without sharing class UpdateCustomBillingSchedule_Trig implements TriggerInterface_Opportunity.Runnable{
    
    /** 
     * @description : method to update the custom billing schedule fields on opportunity
	 * @param trig
	 */
    public void run(TriggerInterface_Opportunity.Trig trig) {
        if (trig.isBefore && trig.isUpdate ) {
            customBillingScheduleUpdate(trig.newList, trig.oldMap);
        }
    }
    
    /** 
     * @description : method to update the custom billing schedule fields on opportunity
	 * @param newOppLst 
	 * @param oldOppMap
	 */
    public void customBillingScheduleUpdate(List<Opportunity> newOppLst, Map<id, Opportunity> oldOppMap ) {
        try {
            for(Opportunity opp : newOppLst) {
                Opportunity oldOpp = oldOppMap.get(opp.Id);
                if(opp.Custom_Payment__c == false) {
                    opp.Total_No_of_payment__c = null; 
                    opp.Start_Date__c = null; 
                    opp.Total_Milestone_Amount__c = null;
                    opp.Total_Milestone_Dates__c  = null;
                    for(Integer i = 1; i <= 12; i++){
                        opp.put('Milestone_'+i+'_Amount__c', null);
                        opp.put('Milestone_'+i+'_Delivery_Date__c', null);
                        opp.put('Milestone_'+i+'_Percent__c', null);
                    }
                } 
                else if(opp.Custom_Payment__c && opp.Total_No_of_payment__c != null && opp.Total_No_of_payment__c != 0 && opp.Amount != null && opp.Amount != 0 && opp.StageName=='Closed Won') {
                    Boolean isPercentaceChanged = false;
                    for(Integer i = 1; i <= 12; i++){
                        if(opp.get('Milestone_'+i+'_Percent__c') != oldOpp.get('Milestone_'+i+'_Percent__c') && !isPercentaceChanged){
                            isPercentaceChanged = true;
                        }
                    }
                    if(opp.Amount != oldOpp.Amount || isPercentaceChanged){
                        for(Integer i = 1; i <= 12; i++){
                            opp.put('Milestone_'+i+'_Amount__c', 0);
                            if(i > opp.Total_No_of_payment__c){
                                opp.put('Milestone_'+i+'_Delivery_Date__c', null);
                                opp.put('Milestone_'+i+'_Percent__c', null);
                            }
                        }
                        Decimal lastAmount = opp.Amount;
                        for(Integer i = 1; i <= opp.Total_No_of_payment__c; i++){
                            if(i > 1){
                                lastAmount -= Decimal.valueOf(String.valueOf(opp.get('Milestone_'+(i-1)+'_Amount__c')));
                            }
                            Decimal percentege = Decimal.valueOf(String.valueOf(opp.get('Milestone_'+i+'_Percent__c')));
                            Decimal amount = ((opp.Amount * percentege)/100).round(System.RoundingMode.DOWN);
                            opp.put('Milestone_'+i+'_Amount__c',amount);
                            if(i == opp.Total_No_of_payment__c){
                                opp.put('Milestone_'+i+'_Amount__c',lastAmount);
                            }
                        }
                    }
                }
            }
        }catch(exception ex){
            System.debug(LoggingLevel.Debug, 'Error Message '+ ex.getMessage());
        }
    }
}