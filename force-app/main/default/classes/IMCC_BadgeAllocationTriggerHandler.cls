/**
* Created By     :  Girikon(Shiv[IMCC-4279])
* Created On     :  05/09/2022
* @description   :  This class is used for handle logic - If Unlimited Badges checkbox is checked on Badge_Allocation_c then Unlimited Badges checkbox will be checked on purchase Data 
					on after insert or after update of Badge Allocation. 
* Apex Test Class:  IMCC_BadgeAllocationTriggerHandler_Test(100%)
**/

public class IMCC_BadgeAllocationTriggerHandler {
    
    /**
    * @description This method will update Unlimited Badges checkbox on purchase data 
                    If Unlimited Badges checkbox is checked on Badge_Allocation_c 
    * @param newMap
    * @param oldMap
    */
    public static void handleAfterInsertAfterUpdateBadgeAllocation(Map<Id, Badge_Allocation__c> newMap,Map<Id, Badge_Allocation__c> oldMap){
        Set<Id> bgSettingIds = new Set<Id>();
        Map<Id,Edition__c> editionMap = new Map<Id,Edition__c>();  
        Map<Id,Purchase_Data__c> purchaseDataToUpdate = new Map<Id,Purchase_Data__c>();
        Map<Id,Set<Id>> badgeSettingIdEditionIds = new Map<Id,Set<Id>>();
        Map<String,Map<String,List<Purchase_Data__c>>> purchaseDataQtyMap = new Map<String,Map<String,List<Purchase_Data__c>>>();
        
        try{
            for(Badge_Allocation__c bg : newMap.Values()){
                if((oldMap == null && newMap.get(bg.id).Unlimited_Badges__c == true) || (oldMap.get(bg.id).Unlimited_Badges__c != newMap.get(bg.id).Unlimited_Badges__c)){
                    if(bg.Badge_Setting__c != null){
                        bgSettingIds.add(bg.Badge_Setting__c);
                    }
                }
            } 
            
            if(!bgSettingIds.isEmpty() && (Schema.sObjectType.Edition__c.isAccessible())){
                for(Edition__c editionData : [SELECT Id,Edition_Status__c,Badge_Setting__c FROM Edition__c WHERE Edition_Status__c = 'Confirmed' AND Badge_Setting__c IN: bgSettingIds]){
                    Set<Id> editionIds = (badgeSettingIdEditionIds.ContainsKey(editionData.Badge_Setting__c)?badgeSettingIdEditionIds.get(editionData.Badge_Setting__c):new Set<Id>());
                    editionIds.add(editionData.Id);
                    badgeSettingIdEditionIds.put(editionData.Badge_Setting__c,editionIds);
                    editionMap.put(editionData.Id,editionData);
                }              
            }
            
            if(Schema.sObjectType.Purchase_Data__c.isAccessible()){
                for(Purchase_Data__c pdData : [Select id,Unlimited_Badges__c,Quantity_Area__c,User_Type__c,Purchase_Status__c,Edition__c,Booth_Product_Type__c,Transaction_Status__c,Contact_Edition_Mapping__r.Unlimited_Badges__c from Purchase_Data__c where Edition__c IN: editionMap.keyset() And Purchase_Status__c = 'Active' And Transaction_Status__c ='Active']){
                    Map<String,List<Purchase_Data__c>> mapProdTypePDListTemp = (purchaseDataQtyMap.ContainsKey(pdData.Edition__c)?purchaseDataQtyMap.get(pdData.Edition__c):new Map<String,List<Purchase_Data__c>>());
                    List<Purchase_Data__c> pdDataList = (mapProdTypePDListTemp.ContainsKey(pdData.Booth_Product_Type__c)?mapProdTypePDListTemp.get(pdData.Booth_Product_Type__c):new List<Purchase_Data__c>());
                    pdDataList.add(pdData);
                    mapProdTypePDListTemp.put(pdData.Booth_Product_Type__c,pdDataList);
                    purchaseDataQtyMap.put(pdData.Edition__c,mapProdTypePDListTemp);                 
                }
            }
            
            for(Badge_Allocation__c badgeAllocateData : newMap.Values()){
                Set<String> boothProductTypeSet = new Set<String>();
                if(badgeAllocateData.Booth_Product_Type__c != null && badgeAllocateData.Booth_Product_Type__c !=''){
                    boothProductTypeSet.addAll(badgeAllocateData.Booth_Product_Type__c.split(';'));
                }                
                Set<String> userTypeSet = new Set<String>();
                if(badgeAllocateData.User_Type__c != null && badgeAllocateData.User_Type__c !=''){
                    userTypeSet.addAll(badgeAllocateData.User_Type__c.split(';'));
                }
                Id badgeSettingId = badgeAllocateData.Badge_Setting__c;
                Map<String,List<Purchase_Data__c>> mapProdTypePDList = new Map<String,List<Purchase_Data__c>>(); 
                for(Id editionId : badgeSettingIdEditionIds.get(badgeSettingId)){
                    mapProdTypePDList  = purchaseDataQtyMap.get(editionId);                
                }
                
                for(string boothType : boothProductTypeSet){                   
                    if(mapProdTypePDList != null && mapProdTypePDList.containsKey(boothType)){
                        List<Purchase_Data__c> pHDataList = mapProdTypePDList.get(boothType);
                        for(Purchase_Data__c pH : pHDataList){
                            Boolean cemFieldVal = pH.Contact_Edition_Mapping__r.Unlimited_Badges__c;
                            if(userTypeSet.contains(pH.User_Type__c)){
                                if(badgeAllocateData.Upper__c != null){
                                    if((badgeAllocateData.Lower__c <= pH.Quantity_Area__c) && (pH.Quantity_Area__c <= badgeAllocateData.Upper__c)){
                                        pH.Unlimited_Badges__c = (cemFieldVal?true:badgeAllocateData.Unlimited_Badges__c);
                                        purchaseDataToUpdate.put(pH.Id,pH);
                                    } 
                                }
                                else{
                                    if(badgeAllocateData.Lower__c <= pH.Quantity_Area__c){
                                        pH.Unlimited_Badges__c = (cemFieldVal?true:badgeAllocateData.Unlimited_Badges__c);
                                        purchaseDataToUpdate.put(pH.Id,pH);
                                    } 
                                }
                            }
                        }
                    }
                }                                
            } 
            if(!purchaseDataToUpdate.isEmpty())
            {
                update purchaseDataToUpdate.Values();
            }
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Badge_Allocation__c', 'After Update');
        }        
    }
}