/**
* File			: 	IOM_ObjectValidation
* Project       :   Informa Order Management
* Created By	: 	Suresh(Girikon)
* Created Date	: 	28th Dec 2021
* Test Class   :    IOM_ObjectValidation_Test(100%)
* ***************************************************************************
* @description : Class to prevent user from deleting opportunity,account and Contact
*****************************************************************************
* Last Modified By :
*/
public with sharing class IOM_ObjectValidation {
    
    public static IOM_Application_Bypass__c abpUser = IOM_Application_Bypass__c.getInstance(UserInfo.getUserId());
/**
* @description  This method is used to prevent user from deleting opportunities
* @param opplist opportunity list
* @param oppmap map of opportunity
*/
    public static void oppValidate(List<Opportunity> opplist, Map<Id,Opportunity> oppmap) 
    {
        for(Opportunity opp : opplist){
            if(opp.IOM_Sync_Status__c == IOM_GlobalConstantsData.getValue('IOM_Sync_Status') &&
              abpUser.Bypass_Opportunity_Deletion__c != true){
                opp.addError('You are not allowed to delete Opportunity records!');
            }
        }
        
    }
    
/**
* @description  This method is used to prevent user from deleting accounts
* @param acclist opportunity list
* @param accmap map of opportunity
*/
    public static void accValidate(List<Account> acclist, Map<Id,Account> accmap) 
    {
        for(Account acc : acclist){
            if(acc.IOM_Sync_Status__c == IOM_GlobalConstantsData.getValue('IOM_Sync_Status') &&
              abpUser.Bypass_Account_Deletion__c != true){
                acc.addError('You are not allowed to delete Account records!');
            }
        }
        
    }
/**
* @description  This method is used to prevent user from deleting contacts
* @param conlist opportunity list
* @param conmap map of opportunity
*/
    public static void conValidate(List<Contact> conlist, Map<Id,Contact> conmap) 
    {
        for(Contact con : conlist){
            if(con.IOM_Sync_Status__c == IOM_GlobalConstantsData.getValue('IOM_Sync_Status') &&
              abpUser.Bypass_Contact_Deletion__c != true){
                con.addError('You are not allowed to delete Contact records!');
            }
        }
        
    }    
}