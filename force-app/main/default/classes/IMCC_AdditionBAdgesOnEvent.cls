/**
* Created/Modified By: Girikon(Arushi[IMCC-59])
* Created On    :      23/12/2021
* @description  :      This class is used to allocate the additional badges to the given Edition and to the related purchase data records 
* Methods:             getData
* Apex Class:          IMCC_AdditionBAdgesOnEvent 
* Apex Test Class:     IMCC_AdditionBAdgesOnEvent_Test(85%)
**/

public  without sharing class IMCC_AdditionBAdgesOnEvent {
   @auraEnabled
    public static void getEditionData(Id editionId, Integer additionBadges){
        
        Set<Id> contactEditionMappingSet = new Set<Id>();
        Set<Id> EditionSet = new Set<Id>();
        List<Edition__c> updateEditionList = new List<Edition__c>();
        List<Purchase_Data__c> purchaseDataToUpdateList = new List<Purchase_Data__c>();
        
        try{
            if(editionId != null && (Schema.sObjectType.Edition__c.isAccessible()))
            {
                for(Edition__c editionData : [SELECT Id, Edition_Status__c,Badge_Setting__c, Additional_Badge_Allocated__c FROM Edition__c WHERE Edition_Status__c = 'Confirmed'AND 
                                                         Customer_Center_Status__c='Active' AND Id =: editionId])
                {
                    if(additionBadges != null){
                        editionData.Additional_Badge_Allocated__c = additionBadges;
                        updateEditionList.add(editionData);
                    }
                }
            }
        
            if(!updateEditionList.isEmpty() && (Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible()))
            {
                for(Contact_Edition_Mapping__c cemData : [SELECT Id,Edition__c,Relationship_Status__c,Access_Type__c FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active'
                                                                    AND Edition__c =: editionId])
                {
                    contactEditionMappingSet.add(cemData.Id);
                }
            }
            
            if(contactEditionMappingSet.size() > 0 && (Schema.sObjectType.Purchase_Data__c.isAccessible()))
            {
                for(Purchase_Data__c pHData : [SELECT Id,Booth_Product_Type__c,Badge_Allocated__c,Contact_Edition_Mapping__c,Purchase_Status__c,Quantity_Area__c,Transaction_Status__c,User_Type__c,
                                               Addition_Badge_Count__c FROM Purchase_Data__c WHERE Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' AND Contact_Edition_Mapping__c IN : contactEditionMappingSet])
                {
                    if(pHData.Addition_Badge_Count__c != null){
                        pHData.Addition_Badge_Count__c += additionBadges;
                        purchaseDataToUpdateList.add(pHData);
                    }
                    else{
                        pHData.Addition_Badge_Count__c = additionBadges;
                        purchaseDataToUpdateList.add(pHData);
                    }
                }
            }
            if(!updateEditionList.isEmpty()) update updateEditionList;
            if(!purchaseDataToUpdateList.isEmpty()) update purchaseDataToUpdateList;
        }
        catch(exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
}