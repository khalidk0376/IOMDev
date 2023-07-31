/**  
* Created By         : Girikon(Keertiraj)
* Created On         : 06/10/2021
* Modified By        : Girikon(Garima)
* Modified Date      : 16/08/2022 - (IMCC-4188)
* @description       : This class is used to update Contact's Account if Account is blank and also create community user if not already exists                   
* Test Class         : IMCC_ContactEdMapTriggerHandler_Test(100%)
*/

public without sharing class IMCC_ContactEditionMappingTriggerHandler {
    /**
    * @description After Insert Handler for Contact Edition Mapping to update Contact's Account if Account is blank and create community user if not already exists
    * @param lstConEvnMap
    */
    public static void handleAfterInsert(List<Contact_Edition_Mapping__c> lstConEvnMap){
        List<Contact> conList = new List<Contact>();
        Set<Id> contactId = new Set<Id>();
        for(Contact_Edition_Mapping__c cem : lstConEvnMap){
            contactId.add(cem.Contact__c);
        }
        Map<Id,Contact> conMap = New Map<Id,Contact>([Select id,AccountId from Contact where Id IN: contactId WITH SECURITY_ENFORCED]);
        for(Contact_Edition_Mapping__c cem : lstConEvnMap){
            if((String.isBlank(conMap.get(cem.Contact__c).AccountId))){
                Contact con = new Contact();
                con.Id = cem.Contact__c;
                con.AccountId = cem.Account__c;
                conList.add(con);
            }
        }
        if(Schema.sObjectType.Contact.isUpdateable()){
            update conList;
        }
        
        IMCC_EditionWelcomeEmail.processWelcomeEmail(lstConEvnMap, false);
    }
    
    /**
    * @description set/unset Unlimited Badges On Purchase datas
    * @param newMap
    * @param oldMap
    */
    public static void updatePurchaseData(Map<Id, Contact_Edition_Mapping__c> newMap, Map<Id, Contact_Edition_Mapping__c> oldMap){
        Set<Id> cemIds = new Set<Id>();
        for(Contact_Edition_Mapping__c cem : newMap.Values()){
            if((oldMap==null && cem.Unlimited_Badges__c) || (oldMap!=null && cem.Unlimited_Badges__c != oldMap.get(cem.Id).Unlimited_Badges__c)){
                cemIds.add(cem.Id);
            }
        }
        List<Purchase_Data__c> listPData = new List<Purchase_Data__c>();
        if(Schema.sObjectType.Purchase_Data__c.isAccessible() && !cemIds.isEmpty()){
            listPData = new List<Purchase_Data__c>([SELECT Id,Booth_Product_Type__c,Badge_Allocated__c,Contact_Edition_Mapping__c,Purchase_Status__c,Quantity_Area__c,Transaction_Status__c,User_Type__c,Edition__c FROM Purchase_Data__c WHERE Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' AND Contact_Edition_Mapping__c IN:cemIds AND Edition__r.Edition_Status__c = 'Confirmed']);
            IMCC_PurchaseDataTriggerHandler.recalculateBadge(listPData,false);
        }
    }
}