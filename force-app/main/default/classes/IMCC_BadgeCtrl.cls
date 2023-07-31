/**
* Created/Modified By: Girikon(Mukesh[IMCC-142], Arushi[IMCC-44])
* Created On    :      27/12/2021
* @description  :      This class is used for , as an Ops Admin, I should be able to customize the Badge
page in the portal and also set the fields visibility based on event type and user typethe 
badge Allocation records to update the purchase data field with the current badge numbers in bulk
* @description  :      This class is used for , As a Customer , I Should be able to See a tab for my
Registrations information in the portal and to see the badga data table of all the purchase data of current CEM
* Methods:             getData,getData2
* Apex Class:          IMCC_BadgeCtrl 
* Apex Test Class:     IMCC_BadgeCtrl_Test( 98% )
**/
public with sharing class IMCC_BadgeCtrl {
    
    @AuraEnabled
    public static Map<String,Object> getDatas(String accountId, String editionCode){
        
        User userObj = [SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        List<Purchase_Data__c> pd = [SELECT Id,Total_Badges__c,Remaining_Badges__c,Badge_Allocated__c, Addition_Badge_Count__c, Quantity_Area__c, Transaction_Status__c, 
                                     Booth_Number__c, Purchase_Status__c,Submitted_Badge__c, Booth_Product_Type__c FROM Purchase_Data__c 
                                     WHERE Account__c=:String.escapeSingleQuotes(accountId) AND Edition__r.Edition_Code__c=:String.escapeSingleQuotes(editionCode) AND Contact__c=:userObj.ContactId 
                                     WITH SECURITY_ENFORCED];
        return new Map<String,Object>{
            'purchaseData'=>pd
                }; 
                    }
    
    @AuraEnabled                
    public static List<wrapperlist> getDatas2(String accountId, String editionCode){
        
        List<wrapperlist> badgeWrapperList = new List<wrapperlist>();
        List<Badge_Data__c> bdList = new List<Badge_Data__c>();
        List<Contact_Edition_Mapping__c> listCEM = new List<Contact_Edition_Mapping__c>();
        Map<Id, Contact_Edition_Mapping__c> cEMmap = new Map<Id, Contact_Edition_Mapping__c>();
        User userObj = [SELECT Id, contactId FROM User WHERE Id = : UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
        
        if(Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()){
            listCEM = [SELECT Id,Edition__c,Relationship_Status__c,Access_Type__c,Account__c
                       ,Contact__c, Edition__r.Edition_Code__c, Edition__r.Event_Type__c
                       ,Edition__r.Due_Date__c, Edition__r.Badge_Setting__r.Show_Due_Date__c
                       FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' 
                       AND Account__c=:String.escapeSingleQuotes(accountId)
                       AND Edition__r.Edition_Code__c=:String.escapeSingleQuotes(editionCode) 
                       AND Contact__c=:userObj.ContactId];
        }
        
        if(!listCEM.isEmpty()){
            for(Contact_Edition_Mapping__c cemData : listCEM){
                cEMmap.put(cemData.Id,cemData);
            }   
        }
        
        if(Schema.sObjectType.Badge_Data__c.isAccessible()){
            bdList = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Job_Title__c, Country__c,Status__c
                                          ,Purchase_Data__r.Edition__r.Edition_Code__c,Purchase_Data__r.Account__c,Purchase_Data__r.Edition__r.Event_Type__c
                                          ,Purchase_Data__r.Contact__c,Purchase_Data__r.Booth_Number__c,Purchase_Data__r.Booth_Product_Type__c
                                          ,Purchase_Data__r.Edition__r.Due_Date__c,Purchase_Data__r.Edition__r.Badge_Setting__r.Show_Due_Date__c
                                          ,Purchase_Data__r.Contact_Edition_Mapping__c
                                          FROM Badge_Data__c WHERE Purchase_Data__r.Contact_Edition_Mapping__c IN: cEMmap.keySet()];
        }
        
        if(!bdList.isEmpty()){
            for(Badge_Data__c bd : bdList){
                wrapperlist wrap = new wrapperlist();
                wrap.badgeDataId = bd.Id;
                wrap.firstName = bd.First_Name__c;
                wrap.lastName = bd.Last_Name__c;
                wrap.email = bd.Email__c;
                wrap.jobTitle = bd.Job_Title__c;
                wrap.country = bd.Country__c;
                if((bd.Purchase_Data__r.Booth_Number__c == null || bd.Purchase_Data__r.Booth_Number__c == '') && (cEMmap.get(bd.Purchase_Data__r.Contact_Edition_Mapping__c).Edition__r.Event_Type__c =='Online' || cEMmap.get(bd.Purchase_Data__r.Contact_Edition_Mapping__c).Edition__r.Event_Type__c =='Hybrid')){
                    wrap.standNo = 'online';
                }
                else{
                    wrap.standNo = bd.Purchase_Data__r.Booth_Number__c;
                }
                wrap.status = bd.Status__c;
                wrap.boothProduct = bd.Purchase_Data__r.Booth_Product_Type__c;
                wrap.dueDate = cEMmap.containsKey(bd.Purchase_Data__r.Contact_Edition_Mapping__c)?cEMmap.get(bd.Purchase_Data__r.Contact_Edition_Mapping__c).Edition__r.Due_Date__c:null;
                wrap.showDueDate = cEMmap.containsKey(bd.Purchase_Data__r.Contact_Edition_Mapping__c)?cEMmap.get(bd.Purchase_Data__r.Contact_Edition_Mapping__c).Edition__r.Badge_Setting__r.Show_Due_Date__c:false;
                wrap.PurchaseData = bd.Purchase_Data__c;
                badgeWrapperList.add(wrap);
            }  
        }
        
        system.debug('badgeWrapperList'+badgeWrapperList);
        return badgeWrapperList;
    }
    
    public class wrapperlist{
        @AuraEnabled public String badgeDataId{get;set;}
        @AuraEnabled public String firstName{get;set;}
        @AuraEnabled public String lastName{get;set;}
        @AuraEnabled public String email{get;set;}
        @AuraEnabled public String jobTitle{get;set;}
        @AuraEnabled public string country{get;set;}
        @AuraEnabled public String standNo{get;set;}
        @AuraEnabled public String status{get;set;}
        @AuraEnabled public String boothProduct{get;set;}
        @AuraEnabled public date dueDate{get;set;}
        @AuraEnabled public boolean showDueDate{get;set;}
        @AuraEnabled public string PurchaseData{get;set;}
        
    }
}