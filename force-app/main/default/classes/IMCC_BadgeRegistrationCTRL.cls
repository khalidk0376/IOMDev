/**
* Created       :  Girikon(Arushi [IMCC-1685])
* Created On    :  21/03/2022
* @description  :  As a customer, I would like to view details of the Badge Registration as a tab in the portal.
* Methods          :   getProgressPercent(),getPurchaseData(),setUpdatedValue(),getPurchaseSummary()
* Apex Class       :   IMCC_BadgeRegistrationCTRL 
* Apex Test Class  :   IMCC_BadgeRegistrationCTRL_Test (97%)
**/
public without sharing class IMCC_BadgeRegistrationCTRL {
    
    /**
    * @description get Progress Percent
    * @param accountId
    * @param editionCode
    * @return Contact_Edition_Mapping__c
    */
    @auraEnabled
    public static Contact_Edition_Mapping__c getProgressPercent(String accountId, String editionCode){
        Contact_Edition_Mapping__c cem;
        try{
            Map<String,Object> mapCEMDetails = IMCC_UtilityMethods.getContactEditionMappings(editionCode, accountId);
            cem = (Contact_Edition_Mapping__c)mapCEMDetails.get('cem');
            List<Contact_Edition_Mapping__c> pcem =  [SELECT Id,Name,Access_Type__c,Account__c,Account__r.Name,
                                                CC_Status__c,Contact__c,Relationship_Status__c,Completed_Purchase_Summaries__c,      
                                                Primary_Contact_Edition_Mapping__c,Edition__c, Edition__r.Edition_Code__c,  
                                                Edition__r.Form_Setting__c,Edition__r.Event_Setting__c,
                                                Edition__r.Due_Date__c,Edition__r.Company_Profile_Submission_Due_Date__c,
                                                Edition__r.Contractor_Nomination_Due_Date__c,        
                                                Edition__r.Event_Type__c,Edition__r.Stand_Setting__r.Allow_Contractor_Nomination__c,
                                                Edition__r.Stand_Design_Completion_Due_Date__c
                                                FROM Contact_Edition_Mapping__c 
                                                WHERE Id =:cem.Primary_Contact_Edition_Mapping__c   WITH SECURITY_ENFORCED];
    
            if(String.isBlank(cem.Completed_Purchase_Summaries__c)){cem.Completed_Purchase_Summaries__c='';}
            if(!pcem.isEmpty()){cem.Completed_Purchase_Summaries__c = cem.Completed_Purchase_Summaries__c + ';' + (String.isBlank(pcem.get(0).Completed_Purchase_Summaries__c)?'':pcem.get(0).Completed_Purchase_Summaries__c);}
        }
        catch (Exception e) {String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';String stackTrace = e.getStackTraceString().substringBefore('\n');throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return cem;
    }
    
    /**
    * @description get Purchase Data
    * @param accountId
    * @param editionCode
    * @return List<Purchase_Data__c>
    */
    @auraEnabled
    public static List<Purchase_Data__c> getPurchaseData(String accountId, String editionCode){
        return IMCC_HomeCtrl.getBadges(editionCode,accountId);        
    }
    
    /**
    * @description set Updated Value
    * @param type
    * @param cemId
    * @return String
    */
    @auraEnabled
    public static String setUpdatedValue(String type,String cemId){        
        return IMCC_HomeCtrl.updatePurchaseSummary(type, cemId);
    }
    
    /**
    * @description get Purchase Summary
    * @param editionCode
    * @param accountId
    * @return List<Purchase_Summary__c>
    */
    @AuraEnabled(cacheable=true)
    public static List<Purchase_Summary__c> getPurchaseSummary(String editionCode, String accountId){
        List<Purchase_Summary__c> psl;
        try{
            //get event setting
            List<Edition__c> listEd = [SELECT Id,Event_Setting__c FROM Edition__c WHERE Edition_Code__c=:editionCode WITH SECURITY_ENFORCED LIMIT 1];
        
            if(!listEd.isEmpty()){
                psl = [SELECT Id,Name,Is_Active__c,External_Link__c,External_Link_Label__c
                                   ,Mark_This_Task_Helptext__c,Purchase_Summary_Type__c,Event_Setting__c,Task_Submission_Type__c,
                                   Event_Tab__c FROM Purchase_Summary__c WHERE Event_Setting__c=:listEd.get(0).Event_Setting__c AND Is_Active__c = TRUE
                                   AND Purchase_Summary_Type__c = 'Badge' WITH SECURITY_ENFORCED LIMIT 1];
            }
        }
        catch (Exception e) {String mesg = String.isNotBlank(e.getMessage()) ? e.getMessage():'';String stackTrace = e.getStackTraceString().substringBefore('\n');throw new AuraHandledException('Message='+mesg+'Stacktrace='+stackTrace);                     
        } 
        
        return psl;
    }
}