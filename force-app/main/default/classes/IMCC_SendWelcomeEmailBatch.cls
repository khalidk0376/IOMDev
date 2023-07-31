/**
* Created/Modified By    : Girikon(Deepak)
* Created On             : 29-06-2022
* @description           : This batch class is for sending welcome emails in bulk
* Test Class             : IMCC_EditionWelcomeEmailTest
* Code Coverage          : 100%
* Modified by 
**/
public class IMCC_SendWelcomeEmailBatch implements Database.Batchable<sobject>,Database.stateful{

    public List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
    public Boolean isManual = false;
    public Set<Id> editionIds;
    
    /**
    * @description  IMCC_SendWelcomeEmailBatch Constructor
    * @param  listCEM
    * @param  isManual
    */
    public IMCC_SendWelcomeEmailBatch(List<Contact_Edition_Mapping__c> listCEM, Boolean isManual){
        this.listCEM = listCEM;
        this.isManual = isManual;
        this.editionIds = new Set<Id>();
    }
    
    /**
    * @description  IMCC_SendWelcomeEmailBatch Start Method
    * @param  bc
    * @return List<Contact_Edition_Mapping__c>
    */
    public List<Contact_Edition_Mapping__c> start(Database.BatchableContext bc){
        List<Contact_Edition_Mapping__c> listCemUpdate = new List<Contact_Edition_Mapping__c>();
        for(Contact_Edition_Mapping__c cem : this.listCEM){
            listCemUpdate.add(new Contact_Edition_Mapping__c(Id=cem.Id,Welcome_Email_Job_Id__c=bc.getJobId()));
            editionIds.add(cem.Edition__c);
        }
        update listCemUpdate;
        return this.listCEM;
    }

    /**
    * @description  IMCC_SendWelcomeEmailBatch execute Method
    * @param bc
    * @param scope
    */
    public void execute(Database.BatchableContext bc, List<Contact_Edition_Mapping__c> scope){
        IMCC_EditionWelcomeEmail.processWelcomeEmail(scope, this.isManual);
    }

    /**
    * @description  IMCC_SendWelcomeEmailBatch finish Method
    * @param bc
    */
    public void finish(Database.BatchableContext bc){
        List<Edition__c> listEditionUpdate = new List<Edition__c>();
        for(Id edId : editionIds){
            listEditionUpdate.add(new Edition__c(Id=edId,Welcome_Email_Job_Status__c='Completed'));
        }
        if(!listEditionUpdate.isEmpty()){update listEditionUpdate;}
    }
}