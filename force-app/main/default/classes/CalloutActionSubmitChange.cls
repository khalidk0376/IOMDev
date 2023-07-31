/**
 * Test the apex class named 'OpportunityUserType'
 * @Author      : Sachin Chaudhary
 * @Date        : 18/Dec/2019 
 * Apex Class   : CalloutActionSubmitChange
 * @description Test class
 */
public class CalloutActionSubmitChange implements Queueable, Database.AllowsCallouts {
    Set<Id> recordIds;
    /**
     * [CalloutActionSubmitChange parameterized constructor ]
     * @param  recordIds [get opportunity id from changes record button.t]
     * @return           [null]
     */
    public CalloutActionSubmitChange (Set<Id> recordIds) {
        this.recordIds = recordIds;
    }
    /**
     * [execute update opportunity after closed won opportunity , only sales and sales brasil applicable for this funcationality]
     * @param context [execute update opportunity after closed won opportunity , only sales and sales brasil applicable for this funcationality]
     */
    public void execute(QueueableContext context) {
      if(recordIds != null){
        Change_Request__c  ochange = [SELECT  id , Opportunity__c, Account__c FROM Change_Request__c WHERE Id = :recordIds];
        if (ochange.Opportunity__c != null){
            Opportunity oOpportunity = [SELECT  id , StageName , Status__c FROM Opportunity WHERE Id = :ochange.Opportunity__c];
             oOpportunity.Status__c = 'Pending Change';
             UPDATE oOpportunity;
        }
        
      }
    }
}