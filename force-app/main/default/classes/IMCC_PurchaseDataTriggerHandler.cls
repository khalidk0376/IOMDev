/**
* Created       : Girikon(Arushi[IMCC-58])
* Created On    : 20/12/2021
* @description  : This class is used to fetch the badge Allocation records to update the current purchase data with the current badge numbers
* Modified By   : Girikon(Arushi[IMCC-59])
* Modified On   : 27/12/2021
* @description  : This class is used to fetch the badge Allocation records to update the current purchase data with the current badge numbers
* Methods       : additionalBadge
* Test Class    : IMCC_SyncBadgeNumbersBulkCtrl_Test(86%), IMCC_EditionTriggerHandler_Test(64%)
* Coverage      : (98%) 
**/

public without sharing class IMCC_PurchaseDataTriggerHandler {
    
    /**
    * @description this method will allocate badge on purchase based on Badge Allocation
    * @param newPDList
    * @param isCallFromTrigger
    */
    public static void recalculateBadge(List<Purchase_Data__c> newPDList, Boolean isCallFromTrigger){
        Set<Id> editionSet = new Set<Id>();
        List<Purchase_Data__c> agentCOExhbTypePDList = new List<Purchase_Data__c>();
        Map<Id,Edition__c> editionMap = new Map<Id,Edition__c>();
        Map<Id,Set<Id>> badgeSettingIdEditionIds = new Map<Id,Set<Id>>();
        Map<Id,Purchase_Data__c> purchaseDataToUpdate = new Map<Id,Purchase_Data__c>();
        Map<String,Map<String,List<Purchase_Data__c>>> purchaseDataQtyMap = new Map<String,Map<String,List<Purchase_Data__c>>>();

        Set<Id> cemIds = new Set<Id>();
        for(Purchase_Data__c pdData : newPDList){
            cemIds.add(pdData.Contact_Edition_Mapping__c);
        }

        Map<Id,Contact_Edition_Mapping__c> mapCEM = new Map<Id,Contact_Edition_Mapping__c>([SELECT Id,Unlimited_Badges__c FROM Contact_Edition_Mapping__c WHERE Id IN:cemIds WITH SECURITY_ENFORCED]);
        Set<Id> pdIdsAll = new Set<Id>();
        Set<Id> pdIdsProcessed = new Set<Id>();
        for(Purchase_Data__c pdData : newPDList){
            if(pdData.Purchase_Status__c == 'Active' && pdData.Transaction_Status__c =='Active'){
                editionSet.add(pdData.Edition__c);
                if(pdData.User_Type__c == 'Reseller' || pdData.User_Type__c == 'Co-Exhibitor'){
                    agentCOExhbTypePDList.add(pdData);
                }
                else{
                    Map<String,List<Purchase_Data__c>> mapProdTypePDListTemp = (purchaseDataQtyMap.ContainsKey(pdData.Edition__c)?purchaseDataQtyMap.get(pdData.Edition__c):new Map<String,List<Purchase_Data__c>>());
                    List<Purchase_Data__c> pdDataList = (mapProdTypePDListTemp.ContainsKey(pdData.Booth_Product_Type__c)?mapProdTypePDListTemp.get(pdData.Booth_Product_Type__c):new List<Purchase_Data__c>());
                    pdDataList.add(pdData);
                    mapProdTypePDListTemp.put(pdData.Booth_Product_Type__c,pdDataList);
                    purchaseDataQtyMap.put(pdData.Edition__c,mapProdTypePDListTemp);
                }
                if(String.isNotBlank(pdData.Id)){pdIdsAll.add(pdData.Id);}
            }
        }
        
        if(!editionSet.isEmpty() && (Schema.sObjectType.Edition__c.isAccessible())){
            for(Edition__c editionData : [SELECT Id,Edition_Status__c,Badge_Setting__c,Badge_Setting__r.Co_Exhibitor_Badge_Count__c,Badge_Setting__r.Reseller_Badge_Count__c FROM Edition__c WHERE Edition_Status__c = 'Confirmed' AND Badge_Setting__c!= null AND Id IN:editionSet]){
                Set<Id> editionIds = (badgeSettingIdEditionIds.ContainsKey(editionData.Badge_Setting__c)?badgeSettingIdEditionIds.get(editionData.Badge_Setting__c):new Set<Id>());
                editionIds.add(editionData.Id);
                badgeSettingIdEditionIds.put(editionData.Badge_Setting__c,editionIds);
                editionMap.put(editionData.Id,editionData);
            }  
        }
        
        List<Badge_Allocation__c> badgeAllocationList = new List<Badge_Allocation__c>();
        if(Schema.sObjectType.Badge_Allocation__c.isAccessible()){
            badgeAllocationList = [SELECT Id,Badge_Numbers__c,Booth_Product_Type__c,Badge_Setting__c,Lower__c,Upper__c,User_Type__c,Unlimited_Badges__c FROM Badge_Allocation__c WHERE Badge_Setting__c =:badgeSettingIdEditionIds.keySet()];
        }
        
        if(!purchaseDataQtyMap.isEmpty()){
            for(Badge_Allocation__c badgeAllocateData : badgeAllocationList){
                Id badgeSettingId = badgeAllocateData.Badge_Setting__c;
                for(Id editionId : badgeSettingIdEditionIds.get(badgeSettingId)){
                    Map<String,List<Purchase_Data__c>> mapProdTypePDList = purchaseDataQtyMap.get(editionId);
                    
                    Set<String> boothProductTypeSet = new Set<String>();
                    if(badgeAllocateData.Booth_Product_Type__c != null && badgeAllocateData.Booth_Product_Type__c !=''){
                        boothProductTypeSet.addAll(badgeAllocateData.Booth_Product_Type__c.split(';'));
                    }
                    
                    Set<String> userTypeSet = new Set<String>();
                    if(badgeAllocateData.User_Type__c != null && badgeAllocateData.User_Type__c !=''){
                        userTypeSet.addAll(badgeAllocateData.User_Type__c.split(';'));
                    }
                    
                    for(string boothType : boothProductTypeSet){
                        if(mapProdTypePDList != null && mapProdTypePDList.containsKey(boothType)){
                            List<Purchase_Data__c> pHDataList = mapProdTypePDList.get(boothType);
                            for(Purchase_Data__c pH : pHDataList){
                                Contact_Edition_Mapping__c cem = mapCEM.get(pH.Contact_Edition_Mapping__c);
                                Boolean cemFieldVal = cem.Unlimited_Badges__c;
                                if(userTypeSet.contains(pH.User_Type__c)){
                                    if(badgeAllocateData.Upper__c != null){
                                        if((badgeAllocateData.Lower__c <= pH.Quantity_Area__c) && (pH.Quantity_Area__c <= badgeAllocateData.Upper__c)){
                                            pH.Badge_Allocated__c = badgeAllocateData.Badge_Numbers__c;
                                            pH.Unlimited_Badges__c = (cemFieldVal?true:badgeAllocateData.Unlimited_Badges__c);
                                            purchaseDataToUpdate.put(pH.Id,pH);
                                            if(String.isNotBlank(pH.Id)){pdIdsProcessed.add(pH.Id);}
                                        } 
                                    }
                                    else{
                                        if(badgeAllocateData.Lower__c <= pH.Quantity_Area__c){
                                            pH.Badge_Allocated__c = badgeAllocateData.Badge_Numbers__c;
                                            pH.Unlimited_Badges__c = (cemFieldVal?true:badgeAllocateData.Unlimited_Badges__c);
                                            purchaseDataToUpdate.put(pH.Id,pH);
                                            if(String.isNotBlank(pH.Id)){pdIdsProcessed.add(pH.Id);}
                                        } 
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        if(!agentCOExhbTypePDList.isEmpty()){
            for(Purchase_Data__c pH : agentCOExhbTypePDList){
                Contact_Edition_Mapping__c cem = mapCEM.get(pH.Contact_Edition_Mapping__c);
                Boolean cemFieldVal = cem!= null?cem.Unlimited_Badges__c:false;
                if(editionMap.containskey(pH.Edition__c)){
                    if(pH.User_Type__c == 'Co-Exhibitor'){
                        pH.Badge_Allocated__c = editionMap.get(pH.Edition__c).Badge_Setting__r.Co_Exhibitor_Badge_Count__c;
                        if(cemFieldVal){pH.Unlimited_Badges__c = true;}
                        purchaseDataToUpdate.put(pH.Id,pH);
                        if(String.isNotBlank(pH.Id)){pdIdsProcessed.add(pH.Id);}
                    }
                    if(pH.User_Type__c == 'Reseller'){
                        pH.Badge_Allocated__c = editionMap.get(pH.Edition__c).Badge_Setting__r.Reseller_Badge_Count__c;
                        if(cemFieldVal){pH.Unlimited_Badges__c = true;}
                        purchaseDataToUpdate.put(pH.Id,pH);
                        if(String.isNotBlank(pH.Id)){pdIdsProcessed.add(pH.Id);}
                    }
                }
            }
        }

        for(Purchase_Data__c pH : newPDList){
            if(String.isNotBlank(pH.Id) && pdIdsAll.contains(pH.Id) && !pdIdsProcessed.contains(pH.Id)){
                if(String.isNotBlank(pH.Contact_Edition_Mapping__c)){
                    Contact_Edition_Mapping__c cem = mapCEM.get(pH.Contact_Edition_Mapping__c);
                    Boolean cemFieldVal = cem.Unlimited_Badges__c;
                    pH.Badge_Allocated__c = null;
                    pH.Unlimited_Badges__c = false;
                    if(cemFieldVal){pH.Unlimited_Badges__c = true;}
                    purchaseDataToUpdate.put(pH.Id,pH);
                }
            }
        }
        
        if(!isCallFromTrigger && !purchaseDataToUpdate.isEmpty()){update purchaseDataToUpdate.Values();}
    }
    
    /**
    * @description this method will allocate additional badges
    * @param pdList
    * @param cEMSet
    */
    public static void additionalBadge(List<Purchase_Data__c> pdList, Set<Id> cEMSet){
        List<Purchase_Data__c> purchaseDataToUpdateList = new List<Purchase_Data__c>();
        Map<Id,Decimal> editionMap = new Map<Id,Decimal>();
        if(cEMSet.size() > 0 && (Schema.sObjectType.Contact_Edition_Mapping__c.isAccessible())){
            for(Contact_Edition_Mapping__c cemData : [SELECT Id,Edition__c, Edition__r.Additional_Badge_Allocated__c,Relationship_Status__c,Access_Type__c FROM Contact_Edition_Mapping__c WHERE Relationship_Status__c = 'Active' AND Id IN : cEMSet])
            {
                if(cemData.Edition__r.Additional_Badge_Allocated__c != null){
                    editionMap.put(cemData.Id,cemData.Edition__r.Additional_Badge_Allocated__c);
                }
            }
        }
        
        if(!editionMap.isEmpty()){
            for(Purchase_Data__c pHData : pdList){
                if(editionMap.ContainsKey(pHData.Contact_Edition_Mapping__c)){
                    pHData.Addition_Badge_Count__c = (pHData.Addition_Badge_Count__c== null?(0):(pHData.Addition_Badge_Count__c)) + editionMap.get(pHData.Contact_Edition_Mapping__c);
                    purchaseDataToUpdateList.add(pHData);
                }  
            }
        }
    }
    
    /**
    * @description this method will notify User To Assign Contractor
    * @param newPHMap
    * @param oldPHMap
    */
    public static void notifyUserToAssignContractor(Map<Id, Purchase_Data__c> newPHMap,Map<Id, Purchase_Data__c> oldPHMap){
        Set<Id> pdIds = new Set<Id>();
        
        try{
            for(Purchase_Data__c pH : newPHMap.Values()){
                if((oldPHMap == null && newPHMap.get(pH.id).Purchase_Status__c == 'Active') || (oldPHMap.get(pH.id).Purchase_Status__c != 'Active' && newPHMap.get(pH.id).Purchase_Status__c == 'Active')){
                    if((pH.Booth_Number__c!=null && pH.Booth_Number__c!='') && (pH.Booth_Product_Type__c =='Space' || pH.Booth_Product_Type__c == 'Space Only')){
                        pdIds.add(pH.Id);
                    }
                }
            }
            if(!pdIds.isEmpty()){
                notifyUserToAssignContractor(pdIds);
            }
            
        }
        catch (Exception ex) {
            HandleAllCustomException.logException(ex,'Edition__c', 'After Update');
        }
    }

    /**
    * @description this method will notify User To Assign Contractor Based of Purchased Datas
    * @param pdIds
    */
    public static void notifyUserToAssignContractor(Set<Id> pdIds){

        Map<Id,Date> mapEditionIdConAssignDate = new Map<Id,Date>();
        set<Id> conIds = new set<Id>();
        List<Task> taskList = new List<Task>();
        List<Task> tasksToBeCreated = new List<Task>();
        List<Task> taskToBeUpdated = new List<Task>();
        Map<Id,Contact_Edition_Mapping__c> mapCEM = new Map<Id,Contact_Edition_Mapping__c>();
        Map<Id,Id> userConMap = new Map<Id,Id>();  
        Map<String,Task> taskMap = new Map<String,Task>();
        
        List<Purchase_Data__c> listPD  = [SELECT Id, Contact_Edition_Mapping__c,Contact_Edition_Mapping__r.Contact__c,Contact_Edition_Mapping__r.Edition__c,Contractor_Mapping__c,Contractor_Mapping__r.Contractor_Status__c,Contact_Edition_Mapping__r.Edition__r.Contractor_Nomination_Due_Date__c FROM Purchase_Data__c WHERE Booth_Number__c!=null AND Booth_Number__c!='' AND Id IN:pdIds AND Booth_Product_Type__c IN ('Space','Space Only') AND Purchase_Status__c = 'Active' AND Transaction_Status__c ='Active' AND Contact_Edition_Mapping__r.Relationship_Status__c = 'Active' AND Contact_Edition_Mapping__r.Edition__r.Stand_Setting__c != null AND Contact_Edition_Mapping__r.CC_Status__c = 'Active' WITH SECURITY_ENFORCED];

        for(Purchase_Data__c pHData : listPD){
            if(String.isBlank(pHData.Contractor_Mapping__c) || (String.isNotBlank(pHData.Contractor_Mapping__c) && (pHData.Contractor_Mapping__r.Contractor_Status__c == 'Contractor Declined Nomination' || pHData.Contractor_Mapping__r.Contractor_Status__c == 'New Contractor Nomination Rejected'))){
                mapCEM.put(pHData.Contact_Edition_Mapping__c, pHData.Contact_Edition_Mapping__r);
                  
                conIds.add(pHData.Contact_Edition_Mapping__r.Contact__c);

                mapEditionIdConAssignDate.put(pHData.Contact_Edition_Mapping__r.Edition__c,pHData.Contact_Edition_Mapping__r.Edition__r.Contractor_Nomination_Due_Date__c);
            }
        }
        
        if(!conIds.isEmpty()){
            for(User usr : [SELECT Id,ContactId FROM User WHERE ContactId IN:conIds AND IsActive=true WITH SECURITY_ENFORCED]){
                userConMap.put(usr.ContactId,usr.Id);  
            }
        }
        
        //System.debug('boothToBeAssigned' + boothToBeAssigned);
        if(Schema.sObjectType.Task.isAccessible()){
            taskList = [SELECT Id, WhoId, WhatId, Subject, ActivityDate, Status, Priority, IsHighPriority, OwnerId, ReminderDateTime FROM Task WHERE WhoId IN:conIds  AND WhatId IN:mapEditionIdConAssignDate.KeySet() AND Status = 'Open' AND Subject='Nominate the Contractor'];
        }
        
        for(Task t : taskList){
            if(mapEditionIdConAssignDate.ContainsKey(t.whatId) && (t.ActivityDate != mapEditionIdConAssignDate.get(t.whatId))){
                t.ActivityDate = mapEditionIdConAssignDate.get(t.whatId);
                t.ReminderDateTime = mapEditionIdConAssignDate.get(t.whatId).addDays(-7);
                taskToBeUpdated.add(t);
            }
            taskMap.put('Nominate the Contractor_' + t.WhoId + '_' + t.WhatId, t);
        }
        
        if(!mapCEM.isEmpty()){
            for(Contact_Edition_Mapping__c cEEM : mapCEM.Values()){
                String key = 'Nominate the Contractor_' + cEEM.Contact__c + '_' + cEEM.Edition__c;
                if(!taskMap.containsKey(key) && userConMap.containsKey(cEEM.Contact__c)){
                    Task tsk = new Task();
                    tsk.Subject = 'Nominate the Contractor';
                    tsk.WhatId = cEEM.Edition__c;
                    tsk.OwnerId = userConMap.get(cEEM.Contact__c);
                    tsk.WhoId = cEEM.Contact__c;
                    tsk.ActivityDate = cEEM.Edition__r.Contractor_Nomination_Due_Date__c;
                    tsk.IsReminderSet = true;
                    tsk.ReminderDateTime = cEEM.Edition__r.Contractor_Nomination_Due_Date__c.addDays(-7);
                    tsk.Status = 'Open';
                    tsk.Type = 'meeting';
                    tasksToBeCreated.add(tsk);
                }
            }
            
            if(!tasksToBeCreated.isEmpty() && Schema.sObjectType.Task.isCreateable()){
                insert tasksToBeCreated;
            }
            if(!taskToBeUpdated.isEmpty() && Schema.sObjectType.Task.isUpdateable()){
                update taskToBeUpdated;
            }
        }
    }
}