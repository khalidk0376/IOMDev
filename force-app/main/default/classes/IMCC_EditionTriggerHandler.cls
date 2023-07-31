/**
* Created By    : Girikon(Keertiraj)
* Created On    : 07/10/2021
* @description  : This class is used to create community user if not already exists when Send Welcome email is checked.                    
* Test Class    : IMCC_EditionTriggerHandler_Test(95%)
****************************************************************
* Modified By   : Girikon(Arushi, Saurabh)
* Modified On   : 08/02/2022
* @Modification : (IMCC-69) As an Ops User , I Should be able to  choose the due submission date for stand design forms so the contractor and customer are aware of the deadline to complete this process. 
* @Modification : (IMCC-68) As an  Ops User , I Should be able to  set a due date for an exhibitor to associate a contractor so that the customer is aware of the deadline to nominate contractors to complete the stand design process.
*/

public without sharing class IMCC_EditionTriggerHandler {
    /**
    * @description before Insert Handler for Edition                     
    * @param newEditions
    */
    public Static void handleBeforeInsert(List<Edition__c> newEditions){
        updateDueDates(newEditions);
    }  

    /**
    * @description before update Handler for Edition                     
    * @param newEditions
    */
    public Static void handleBeforeUpdate(List<Edition__c> newEditions){
        updateDueDates(newEditions);
    }
    
    /**
    * @description update Due Dates                 
    * @param newEditions
    */
    public Static void updateDueDates(List<Edition__c> newEditions){ 
        for(Edition__c edition : newEditions){
            if(edition.Contractor_Nomination_Due_Date__c == null && edition.Start_Date__c != null){
                edition.Contractor_Nomination_Due_Date__c = edition.Start_Date__c;
            }
            if(edition.Stand_Design_Completion_Due_Date__c == null && edition.Start_Date__c != null){
                edition.Stand_Design_Completion_Due_Date__c = edition.Start_Date__c;
            }
            if(edition.Due_Date__c == null && edition.End_Date__c != null){
                edition.Due_Date__c = edition.End_Date__c;
            }
            if(edition.Company_Profile_Submission_Due_Date__c == null && edition.End_Date__c != null){
                edition.Company_Profile_Submission_Due_Date__c = edition.End_Date__c;
            }
        }
    }
    
    /**
    * @description after update Handler for Edition                    
    * @param newEditions                   
    * @param oldEditions
    */
    public static void handleAfterUpdate(List<Edition__c> newEditions,Map<Id,Edition__c> oldEditions){
        try{
            Set<Id> editionIds=new Set<Id>();
            for(Edition__c edition : newEditions){
                if((edition.Customer_Center_Status__c!=oldEditions.get(edition.Id).Customer_Center_Status__c || edition.Send_Welcome_email__c!=oldEditions.get(edition.Id).Send_Welcome_email__c) && (edition.Customer_Center_Status__c =='Active' && edition.Send_Welcome_email__c == true && (edition.Welcome_Email_Job_Status__c == null || edition.Welcome_Email_Job_Status__c == 'Completed'))){
                    editionIds.add(edition.Id);
                }
            }
            
            if(!editionIds.isEmpty() && Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
                List<Contact_Edition_Mapping__c> lstContactEDMapping = [SELECT Id, Name, Account__c, Contact__c, Edition__c, CC_Status__c, IsEmailSent__c FROM Contact_Edition_Mapping__c WHERE Edition__c IN:editionIds AND IsEmailSent__c=false];
                IMCC_SendWelcomeEmailBatch batch = new IMCC_SendWelcomeEmailBatch(lstContactEDMapping,false);
                Id jobId = Database.executeBatch(batch,50);
                Map<Id,Edition__c> mapEditionUpdate = new Map<Id,Edition__c>();
                for(Contact_Edition_Mapping__c cem : lstContactEDMapping){
                    mapEditionUpdate.put(cem.Edition__c,new Edition__c(Id=cem.Edition__c,Welcome_Email_Job_Id__c=jobId,Welcome_Email_Job_Status__c='In Progress'));
                }
                if(!mapEditionUpdate.isEmpty()){update mapEditionUpdate.Values();}
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Edition__c', 'After Update');
        }
    }
    
    /**
    * @description notify User To Assign Contractor                   
    * @param newEditions                   
    * @param oldEditions
    */
    public static void notifyUserToAssignContractor(Map<Id,Edition__c> newEditions,Map<Id,Edition__c> oldEditions){
        Set<Id> editionIds = new Set<Id>();
        Set<Id> pdIds = new Set<Id>();
        
        try{
            for(Edition__c edition : newEditions.Values()){
                if((oldEditions == null || (edition.Contractor_Nomination_Due_Date__c!=oldEditions.get(edition.Id).Contractor_Nomination_Due_Date__c)) && edition.Stand_Setting__c != null){
                    editionIds.add(edition.Id);
                }
            }
            
            if(!editionIds.isEmpty()){
                List<Purchase_Data__c> listPD  = [SELECT Id FROM Purchase_Data__c WHERE Booth_Number__c!=null AND Booth_Number__c!='' AND Contact_Edition_Mapping__r.Edition__c IN:editionIds AND Booth_Product_Type__c IN ('Space','Space Only') AND Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' WITH SECURITY_ENFORCED];
                for(Purchase_Data__c pd : listPD){
                    pdIds.add(pd.Id);
                }
                if(!pdIds.isEmpty()){
                    IMCC_PurchaseDataTriggerHandler.notifyUserToAssignContractor(pdIds);
                }
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Edition__c', 'After Update');
        } 
    }
}